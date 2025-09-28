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
MYSQL_HOST=mysql.chandradevops.space
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

# maven install
run_cmd "maven install" dnf install maven -y

# add application user
 run_cmd "Creating roboshop user" useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

# create/app directory
run_cmd "Creating /app directory" mkdir -p /app


#Download application code
run_cmd "Downloading catalogue application" curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip

# Extract application code
run_cmd "Extracting application code" bash -c "cd /app && unzip -o /tmp/shipping.zip"

# maven clean package
run_cmd "maven clean package" mvn clean package 

# maven target
run_cmd "maven target" mv target/shipping-1.0.jar shipping.jar  

# Add shipping.service
run_cmd "shipping service " cp shipping.service /etc/systemd/system/shipping.service

# reload
run_cmd "daemon reload" systemctl daemon-reload
#enable shipping
run_cmd "systemctl enable shipping" systemctl enable shipping
#start shipping
run_cmd "systemctl start shipping" systemctl start shipping

#client side install
run_cmd "client side mysql install" dnf install mysql -y 

#load the schema
run_cmd "load the schema" mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql

#MySQL expects a password authentication,
run_cmd "MySQL expects a password authentication," mysql -h  $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 

#load the master
run_cmd "load the master" mysql -h  $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 


#restarting the shipping service
run_cmd "restarting the shipping service" systemctl restart shipping

 
