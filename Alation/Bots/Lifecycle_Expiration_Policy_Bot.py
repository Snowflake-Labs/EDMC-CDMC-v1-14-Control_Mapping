# coding=utf-8
##########################################################################################
# Name: Lifecycle_Expiration_Policy_Bot
# Description:
# This is a monitoring script for data sources, schemas, tables, and columns.  It
# checks if a lifecycle expiration date has passed.
#
# When the condition is satisfied it triggers a notification to the steward assigned
# to the asset via a conversation.  The notification let's them know that they need
# to evaluate the asset and either reset the expiration date of change the lifecycle status.  It also checks if a
# task already exists but has not been resolved, as we don't want to overwhelm the steward with
# duplicative notices.
#
# The code uses the Alation Django framework.
#
# Author: Alation
# Alation Catalog Version: 2021.3
#
# Catalog Requirements:
# 1. Custom Field of type Date named Lifecycle Expiration Date.
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
from logical_metadata.models.models_values import PickerFieldValue, RichTextFieldValue, PickerValueHistory, DateFieldValue
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

attributePII = False
tableEntitlement = False
schemaEntitlement = False

# defaults for generated conversations
title_review_asset = 'Action Required: Data Asset Lifecycle Expired'
text_review_asset = 'The expiration date for the lifecycle stage setting of this data asset has expired. ' \
              ' By policy, you are required to review the asset and either reset the expiration date or change '\
              'the lifecycle stage.  Mark the task resolved when completed. '


def create_task(type, id, stewardid, title, bodytext):
    # check if a conversation already exists and it is not approved yet, so we don't repeat - task_status=0 is
    # not approved
    task_exist_or_approved = False

    # get the server admins and catalog admins in case we need to assign them to a conversation
    server_admins = GroupProfile.objects.get(group__name="Server Admins").group
    my_admin = server_admins.user_set.first()
    default_catalog_admin = server_admins.user_set.last()
    policyBot = User.objects.get(username='jdubudubu@gmail.com')
    print('got users')

    for my_thread in Thread.objects.filter(_subject_oid=cast_to_uuid(id), subject_otype=type).values():
        my_user_task = UserTask.objects.filter(subject_otype=ObjectType.THREAD,
                                               subject_uuid=cast_to_uuid(my_thread.get('id')), task_status=0,
                                               deleted=False)
        mut_len = len(my_user_task)
        print('in check for task')

        # task exists but not approved
        if mut_len == 1 and my_thread['title'] == title:
            task_exist_or_approved = True

    # check if conversation already exists and is approved - unlikely unless the check happens infrequently
    for my_thread in Thread.objects.filter(_subject_oid=cast_to_uuid(id), subject_otype=type).values():
        my_user_task = UserTask.objects.filter(subject_otype=ObjectType.THREAD,
                                               subject_uuid=cast_to_uuid(my_thread.get('id')), task_status=1,
                                               deleted=False)
        mut_len = len(my_user_task)
        print('in second check for task')

        if mut_len == 1 and my_thread['title'] == title:
            task_exist_or_approved = True

    # if conversation existence check failed then create the new conversation
    if not task_exist_or_approved:
        print('in starting conversation task')
        # create a discussion thread using the text argument, but replacing title and template
        question = dict(otype='post', post_type='question', text=bodytext.format(title=title))

        # create the conversation (aka a thread)
        thread = Thread.objects.create(author=policyBot, _subject_oid=cast_to_uuid(id), subject_otype=type,
                                       title=title, question_post=question)
        print('after created thread')

        # get the user as found above when processing the data source, if no steward assign to server admin
        if stewardid == 0:
            uid = my_admin.id
        else:
            uid = stewardid

        # get the task object key so we can update the assigned
        print('do assignment')
        user_task_obj_key = ObjectKey(ObjectType.USER_TASK, thread.user_task_id())
        update_assignee(user_task_obj_key, ObjectKey(ObjectType.USER, uid), Operation.ADD, policyBot.id)


# get all lifecycle expiration date values
all_date_fields = DateFieldValue.objects.filter(field_id=10057).values()

# default setting for duration before not having an owner on a data set is a violation
time_threshold = datetime.utcnow() - timedelta(days=0)
#print(str(time_threshold))

# declare objtype for passing to task creation funtion
objtype = ''
Pickers = []

# outer loop for iterating over all returned dates
for aField in all_date_fields:

    # eliminate the time zone on the datetime setting of the field
    newt = aField['datetime'].astimezone(timezone.utc).replace(tzinfo=None)
    # print(str(newt))

    # if the date is expired, send a task
    if newt<time_threshold:

        # figure out what type of otype its set on - data source, schema, table, or column
        # get the pickers for the object so we can find the steward
        if aField['otype'] == 23:
            obj = ObjectKey(ObjectType.SCHEMA, aField['oid'])
            Pickers = PickerFieldValue.objects.filter(otype=ObjectType.SCHEMA).values()
            objtype = 'schema'
        elif aField['otype'] == 1:
            obj = ObjectKey(ObjectType.ATTRIBUTE, aField['oid'])
            # get all picker fields for columns (attributes)
            Pickers = PickerFieldValue.objects.filter(otype=ObjectType.ATTRIBUTE).values()
            objtype = 'attribute'
        elif aField['otype'] == 27:
            obj = ObjectKey(ObjectType.TABLE, aField['oid'])
            # get all picker fields for columns (attributes)
            Pickers = PickerFieldValue.objects.filter(otype=ObjectType.TABLE).values()
            objtype = 'table'
        elif aField['otype'] == 7:
            obj = ObjectKey(ObjectType.DATA, aField['oid'])
            # get all picker fields for columns (attributes)
            Pickers = PickerFieldValue.objects.filter(otype=ObjectType.DATA).values()
            objtype = 'data'
        else:
            exit()

        # initialize the steward id
        stewardid = 0

        # start looking for stewards on the attribute
        for Picker in Pickers:

            # get the steward on the object - 8 is the field_id for Stewards
            if Picker['oid'] == aField['oid'] and Picker['field_id'] == 8:

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
        create_task(objtype, aField['oid'], stewardid, title_review_asset, text_review_asset)
