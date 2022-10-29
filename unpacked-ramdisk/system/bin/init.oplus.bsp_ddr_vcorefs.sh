#!/system/bin/sh
#=============================================================================
#persist.debug.cpu.dvfs.config
#testing_phase=`getprop persist.debug.ddr.vcorefs.config`
#=============================================================================

echo "Just for CPU DVFS Debug"

#ntest*delay= 30S
ntest=200
phase2tesettime=400
phase=1
delay=0.3	## 00ms

model=`getprop ro.vendor.qti.soc_model`
for line in `cat /ddr_freqencies_by_platform.csv`
do
        OLD_IFS="$IFS"
        IFS=","
        arr=($line)
        IFS="$OLD_IFS"
        if [ x"${arr[0]}" =  x"$model" ]; then
				for i in $(seq 1 ${#arr[*]}-1)
                do
                        bimc_scaling_freq_list[i-1]="${arr[i]}"
                done
                break
        fi
done

if [ ${#bimc_scaling_freq_list[*]} == 0 ]; then
platform=`getprop ro.board.platform`

if [ x"$platform" = x"taro" ]; then
	bimc_scaling_freq_list=(3196800 2736000 2092800 1708800 1555200 1353600 1017600 768000 681600 547200 451200 200000)
else
	bimc_scaling_freq_list=(2092800 1708800 1555200 1353600 1017600 768000 547200 451200 200000)
fi
fi

bmic_scaling_phase2_freq_list=(547200 768000 1018000 1552000)

display_freq() {
  if [ -f /sys/kernel/debug/clk/measure_only_mccc_clk/clk_measure ]; then
    # SM8150/8250
    echo "BIMC cur_freq: " $(< /sys/kernel/debug/clk/measure_only_mccc_clk/clk_measure)
  else
    echo "BIMC measure unsupported, try dercit read"
    echo "BIMC cur_freq: " $(< /sys/kernel/debug/clk/measure_only_mccc_clk/clk_measure)
  fi
}

bimc_freq_switch() {
  ## don't turn off thermal-engine, otherwise thermal reset will be triggered easily. #stop thermal-engine
  for REQ_KHZ in ${FREQ_LIST}; do
    #SM8150/8250
    if [ -f /sys/kernel/debug/aop_send_message ]; then
        echo "BIMC req_freq: ${REQ_KHZ}"
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /sys/kernel/debug/aop_send_message
    elif [ -f /sys/kernel/debug/aoss_send_message ]; then
        echo "BIMC req_freq: ${REQ_KHZ}"
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /sys/kernel/debug/aoss_send_message
    elif [ -f /proc/aop_send_message ]; then
        echo "BIMC req_freq proc: ${REQ_KHZ}"
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /proc/aop_send_message
    elif [ -f /proc/aoss_send_message ]; then
        echo "BIMC req_freq proc: ${REQ_KHZ}"
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /proc/aoss_send_message
    else
        echo "BIMC measure unsupported, try dercit set"
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /sys/kernel/debug/aop_send_message
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /sys/kernel/debug/aoss_send_message
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /proc/aop_send_message
        echo "{class:ddr, res:fixed, val: $((${REQ_KHZ}/1000))}" > /proc/aoss_send_message
    fi

    display_freq
    sleep ${delay}
  done
}


#cpu dvfs ramdom
do_ddr_vcorefs_random(){
    last_sec=`date '+%s'`
    echo "do_ddr_vcorefs_random time `date "+%H:%M:%S"` "
	for i in $(seq 1 ${ntest})
	do
		# Seed random generator
		# randomly select the frequency from the list
		FREQ_LIST=${bimc_scaling_freq_list[$RANDOM % ${#bimc_scaling_freq_list[@]}]}
		bimc_freq_switch
        cur_sec=`date '+%s'`
		let diff_time=`expr $cur_sec - $last_sec`
        if [ "$diff_time" -ge "60" ]; then
		     break
		fi
	done
	echo "do_ddr_vcorefs_random time over `date "+%H:%M:%S"` "
}


do_ddr_vcorefs_longstep_random(){
    last_sec=`date '+%s'`
    echo "do_ddr_vcorefs_longstep_random time `date "+%H:%M:%S"` "
	len=$((${#bimc_scaling_freq_list[@]}-1))
	current=0
	mid=$(($len/2))
		for i in $(seq 1 ${ntest})
		do
			step=$(($(($RANDOM%$(($len-5))))+5))
		if [ $current -lt $mid ]; then
			current=$(($current+$step))
		else
			current=$(($current-$step))
		fi
		if [ $current -lt 0 ]; then
			current=0
		fi
		if [ $current -eq $len ]; then
			current=$len
		fi
		if [ $current -gt $len ]; then
			current=$len
		fi

		FREQ_LIST=${bimc_scaling_freq_list[$current]}
		bimc_freq_switch
		cur_sec=`date '+%s'`
		let diff_time=`expr $cur_sec - $last_sec`
        if [ "$diff_time" -ge "60" ]; then
		     break
		fi
	done
	echo "do_ddr_vcorefs_longstep_random time over `date "+%H:%M:%S"` "
}


do_ddr_vcorefs_max(){
    last_sec=`date '+%s'`
    echo "do_ddr_vcorefs_max time `date "+%H:%M:%S"` "
	for i in $(seq 1 ${ntest})
	do
		FREQ_LIST=${bimc_scaling_freq_list[0]}
		bimc_freq_switch
        cur_sec=`date '+%s'`
		let diff_time=`expr $cur_sec - $last_sec`
        if [ "$diff_time" -ge "60" ]; then
		     break
		fi
	done
	echo "do_ddr_vcorefs_max time over `date "+%H:%M:%S"` "
}


do_ddr_vcorefs_min(){
    last_sec=`date '+%s'`
    echo "do_ddr_vcorefs_min time `date "+%H:%M:%S"` "
	for i in $(seq 1 ${ntest})
	do
		FREQ_LIST=${bimc_scaling_freq_list[${#bimc_scaling_freq_list[@]}-1]}
		bimc_freq_switch
        cur_sec=`date '+%s'`
		let diff_time=`expr $cur_sec - $last_sec`
        if [ "$diff_time" -ge "60" ]; then
		     break
		fi
	done
	echo "do_ddr_vcorefs_min time over `date "+%H:%M:%S"` "
}


enable_ddr_vcorefs_test_phase1(){
	while [ 1 ] 
	do
		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		if [ "$ddr_testphase" = "done" ]; then
			break
		fi
		setprop persist.debug.ddr.vcorefs.config random
		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		echo "ddr_testphase:$ddr_testphase."
		if [ "$ddr_testphase" = "random" ]; then
			do_ddr_vcorefs_random
		fi

		echo "getprop persist.debug.ddr.vcorefs.config."
		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		if [ "$ddr_testphase" = "done" ]; then
			break
		fi
		setprop persist.debug.ddr.vcorefs.config max
		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		echo "ddr_testphase:$ddr_testphase."
		if [ "$ddr_testphase" = "max" ]; then
			do_ddr_vcorefs_max
		fi

		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		if [ "$ddr_testphase" = "done" ]; then
			break
		fi
		setprop persist.debug.ddr.vcorefs.config min
		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		echo "ddr_testphase:$ddr_testphase."
		if [ "$ddr_testphase" = "min" ]; then
			do_ddr_vcorefs_min
		fi

		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		if [ "$ddr_testphase" = "done" ]; then
			break
		fi
		setprop persist.debug.ddr.vcorefs.config longstep
		ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
		echo "ddr_testphase:$ddr_testphase."
		if [ "$ddr_testphase" = "longstep" ]; then
			do_ddr_vcorefs_longstep_random
		fi
	done
	echo "The ddr_vcorefs_test_phase1 is done and PASS if no exception occurred."
}
enable_ddr_vcorefs_test_phase2(){
	echo "phase2 is actually runned."
	setprop persist.debug.ddr.vcorefs.config max
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "max" ]; then
		FREQ_LIST=${bimc_scaling_freq_list[0]}
		bimc_freq_switch
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		last_sec=`date '+%s'`
		echo "do_ddr_vcorefs_phase2_test1 time `date "+%H:%M:%S"` "
		for i in $(seq 1 ${phase2tesettime})
		do
			FREQ_LIST=${bmic_scaling_phase2_freq_list[1]}
			bimc_freq_switch
			cur_sec=`date '+%s'`
			let diff_time=`expr $cur_sec - $last_sec`
			if [ "$diff_time" -ge "60" ]; then
				break
			fi
		done
		echo "do_ddr_vcorefs_phase2_test1 time over `date "+%H:%M:%S"` "
	fi
	
	setprop persist.debug.ddr.vcorefs.config max
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "max" ]; then
		FREQ_LIST=${bimc_scaling_freq_list[0]}
		bimc_freq_switch
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		last_sec=`date '+%s'`
		echo "do_ddr_vcorefs_phase2_test2 time `date "+%H:%M:%S"` "
		for i in $(seq 1 ${phase2tesettime})
		do
			FREQ_LIST=${bmic_scaling_phase2_freq_list[3]}
			bimc_freq_switch
			cur_sec=`date '+%s'`
			let diff_time=`expr $cur_sec - $last_sec`
			if [ "$diff_time" -ge "60" ]; then
				break
			fi
		done
		echo "do_ddr_vcorefs_phase2_test2 time over `date "+%H:%M:%S"` "
	fi
	
	setprop persist.debug.ddr.vcorefs.config max
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "max" ]; then
		FREQ_LIST=${bimc_scaling_freq_list[0]}
		bimc_freq_switch
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		last_sec=`date '+%s'`
		echo "do_ddr_vcorefs_phase2_test3 time `date "+%H:%M:%S"` "
		for i in $(seq 1 ${phase2tesettime})
		do
			FREQ_LIST=${bmic_scaling_phase2_freq_list[1]}
			bimc_freq_switch
			cur_sec=`date '+%s'`
			let diff_time=`expr $cur_sec - $last_sec`
			if [ "$diff_time" -ge "60" ]; then
				break
			fi
		done
		echo "do_ddr_vcorefs_phase2_test3 time over `date "+%H:%M:%S"` "
	fi
	
	setprop persist.debug.ddr.vcorefs.config max
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "max" ]; then
		FREQ_LIST=${bimc_scaling_freq_list[0]}
		bimc_freq_switch
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		last_sec=`date '+%s'`
		echo "do_ddr_vcorefs_phase2_test4 time `date "+%H:%M:%S"` "
		for i in $(seq 1 ${phase2tesettime})
		do
			FREQ_LIST=${bmic_scaling_phase2_freq_list[3]}
			bimc_freq_switch
			cur_sec=`date '+%s'`
			let diff_time=`expr $cur_sec - $last_sec`
			if [ "$diff_time" -ge "60" ]; then
				break
			fi
		done
		echo "do_ddr_vcorefs_phase2_test4 time over `date "+%H:%M:%S"` "
	fi
	
	setprop persist.debug.ddr.vcorefs.config max
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "max" ]; then
		FREQ_LIST=${bimc_scaling_freq_list[0]}
		bimc_freq_switch
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		FREQ_LIST=${bmic_scaling_phase2_freq_list[2]}
		bimc_freq_switch
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		last_sec=`date '+%s'`
		echo "do_ddr_vcorefs_phase2_test5 time `date "+%H:%M:%S"` "
		for i in $(seq 1 ${phase2tesettime})
		do
			FREQ_LIST=${bmic_scaling_phase2_freq_list[0]}
			bimc_freq_switch
			cur_sec=`date '+%s'`
			let diff_time=`expr $cur_sec - $last_sec`
			if [ "$diff_time" -ge "60" ]; then
				break
			fi
		done
		echo "do_ddr_vcorefs_phase2_test5 time over `date "+%H:%M:%S"` "
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		FREQ_LIST=${bmic_scaling_phase2_freq_list[2]}
		bimc_freq_switch
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		last_sec=`date '+%s'`
		echo "do_ddr_vcorefs_phase2_test6 time `date "+%H:%M:%S"` "
		for i in $(seq 1 ${phase2tesettime})
		do
			FREQ_LIST=${bmic_scaling_phase2_freq_list[0]}
			bimc_freq_switch
			cur_sec=`date '+%s'`
			let diff_time=`expr $cur_sec - $last_sec`
			if [ "$diff_time" -ge "60" ]; then
				break
			fi
		done
		echo "do_ddr_vcorefs_phase2_test6 time over `date "+%H:%M:%S"` "
	fi
	
	setprop persist.debug.ddr.vcorefs.config switch
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	echo "ddr_testphase:$ddr_testphase."
	if [ "$ddr_testphase" = "switch" ]; then
		FREQ_LIST=${bmic_scaling_phase2_freq_list[2]}
		bimc_freq_switch
	fi
	
	phase=2
	
	echo "The ddr_vcorefs_test_phase2 is done and PASS if no exception occurred."
}
enable_ddr_vcorefs_manual(){
	ddr_testphase=`getprop persist.debug.ddr.vcorefs.config`
	while [ 1 ] 
	do
		if [ "$ddr_testphase" != "done" ]; then
			break
		fi
		ddr_manualphase=`getprop persist.debug.ddr.vcorefs.manual`
		echo "ddr_manualphase:$ddr_manualphase."
		if [ "$ddr_manualphase" = "random" ]; then
			do_ddr_vcorefs_random
		elif [ "$ddr_manualphase" = "max" ]; then
			do_ddr_vcorefs_max
		elif [ "$ddr_manualphase" = "min" ]; then
			do_ddr_vcorefs_min
		elif [ "$ddr_manualphase" = "longstep" ]; then
			do_ddr_vcorefs_longstep_random
		elif [ "$ddr_manualphase" = "done" ]; then
			break
		else
			sleep 10
		fi
	done
	echo "The enable_ddr_vcorefs_manual is done and PASS if no exception occurred."
}

start_ddr_vcorefs_test_timer(){
	{
		echo "Current running phase 1."
		sleep 6000
		setprop persist.debug.ddr.vcorefs.config done
		echo "Current running phase 2."
	}&
}

start_ddr_vcorefs_test_timer 
enable_ddr_vcorefs_test_phase1
enable_ddr_vcorefs_test_phase2
enable_ddr_vcorefs_test_phase1
enable_ddr_vcorefs_manual

