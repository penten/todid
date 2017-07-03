#!/bin/bash
todo="$1/todo.txt"
done="$1/done.txt"
tmp=`mktemp`
email="$2"

yesterday=`date --date='1 day ago' +'%Y-%m-%d'`
tomorrow=`date --date='+ 1 day' +'%Y-%m-%d'`
today=`date +'%Y-%m-%d'`

function header() {
	printf "\n\n# $1\n\n" >> $tmp
}

function undo_task() {
	cut -d ' ' -f 3-
}

if [ ! -f "$todo" ] || [ ! -f "$done" ]; then
	echo "Could not find todo.txt/done.txt at $1"
fi

# move daily tasks from done back to todo
grep '@daily' "$todo" "$done" | undo_task | uniq | sed 's/^/(A) /' >> "$todo"

# Set today's calendar tasks to (A) priority
sed -i "/^[^x(].*due:$today/s/^/(A) /" "$todo"

# Find random book-note file
bn=`find $1/booknotes -type f|shuf -n1`
printf "From: " >> "$tmp"
# filename
echo "$bn" | awk -F '[./]' '{print $(NF-1)}'|sed 's/-/ /g' >> "$tmp"
record=`cat $bn | dos2unix | tail -n+5 | awk -v RS='' '/^[^>#=\*]/ {print NR}' | shuf -n1`
# random note from the file
cat $bn | dos2unix | awk -v RS='' -v ORS='\n' "/^[^>#=\*]/ && NR==$record { print \$0; exit }" >> "$tmp"

# create a list of tasks that were done yesterday
header "Tasks Completed Yesterday"
grep "^x $yesterday " "$todo" "$done" | undo_task | sed 's/^/✓ /' >> "$tmp"

# create a list of tasks to be done today
header "Today's Tasks"
grep -v 'x ' "$todo" | grep -e '(A)' -e "$today" | sort | sed 's/^/- /' >> "$tmp"

if [ -f "$1/*conflict*.txt" ]; then
	header "Possible Conflicts Found"
	ls "$1/*conflict*.txt" >> "$tmp"
fi

# Tomorrow's due tasks
header "Tasks Due Tomorrow"
grep -v 'x ' "$todo" | grep -e "$tomorrow" | sort | sed 's/^/- /' >> "$tmp"

cat $tmp | sed 's/\r$//' | mail -s "Todid $today" -r max@maxjmartin.com $email
rm $tmp

