#!/bin/bash

function _init_pwms
{
	echo 0 >  /sys/class/pwm/pwmchip0/export 2>/dev/null
	echo 1 >  /sys/class/pwm/pwmchip0/export 2>/dev/null

	echo 0 > /sys/class/pwm/pwmchip0/pwm0/enable 2>/dev/null
	echo 0 > /sys/class/pwm/pwmchip0/pwm1/enable 2>/dev/null

	echo 20000000 > /sys/class/pwm/pwmchip0/pwm0/period
	echo 20000000 > /sys/class/pwm/pwmchip0/pwm1/period

	echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
	echo 1 > /sys/class/pwm/pwmchip0/pwm1/enable

	echo 0 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
	echo 0 > /sys/class/pwm/pwmchip0/pwm1/duty_cycle
}

function _set_low_servo_pos
{
	local pos_to_set=$1
#	local pos_min=500000
#	local pos_max=2000000
	local pos_min=-140
	local pos_max=140
	local firstfact=7408
	local secondfact=1550000

	if [ $pos_to_set -lt $pos_min ]; then pos_to_set=$pos_min; fi
	if [ $pos_to_set -gt $pos_max ]; then pos_to_set=$pos_max; fi

	echo $pos_to_set

	pos_to_set=$(echo "$firstfact*$pos_to_set+$secondfact" | bc)
	echo $pos_to_set > /sys/class/pwm/pwmchip0/pwm1/duty_cycle

	echo $pos_to_set
}

function _set_high_servo_pos
{
	local pos_to_set=$1
#	local pos_min=900000
#	local pos_max=1400000
	local pos_min=-30
	local pos_max=100
	local firstfact=11538
	local secondfact=1250000

	if [ $pos_to_set -lt $pos_min ]; then pos_to_set=$pos_min; fi
	if [ $pos_to_set -gt $pos_max ]; then pos_to_set=$pos_max; fi

	echo $pos_to_set
	
	pos_to_set=$(echo "$firstfact*$pos_to_set+$secondfact" | bc)
	echo $pos_to_set > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
}

function _init_low_servo
{
	_set_low_servo_pos -140
	sleep 0.5

	for pos in $(seq -140 1 140); do
		_set_low_servo_pos $pos 
		sleep 0.01
	done

	for pos in $(seq 140 -1 0); do
		_set_low_servo_pos $pos 
		sleep 0.01
	done
}

function _init_high_servo
{
	_set_high_servo_pos -30
	sleep 0.5

	for pos in $(seq -30 1 100); do
		_set_high_servo_pos $pos 
		sleep 0.01
	done

	for pos in $(seq 100 -1 -30); do
		_set_high_servo_pos $pos 
		sleep 0.01
	done

	for pos in $(seq -30 1 20); do
		_set_high_servo_pos $pos 
		sleep 0.01
	done
}

function _init_servos
{
	_init_pwms

	_init_low_servo &
	_init_high_servo &

	wait
}


##### main #####
_init_servos
#_set_high_servo_pos $1

##### end ######

