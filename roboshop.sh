#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-00dac7c720709bc8e"

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

   # get private ip (default) or public ip (frontend)
   if [ "$instance" != "frontend" ]; then
        ip=$(aws ec2 describe-instances \
          --instance-ids $instance_id \
          --query "Reservations[0].Instances[0].PrivateIpAddress" \
          --output text)
   else
        ip=$(aws ec2 describe-instances \
          --instance-ids $instance_id \
          --query "Reservations[0].Instances[0].PublicIpAddress" \
          --output text)
   fi

   echo "$instance: $ip"
done
