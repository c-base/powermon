#!/bin/sh
#
# - one datapoint every 15 seconds, may be missed for 300s
# - stored non-summarized for 15*1*5760 = 86400s = 1 day
# - stored summarized over 4*15 = 60s for 4*15*10800 = 7 days
# - stored summarized over 20*15 = 300s = 5m for 20*15*26208 = 13weeks
# - stored summarized over 60*15 = 900s = 15m for 60*15*30540 = 1year
# - stored summarized over 240*15 = 3600s = 1h for 240*15*87600 = 10years
# - stored summarized over 720*15 = 10800s = 3h for 720*15*146000 = 50years
# - there have to be at least 50% of the values for summaries

rrdtool create powermon.rrd -O \
  --step 15 \
  DS:counter:GAUGE:300:0:25000000 \
  DS:load:GAUGE:300:0:25000 \
  RRA:MIN:0.5:1:5760 \
  RRA:MAX:0.5:1:5760 \
  RRA:AVERAGE:0.5:1:5760 \
  RRA:MIN:0.5:4:10080 \
  RRA:MAX:0.5:4:10080 \
  RRA:AVERAGE:0.5:4:10080 \
  RRA:MIN:0.5:20:26208 \
  RRA:MAX:0.5:20:26208 \
  RRA:AVERAGE:0.5:20:26208 \
  RRA:MIN:0.5:60:30540 \
  RRA:MAX:0.5:60:30540 \
  RRA:AVERAGE:0.5:60:30540 \
  RRA:MIN:0.5:240:87600 \
  RRA:MAX:0.5:240:87600 \
  RRA:AVERAGE:0.5:240:87600 \
  RRA:MIN:0.5:720:146000 \
  RRA:MAX:0.5:720:146000 \
  RRA:AVERAGE:0.5:720:146000 \
