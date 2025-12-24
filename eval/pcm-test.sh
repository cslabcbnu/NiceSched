#!/bin/bash

home=/home/binwon
LOG=$home/pcm-log
PCM_DIR=$home/pcm/build/bin
NPB_DIR=$home/benchmarks/npb/npb-omp/bin/
XS_DIR=$home/benchmarks/XSBench/openmp-threading/
MEM_LIMIT_DIR=$home/script/
mem_ratio="48 53.3 55 56.6" # 총 워크로드 크기가 64G 일때 1:1 1:3 1:5, 1:7, 1:9
#mem_ratio="48 53.3" # 총 워크로드 크기가 64G 일때 1:1 1:3 1:5, 1:7, 1:9
mkdir -p $LOG
function 7z-bench()
{
	for k in {1..7}
	do
		7z b -mmt22 -md26 > a.out 2>&1 &  # 9G for each
		bench_pid=$!
		bench_pids+=($bench_pid)  # PID 저장
		echo "[*] iter : $k 7z [${bench_pid}] start"
		sleep 2
	done
}
function xs()
{
	grid=25000000
	for k in {1..11}; do
		${XS_DIR}/XSBench -t 22 -p ${grid} > a.out 2>&1 & # 6G
		bench_pid=$!
		bench_pids+=($bench_pid)
		echo "[*] iter : $k xs [${bench_pid}] start"
		sleep 2
	done
}
function mg()
{
	for k in {1..2}
	do
		$NPB_DIR//mg.D.x & #28G
		bench_pid=$!
		bench_pids+=($bench_pid)  # PID 저장
		echo "[*] iter : $k npb mg [${bench_pid}] start"
		sleep 10
	done

}

#cd $NPB_DIR
#cd $XS_DIR
for ratio in $mem_ratio
do
	$MEM_LIMIT_DIR/mem_limit.sh $ratio
	echo "[*] Start test for mem_ratio = $ratio"
	for i in {1..1}
	do
		echo 3 | sudo tee /proc/sys/vm/drop_caches
		echo "[*] cache clear"

		SECONDS=0
		bench_pids=()  # 7z PID들을 저장할 배열
		
		sudo nice -n -19 $PCM_DIR/pcm-numa -c=0-21 -silent -csv=$LOG/`uname -r`-pcm-xs-$ratio.csv  &
		pcm_pid=$!
		echo "[*] PCM monitor start "

		#benchmakr start
		xs
		#7z-bench
		#mg




		for pid in "${bench_pids[@]}"; do
			wait $pid
		done
		sleep 1
		echo "[*] benchmark complete"
		echo "[*] seconds : $SECONDS s" >> $LOG/`uname -r`-pcm-xs-$ratio.log
		sudo kill -9 $pcm_pid
		echo "[*] monitoring finish"
	done
	sudo umount /mnt/numa0-tmp

done
