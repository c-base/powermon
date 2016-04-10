#!/bin/bash -e

while inotifywait -qq -e close_write powermon.rrd; do
    for PERIOD in '60 minutes' '4 hours' '24 hours' '3 days' '7 days' '1 month' '3 months' '1 year' ; do
        FPERIOD=`echo ${PERIOD}|tr -d ' '`
        rrdtool graph powermon-${FPERIOD}.png.new \
        --start "end-${PERIOD}" \
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
        'LINE1:week#6666FF:Avg Week' \
        'LINE1:mon#33FF33:Avg Month' \
        'LINE1:day#FF3333:Avg Day' \
        >/dev/null && mv powermon-${FPERIOD}.png.new powermon-${FPERIOD}.png
    done
done
