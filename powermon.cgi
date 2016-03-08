#!/bin/sh

if [ -z "${QUERY_STRING}" ]; then
    echo Status: 400
    echo Content-Type: text/plain
    echo
    echo Invalid parameters.
    exit 0
fi
echo Content-Type: application/json
echo

/usr/bin/rrdtool xport --json -s "now-${QUERY_STRING}" DEF:load=powermon.rrd:load:MAX DEF:counter=powermon.rrd:count:MAX "XPORT:load:Load over ${QUERY_STRING}" "XPORT:counter:Counter delta over ${QUERY_STRING}" | sed -e 's% about:% "about":%g' -e 's% meta:% "meta":%g' -e "s%'%\"%g"
