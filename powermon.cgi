#!/bin/sh

echo Content: text/json
if [ -z "${QUERY_STRING}" ]; then
    echo Status: 400
    echo
    echo Invalid parameters.
    exit 0
fi
echo

/usr/bin/rrdtool xport --json -s "end-${QUERY_STRING}" DEF:load=powermon.rrd:load:MAX DEF:counter=powermon.rrd:count:MAX "XPORT:load:Load over ${QUERY_STRING}" "XPORT:counter:Counter delta over ${QUERY_STRING}"
