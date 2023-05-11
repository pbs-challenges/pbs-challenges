#!/usr/bin/env bash

# Written by Allison Sheridan (aka @podfeet) in 2023 under the MIT license
# This script was written as a response to the challenge starting at
# Bart Busschots in Programming By Stealth 147 at
# https://pbs.bartificer.net/pbs147 d
# PBS147:
# Write a script to take the user’s breakfast order. The script should store the
# menu items in an array, then use a select loop to present the user with the 
# menu, plus an extra option to indicate they’re done ordering. Each time the 
# user selects an item, append it to an array representing their order. 
# When the user is done adding items, print their order.
# For bonus credit, update your script to load the menu into an array from a 
# text file containing one menu item per line, ignoring empty lines and lines 
# starting with a # symbol.
# PBS148: 
# accept an optional argument limiting the number of items a user can order 
# from the breakfast menu.
# PBS149: 
# update your solution to the previous challenge to convert the optional 
# argument for specifying a limit to a -l optional argument, and add a -s flag 
# to enable snarky output (like the infamous Carrot weather app for iOS does).
# PBS150:
# Update your challenge solution from last time so it can optionally load the
# menu from a or from STDIN. Add an option named -m (for menu), and if that 
# option has the value -, read from STDIN, otherwise, treat the value of -m as a
# file path and load the menu from that file. If -m is not passed, default to 
#  reading from ./menu.txt.
# Also, make a conscious choice about what goes to STDOUT and STDERR.

# Variable to hold snarkiness - assume it's blank
isSnark=""
# Variable to hold maximum number of food items
maxFood="2"

usage="Usage: $(basename $0) [-s] [-l LIMIT]"

# while loop to use getopts go through and look for arguments
# Start with : to suppress error messages, I'll write my own
# s goes first cuz it's a flag
# : after the l because it has arguments
# $opt will hold the matched options

while getopts ':sl:' opt
do
  case $opt in
    s)
      # if we find the flag for snarkiness - 1 means to be snarky
      isSnark=1
      ;;
    l)
      # if we get an optional argument to set a limit on how many items th
      # they can order
      maxFood="$OPTARG"
      ;;
    ?)
      # here comes my fancy error message if they type something after the shell
      # script name that isn't -s or -l
      echo "$usage"
      exit 1
      ;;
  esac
done

# regex allows whole positive numbers
regex=^[+]?[0-9]+$

# ------------------------------------------------------------------------------
# At 1:17 in PBS149 I tell Bart I don't understand shift and what it's doing. 
# His example is very helpful and is not in the show notes. Plus you get to hear
# him say "minus a stinky would be 2" and it will make perfect sense.
# ------------------------------------------------------------------------------

# remove all of the arguments from the indices by using shift by one less than
# $OPTIND which is the next value that would come into getops
shift $(echo "$OPTIND-1" | bc)

# Initialize a variable with a leading line feed to hold the message when 
# maxFood has been reached
message="
"

if [[ -n $isSnark ]] # if isSnark is NOT empty
then
  message+="Your doctor says you're obese so you can't order any more food.
  "
else # isSnark is empty so we have to be more polite
  message+="Thank you. You have ordered the maximum number of items.
  "
fi

# test for whole number as input for maxFood
if [[ -z $maxFood ]] # if no argument supplied
  then
    maxFood=2 # Arbitrary max number of items allowed to be ordered
    message+="The max items you can order is $maxFood"
  else
  until [[ $maxFood =~ $regex ]] # $maxFood is a positive number
    do
      read -p 
      "Please enter a whole number for the food order limit:" maxFood		
    done
fi

# Create an array of breakfast foods
declare -a breakfastMenu
# Create an array to hold the user's order
declare -a order

# Loop through the menu.txt file and populate the breakfastMenu array

while read -r line
  do
    # skip invalid selections ($food is empty)
    [[ -z $line ]] && continue
    
    # skip comment lines
    echo "$line" | egrep -q '^[ ]*#' && continue

    breakfastMenu+=("$line")

  # cat to read in the file
  # $BASH_SOURCE if the path of the executing script including script name
  # dirname grabs just the directory name from $BASH_SOURCE
  # menu.txt is where our breakfast menu resides
  done <<< "$(cat $(dirname "$BASH_SOURCE")/menu.txt)"

echo -e "
Below is the breakfast menu.
Enter the number for the item you would like to order.
When you're done ordering, type 1 to select done and complete your order
"

# Quotes around the array in select required to keep items with 
# spaces in their names as one item

select food in "${breakfastMenu[@]}" 
  do 
    # skip invalid selections ($food is empty)  
    [[ -z $food ]] && continue

    # exit if done
    [[ $food == done ]] && break

    order+=("$food")
    # using printf because it's easier to add line feeds
    printf "You added $food to your order\n\n"
    # echo "You have ordered ${#order[@]} item(s)"

    # exit if $maxFood is reached
    [[ ${#order[@]} -eq $maxFood ]] && echo "$message" && break
done

echo "Let me read your order back to you:"
for item in "${order[@]}"
  do
    echo "* $item"
  done
