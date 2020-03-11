#!/bin/bash

source $SRC/lib/functions.sh
display_alert "$(basename $BASH_SOURCE)" "${BOARD_NAMES[$x]} @ ${HOST}" "info"

readarray -t array < <(get_device "^[wr].*" "")
for u in "${array[@]}"
do
	display_alert "... " "$u" "info"
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${HOST} "nmcli con down $u &>/dev/null" # go down and
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${HOST} "nmcli c del $u &>/dev/null" # delete if previous defined
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${HOST} "nmcli c add type wifi con-name $u ifname $u ssid ${WLAN_ID_24}" >> ${SRC}/logs/${HOST}.txt 2>&1
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${HOST} "nmcli con modify $u wifi-sec.key-mgmt wpa-psk" >> ${SRC}/logs/${HOST}.txt 2>&1
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${HOST} "nmcli con modify $u wifi-sec.psk ${WLAN_PASS_24}" >> ${SRC}/logs/${HOST}.txt 2>&1
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${HOST} "nmcli con up $u" >> ${SRC}/logs/${HOST}.txt 2>&1
	[[ $? -ne 0 ]] && display_alert "Something went wrong with $u - check logs ${SRC}/logs/${HOST}.txt" "$u" "wrn"
done
sleep 3