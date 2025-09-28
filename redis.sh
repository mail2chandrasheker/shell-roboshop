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


# Disable current Redis module
run_cmd "Disabling current Redis module" dnf module disable redis -y

# Enable Redis
run_cmd "Enabling Redis service" dnf module enable redis:7 -y


# Install Redis
run_cmd "Installing Redis" dnf install redis -y 

# Change bind address
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf

# Disable protected mode
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf

# Enable Redis
run_cmd "Enabling Redis service" systemctl enable redis

# start Redis
run_cmd "Starting Redis service" systemctl start redis


 
 