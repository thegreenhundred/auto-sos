#!/bin/sh
# AUTO SOS - v0.20.a
# This script will help to automate mass sosreport analysis.
# To Use:
# (a)   Add all needed sosreports to a single directory
# (b)   Execute "auto-sos" in said working directory
# (c)   Individual logs will be placed in the root directory of each sosreport
# (d)   A cumulative log will be placed in the working directory
#
# Dependencies: xsos unzip tar unxz
# Authors:      Please submit feedback to ben.morgan@canonical.com

#Setting Start Directory, Log names, and zeroing sosreport counter
START_DIR=$(pwd) 
echo "Working from $START_DIR"

XSOS_LOG=xsos-report.log
XSOS_CUMULATIVE_LOG=cumulative.log
SOSREPORT_COUNT=0

xsos_HOSTS_FOUND () {
	echo "Processed reports from the following hosts"
	cat $START_DIR/$XSOS_CUMULATIVE_LOG | grep Hostname
}

xsos_COMPLETED_REPORT () {
        echo "Reports Complete"
	xsos_HOSTS_FOUND
}

# Compile all collected logs into a cumulative log in the working directory
xsos_COMPILE_ADD () {
	echo "Adding report for $dir to the cumulative xsos report"
	for report in $(ls $START_DIR/sosreport*/xsos-report.log); do
		echo "Adding $report to $START_DIR/cumulative.log"
		cat $report >>$START_DIR/$XSOS_CUMULATIVE_LOG
    done
}

# Report when all processes have finished
xsos_FINISHED () {
        echo "Completed xsos analysis for $NUM sosreports."
        echo "Cumulative log can be found at $START_DIR/$XSOS_CUMULATIVE_LOG"
        echo "Individual xsos reports can be found in the root directory of each sosreport"
}

# start xsos tool with "all" and "no colorize" flags
# Output goes to $XSOS_LOG within the original sosreport directory
xsos_RUN () {
	echo "Generating xsos log in $START_DIR/$dir/xsos-report.log"  
        xsos -ax $START_DIR/$dir 2>/dev/null | cat >>$START_DIR/$dir/$XSOS_LOG  \
	   && xsos_COMPILE_ADD
}

# Search for all valid sosreport extracted in the working directory
sosreport_FIND () {
echo "Searching for sosreports in this directory...." 
    pids=""
    RESULT=0
        for dir in $(ls $START_DIR | grep sosreport ); do
            echo "Found $dir" 
	        $NUM=$(( $NUM + 1 ))
		xsos_RUN $i &
	        pids="$pids $!"
    done
        for pid in $pids; do
            wait $pid || let "RESULT=1"
    done
        if [ "$RESULT" == "1" ];
            then
                exit 1
fi
xsos_FINISHED
}

# Remove any possible pre-existing xsos logs
xsos_LOG_CLEAN () {
	echo "Cleaning any pre-existing logs"
	rm $START_DIR/$XSOS_CUMULATIVE_LOG 2>/dev/null
	rm $START_DIR/sosreport*/$XSOS_LOG 2>/dev/null
}

#Extract tar.gz & tar.xz compressed sosreports
sosreport_BALOON () {
        for file in $START_DIR/sosreport*.tar.xz; do
            unxz -dvf -T 20 "$file"
    done

        for file in $START_DIR/sosreport*.tar.gz; do
            tar -xvf "$file"
    done

        for file in $START_DIR/sosreport*.tar; do
            tar -xvf "$file"
        clear ; ls -lah ; du -sh ./
    done
}

RUN () {
sosreport_BALOON
xsos_LOG_CLEAN
sosreport_FIND
xsos_COMPLETED_REPORT
}

RUN
