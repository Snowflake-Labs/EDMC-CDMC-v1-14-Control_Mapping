# coding=utf-8
##########################################################################################
# Name: Entitlement_Policy_Bot
# Description:
# This is a monitoring script for cataloged data sources.  It
# checks if a schemas and tables have entitlement (grants) when one of their underlying
# columns has been verified as sensitive data.  This verification is done by a steward who
# sets the PII Classification field to Verified.
#
# When the condition is satisfied and either the schema or table do not have entitlements
# it triggers a notification to the steward assigned to the data source via a conversation on each
# (schema and/or table).  It also checks if there is a
# previous conversation already generated for the same reason which has
# not been resolved, as we don't want to overwhelm the steward with
# duplicative notices.
#
# In the case of Snowflake grants are populated at the table and schema level via the Snowflake integrations (see
# the PS github repo).
#
# The code uses the Alation Django framework.
#
# Author: Alation
# Alation Catalog Version: 2021.3
#
# Catalog Requirements:
# 1. Custom Field of type Picker named PII Classification with at least one picker value of Verified
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
from logical_metadata.models.models_values import PickerFieldValue, RichTextFieldValue
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
title_schema = 'Action Required: Schema Requires Entitlements'
text_schema = 'This schema has at least one column in a table with a PII classified values.  By policy it requires' \
              ' schema level entitlements. Mark the task resolved when completed. '

title_table = 'Action Required: Table Requires Entitlements'
text_table = 'This table has at least one column with a PII classified values.  By policy it requires' \
              ' table level entitlements. Mark the task resolved when completed. '

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

# check data sources and finding stewards so a message can be trigger to them
schemas = Schema.objects.all().values()
for schema in schemas:

    # declare variables
    schemaEntitlement = False
    schemaAttributePII = False

    # get all rich text fields
    RTFields = RichTextFieldValue.objects.filter(otype=ObjectType.SCHEMA).values()

    # iterate over the RTF fields looking for our entitlement field
    for RTField in RTFields:

        # grant entitlement is field_id 10015
        if RTField['oid'] == cast_to_uuid(schema['id']) and RTField['field_id'] == 10015:
            if len(RTField['text']) > 5:
                schemaEntitlement = True

    # get the tables for the schema
    tables = Table.objects.filter(schema=schema['name']).values()

    tableEntitlement = False

    # check each table for a grant information rich text field
    for table in tables:

        # get all rich text fields
        tFields = RichTextFieldValue.objects.filter(oid=cast_to_uuid(table['id']), field_id=10015).values()

        if len(tFields) > 0:
            for tField in tFields:
                #Make sure there is actually something in the field
                if len(tField['text']) > 5:
                    tableEntitlement = True

        # if table does not have any grant information then check if any attribute have PII classification set
        if not tableEntitlement:
            #attributes = Attribute.objects.filter(table=table['id']).values()
            #print('Inside not table entitlement')

            # get all rich text fields for the table with a PII field populated
            aFields = PickerFieldValue.objects.filter(otype=ObjectType.ATTRIBUTE,field_id=10042,grouping_key=cast_to_uuid(table['id'])).values()

            # iterate over the RTF fields looking for our entitlement field
            for aField in aFields:

                #PII Classification is field_id 10042
                #print('about to check the PII field')
                if aField['object_set'][0] == 'Verified':

                    attributePII = True
                    schemaAttributePII = True
                    print('attributePII: verified')
                    break

        # send table task
        if attributePII and not tableEntitlement:

            print('Table conversation trigger: ' + table['name'])

            # get all picker fields
            tablePickers = PickerFieldValue.objects.filter(otype=ObjectType.TABLE).values()

            stewardid = 0

            for tablePicker in tablePickers:
                print('starting look for steward')

                # get the steward on the table - 8 is the field_id for Stewards
                if tablePicker['oid'] == cast_to_uuid(table['id']) and tablePicker['field_id'] == 8:

                    # get the first in what could be a list of stewards
                    first = tablePicker['object_set'][0]

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

                    # call send function
                    print(str(table['id']))
                    print(str(stewardid))

            create_task('table', table['id'], stewardid, title_table, text_table)

        tableEntitlement = False
        attributePII = False

    print('after tables for the schema')
    print('schemaAttributePII: ' + str(schemaAttributePII))
    print('schemaEntitlement: ' + str(schemaEntitlement))

    # send schema task
    if schemaAttributePII and not schemaEntitlement:

        print('Schema conversation trigger: ' + schema['name'])

        # get all picker fields
        schemaPickers = PickerFieldValue.objects.filter(otype=ObjectType.SCHEMA).values()

        for schemaPicker in schemaPickers:

            stewardid = 0

            # get the steward on the schema - 8 is the field_id for Stewards
            if schemaPicker['oid'] == cast_to_uuid(schema['id']) and schemaPicker['field_id'] == 8:

                # get the first in what could be a list of stewards
                first = schemaPicker['object_set'][0]

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

                # call send function
        create_task('schema', schema['id'], stewardid, title_schema, text_schema)

    # reset for next iteration
    schemaEntitlement = False
    schemaAttributePII = False

