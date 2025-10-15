import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

REGION = os.getenv('AWS_REGION', 'us-east-1')
TAG_KEY = 'Schedule'
TAG_VALUE = os.getenv('TAG_VALUE', 'OfficeHours')

ec2 = boto3.client('ec2', region_name=REGION)

def lambda_handler(event, context):
    action = event.get('action')
    filters = [{'Name': f'tag:{TAG_KEY}', 'Values': [TAG_VALUE]}]
    response = ec2.describe_instances(Filters=filters)
    instance_ids = [
        i['InstanceId']
        for r in response['Reservations']
        for i in r['Instances']
    ]

    if not instance_ids:
        logger.info("No instances found with given tag.")
        return {"status": "no_instances"}

    if action == 'start':
        logger.info(f"Starting instances: {instance_ids}")
        ec2.start_instances(InstanceIds=instance_ids)
    elif action == 'stop':
        logger.info(f"Stopping instances: {instance_ids}")
        ec2.stop_instances(InstanceIds=instance_ids)
    else:
        logger.warning("No valid action specified.")
        return {"status": "invalid_action"}

    return {"status": "done", "action": action, "instances": instance_ids}
