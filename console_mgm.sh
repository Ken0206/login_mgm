#!/bin/sh
# console login managermant
# date: 2019-02-15
#
# 1. /etc/pam.d/system-auth
#    account     required      pam_access.so
#
# 2. /etc/pam.d/password-auth (RHEL6)
#    account     required      pam_access.so
#
# 3. /etc/ssh/sshd_config
#    UsePAM yes
#
#   service sshd reload
#
# 4. /etc/security/access.conf  (allow root & spadmin)
#    -:ALL EXCEPT root,spadmin:tty1 tty2 tty3 tty4 tty5 tty6 LOCAL
#


if [ ! -f /etc/redhat-release ] ; then
    echo ""
    echo "This script is for Red Hat/CentOS Linux!"
    echo ""
    exit 1
fi

u_list="${0%/*}/console_users"
log_=${0%/*}/console_mgm.log
backup_dir="${0%/*}/backup_access.conf"
[ -d ${backup_dir} ] || mkdir -p ${backup_dir}


w_log() {
  timeStamp=$(date +%Y-%m-%d' '%H:%M:%S)
  echo "${timeStamp} ${1}" >> ${log_}
}


read_settings() {
    console_sers=$(grep "^-:ALL EXCEPT" /etc/security/access.conf | awk '{print $3}' | awk -F':' '{print $1}' | sed 's/,/ /g')
    rm -f ${u_list}
    for list_ in $(echo ${console_sers}) ; do
      echo ${list_} >> ${u_list}
    done
    touch ${u_list}
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
  w_log "List all console user."
}


check_user() {
  id ${user_name} > /dev/null 2>&1
  test_1=$?
  if [ ${test_1} != "0" ] ; then
    echo ''
    echo 'username "'${user_name}'" not found !'
  fi
  grep "^${user_name}$" ${u_list} > /dev/null 2>&1
  test_2=$?
}


add_user() {
  echo 'Add console user'
  echo ''
  echo 'User name :'
  read user_name
  [ -z ${user_name} ] && return
  check_user
  [ ${test_1} != "0" ] && return
  if [ ${test_2} == "0" ] ; then
    echo ''
    echo "${user_name} can console login!"
    return
  fi
  echo ${user_name} >> ${u_list}
  confirm_modify
  w_log "Added console user: ${user_name}"
  echo ''
  echo "Added console user: ${user_name}"
}


del_user() {
  echo 'Delete console user'
  echo ''
  echo 'User name :'
  read user_name
  [ -z ${user_name} ] && return
  grep "^${user_name}$" ${u_list} > /dev/null 2>&1
  if [ $? != "0" ] ; then
    echo ''
    echo "${user_name} can not console login!"
    return
  fi
  echo ''
  echo "Are you sure to delete account ${user_name} ?  yes/no"
  read choice
  case $choice in
    yes)  
      sed -i "/^${user_name}$/d" ${u_list}
      confirm_modify
      w_log "Deleted console user: ${user_name}"
      echo ''
      echo "Deleted console user: ${user_name}"
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
  cp /etc/security/access.conf ${backup_dir}/access.conf_${timeStamp}
  modify_str=''
  for str_ in $(cat ${u_list}) ; do
    modify_str=${modify_str}","${str_}
  done
  sed -i '/^-:ALL EXCEPT/d' /etc/security/access.conf
  echo '-:ALL EXCEPT '${modify_str:1}':tty1 tty2 tty3 tty4 tty5 tty6 LOCAL' >> /etc/security/access.conf
}


clear_old() {
  # Delete backup file 14 days ago
  find ${backup_dir} -name "access.conf_*" -type f -mtime +14 -exec rm -f {} \;

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

      console user managermant

      1. List all console users
      2. Add console user
      3. Delete console user
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
             echo 'press enter key !' 
             read a ;;
          2) add_user
             echo ''
             echo 'press enter key !' 
             read a ;;
          3) del_user
             echo ''
             echo 'press enter key !' 
             read a ;;
          4) view_log 
             echo ''
             echo 'press enter key !' 
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

