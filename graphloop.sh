#!/bin/bash -e

while inotifywait -qq -e close_write powermon.rrd; do
    for PERIOD in 1hour 4hours 1day 3days 1week 1month 1year ; do
        rrdtool graph powermon-${PERIOD}.png --end now --start end-${PERIOD} DEF:min=powermon.rrd:load:MIN DEF:max=powermon.rrd:load:MAX DEF:avg=powermon.rrd:load:AVERAGE --color 'SHADEA#425466' --color 'SHADEB#425466' --color 'GRID#ffffff7f' --color 'MGRID#FF99007f' --color 'BACK#22374C' --color 'FRAME#000000' --color 'FONT#ffffff' --color 'CANVAS#22374C' --color 'ARROW#FFFFFF' -w 640 -h 150 -t "spacestation power consumption" -v "Watt" "COMMENT:Watt used within the last ${PERIOD}" 'AREA:avg#000000:Average' 'LINE1:min#46B6EE:Min' 'LINE1:max#FF9900:Max' >/dev/null
    done
done
