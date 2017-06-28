#!/bin/bash
todo="$1/todo.txt"
done="$1/done.txt"
tmp=`mktemp`
email="$2"

yesterday=`date --date='1 day ago' +'%Y-%m-%d'`
today=`date +'%Y-%m-%d'`

if [ ! -f "$todo" ] || [ ! -f "$done" ]; then
	echo "Could not find todo.txt/done.txt at $1"
fi

# 1. move daily tasks from done back to todo
grep '@daily' "$todo" "$done" | cut -d ' ' -f 3- | uniq | sed 's/^/(A) /' >> "$todo"

# 2. create a list of tasks that were done yesterday
printf "\n# Tasks Completed Yesterday:\n\n" >> "$tmp"
grep "^x $yesterday " "$todo" "$done" | cut -d ' ' -f 3- | sed 's/^/✓ /' >> "$tmp"

# 3. create a list of tasks to be done today
printf "\n\n# Today's Tasks (todo: currently this does not increment (B) tasks to (A)\n\n" >> "$tmp"
grep -v 'x ' "$todo" | grep -e '(A)' -e "$today" | sort | sed 's/^/- /' >> "$tmp"

cat $tmp | sed 's/\r$//' | mail -s "Todid $today" -r max@maxjmartin.com $email
rm $tmp
