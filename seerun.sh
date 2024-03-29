tmpfile="tmpfile"

function show_help ()  
{
	echo "Usage: run -ec <file> 3 4"
	echo "       -e Execute commands. Default is not execute."
	echo "       -c Confirm each command."
	echo "       <file>: is the file you have commands in"
	echo "       3 4: from lines 3 to 4"
	echo "       5: only line 5"
}

function clean_up () 
{
	if [ -f "$tmpfile" ]; then
		rm "$tmpfile"
	fi
}

# set cmd line input variables
# ref: https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

check=0
execute=0
while getopts "ceh" opt; do
    case "$opt" in
    h)
        show_help
        exit 0
        ;;
    c)  check=1
        ;;
    e)  execute=1
        ;;
    esac
done

shift $((OPTIND-1))
#echo "check is: $check"

# ensure file exists
file="$1"
if [ -z "$file" ]; then
	echo "No input file given."
	exit 1
fi
if [ ! -f "$file" ]; then
	echo "Given input file does not exist: $file"
	exit 1
fi

start=$2
end=$3

if [ -z $start ]; then
	echo "No lines specified, so listing full file..."
	cat -n "$file"
	clean_up
	exit 0
fi

# if end is not mentioned, then it is equal to start
if [ -z $end ]; then
	end=$start
fi

#if [ "$end" != "$" ] && [ "$start" -gt "$end" ]; then
if [ "$end" != "$" ] && [ "$start" -gt "$end" ]; then
	echo "Start line cannot be greater than end."
	clean_up
	exit 0
fi

sed -n "$start,$end"p "$file" > $tmpfile

line_count=$start
cat "$tmpfile" | while read line || [[ -n $line ]]; do

	# only showing statements
	if [[ ! $execute == "1" ]]; then
		echo "$line_count: $line"
		let "line_count+=1"
		continue
	fi


	# if command starts with #, continue
	if [[ $line =~ ^\s*# ]]; then
		echo ""
		echo "-> Skipping comment: $line_count: $line"
		let "line_count+=1"
		continue
	fi

	# if line is empty, continue
	if [[ $line =~ ^\s*$ ]]; then
		echo ""
		echo "-> Skipping empty line: $line_count: $line"
		let "line_count+=1"
		continue
	fi

	# if command contains "#needs_param", then exit without executing.
	if [[ $line =~ .*#needs_param.* ]]; then
		echo ""
		echo "-> Command needs param. Exiting without executing."
		echo "$line_count: $line"
		exit 0
	fi

	# executing statements
	if [[ $check == "0" ]]; then
		echo ""
		echo "-> Running:"
		echo "$line_count: $line"
		eval "$(echo $line)"
	else
		echo ""
		echo "-> $line_count: $line"
		echo -n "Run above statemet? (yes is default) "
		read should_run</dev/tty

		if [ "$should_run" = "y" ] || [ "$should_run" = "Y" ] || [ -z "$should_run" ]; then
			echo "-> Running:"
			echo "$line_count: $line"
			eval "$(echo $line)"
		else
			echo "Exiting"
			clean_up
			exit 0
		fi
	fi
	let "line_count+=1"

done 

clean_up
exit 0
