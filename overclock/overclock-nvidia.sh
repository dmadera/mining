#!/bin/bash

for f in nvidia-config*
do
	. $f

	if [[ -z $GPU_NAME_CONTAINS ]] ; then echo "set variable GPU_NAME_CONTAINS" && exit 2 ; fi
	if [[ -z $GPU_MAX_POWER ]] ; then echo "set variable GPU_MAX_POWER" && exit 2 ; fi
	if [[ -z $GPU_CLOCK_OFFSET ]] ; then echo "set variable GPU_CLOCK_OFFSET" && exit 2 ; fi
	if [[ -z $GPU_FAN_SPEED ]] ; then echo "set variable GPU_FAN_SPEED" && exit 2 ; fi
	if [[ -z $GPU_MEM_CLOCK_TRANSFER_OFFSET ]] ; then 
		echo "set variable GPU_MEM_CLOCK_TRANSFER_OFFSET" && exit 2 ;
	fi

	echo "Performing overclock NVIDIA gpus: ${GPU_NAME_CONTAINS}"

	if [ $EUID -ne 0 ]; then
		echo "Not running as root"
		exit 2
	fi

	# ssh variables 
	export DISPLAY=:0 
	export XAUTHORITY=/var/run/lightdm/root/:0

	gpus_status='nvidia-smi --query-gpu=index,gpu_name,clocks.sm,clocks.mem,temperature.gpu	--format=csv | grep "${GPU_NAME_CONTAINS}" | column -s, -t'

	if [[ -z $(eval $gpus_status) ]] ; then
		echo "No devices '${GPU_NAME_CONTAINS}' found"
		exit 0
	fi

	echo "Found devices:"
	eval $gpus_status
	nvidia-smi -pm 1

	for i in $(eval $gpus_status | grep ^[[:digit:]] -Eo) ; do
		echo "Overclocking device with index: $i."
		nvidia-settings -a [gpu:$i]/GpuPowerMizerMode=1
		nvidia-smi -i $i -pl ${GPU_MAX_POWER}
		nvidia-settings -a [gpu:$i]/GPUFanControlState=1
		nvidia-settings -a [fan:$i]/GPUTargetFanSpeed=${GPU_FAN_SPEED}
		nvidia-settings -a [gpu:$i]/GPUGraphicsClockOffset[3]=${GPU_CLOCK_OFFSET}
		nvidia-settings -a [gpu:$i]/GPUMemoryTransferRateOffset[3]=${GPU_MEM_CLOCK_TRANSFER_OFFSET}
	done
	eval $gpus_status
	echo "Done for ${GPU_NAME_CONTAINS}!"

done

export GPU_FORCE_64BIT_PTR=0
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100