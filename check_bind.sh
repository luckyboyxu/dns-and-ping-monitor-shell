#!/bin/bash
#####  check bind server port #####
#hostname=`grep certname /etc/puppetlabs/puppet/puppet.conf | awk '{print $3}'`
#hostip=$(/sbin/ifconfig |grep inet |awk -F ':' '{split($2,d," ");print d[1]}'|sed -n 1p)
###### useage：check_bind ip  #####
check_bind()
{
    local hostip=$1
    local status="ok"
    local from="from@xx.com"
    local to="to@xx.com"
    local username="user@xx.com"
    local userpasswd="xxxxx"
    local email_smtphost="host.xx.com"
    local email_title="DNS服务异常告警"
    local falied_sum=0
    local failed_packages_sum=5
    local status="ok"
    local send_mail_sum=10
    local send_mail=0
    local stop_run=false
    
    while ! $stop_run
    do
        #通过写文件记录上次的监控结果
	      if [ ! -e "/home/dji/shell/check_bind/sum/"$1.log ];then
            echo 0 0 > "/home/dji/shell/check_bind/sum/"$1.log
        fi
        #获取上次监控的结果
	      local failed_sum=`cat "/home/dji/shell/check_bind/sum/"$1.log | awk '{print $1}'`
        local send_mail=`cat "/home/dji/shell/check_bind/sum/"$1.log | awk '{print $2}'`
  
        #每告警10条以后，休眠5分钟后再告警,否则休眠一秒
        if [[ $send_mail -eq $send_mail_sum ]]
        then
	          send_mail=0
	          sleep 300
	      else
	          sleep 1
	      fi
        local datetime=`date "+%Y-%m-%d %H:%M:%S"`
	      ## 53端口检测
            check_result=$(nc -vzw 2 $hostip 53 2>&1 >> /dev/null | awk '{print $7}')
    	      if [ $check_result != "succeeded!" ];then
    	          status="failed"
    	      fi
        ## nslookup or dig解析检测，业务检测
        resolve_result=`dig www.baidu.com +time=3 +short @$hostip | head -1`
        if [ -n "$resolve_result" ] && [ $resolve_result = "www.a.shifen.com." ];then
            status="ok"
        fi
        [[ $status = "failed" ]] && (( failed_sum+=1 ))
        #检测次数达到5次，发送告警邮件，并停止进程，下次由supervisor拉起
        if [[ $failed_sum -eq $failed_packages_sum ]]
        then
	          failed_sum=0
    	      email_content="[节点ip]：$hostip\n\n[详情]：DNS服务53端口异常，且解析服务不可用，请处理！！\n\n[时间]：$datetime"
    	      sendemail -f ${from} -t ${to1} -t ${to2} -s ${email_smtphost} -u ${email_title} -xu ${username} -xp ${userpasswd} -m ${email_content} -o message-charset=utf-8 2>&1 >> /dev/null 
	          let send_mail+=1
	          stop_run=true
        fi
	      echo $failed_sum $send_mail > "/home/dji/shell/check_bind/sum/"$1.log
    done
}
check_bind $1
