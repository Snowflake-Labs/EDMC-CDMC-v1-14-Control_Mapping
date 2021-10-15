# coding=utf-8
##########################################################################################
# Name: DQ_Summary_Monitor
# Description:
# It creates data quality summary charts for table for level schemas data assets based on the data quality scores
# contained in their underlying columns.
#
# It assumes that the Alation Microservice for DQ application is being used to populated columns with DQ results
# as described by that integration (in its PS github repo).
# It loops through all schemas and tables, creates the summary and inserts it into Data Quality Summary rich text
# custom field on tables and schemas.  It can be scheduled via cron to run at any desired frequency.
#
# There is some hard coding of field ids which will need to be changed based on the custom field ids of the instance
# where its deployed.
#
# The code uses the Alation Django framework.
#
# Author: Alation
# Alation Catalog Version: 2021.3
#
# Catalog Requirements:
# 1. Use of AMS DQ integration which populates the Data Quality Metrics custom field on column pages
# 2. Use of a rich text custom field called Data Quality Summary on the table and schema template.
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
import matplotlib.pyplot as plt
import dq_html_template

# declare table variables
table_percentage_score = 0
total_possible_table_score = 0
total_actual_table_score = 0
table_coverage_percentage = 0
total_table_attributes_with_dq = 0
total_table_attributes = 0
total_attributes = 0
table_rating = 0
attribute_list = ''

# declare schema variables
total_schema_attributes = 0
schema_percentage_score = 0
total_actual_schema_score = 0
total_possible_schema_score = 0
schema_coverage_percentage = 0
total_schema_tables_with_dq = 0
total_schema_tables = 0
schema_rating = 0
table_list = ''
gcount = 0
ycount = 0
rcount = 0
rule_count = 0

def rating(percentage_score):
      if percentage_score > .79:
          return ('Green')

      if percentage_score < .41:
          return ('Red')
      else:
          return ('Yellow')


# get user that will be used to update the dq summary RTF field on the objects
policyBot = User.objects.get(username='jdubudubu@gmail.com')

# iterate through all schemas
schemas = Schema.objects.all().values()
for schema in schemas:

    # get all tables for the schema
    tables = Table.objects.filter(schema_obj=schema['id']).values()

    # get the total number of tables in the schema
    total_schema_tables = len(tables)

    # iterate through all tables
    for table in tables:

        # get all attributes (columns) in the table
        attributes = Attribute.objects.filter(table=table['id']).values()

        # get the total attributes in the table and add to schema
        total_table_attributes = len(attributes)
        total_schema_attributes = total_schema_attributes + total_attributes

        # find attributes in the table where there is a Data Quality Metrics custom RTF field
        tFields = RichTextFieldValue.objects.filter(grouping_key=cast_to_uuid(table['id']), field_id=10048).values()

        # if the table includes populated RTF fields in the attribute list
        if len(tFields) > 0:
            # add attribute name to attribute list
            if table_list == '':
                table_list = table['name']
            else:
                table_list = table_list + ', ' + table['name']
            print('table name: ' + table['name'])

            total_table_attributes_with_dq = len(tFields)
            total_schema_tables_with_dq = total_schema_tables_with_dq + 1

            # find all the dq rules and count the reds, yellows and greens
            for tField in tFields:

                gcount = tField['text'].count('>Green<')
                ycount = tField['text'].count('>Yellow<')
                rcount = tField['text'].count('>Red<')
                rule_count = rule_count + (gcount + ycount + rcount)

                # keep subtotalling total possible score
                total_possible_table_score = rule_count * 3

                # for each r,y,g total the actual TABLE & SCHEMA score
                green_score = tField['text'].count('>Green<') * 3
                yellow_score = tField['text'].count('>Yellow<') * 2
                red_score = tField['text'].count('>Red<') * 1
                total_actual_table_score = total_actual_table_score + (green_score + yellow_score + red_score)

                # add attribute name to attribute list, first get the objectkey so we can get the name
                #object_key = ObjectKey(ObjectType.ATTRIBUTE, tField['id'])
                attr = Attribute.objects.filter(id=tField['oid']).values('name')
                for j in attr:
                    print(j['name'])
                    if attribute_list == '':
                        attribute_list = j['name']
                    else:
                        attribute_list = attribute_list + ', ' + j['name']

            # at the end of the loop calculate the TABLE percentage score
            print('total_actual_table_score: ' + str(total_actual_table_score))
            print('total_possible_table_score: ' + str(total_possible_table_score))
            table_percentage_score = total_actual_table_score/total_possible_table_score

            # calculate % dq coverage
            print('total_table_attributes_with_dq: ' + str(total_table_attributes_with_dq))
            print('total_table_attributes: ' + str(total_table_attributes))
            table_coverage_percentage = total_table_attributes_with_dq/total_table_attributes

            # add to schema totals
            total_possible_schema_score = total_possible_schema_score + total_possible_table_score
            total_actual_schema_score = total_actual_schema_score + total_actual_table_score

            # look up TABLE rating
            table_rating = rating(table_percentage_score)

            # write to table DQ summary RTF field
            print('table_rating: ' + table_rating)
            print('table_percentage_score: ' + str(table_percentage_score))
            print('table_coverage_percentage: ' + str(table_coverage_percentage))
            print('attribute list: ' + str(attribute_list))

            tsdata = [total_possible_table_score,total_actual_table_score]
            labels = ['Max Possible Score', 'Actual Score']
            plt.xticks(range(len(tsdata)), labels)
            plt.xlabel('Categories')
            plt.ylabel('Count')
            plt.title('Column Scoring')
            plt.bar(range(len(tsdata)), tsdata, color=['blue','orange'])
            table1_name = table['name'] + '_score.jpg'
            figure = plt.gcf()
            figure.set_size_inches(5, 4)
            plt.savefig('/data1/site_data/media/image_bank/' + table1_name)
            table1_name_url = '/media/image_bank/' + table1_name

            tcdata = [total_table_attributes,total_table_attributes_with_dq]
            labels = ['Total Columns', 'Columns with DQ Rules']
            plt.xticks(range(len(tcdata)), labels)
            plt.xlabel('Categories')
            plt.ylabel('Count')
            plt.title('Column Rule Coverage')
            plt.bar(range(len(tcdata)), tcdata, color=['blue','orange'])
            table2_name = table['name'] + '_coverage.jpg'
            figure = plt.gcf()
            figure.set_size_inches(5, 4)
            plt.savefig('/data1/site_data/media/image_bank/' + table2_name)
            table2_name_url = '/media/image_bank/' + table2_name

            # insert results into dq summary field on the table catalog page 10051
            body = dq_html_template.format_RTF('Columns', table1_name_url, str(round(table_percentage_score,2)),
                                               table_rating, table2_name_url,
                                               str(round(table_coverage_percentage,2)), attribute_list)
            print(body)

            # update table DQ Summary RTF fiel
            # get the key of the table
            key = ObjectKey(ObjectType.TABLE, (table['id']))

            # Add a value to dq summary custom field
            try:
                diff = RichTextFieldValueDiff(body)
                RichTextFieldValue.update_value_with_diff(object_key=key, field_id=10051, diff=diff, user_id=policyBot.id)
            except TypeError:
                print('Issue with table output')

            # reset table variables
            table_percentage_score = 0
            total_possible_table_score = 0
            total_actual_table_score = 0
            table_coverage_percentage = 0
            total_table_attributes_with_dq = 0
            total_attributes = 0
            table_rating = 0
            attribute_list = ''
            gcount = 0
            ycount = 0
            rcount = 0
            rulecount = 0

    if total_possible_schema_score > 0:
        # at the end of the loop calculate the SCHEMA percentage score
        print('total_actual_schema_score: ' + str(total_actual_schema_score))
        print('total_possible_schema_score: ' + str(total_possible_schema_score))
        schema_percentage_score = total_actual_schema_score/total_possible_schema_score

        # calculate % dq coverage
        print('total_schema_tables_with_dq: ' + str(total_schema_tables_with_dq))
        print('total_schema_tables: ' + str(total_schema_tables))
        schema_coverage_percentage = total_schema_tables_with_dq/total_schema_tables

        # look up SCHEMA rating
        schema_rating = rating(schema_percentage_score)

        # write to schema DQ summary RTF field
        print('schema_rating: ' + schema_rating)
        print('schema_percentage_score: ' + str(schema_percentage_score))
        print('schema_coverage_percentage: ' + str(schema_coverage_percentage))
        print('table list: ' + str(table_list))

        # generate and save schema charts to alation media
        ssdata = [total_possible_schema_score, total_actual_schema_score]
        labels = ['Max Possible Score', 'Actual Score']
        plt.xticks(range(len(ssdata)), labels)
        plt.xlabel('Categories')
        plt.ylabel('Count')
        plt.title('Table Scoring')
        plt.bar(range(len(ssdata)), ssdata, color=['blue','orange'])
        schema1_name = schema['name'] + '_score.jpg'
        figure = plt.gcf()
        figure.set_size_inches(5, 4)
        plt.savefig('/data1/site_data/media/image_bank/' + schema1_name)
        schema1_name_url = '/media/image_bank/' + schema1_name

        scdata = [total_schema_tables, total_schema_tables_with_dq]
        labels = ['Total Tables', 'Tables with DQ Rules']
        plt.xticks(range(len(scdata)), labels)
        plt.xlabel('Categories')
        plt.ylabel('Count')
        plt.title('Table Rule Coverage')
        plt.bar(range(len(scdata)), scdata, color=['blue','orange'])
        schema2_name = schema['name'] + '_coverage.jpg'
        figure = plt.gcf()
        figure.set_size_inches(5, 4)
        plt.savefig('/data1/site_data/media/image_bank/' + schema2_name)
        schema2_name_url = '/media/image_bank/' + schema2_name

        # insert results into dq summary field on the table catalog page 10051
        body = dq_html_template.format_RTF('Tables', schema1_name_url, str(round(schema_percentage_score,2)),
                                           schema_rating, schema2_name_url,
                                           str(round(schema_coverage_percentage,2)), table_list)
        print(body)

        # update schema DQ Summary RTF field
        # get the key of the schema
        key = ObjectKey(ObjectType.SCHEMA, (schema['id']))

        # Add a value to dq summary custom field
        try:
            diff = RichTextFieldValueDiff(body)
            RichTextFieldValue.update_value_with_diff(object_key=key, field_id=10051, diff=diff, user_id=policyBot.id)

        except TypeError:
            print('Issue with table output')

        # reset schema variables
        schema_percentage_score = 0
        total_actual_schema_score = 0
        total_possible_schema_score = 0
        schema_coverage_percentage = 0
        total_schema_tables_with_dq = 0
        total_schema_tables = 0
        schema_rating = 0
        table_list = ''
