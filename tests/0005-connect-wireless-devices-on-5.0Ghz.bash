#!/bin/bash

source $SRC/lib/functions.sh

TEST_TITLE="5Ghz"
TEST_ICON="<img width=32 src=https://cdn4.iconfinder.com/data/icons/ionicons/512/icon-wifi-32.png>"
TEST_SKIP="true"
[[ $DRY_RUN == true ]] && return 0

display_alert "$(basename $BASH_SOURCE)" "${BOARD_NAMES[$x]} @ ${USER_HOST}" "info"

readarray -t array < <(get_device "^[wr].*")

for u in "${array[@]}"
do
	display_alert "... " "$u" "info"
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli con down $u &>/dev/null" # go down and
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli c del $u &>/dev/null" # delete if previous defined
	output=$(sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli c add type wifi con-name $u ifname $u ssid ${WLAN_ID_50}" >> ${SRC}/logs/${USER_HOST}.txt 2>&1)
	# retry once if it fails
        [[ $? -ne 0 ]] && sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli c add type wifi con-name $u ifname $u ssid ${WLAN_ID_50}" >> ${SRC}/logs/${USER_HOST}.txt 2>&1

	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli con modify $u wifi-sec.key-mgmt wpa-psk" >> ${SRC}/logs/${USER_HOST}.txt 2>&1
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli con modify $u wifi-sec.psk ${WLAN_PASS_50}" >> ${SRC}/logs/${USER_HOST}.txt 2>&1
	sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli con up $u" >> ${SRC}/logs/${USER_HOST}.txt 2>&1
	if [[ $? -ne 0 ]]; then
		sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli con down $u" >> ${SRC}/logs/${USER_HOST}.txt 2>&1
		sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "nmcli c del $u &>/dev/null" # delete if failed
		sshpass -p ${PASS_ROOT} ssh ${USER_ROOT}@${USER_HOST} "service network-manager reload"
		[[ -n $(echo "${output}" | grep succesfully) ]] && display_alert "Can't connect to ${WLAN_ID_50}" "$u" "wrn"
	fi
done
