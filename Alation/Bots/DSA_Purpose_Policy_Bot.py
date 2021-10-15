# coding=utf-8
##########################################################################################
# Name: DSA_Purpose_Policy_Bot
# Description:
# This is a monitoring script for cataloged Data Sharing Agreements (DSA).  It
# checks if a DSA has a purpose filled out.  If not it triggers a notification to the steward assigned
# to the data source via a conversation.  It also checks if there is a
# previous conversation already generated for the same reason which has
# not been resolved, as we don't want to overwhelm the steward with
# duplicative notices.
#
# The code uses the Alation Django framework.
#
# Author: Alation
# Alation Catalog Version: 2021.3
#
# Catalog Requirements:
# 1. Custom Field of type Rich Text Field named Purpose
# 2. Article template named: Data Sharing Agreement
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
from logical_metadata.models.models_values import PickerFieldValue
from alation_object_type_directory.resources import ObjectKey
from alation_object_type_directory.resources import cast_to_uuid
from alation_object_types.enums import ObjectType
from logical_metadata.models import Operation
from logical_metadata.public.builtin_field_helpers import update_assignee
from rosemeta.models import DataSource
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

# get the server admins and catalog admins in case we need to assign them to a conversation
server_admins = GroupProfile.objects.get(group__name="Server Admins").group
my_admin = server_admins.user_set.first()
policyBot = User.objects.get(username='jdubudubu@gmail.com')

# defaults for generated conversations
title = 'Action Required: Data Sharing Agreement requires a purpose statement'
text = 'This data sharing agreement does not have a purpose statement.  Policy requires it to have one. '  \
    'Please mark this task resolved when after its completed. '

# check articles with template Data Sharing Agreements and finding stewards so a message can be trigger to them
a = Article.objects.filter(custom_field_templates=42,deleted=False).values()
for val in a:
    cfvs = (val['custom_field_values'])

    try:
        # Purpose RTF field 10021
        print(cfvs['10021'])
    except:

        # declare variable
        task_exist_or_approved = False

        # check if conversation already exists and it is not approved yet, so we don't repeat - task_status=0 is not
        # approved
        for my_thread in Thread.objects.filter(_subject_oid=cast_to_uuid(val['id']), subject_otype='article').values():
            my_user_task = UserTask.objects.filter(subject_otype=ObjectType.THREAD,
                                                   subject_uuid=cast_to_uuid(my_thread.get('id')), task_status=0,
                                                   deleted=False)
            mut_len = len(my_user_task)

            # task exists but not approved
            if mut_len == 1 and my_thread['title'] == title:
                task_exist_or_approved = True

        # check if conversation already exists and is approved - unlikely unless the check happens infrequently
        for my_thread in Thread.objects.filter(_subject_oid=cast_to_uuid(val['id']), subject_otype='article').values():
            my_user_task = UserTask.objects.filter(subject_otype=ObjectType.THREAD,
                                                   subject_uuid=cast_to_uuid(my_thread.get('id')), task_status=1,
                                                   deleted=False)
            mut_len = len(my_user_task)

            if mut_len == 1 and my_thread['title'] == title:
                task_exist_or_approved = True

        # if conversation existence check failed then create the new conversation
        if task_exist_or_approved == False:

            # create a discussion thread using the text argument, but replacing title and template
            question = dict(otype='post', post_type='question', text=text.format(title=title))

            # create the conversation (aka a thread)
            thread = Thread.objects.create(author=policyBot, _subject_oid=cast_to_uuid(val['id']), subject_otype='article',
                                           title=title, question_post=question)

            # get the task object key so we can update the assigned
            user_task_obj_key = ObjectKey(ObjectType.USER_TASK, thread.user_task_id())
            update_assignee(user_task_obj_key, ObjectKey(ObjectType.USER, my_admin.id), Operation.ADD, policyBot.id)

        continue