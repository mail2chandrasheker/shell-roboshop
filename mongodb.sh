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

run_cmd() {
    desc=$1
    shift
    "$@" 2>&1 | tee -a $log_file
    validate $? "$desc"
}

# Add MongoDB repo
run_cmd "Adding MongoDB repo" cp mongo.repo /etc/yum.repos.d/mongo.repo

# Install MongoDB
run_cmd "Installing MongoDB" dnf install -y mongodb-org

# Enable MongoDB
run_cmd "Enabling MongoDB service" systemctl enable mongod

# Update bindIp in config
run_cmd "Updating bindIp in mongod.conf" sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Restart MongoDB
run_cmd "Restarting MongoDB service" systemctl restart mongod
