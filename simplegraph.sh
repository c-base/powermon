#!/bin/sh

rrdtool graph powermon.png --end now --start end-4h DEF:max=powermon.rrd:load:MAX DEF:avg=powermon.rrd:load:AVERAGE 'COMMENT:Watt used in the last 4 hours' 'AREA:avg#B7B7B7:Average' 'LINE1:max#0000FF:Max' 2>&1 | grep -v '^481x155$'
