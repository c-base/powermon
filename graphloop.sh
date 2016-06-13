#!/bin/bash -e

while inotifywait -qq -e close_write powermon.rrd; do
    for PERIOD in 'main' '60 minutes' '4 hours' '24 hours' '3 days' '7 days' '1 month' '3 months' '1 year' ; do
        if [ "${PERIOD}" == "main" ]; then
            # Special handling of "main" picture
            FPERIOD=''
            PERIOD='60 minutes'
            # Background is fully transparent
            COLOR_BACK='00000000'
            COLOR_SHADEA='00000000'
            COLOR_SHADEB='00000000'
            COLOR_CANVAS='00000000'
            LIMITS=''
        else
            FPERIOD=-`echo ${PERIOD}|tr -d ' '`
            COLOR_BACK='22374CFF'
            COLOR_SHADEA='425466FF'
            COLOR_SHADEB='425466FF'
            COLOR_CANVAS='22374CFF'
            LIMITS='--lower-limit 0 --upper-limit 16000'
        fi
        COLOR_GRID='FFFFFF7F'
        COLOR_MGRID='FF99007F'
        COLOR_FRAME='000000FF'
        COLOR_FONT='FFFFFFFF'
        COLOR_CANVAS='22374CFF'
        COLOR_ARROW='FFFFFFFF'
        rrdtool graph powermon${FPERIOD}.png.new \
        -E \
        -M \
        ${LIMITS} \
        --start "end-${PERIOD}" \
        --end now \
        DEF:min=powermon.rrd:load:MIN \
        DEF:max=powermon.rrd:load:MAX \
        DEF:avg=powermon.rrd:load:AVERAGE \
        DEF:day=pervavergraph.rrd:day:AVERAGE \
        DEF:week=pervavergraph.rrd:week:AVERAGE \
        DEF:mon=pervavergraph.rrd:mon:AVERAGE \
        --disable-rrdtool-tag \
        --color "SHADEA#${COLOR_SHADEA}" \
        --color "SHADEB#${COLOR_SHADEB}" \
        --color "GRID#${COLOR_GRID}" \
        --color "MGRID#${COLOR_MGRID}" \
        --color "BACK#${COLOR_BACK}" \
        --color "FRAME#${COLOR_FRAME}" \
        --color "FONT#${COLOR_FONT}" \
        --color "CANVAS#${COLOR_CANVAS}" \
        --color "ARROW#${COLOR_ARROW}" \
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
        >/dev/null && mv powermon${FPERIOD}.png.new powermon${FPERIOD}.png
    done
done
