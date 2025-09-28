#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

userid=$(id -u)

logs_folder="/var/log/shell-roboshop"
script_name=$(basename $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"
MONGODB_HOST=mongodb.chandradevops.space
mkdir -p $logs_folder

echo "Script started execution at: $(date)" | tee -a $log_file

if [ "$userid" -ne 0 ] ; then
   echo -e "$R Error: You are not root user. Please run as root. $N" | tee -a $log_file
   exit 1
fi

validate() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 .... $R Failure $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 .... $G Success $N" | tee -a $log_file
    fi
}

run_cmd() {
    desc=$1
    shift
    "$@" 2>&1 | tee -a $log_file
    validate $? "$desc"
}

# List NodeJS modules
run_cmd "Listing NodeJS modules" dnf module list nodejs

# Disable current NodeJS module
run_cmd "Disabling current NodeJS module" dnf module disable nodejs -y

# Install NodeJS
run_cmd "Installing NodeJS" dnf install nodejs -y

# add application user
 run_cmd "Creating roboshop user" useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

# create/app directory
run_cmd "Creating /app directory" mkdir -p /app

#Download application code
run_cmd "Downloading catalogue application" curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip

# Extract application code
run_cmd "Extracting application code" bash -c "cd /app && unzip -o /tmp/catalogue.zip"

# Install NodeJS dependencies
run_cmd "Installing NodeJS dependencies" bash -c "cd /app && npm install"

# add catalogue service
run_cmd "Adding catalogue service" cp /etc/systemd/system/catalogue.service

#Daemon reload
run_cmd "Daemon relaod" systemctl daemon-reload

#enable catalogue
run_cmd "Daemon relaod" systemctl enable catalogue 

#start catalouge
run_cmd "Daemon relaod" systemctl start catalogue

# Add MongoDB repo
run_cmd "Adding MongoDB repo" cp mongo.repo /etc/yum.repos.d/mongo.repo

# Install MongoDB
run_cmd "Installing MongoDB Client" dnf install mongodb-mongosh -y

#load catalogue products
run_cmd "Load catalogue products " mongosh --host $MONGODB_HOST </app/db/master-data.js

# Restart Catalogue
run_cmd "Restarting Catalogue service" systemctl restart catalogue