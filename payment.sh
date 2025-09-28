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


# install python
run_cmd "install python" dnf install python3 gcc python3-devel -y

# add application user
 run_cmd "Creating roboshop user" useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

# create/app directory
run_cmd "Creating /app directory" mkdir -p /app

#Download application code
run_cmd "Downloading catalogue application" curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip

# Extract application code
run_cmd "Extracting application code" bash -c "cd /app && unzip -o /tmp/payment.zip"

# Install python dependencies
run_cmd "Installing python dependencies" bash -c "cd /app && pip3 install -r requirements.txt"

#Daemon reload
run_cmd "Daemon relaod" systemctl daemon-reload

#enable payment
run_cmd "enable payment" systemctl enable payment 

#start payment
run_cmd "start payment" systemctl start payment