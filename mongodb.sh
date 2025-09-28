#!/bin/bash


R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[033m"
#validate the user is root or normla
userid=$(id  -u)

logs_folder="/var/log/shell-roboshop"
script_name=$( echo $0 | cut -d "." -f1 )
log_file="$logs_folder/$script_name.log"

mkdir -p $logs_folder

echo "script started executed at: $(date)" | tee -a $log_file
if [ "$userid"   -ne  0 ] ; then
   echo -e "$R Error:: you are  not root user $N" | tee -a $log_file
   exit 1
fi

validate(){
    if [ $1 -ne  0 ]; then
        echo -e "$1....$R Failure $N" | tee -a $log_file
    else
        echo -e "$1.....$G success $N" | tee -a $log_file
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo repo"

dnf install mongodb-org -y &>>#$log_file
validate $? "Installing MongoDB"

systemctl enable mongod  &>>#$log_file
validate $? "Enable Mongodb"

systemctl start mongod  &>>#$log_file
validate $? "Start Mongodb"