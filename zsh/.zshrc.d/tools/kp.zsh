### PROCESS
# mnemonic: [K]ill [P]rocess
# show output of "ps -ef", use [tab] to select one or multiple entries
# press [enter] to kill selected processes and go back to the process list.
# or press [escape] to go back to the process list. Press [escape] twice to exit completely.


function kp() {
	local pid=$(ps -ef | sed 1d | eval "$FZF_CMD" | awk '{print $2}')
	if [ "x$pid" != "x" ]
		then
  	echo $pid | xargs kill -${1:-9}
  	kp
	fi
}

# function kp() {
# 		local  FZF_CMD="fzf -m --header='[kill:process]'"
#     local pid
#     if [ "$UID" != "0" ]; then
#         pid=$(ps -f -u $UID | sed 1d | $FZF_CMD | awk '{print $2}')
#     else
#         pid=$(ps -ef | sed 1d | $FZF_CMD | awk '{print $2}')
#     fi
#
#     if [ "x$pid" != "x" ]
#     then
#         echo $pid | xargs kill -${1:-9}
#     fi
# }
