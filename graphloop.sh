#!/bin/bash -e

while inotifywait -qq -e close_write powermon.rrd; do
    for PERIOD in 1hour 4hours 1day 3days 1week 1month 3months 1year ; do
        rrdtool graph powermon-${PERIOD}.png.new \
        --start end-${PERIOD} \
        --end now \
        DEF:min=powermon.rrd:load:MIN \
        DEF:max=powermon.rrd:load:MAX \
        DEF:avg=powermon.rrd:load:AVERAGE \
        DEF:day=pervavergraph.rrd:day:AVERAGE \
        DEF:week=pervavergraph.rrd:week:AVERAGE \
        DEF:mon=pervavergraph.rrd:mon:AVERAGE \
        --color 'SHADEA#425466' \
        --color 'SHADEB#425466' \
        --color 'GRID#FFFFFF7F' \
        --color 'MGRID#FF99007F' \
        --color 'BACK#22374C' \
        --color 'FRAME#000000' \
        --color 'FONT#FFFFFF' \
        --color 'CANVAS#22374C' \
        --color 'ARROW#FFFFFF' \
        -w 640 -h 150 \
        -t "spacestation power consumption" \
        -v "Watt" \
        "COMMENT:Watt used within the last ${PERIOD}" \
        'AREA:avg#000000:Average' \
        'LINE1:min#333333:Min' \
        'LINE1:max#555555:Max' \
        'LINE1:day#0000FF:Avg Day' \
        'LINE1:week#46B6EE:Avg Week' \
        'LINE1:mon#FF9900:Avg Month' \
        >/dev/null && mv powermon-${PERIOD}.png.new powermon-${PERIOD}.png
    done
done
