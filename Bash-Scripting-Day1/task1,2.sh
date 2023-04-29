#!/bin/bash
# Task 1 How to perform floating point operation
# Task 2 How to check a number is a valid floating point
# This Script is for sum , multiplay , subtract, division of 2 floating point

##Parameters
##	1st parameter: 1st number
##	2nd parameter: 2nd number

## Exit codes
##	0: Success
##	1: Not enough parameters
##	2: Division by zero
##	3: NUM1 is not an Float
##	4: NUM2 is not an Float

## Check for parameters
[ ${#} -ne 2 ] && echo 'You should enter two parameters ' && exit 1
## Assign values to custom variables
NUM1=${1}
NUM2=${2}

## Check for division by zero
[ "${2}" == 0 ] || [ "${2}" == "0.0" ] && echo 'can not Divide by zero ' && exit 2

## Check for Float values
[ ! $NUM1=^[-+]?[0-9]*\.[0-9]*$ ] && echo 'paramter 1 should be float' && exit 3
[ ! $NUM2=^[-+]?[0-9]*\.[0-9]*$ ] && echo 'paramter 2 should be float' && exit 4

# Add two floating point numbers

echo "Sum of ${NUM1} + ${NUM2} is = " $(echo "${NUM1} + ${NUM2}" | bc -l)

# # Subtract two floating point numbers
echo "Subtract of ${NUM1} - ${NUM2} is = " $(echo "${NUM1} - ${NUM2}" | bc -l)

# # Multiply two floating point numbers
echo "Multiply of ${NUM1} * ${NUM2} is = " $(echo "${NUM1} * ${NUM2}" | bc -l)

# # Divide two floating point numbers
echo "Divide of ${NUM1} / ${NUM2} is = " $(echo "${NUM1} / ${NUM2}" | bc -l)

exit 0
