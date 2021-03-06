#!/bin/bash

if [[ ! -e makefile ]] 
  then echo "Please execute this script from repository root"
  exit 2
fi

prog=$1
dir=$2

my_out=$(mktemp)
my_err=$(mktemp)

for f in "$dir"/*.in
do 
    out=${f%in}out
    err=${f%in}err

    ./"$prog" < "$f" 1> "$my_out" 2> "$my_err"

    valgrind --error-exitcode=123 --leak-check=full --show-leak-kinds=all \
    --errors-for-leak-kinds=all ./"$prog" < "$f" > /dev/null 2>&1
    val_return=$?

    if [[ "$val_return" == "123" ]]
        then val_return="ERROR"
    else
        val_return="OK"
    fi 

    diff "$out" "$my_out" > /dev/null 2>&1
    status[0]=$?
    diff "$err" "$my_err" > /dev/null 2>&1
    status[1]=$?
    test=${f#"$dir"}

    for i in 0 1
    do
        if [[ "${status[${i}]}" == "0" ]]
            then status[$i]="OK"
        else
            status[$i]="WRONG"
        fi
    done 
    
    printf "%-40s %-20s %-20s %-20s\n" "$test: \
    " "OUT - ${status[0]}" "ERR - ${status[1]}" "VALGRIND - $val_return"
done

rm "$my_out"
rm "$my_err"