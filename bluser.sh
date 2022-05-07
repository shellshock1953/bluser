#!/bin/bash
# Change this, if needed
DEVICE="D9:D1:6E:F1:A6:FD"
ARG="${1}"
LOCK_CMD="i3lock -c 000000"
WAIT_TILL=10

# Dont change this
pipe=/tmp/btctlpipe 
output_file=/tmp/btctl_output
log_file=/tmp/bluser.log
NO_DEVICE=0
SYSTEMD_STATUS=

# Colors
NC='%{F-}%{B-}'
BLACK="%{F#263238}"
DARK_GRAY="%{F#37474f}"
RED="%{F#ff9800}"
LIGHT_RED="%{F#ffa74d}"
GREEN="%{F#8bc34a}"
LIGHT_GREEN="%{F#9ccc65}"
ORANGE="%{F#ffc107}"
YELLOW="%{F#ffa000}"
BLUE="%{F#03a9f4}"
LIGHT_BLUE="%{F#81d4fa}"
PURPLE="%{F#e91e63}"
LIGHT_PURPLE="%{F#ad1457}"
CYAN="%{F#009688}"
LIGHT_CYAN="%{F#26a69a}"
LIGHT_GRAY="%{F#cfd8dc}"
WHITE="%{F#eceff1}"
BBLACK="%{B#263238}"
BDARK_GRAY="%{B#37474f}"
BRED="%{B#ff9800}"
BLIGHT_RED="%{B#ffa74d}"
BGREEN="%{B#8bc34a}"
BLIGHT_GREEN="%{B#9ccc65}"
BORANGE="%{B#ffc107}"
BYELLOW="%{B#ffa000}"
BBLUE="%{B#03a9f4}"
BLIGHT_BLUE="%{B#81d4fa}"
BPURPLE="%{B#e91e63}"
BLIGHT_PURPLE="%{B#ad1457}"
BCYAN="%{B#009688}"
BLIGHT_CYAN="%{B#26a69a}"
BLIGHT_GRAY="%{B#cfd8dc}"
BWHITE="%{B#eceff1}"

lecho() {
  echo "Bluser: ${2}$"
  echo "Bluser: ${1}${2}${NC}" > ${log_file}
}

begin() 
{
  if [[ ! -p $pipe ]]; then
    mkfifo $pipe
  fi
}

terminate()
{
  killall bluetoothctl &>/dev/null
  rm -f $pipe
}

bleutoothctl_reader() 
{
  {
    while true
    do
      if read line <$pipe; then
          if [[ "$line" == 'exit' ]]; then
              return 0
          fi          
          echo "$line"
      fi
    done
  } | bluetoothctl > "$output_file"
}

bleutoothctl_writer() 
{
  cmd=$1
  printf "$cmd\n\n" > $pipe
}

bleutoothctl_scan() {
  begin
  trap terminate EXIT

  bleutoothctl_reader &
  sleep 1
  bleutoothctl_writer "scan on"
  sleep 15
  bleutoothctl_writer "scan off"
  sleep 1
  bleutoothctl_writer "devices"
  sleep 1
  bleutoothctl_writer "exit"

  terminate
}

check_device() {
  cat $output_file | grep -e '^Device.*' | sed 's/Device //g' | grep $DEVICE > /dev/null 2>&1
  case $? in
    1) NO_DEVICE=1 ;;
    0) NO_DEVICE=0 ;;
    *) NO_DEVICE=0 ;;
  esac
}

lock_if_no_device() {
  if [ "$NO_DEVICE" -eq 1 ]; then
    lecho "${YELLOW}" "NO user nearby"
    sleep $WAIT_TILL
    bleutoothctl_scan
    check_device
    if [ "$NO_DEVICE" -eq 1 ]; then
      lecho "${RED}" "Device will be locked"
      sleep $WAIT_TILL
      ${LOCK_CMD} &
    fi
  else
    lecho "${GREEN}" "User nearby"
  fi
}

get_status() {
  SYSTEMD_STATUS=$(systemctl --user is-active bluser)
}

toggle() {
  get_status
  case $SYSTEMD_STATUS in
    inactive)
      lecho ${GREEN} "Starting"
      systemctl --user start bluser &
      ARG=
      main
      ;;
    # activating)
    #   lecho "Starting"
    #   ;;
    *)
      systemctl --user stop bluser &
      sleep 10
      ARG=
      main
      ;;
  esac
}

check_if_locked() {
  LOCKED="$(ps aux | grep i3lock | grep -v grep)"
  if [ ! -z "${LOCKED}" ]; then
    lecho ${YELLOW} "already locked"
    # exit 0
  fi
}

main() {
  if [ -z "${DEVICE}" ]; then
    lecho ${RED} "Device is not set"
    # exit 1
  fi
  case "${ARG}" in
    toggle) toggle && break ;;
    *) 
      # check_if_locked
      get_status
      if [ "${SYSTEMD_STATUS}" == "inactive" ]; then
        lecho ${CYAN} "Stopped"
        exit 0
      fi
      lecho ${GREEN} "Scanning"
      bleutoothctl_scan
      check_device
      lock_if_no_device
      ;;
   esac
}

while true; do
  main 
  sleep 60
done
