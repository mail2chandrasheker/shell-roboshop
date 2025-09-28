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

# List  modules
run_cmd "Listing  modules" dnf module list

# Disable current NodeJS module
run_cmd "Disabling current NodeJS module" dnf module disable nodejs -y

# Enable current NodeJS module
run_cmd "Enabling current NodeJS module" dnf module enable nodejs:20 -y

# Install NodeJS
run_cmd "Installing NodeJS" dnf install nodejs -y

# add application user
 run_cmd "Creating roboshop user" useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

# create/app directory
run_cmd "Creating /app directory" mkdir -p /app

#Download application code
run_cmd "Downloading catalogue application" curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip

# Extract application code
run_cmd "Extracting application code" bash -c "cd /app && unzip -o /tmp/cart.zip"

# Install NodeJS dependencies
run_cmd "Installing NodeJS dependencies" bash -c "cd /app && npm install"

#Daemon reload
run_cmd "Daemon relaod" systemctl daemon-reload

#enable catalogue
run_cmd "enable cart" systemctl enable cart  

#start catalouge
run_cmd "start catalouge" systemctl start cart