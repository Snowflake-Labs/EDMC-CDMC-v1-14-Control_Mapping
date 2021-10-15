# coding=utf-8
##########################################################################################
# Name: Lifecycle_Archive_Policy_Bot
# Description:
# This is a monitoring script for data sources, schemas, tables, and columns.  It
# checks if a lifecycle stage has been changed to 'archive request'.
#
# When the condition is satisfied it triggers a notification to the steward assigned
# and asks for confirmation that all child assets should also be included.  A count of those assets and their
# status is included.
#
# If they respond YES then a task is sent to the IT Service Management org requesting archival.
# If NO then a reply is sent by the Policy Bot to the steward telling them the task be closed and not completed.
#
# The code uses the Alation Django framework.
#
# Author: Alation
# Alation Catalog Version: 2021.3
#
# Catalog Requirements:
# 1. Custom Field of type Picker named Lifecycle Stage.
#
# Notice of Usage, Rights, and Alation Responsibility:
# This code is provided as an example and is not intended for use on production
# Alation Catalog instances.  It should only be used on non-production Alation
# catalog instances.  Alation does not provide support for the code and it is not
# covered by the Alation subscription and its associated support agreement. Alation
# is not responsible for any harm it may cause, including the unrecoverable corruption
# of a catalog instance. Its recommended that modifications to this code and production
# use by Alation customers only be done with the direct engagement of Alation
# Professional Services.
#
##########################################################################################

import bootstrap_rosemeta
from django.db.models import Count
from rosemeta.models import cast_to_uuid
from rosemeta.models import GroupProfile
from rosemeta.models.models_text import Article
from rosemeta.models.models_customize import CustomField, CustomFieldValue, CustomGlossary, CustomTemplate
from logical_metadata.models.models_values import PickerFieldValue, RichTextFieldValue, PickerValueHistory, DateFieldValue, PickerFieldValueDiff
from alation_object_type_directory.resources import ObjectKey
from alation_object_type_directory.resources import cast_to_uuid
from alation_object_types.enums import ObjectType
from logical_metadata.models import Operation
from logical_metadata.public.builtin_field_helpers import update_assignee
from rosemeta.models import DataSource, Schema, Table, Attribute
from rosemeta.models import Post
from rosemeta.models import PostType
from rosemeta.models import Thread
from stewardship.models import UserTask
from stewardship.enums import UserTaskType
from rosemeta.models.enums import CustomFieldType
from logical_metadata.resources import *
from django.contrib.auth.models import Group
from django.contrib.auth.models import User
import urllib
from datetime import datetime, timedelta, timezone

# defaults for generated conversations
title_changed_to_archival_requested = 'Action Required: Confirm archival request for all child assets'
text_changed_to_archival_requested = 'The Lifecycle Stage for this asset has been changed to "Archival - Requested".  This ' \
                                  'will result in this AND all child objects being also changed to "Archival - Requested" and ' \
                                  'the archival request process will submitted and confirmed when completed.  ' \
                                  'If this was your intention reply with YES in the body of the reply.  If it was not ' \
                                  'your intent reply with NO in the body of the reply and no action will be taken.'

title_changed_to_archival_confirmed = 'Action Required: Archival request confirmed'
text_changed_to_archival_confirmed = 'An archival request has been confirmed for this asset and all its child assets.' \
                                     ' Please complete the request and mark this task resolved when finished.'

title_changed_to_archival_not_confirmed = 'Archival request cancelled for this asset'
text_changed_to_archival_not_confirmed = 'The change of the Lifecycle Stage of the asset to Archival - Requested was not confirmed. ' \
                                         'This asset and none of its child assets will be archived.  Please change the status of this ' \
                                         'task to resolved.'

# get the server admins and catalog admins in case we need to assign them to a conversation
server_admins = GroupProfile.objects.get(group__name="Server Admins").group
my_admin = server_admins.user_set.first()
default_catalog_admin = server_admins.user_set.last()
IT_service_admins = GroupProfile.objects.get(group__name="IT Services").group
IT_service_admin =IT_service_admins.user_set.first()
policyBot = User.objects.get(username='jdubudubu@gmail.com')

#print('got users')

def create_task(type, id, stewardid, title, bodytext):
    # check if a conversation already exists and it is not approved yet, so we don't repeat - task_status=0 is
    # not approved
    task_exist_or_approved = False

    for my_thread in Thread.objects.filter(_subject_oid=cast_to_uuid(id), subject_otype=type).values():
        my_user_task = UserTask.objects.filter(subject_otype=ObjectType.THREAD,
                                               subject_uuid=cast_to_uuid(my_thread.get('id')), task_status=0,
                                               deleted=False)
        mut_len = len(my_user_task)
        #print('in check for task')

        # task exists but not approved
        if mut_len == 1 and my_thread['title'] == title:
            task_exist_or_approved = True

    # check if conversation already exists and is approved - unlikely unless the check happens infrequently
    for my_thread in Thread.objects.filter(_subject_oid=cast_to_uuid(id), subject_otype=type).values():
        my_user_task = UserTask.objects.filter(subject_otype=ObjectType.THREAD,
                                               subject_uuid=cast_to_uuid(my_thread.get('id')), task_status=1,
                                               deleted=False)
        mut_len = len(my_user_task)
        #print('in second check for task')

        if mut_len == 1 and my_thread['title'] == title:
            task_exist_or_approved = True

    # if conversation existence check failed then create the new conversation
    if not task_exist_or_approved:
        #print('in starting conversation task')
        # create a discussion thread using the text argument, but replacing title and template
        question = dict(otype='post', post_type='question', text=bodytext.format(title=title))

        # create the conversation (aka a thread)
        thread = Thread.objects.create(author=policyBot, _subject_oid=cast_to_uuid(id), subject_otype=type,
                                       title=title, question_post=question)
        #print('after created thread')

        # get the user as found above when processing the data source, if no steward assign to server admin
        if stewardid == 0:
            uid = my_admin.id
        else:
            uid = stewardid

        # get the task object key so we can update the assigned
        #print('do assignment')
        user_task_obj_key = ObjectKey(ObjectType.USER_TASK, thread.user_task_id())
        update_assignee(user_task_obj_key, ObjectKey(ObjectType.USER, uid), Operation.ADD, policyBot.id)


# get all picker value history where Lifecycle Stage field is populated and current value of Archival Requested
aFields = PickerValueHistory.objects.filter(field_id=10031).values()

# create list to check later to make sure we don't process duplicate oids
oid_list = []

# declare variables
tmp_otype = 0
tmp_otype_string = ''
tmp_ts = ''
tmp_object_set = ''
tmp_oid = 0
tmp_current_value = ''

# outer loop for iterating over all returned pickers
for aField in aFields:

    # check to see if the oid is in the list and has been processed already
    if aField['oid'] not in oid_list:

        # inner loop for finding the latest record for a picker based on timestamp
        for item in aFields:
            if aField['oid'] == item['oid']:
                if aField['ts_updated'] > item['ts_updated']:
                    tmp_object_set=aField['old_object_set']
                    tmp_oid=aField['oid']
                    tmp_ts=aField['ts_updated']
                    tmp_otype=aField['otype']
                    tmp_current_value = aField['text']
                else:
                    tmp_object_set=item['old_object_set']
                    tmp_oid=item['oid']
                    tmp_ts=item['ts_updated']
                    tmp_otype = item['otype']
                    tmp_current_value = item['text']

        # check if the previous value found was not 'Archival - Requested', if so send the task
        if tmp_current_value == 'Archival - Requested':

            if tmp_otype == 23:
                tmp_otype_string = ObjectType.SCHEMA
                tmp_otype_name = 'SCHEMA'
            elif tmp_otype == 1:
                tmp_otype_string = ObjectType.ATTRIBUTE
                tmp_otype_name = 'ATTRIBUTE'
            elif tmp_otype == 7:
                tmp_otype_string = ObjectType.DATA
                tmp_otype_name = 'DATA'
            elif tmp_otype == 27:
                tmp_otype_string = ObjectType.TABLE
                tmp_otype_name = 'TABLE'
            else:
                continue

            # create object for the associated object that we need to create the conversation for
            my_obj = ObjectKey(tmp_otype_string, tmp_oid)

            # get all picker fields for the object so we can find the steward on that object
            Pickers = PickerFieldValue.objects.filter(otype=tmp_otype_string).values()

            # initialize the steward id
            stewardid = 0

            # start looking for stewards on the object
            for Picker in Pickers:

                # get the steward on the attribute - 8 is the field_id for Stewards
                if Picker['oid'] == my_obj.oid and Picker['field_id'] == 8:

                    # get the first in what could be a list of stewards
                    first = Picker['object_set'][0]

                    # the value is a combination of type (user or group) and id so we split these
                    type, id = first.split("_")

                    # user
                    if type == '33':
                        steward = User.objects.filter(id=id).values('id', 'username')
                        # print('steward:' + steward[0]['username'])
                        # print('steward ID:' + str(steward[0]['id']))
                        stewardid = steward[0]['id']
                        break

                    # group
                    if type == '38':
                        steward = GroupProfile.objects.filter(id=id).values('builtin_name')
                        stewardid = 0
                        break

            # call the creat task function
            create_task(tmp_otype_name.lower(), my_obj.oid, stewardid, title_changed_to_archival_requested, text_changed_to_archival_requested)

        #print(str(tmp_object_set))
        #print(str(tmp_oid))
        #print(str(tmp_ts))
        #print(str(tmp_otype))
        #print(str(tmp_otype_string))

        # add the processed oid to the list so its not processed again.
        oid_list.append(tmp_oid)

# check for confirmation responses and process them

# get all threads and find the ones for data sources, schemas, tables with a reply that includes YES or NO
threads = Thread.objects.filter(deleted=False).values()
for thread in threads:
    #print(thread['title'])
    #print(thread['id'])

    # check and make sure its not an old already resolved task.  If it is then skip it. task_status of 1 is resolved
    thread_user_task = UserTask.objects.filter(subject_otype=ObjectType.THREAD, subject_uuid=cast_to_uuid(thread.get('id')),
                                                task_status=1,
                                                deleted=False)
    mut_len = len(thread_user_task)

    if mut_len == 1 and thread['title'] == title_changed_to_archival_requested:
        continue

    #Initialize variables
    YES_found = False
    NO_found = False

    # only continue processing threads that are for archival requests
    if 'archival request' in thread['title']:

        # get all posts for the thread
        posts = Post.objects.filter(post_type='answer',thread_id=thread['id']).values()
        for post in posts:
            #print(post['text'])

            # check if YES or NO is in any of the replies
            if 'YES' in post['text']:
                YES_found =True

            if 'NO' in post['text']:
                NO_found = True

        # after all replies processed take action
        if YES_found:

            # process Data Source hierarchy
            if thread['subject_otype'] == 'data':

                # get all schemas
                schemas = Schema.objects.all().values()
                for schema in schemas:

                    if thread['_subject_oid'] == cast_to_uuid(schema['id']):

                        # create and object key for the schema
                        p = ObjectKey(ObjectType.SCHEMA, cast_to_uuid(schema['id']))

                        # create the picker update diff and update the value
                        diff = PickerFieldValueDiff('Archival - Request (Propagated)')
                        PickerFieldValue.update_value_with_diff(object_key=p, field_id=10031, diff=diff, user_id=policyBot.id)

                        # get all tables
                        tables = Table.objects.filter(schema_obj=schema['id']).values()
                        for table in tables:

                            # create and object key for the table
                            p = ObjectKey(ObjectType.TABLE, cast_to_uuid(table['id']))

                            # create the picker update diff and update the value
                            diff = PickerFieldValueDiff('Archival - Request (Propagated)')
                            PickerFieldValue.update_value_with_diff(object_key=p, field_id=10031, diff=diff,
                                                                    user_id=policyBot.id)

                            # get all columns
                            attrs = Attribute.objects.filter(table_obj=table['id']).values()
                            for attr in attrs:

                                # create and object key for the table
                                p = ObjectKey(ObjectType.ATTRIBUTE, cast_to_uuid(attr['id']))

                                # create the picker update diff and update the value
                                diff = PickerFieldValueDiff('Archival - Request (Propagated)')
                                PickerFieldValue.update_value_with_diff(object_key=p, field_id=10031, diff=diff,
                                                                        user_id=policyBot.id)

            elif thread['subject_otype'] == 'schema':

                # get all tables
                tables = Table.objects.filter(schema_obj=thread['_subject_oid']).values()
                for table in tables:

                    # create and object key for the table
                    p = ObjectKey(ObjectType.TABLE, cast_to_uuid(table['id']))

                    # create the picker update diff and update the value
                    diff = PickerFieldValueDiff('Archival - Request (Propagated)')
                    PickerFieldValue.update_value_with_diff(object_key=p, field_id=10031, diff=diff,
                                                            user_id=policyBot.id)

                    # get all columns
                    attrs = Attribute.objects.filter(table_id=table['id']).values()
                    for attr in attrs:
                        # create and object key for the table
                        p = ObjectKey(ObjectType.ATTRIBUTE, cast_to_uuid(attr['id']))

                        # create the picker update diff and update the value
                        diff = PickerFieldValueDiff('Archival - Request (Propagated)')
                        PickerFieldValue.update_value_with_diff(object_key=p, field_id=10031, diff=diff,
                                                                user_id=policyBot.id)

            elif thread['subject_otype'] == 'table':

                # get all columns
                attrs = Attribute.objects.filter(table=thread['_subject_oid']).values()
                for attr in attrs:
                    # create and object key for the table
                    p = ObjectKey(ObjectType.ATTRIBUTE, cast_to_uuid(attr['id']))

                    # create the picker update diff and update the value
                    diff = PickerFieldValueDiff('Archival - Request (Propagated)')
                    PickerFieldValue.update_value_with_diff(object_key=p, field_id=10031, diff=diff,
                                                            user_id=policyBot.id)

            else:
                #something went wrong so just continue
                continue

            # create conversion for IT Services to complete the archival task

            # create object for the associated object that we need to create the conversation for
            tmp_otype_string = thread['subject_otype'].lower()
            my_obj = ObjectKey(tmp_otype_string, thread['_subject_oid'])

            # call the creat task function
            create_task(tmp_otype_string, my_obj.oid, IT_service_admin.id, title_changed_to_archival_confirmed,
                        text_changed_to_archival_confirmed)

        elif NO_found:
            # reply to thread to acknowledge that no action will be taken
            print(str(thread['id']))
            print(str(policyBot.id))
            a = Post.objects.create(otype='post', thread_id=thread['id'], post_type='answer',
                                    text=text_changed_to_archival_not_confirmed, author_id=policyBot, last_edited_by=policyBot)
            a.save()

            # not sure why the first save did not commit these values but I fought that I have to explicitly add them
            # afterwards and save again or the post gets created but is never associated to the thread
            a.thread_id=thread['id']
            a.author=policyBot
            a.last_edited_by=policyBot
            a.save()
            print(str(a.id))
            print(str(a.thread_id))
            print(str(a.author))

        else:
            # something went wrong, skip to the next thread with continue
            continue
