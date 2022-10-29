#!/system/bin/sh
#=============================================================================
#persist.debug.cpu.dvfs.config
#testing_phase=`getprop persist.debug.cpu.dvfs.config`
#=============================================================================

echo "Just for CPU DVFS Debug"

#ntest*delay= 1200S
ntest=4000
delay=0.3	## 300ms

display_freq() {
  echo "policy0 cur_freq: " $(< /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq)
  echo "policy4 cur_freq: " $(< /sys/devices/system/cpu/cpufreq/policy4/scaling_cur_freq)
  echo "policy7 cur_freq: " $(< /sys/devices/system/cpu/cpufreq/policy7/scaling_cur_freq)
}

platform=`getprop ro.board.platform`

if [ x"$platform" = x"taro"]; then
	lit_cfrqs=(307200 403200 518400 614400 710400 806400 902400 998400 1094400 1190400 1286400 1363200 1459200 1536000 1632000 1708800 1785600)
	big_cfrqs=(633600 729600 844800 940800 1036800 1152000 1248000 1344000 1459200 1555200 1651200 1766400 1862400 1977600 2073600 2169600)
	gold_cfrqs=(729600 844800 960000 1075200 1190400 1305600 1420800 1536000 1651200 1766400 1881600 1996800 2112000 2227200 2323200 2419200)
else
	lit_cfrqs=(300000 691200 806400 940800 115200 1324800 1516800 1651200 1804800)
	big_cfrqs=(691200 940800 1228800 1344000 1516800 1651200 1900800 2054400 2131200 2400000)
	gold_cfrqs=(806400 1056000 1324800 1516800 1766400 1862400 2035200 2208000 2380800 2400000)
fi

#cpu dvfs ramdom
do_cpudvfs_ramdom(){
	for i in $(seq 1 ${ntest})
	do
		l=$(($RANDOM%${#lit_cfrqs[@]}))
		g=$(($RANDOM%${#big_cfrqs[@]}))
		gg=$(($RANDOM%${#gold_cfrqs[@]}))
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
		
		display_freq
		sleep ${delay}
	done
}

#cpu dvfs fixOPP0
do_cpudvfs_fixOPPmin(){
	echo "cpu dvfs fixOPPmin"
	for i in $(seq 1 ${ntest})
	do
		l=0
		g=0
		gg=0
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
		
		display_freq
		sleep ${delay}
	done
}


#cpu dvfs fixOPP15
do_cpudvfs_fixOPPmax(){
	echo "cpu dvfs fixOPPmax"
	for i in $(seq 1 ${ntest})
	do
		l=${#lit_cfrqs[@]}-1
		g=${#big_cfrqs[@]}-1
		gg=${#gold_cfrqs[@]}-1
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
		
		display_freq
		sleep ${delay}
	done
}


#cpu dvfs OPP0-OPP15
do_cpudvfs_OPPmax_OPPmin(){
	echo "cpu dvfs fixOPP0"
	for i in $(seq 1 ${ntest})
	do
		check=$(($RANDOM%2))
		if [ $check -eq 0 ]; then
			l=0
			g=0
			gg=0
		else
			l=${#lit_cfrqs[@]}-1
			g=${#big_cfrqs[@]}-1
			gg=${#gold_cfrqs[@]}-1
		fi
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
		display_freq
		sleep ${delay}
	done
}

do_cpudvfs_longstep_random(){
	echo "cpu dvfs long step random"
	l=$(($RANDOM%${#lit_cfrqs[@]}))
	g=$(($RANDOM%${#big_cfrqs[@]}))
	gg=$(($RANDOM%${#gold_cfrqs[@]}))
	for i in $(seq 1 ${ntest})
	do
		do_cpuhotplug
		LL_step=$(($RANDOM%5))
		L_step=$(($RANDOM%5))
		SL_step=$(($RANDOM%5))

		l=$(($l+5+$LL_step))
		g=$(($g+5+$L_step))
		gg=$(($gg+5+$SL_step))

		l=$(($l%${#lit_cfrqs[@]}))
		g=$(($g%${#big_cfrqs[@]}))
		gg=$(($gg%${#gold_cfrqs[@]}))

		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
		display_freq
		sleep ${delay}
	done
}

do_cpudvfs_shortstep_random(){
	echo "cpu dvfs short step random"
	l=$(($RANDOM%${#lit_cfrqs[@]}))
	g=$(($RANDOM%${#big_cfrqs[@]}))
	gg=$(($RANDOM%${#gold_cfrqs[@]}))
	for i in $(seq 1 ${ntest})
	do
		do_cpuhotplug
		LL_step=$(($RANDOM%3))
		L_step=$(($RANDOM%3))
		SL_step=$(($RANDOM%3))

		l=$(($l+1+$LL_step))
		g=$(($g+1+$L_step))
		gg=$(($gg+1+$SL_step))

		l=$(($l%${#lit_cfrqs[@]}))
		g=$(($g%${#big_cfrqs[@]}))
		gg=$(($gg%${#gold_cfrqs[@]}))

		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq
		echo ${lit_cfrqs[l]} > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq
		echo ${big_cfrqs[g]} > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq
		echo ${gold_cfrqs[gg]} > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq
		display_freq
		sleep ${delay}
	done
}


#cpu Hotplug ittle cpu core >=2, big core >=0
do_cpuhotplug(){
	# little cpu core >=2, big core >=0
	
}


enable_cpu_hotplug_dvfs_test(){
	while [ 1 ]
	do
		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		if [ "$cpu_debugconfig" = "done" ]; then
			break
		fi
		setprop persist.debug.cpu.dvfs.config max
		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		echo "cpu_debugconfig:$cpu_debugconfig."
		if [ "$cpu_debugconfig" = "max" ]; then
			do_cpudvfs_fixOPPmax
		fi

		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		if [ "$cpu_debugconfig" = "done" ]; then
			break
		fi
		setprop persist.debug.cpu.dvfs.config min
		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		echo "cpu_debugconfig:$cpu_debugconfig."
		if [ "$cpu_debugconfig" = "min" ]; then
			do_cpudvfs_fixOPPmin
		fi

		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		if [ "$cpu_debugconfig" = "done" ]; then
			break
		fi
		setprop persist.debug.cpu.dvfs.config max_min
		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		echo "cpu_debugconfig:$cpu_debugconfig."
		if [ "$cpu_debugconfig" = "max_min" ]; then
			do_cpudvfs_OPPmax_OPPmin
		fi

		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		if [ "$cpu_debugconfig" = "done" ]; then
			break
		fi
		setprop persist.debug.cpu.dvfs.config longstep_random
		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		echo "cpu_debugconfig:$cpu_debugconfig."
		if [ "$cpu_debugconfig" = "longstep_random" ]; then
			do_cpudvfs_longstep_random
		fi

		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		if [ "$cpu_debugconfig" = "done" ]; then
			break
		fi
		setprop persist.debug.cpu.dvfs.config shortstep_random
		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		echo "cpu_debugconfig:$cpu_debugconfig."
		if [ "$cpu_debugconfig" = "shortstep_random" ]; then
			do_cpudvfs_shortstep_random
		fi

		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		if [ "$cpu_debugconfig" = "done" ]; then
			break
		fi
		setprop persist.debug.cpu.dvfs.config ramdom
		cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
		echo "cpu_debugconfig:$cpu_debugconfig."
		if [ "$cpu_debugconfig" = "random" ]; then
			do_cpudvfs_ramdom
		fi
	done
	echo "The test is done and PASS if no exception occurred."
}

enable_cpu_hotplug_dvfs_test_manual(){
	cpu_debugconfig=`getprop persist.debug.cpu.dvfs.config`
	while [ 1 ] 
	do
		if [ "$cpu_debugconfig" != "done" ]; then
			break
		fi
		cpu_manualconfig=`getprop persist.debug.cpu.dvfs.manual`
		echo "cpu_manualconfig:$cpu_manualconfig."
		if [ "$cpu_manualconfig" = "random" ]; then
			do_cpudvfs_ramdom
		elif [ "$cpu_manualconfig" = "max" ]; then
			do_cpudvfs_fixOPPmax
		elif [ "$cpu_manualconfig" = "min" ]; then
			do_cpudvfs_fixOPPmin
		elif [ "$cpu_manualconfig" = "max_min" ]; then
			do_cpudvfs_OPPmax_OPPmin
		elif [ "$cpu_manualconfig" = "longstep_random" ]; then
			do_cpudvfs_longstep_random
		elif [ "$cpu_manualconfig" = "shortstep_random" ]; then
			do_cpudvfs_shortstep_random
		elif [ "$cpu_manualconfig" = "done" ]; then
			break
		else
			sleep 10
		fi
	done
	echo "The cpu_manualconfig is done and PASS if no exception occurred."
}

enable_cpu_hotplug_dvfs_test
enable_cpu_hotplug_dvfs_test_manual
