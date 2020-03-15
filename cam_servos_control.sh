#!/bin/bash

LOW_SERVO_INIT_POS=0
HIGH_SERVO_INIT_POS=20

LOW_SERVO_MIN_RANGE=-140
LOW_SERVO_MAX_RANGE=140
HIGH_SERVO_MIN_RANGE=-30
HIGH_SERVO_MAX_RANGE=100

INIT_STEP_DELAY=0.0001

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
	local firstfact=7408
	local secondfact=1550000

	if [ $pos_to_set -lt $LOW_SERVO_MIN_RANGE ]; then pos_to_set=$LOW_SERVO_MIN_RANGE; fi
	if [ $pos_to_set -gt $LOW_SERVO_MAX_RANGE ]; then pos_to_set=$LOW_SERVO_MAX_RANGE; fi

	pos_to_set=$(echo "$firstfact*$pos_to_set+$secondfact" | bc)
	echo $pos_to_set > /sys/class/pwm/pwmchip0/pwm1/duty_cycle
}

function _set_high_servo_pos
{
	local pos_to_set=$1
#	local pos_min=900000
#	local pos_max=1400000
	local firstfact=11538
	local secondfact=1250000

	if [ $pos_to_set -lt $HIGH_SERVO_MIN_RANGE ]; then pos_to_set=$HIGH_SERVO_MIN_RANGE; fi
	if [ $pos_to_set -gt $HIGH_SERVO_MAX_RANGE ]; then pos_to_set=$HIGH_SERVO_MAX_RANGE; fi

	pos_to_set=$(echo "$firstfact*$pos_to_set+$secondfact" | bc)
	echo $pos_to_set > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
}

function _init_low_servo
{
	for pos in $(seq $LOW_SERVO_MIN_RANGE 1 $LOW_SERVO_MAX_RANGE); do
		_set_low_servo_pos $pos 
		sleep $INIT_STEP_DELAY
	done

	for pos in $(seq $LOW_SERVO_MAX_RANGE -1 $LOW_SERVO_INIT_POS); do
		_set_low_servo_pos $pos 
		sleep $INIT_STEP_DELAY
	done
}

function _init_high_servo
{
	for pos in $(seq $HIGH_SERVO_MIN_RANGE 1 $HIGH_SERVO_MAX_RANGE); do
		_set_high_servo_pos $pos 
		sleep $INIT_STEP_DELAY
	done

	for pos in $(seq $HIGH_SERVO_MAX_RANGE -1 $HIGH_SERVO_MIN_RANGE); do
		_set_high_servo_pos $pos 
		sleep $INIT_STEP_DELAY
	done

	for pos in $(seq $HIGH_SERVO_MIN_RANGE 1 $HIGH_SERVO_INIT_POS); do
		_set_high_servo_pos $pos 
		sleep $INIT_STEP_DELAY
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
#_init_servos
#_set_low_servo_pos $1
#_set_high_servo_pos $1

##### end ######

