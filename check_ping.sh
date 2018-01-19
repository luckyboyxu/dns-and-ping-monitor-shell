#!/bin/bash
###### useage：check_ping ip  #####
from="from@xx.com"
to="to@xx.com"
username="user@xx.com"
userpasswd="xxxxx"
email_smtphost="host.xxx.com"
email_title="ping异常"

#定义丢包个数
failed_packages_sum=5
send_sum_all=10
ping_timeout=5
STOP=false

#时间函数
timestamp()
{
    echo -n "$(date +"%Y-%m-%d %H:%M:%S") "
}

#动作函数
action()
{
    #echo ---------------$(timestamp)--------------- >>${1}.log
    #traceroute -n -m 11 -q 2 $1 >>${1}.log
    #email_content=`cat ${1}.log`
    local datetime=`date "+%Y-%m-%d %H:%M:%S"`
    email_content="[节点ip]：$1\n\n[详情]：主机ping不可达!\n\n[时间]：$datetime"
    sendemail -f ${from} -t ${to1} -t ${to2} -s ${email_smtphost} -u ${email_title} -xu ${username} -xp ${userpasswd} -m ${email_content} -o message-charset=utf-8 2>&1 >> /dev/null &
}

exec_ping()
{
    local stop_run=false
    while ! $stop_run
    do
        if [ ! -e "/home/dji/shell/check_ping/sum/"$1.log ];then
	    echo 0 0 > "/home/dji/shell/check_ping/sum/"$1.log
    	fi
    	local failed_sum=`cat "/home/dji/shell/check_ping/sum/"$1.log | awk '{print $1}'` 
    	local send_sum=`cat "/home/dji/shell/check_ping/sum/"$1.log | awk '{print $2}'` 
    	ping -c 1 -w $ping_timeout $1 &>/dev/null && failed_sum=0 || (( failed_sum+=1 ))
    	[[ $failed_sum -eq $failed_packages_sum ]] && failed_sum=0 && action $1 && stop_run=true && (( send_sum+=1 ))
	if [[ $send_sum -eq $send_sum_all ]]
	then
	    send_sum=0
	    sleep 300
	else 
	    sleep 1
	fi
    	echo $failed_sum $send_sum > "/home/dji/shell/check_ping/sum/"$1.log
    done
}
exec_ping $1

