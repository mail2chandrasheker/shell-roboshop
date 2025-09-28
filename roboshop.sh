#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-00dac7c720709bc8e"
Hosted_Zone_ID="Z0033676TLKDOCFXBMTY"
Domain_Name="chandradevops.space"

for instance in "$@"
do
   instance_id=$(aws ec2 run-instances \
      --image-id $AMI_ID \
      --instance-type t2.micro \
      --security-group-ids $SG_ID \
      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
      --query "Instances[0].InstanceId" \
      --output text)

   # wait until instance is running
   aws ec2 wait instance-running --instance-ids $instance_id

   # get IP and set record name
   if [ "$instance" != "frontend" ]; then
        ip=$(aws ec2 describe-instances \
          --instance-ids $instance_id \
          --query "Reservations[0].Instances[0].PrivateIpAddress" \
          --output text)
        RECORD_NAME="$instance.$Domain_Name"
   else
        ip=$(aws ec2 describe-instances \
          --instance-ids $instance_id \
          --query "Reservations[0].Instances[0].PublicIpAddress" \
          --output text)
        RECORD_NAME="$Domain_Name"
   fi

   echo "$instance: $ip ($RECORD_NAME)"

   # Update Route53 record
   aws route53 change-resource-record-sets \
     --hosted-zone-id $Hosted_Zone_ID \
     --change-batch "{
       \"Comment\": \"Update $RECORD_NAME\",
       \"Changes\": [{
         \"Action\": \"UPSERT\",
         \"ResourceRecordSet\": {
           \"Name\": \"$RECORD_NAME\",
           \"Type\": \"A\",
           \"TTL\": 60,
           \"ResourceRecords\": [{\"Value\": \"$ip\"}]
         }
       }]
     }"
done
