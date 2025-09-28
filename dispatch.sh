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


# install GoLang
run_cmd "Install GoLang" dnf install golang -y

# add application user
 run_cmd "Creating roboshop user" useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

# create/app directory
run_cmd "Creating /app directory" mkdir -p /app

#Download application code
run_cmd "Downloading catalogue application" curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip

# Extract application code
run_cmd "Extracting application code" bash -c "cd /app && unzip -o /tmp/dispatch.zip"

# Install go dependencies
run_cmd "Installing go dependencies" bash -c "cd /app && go mod init dispatch"
# Install g oget
run_cmd "Installing go get" bash -c "cd /app && go get"
# Install go buildgit 
run_cmd "Installing go build" bash -c "cd /app && go build"


#Daemon reload
run_cmd "Daemon relaod" systemctl daemon-reload

#enable dispatch
run_cmd "enable dispatch" systemctl enable dispatch

#start payment
run_cmd "start dispatch" systemctl start dispatch

 


