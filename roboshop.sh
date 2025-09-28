#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-00dac7c720709bc8e"

for instance in $@
do
   instance_id=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t2.micro \
  --security-group-ids $SG_ID \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test}]' \
  --query "Instances[0].InstanceId" \
  --output text)

  #get privete ip and public ip
  if [ $instance !="frontend " ]; then
        ip=$(aws ec2 describe-instances \
  --instance-ids $instance_id \
  --query "Reservations[0].Instances[0].PrivateIpAddress" \
  --output text)
  else
      ip=$(aws ec2 describe-instances \
  --instance-ids i-083dd8f16722b1755 \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

   fi

   echo "$instnace: $ip"
done