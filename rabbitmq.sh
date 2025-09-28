#!/bin/bash

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
SCRIPT_DIR=$PWD
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

# Add Rabbit  repo
run_cmd "Adding Rabbitmq repo" cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo

# Install rabbit 
run_cmd "Installing rabiitmq" dnf install rabbitmq-server -y

# Enable rabbitmq service
run_cmd "Enable rabbitmq service" systemctl enable rabbitmq-server
# start rabbitmq server
run_cmd "start rabbitmq server" systemctl start rabbitmq-server

# default rabbitmq user name
run_cmd "default user name" rabbitmqctl add_user roboshop roboshop123

# default rabbitmq password
run_cmd "default rabbitmq password" rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"




