#!/bin/sh
# ssh login managermant
# date: 2019-02-15

if [ ! -f /etc/redhat-release ] ; then
    echo ""
    echo "This script is for Red Hat/CentOS Linux!"
    echo ""
    exit 1
fi

u_list="${0%/*}/ssh_AllowUsers"
log_=${0%/*}/ssh_mgm.log
backup_dir=${0%/*}/backup_sshd_config
[ -d ${backup_dir} ] || mkdir -p ${backup_dir}


w_log() {
  timeStamp=$(date +%Y-%m-%d' '%H:%M:%S)
  echo "${timeStamp} ${1}" >> ${log_}
}


read_settings() {
    grep "^AllowUsers" /etc/ssh/sshd_config | tr ' ' '\n' | grep -v AllowUsers > ${u_list}
}


list_all() {
  all_count=$(cat ${u_list} | wc -l)
  if [ ${all_count} -eq 0 ] ; then
    echo ''
    echo 'No user in list !'
    echo ''
  else
    count_=0
    echo ''
    echo 'User List :'
    for user_ in $(cat ${u_list}) ; do
      count_=$((${count_}+1))
      echo ${count_}". "${user_}
    done
  fi
  w_log "List all ssh user."
}


check_user() {
  echo ${user_name} | grep @ >/dev/null 2>&1
  test_0=$?
  if [ ${test_0} == "0" ] ; then
    user_name_1=$(echo ${user_name} | awk -F'@' '{print $1}')
  else
    user_name_1=${user_name}
  fi

  id ${user_name_1} > /dev/null 2>&1
  test_1=$?
  
  if [ ${test_1} != "0" ] ; then
    echo ''
    echo 'username "'${user_name_1}'" not found !'
    return
  fi
  grep "^${user_name}$" ${u_list} > /dev/null 2>&1
  test_2=$?
}


add_user() {
  echo 'Add ssh user'
  echo ''
  echo 'User name :'
  read user_name
  [ -z ${user_name} ] && return
  echo ${user_name} | grep "^@" >/dev/null 2>&1
  if [ $? == "0" ] ; then
    echo ''
    echo 'can not add "'${user_name}'"'
    return
  fi
  check_user
  [ -z ${user_name_1} ] && return
  [ ${test_1} != "0" ] && return
  if [ ${test_2} == "0" ] ; then 
    echo ''
    echo "${user_name} can ssh login!"
    return
  fi
  echo ${user_name} >> ${u_list}
  confirm_modify
  w_log "Added ssh user: ${user_name}"
  echo ''
  echo "Added ssh user: ${user_name}"
}


del_user() {
  echo 'Delete ssh user'
  echo ''
  echo 'User name :'
  read user_name
  [ -z ${user_name} ] && return
  grep "^${user_name}$" ${u_list} > /dev/null 2>&1
  if [ $? != "0" ] ; then
    echo ''
    echo "${user_name} can not ssh login!"
    return
  fi
  echo ''
  echo "Are you sure to delete account ${user_name} ?  yes/no"
  read choice
  case $choice in
    yes)  
      sed -i "/^${user_name}$/d" ${u_list}
      confirm_modify
      w_log "Deleted ssh user: ${user_name}"
      echo ''
      echo "Deleted ssh user: ${user_name}"
      ;;
    *) return ;;
  esac
 
}


view_log() {
  clear
  w_log "View log."
  cat ${log_}
}


confirm_modify() {
  timeStamp=$(date +%Y%m%d_%H%M%S)
  cp /etc/ssh/sshd_config ${backup_dir}/sshd_config_${timeStamp}
  AllowUsers="AllowUsers"
  for str_ in $(cat ${u_list}) ; do
    AllowUsers=${AllowUsers}" "${str_}
  done
  sed -i '/^AllowUsers/d' /etc/ssh/sshd_config
  echo ${AllowUsers} >> /etc/ssh/sshd_config
  service sshd reload > /dev/null 2>&1
}

clear_old() {
  # Delete backup file 14 days ago
  find ${backup_dir} -name "sshd_config_*" -type f -mtime +14 -exec rm -f {} \;

  # If the log file is larger than 1024000, only 1000 lines are left.
  if [ $(ls -l ${log_} | awk '{print $5}') -gt 1024000 ] ; then
    tmp_log=${0%/*}/${RANDOM}_temp
    tail -1000 ${log_} > ${tmp_log}
    cat ${tmp_log} > ${log_}
    rm -f ${tmp_log}
    w_log "Reduce ${log_}"
  fi
}


show_main_menu() {
    # Just show main menu.
    clear
    cat <<EOF
  +====================================================================+
       Hostname: $(hostname), Today is $(date +%Y-%m-%d)
  +====================================================================+

      ssh user managermant

      1. List all ssh users
      2. Add ssh user
      3. Delete ssh user
      4. View log
 
      q.QUIT

      Enter your choice, or press q to quit :

EOF
}


main() {
    # The entry for sub functions.
    while true; do
        show_main_menu
        read choice
        clear
        case $choice in
          1) list_all
             echo ''
             echo 'press Enter key !' 
             read a ;;
          2) add_user
             echo ''
             echo 'press Enter key !' 
             read a ;;
          3) del_user
             echo ''
             echo 'press Enter key !' 
             read a ;;
          4) view_log 
             echo ''
             echo 'press Enter key !' 
             read a ;;
          [Qq]) clear_old
                w_log "Exit."
                exit 0 ;;
          *) echo '' > /dev/null ;;
        esac
    done
}

w_log "Start script.  -->  $(who am i | awk '{print $1" "$2" "$3" "$4" "$5}')"
read_settings
main

