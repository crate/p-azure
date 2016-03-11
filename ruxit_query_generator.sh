#!/bin/bash

metric_types="host.cpu.idle host.cpu.system host.cpu.load host.cpu.user host.cpu.iowait host.cpu.steal host.cpu.other host.mem.available \
	host.mem.availablepercentage host.mem.used host.mem.pagefaults host.nic.bytesreceived host.nic.bytessent host.nic.packetsreceived \
	host.nic.packetssent host.nic.packetsreceiveddroppedpercentage host.nic.packetssentdroppedpercentage host.nic.packetsreceivederrorspercentage \
	host.nic.packetssenterrorspercentage pgi.cpu.usage pgi.mem.usage pgi.nic.bytesreceived pgi.nic.bytessent pgi.responsiveness pgi.workerprocesses \
	service.requestspermin service.responsetime service.failurerate app.useractionduration app.useractionsperminute app.errorcount"

metrics2="host.availability pgi.availability webcheck.availability"

startTimestamp=1457636400000
endTimestamp=1457643600000
agg_types="min avg max"

for i in $metric_types
do	
    for agg_type in $agg_types
    do
        cat <<EOF
	curl -L -H "Authorization: Api-Token Ws31UgzFS4m1g0np0tdZs" "https://akp88036.live.ruxit.com/api/v1/timeseries?timeseriesId=com.ruxit.builtin:$i&startTimestamp=$startTimestamp&endTimestamp=$endTimestamp&aggregationType=$agg_type" > $i.$agg_type.json 
sleep 6
EOF
     done
done > queries.sh 

for m in $metrics2
do
	cat <<EOF
	curl -L -H "Authorization: Api-Token Ws31UgzFS4m1g0np0tdZs" "https://akp88036.live.ruxit.com/api/v1/timeseries?timeseriesId=com.ruxit.builtin:$m&startTimestamp=$startTimestamp&endTimestamp=$endTimestamp" > $m.json
sleep 6
EOF
done >> queries.sh