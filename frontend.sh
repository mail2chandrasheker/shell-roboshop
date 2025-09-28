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


# List Nginx modules
run_cmd "Listing Ngnix modules" dnf module list nginx

# Disable current nginx module
run_cmd "Disabling current nginx module" dnf module disable nginx -y

# Enable current nginx module
run_cmd "Enabling current nginx module" dnf module enable nginx:1.24 -y

# Install Nginx
run_cmd "Installing Nginx" dnf install nginx -y

# enable  Nginx service
run_cmd "Enable Nginx Service" systemctl enable nginx

# Start  Nginx service
run_cmd "Start Nginx Service" systemctl start nginx

# Removing default nginx files
run_cmd "Remove the default files" rm -rf /usr/share/nginx/html/*

# Download application code
run_cmd "Downloading frontend application" curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip

# Extract application code
run_cmd "Extracting application code" unzip -o /tmp/frontend.zip -d /usr/share/nginx/html

# Restart Nginx
run_cmd "Restarting Nginx service" systemctl restart nginx 





