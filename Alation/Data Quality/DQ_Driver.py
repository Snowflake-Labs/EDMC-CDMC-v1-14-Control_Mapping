import os
from pathlib import Path
import string
import requests
import json
from datetime import datetime, timedelta, date
import uuid
import random
from csv import reader
from csv import DictReader
from json import dumps


def json_serial(obj):
    """JSON serializer for objects not serializable by default json code"""

    if isinstance(obj, (datetime, date)):
        return obj.isoformat()
    raise TypeError ("Type %s not serializable" % type(obj))


# get url and Alation user
target_url = 'http://54.191.244.251/alation_integrations/data_quality/upload/'
alation_user = 41
headers = ''

# get start and end data and time string
stime = datetime.now()
etime = datetime.now() + timedelta(seconds=3)
start_time = stime.strftime("%m/%d/%Y, %H:%M:%S")
end_time = etime.strftime("%m/%d/%Y, %H:%M:%S")
#start_time = dumps(stime, default=json_serial)
#end_time = dumps(etime, default=json_serial)
#now.strftime("%m/%d/%Y, %H:%M:%S")

# get random number between 1-3 that is used to post a series of dq rules
series_number = random.randint(1, 3)

#read through the file and process rows that match the series_number - file must be in same directory as script
print('Starting to process rows')

with open('dq_rules.csv', 'r') as read_obj:

    # iterate over each line as a ordered dictionary
        csv_dict_reader = DictReader(read_obj)
        for row in csv_dict_reader:

            # if the series numbers in the file and generated above match then process the row
            if row['series'] == str(series_number):

                # generate a uuid to use as the event code
                event_id = str(uuid.uuid4())

                # construct the json payload
                payload ={
                    "payload": {
                        "ruleInstance": {
                            "ruleId": row["ruleId1"],
                            "ruleCode": row['ruleCode'],
                            "ruleName": row['ruleName'],
                            "ruleDescription": row['ruleDescription'],
                            "ruleInstanceId": row['ruleInstance'],
                            "sourceConnection": row['sourceConnection'],
                            "targetConnection": row['targetConnection'],
                            "sourceConnectionId": row['sourceConnectionId'],
                            "targetConnectionId": row['targetConnectionId'],
                            "startTime": start_time,
                            "endTime": end_time
                        }
                    },
                    "integrations": {
                        "alation": {
                            "dqType": row['dqType'],
                            "schemaName": row['schemaName'],
                            "tableName": row['tableName'],
                            "columnName": row['columnName'],
                            "status": row['status']
                        }
                    },
                    "eventId": event_id,
                    "userId": alation_user,
                    "repository": row['repository'],
                    "reprocessUrl": row['reprocessUrl']
                }

                # submit the request
                try:
                    response = requests.post(target_url, json=payload, headers=headers)
                    print(response)
                    print('done')

                except Exception as e:
                    print('Problem')
                    continue

#close csv file

