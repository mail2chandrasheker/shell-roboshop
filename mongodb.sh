#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

userid=$(id -u)

logs_folder="/var/log/shell-roboshop"
script_name=$(basename $0 | cut -d "." -f1)
log_file="$logs_folder/$script_name.log"

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

# Add MongoDB repo
cp mongo.repo /etc/yum.repos.d/mongo.repo 2>&1 | tee -a $log_file
validate $? "Adding MongoDB repo"

# Install MongoDB
dnf install -y mongodb-org 2>&1 | tee -a $log_file
validate $? "Installing MongoDB"

# Enable MongoDB
systemctl enable mongod 2>&1 | tee -a $log_file
validate $? "Enabling MongoDB service"

# Start MongoDB
systemctl start mongod 2>&1 | tee -a $log_file
validate $? "Starting MongoDB service"
