#!/bin/sh
#
# - one datapoint every 60 seconds, may be missed for 3600s
# - stored non-summarized for 60*1440 = 86400s = 1 day
# - stored summarized over 1x = 60s for 1*10800 = 7 days
# - stored summarized over 5x = 300s = 5m for 5*26208 = 13weeks
# - stored summarized over 15x = 900s = 15m for 15*30540 = 1year
# - stored summarized over 60x = 3600s = 1h for 60*87600 = 10years
# - stored summarized over 180x = 10800s = 3h for 180*146000 = 50years
# - there have to be at least 50% of the values for summaries

rrdtool create pervavergraph-x.rrd -O \
  -b 1457742300 \
  --step 60 \
  DS:day:GAUGE:3600:0:25000 \
  DS:week:GAUGE:3600:0:25000 \
  DS:mon:GAUGE:3600:0:25000 \
  RRA:MIN:0.5:1:1440 \
  RRA:MAX:0.5:1:1440 \
  RRA:AVERAGE:0.5:1:1440 \
  RRA:MIN:0.5:1:9870 \
  RRA:MAX:0.5:1:9870 \
  RRA:AVERAGE:0.5:1:9870 \
  RRA:MIN:0.5:5:26208 \
  RRA:MAX:0.5:5:26208 \
  RRA:AVERAGE:0.5:5:26208 \
  RRA:MIN:0.5:15:30540 \
  RRA:MAX:0.5:15:30540 \
  RRA:AVERAGE:0.5:15:30540 \
  RRA:MIN:0.5:60:87600 \
  RRA:MAX:0.5:60:87600 \
  RRA:AVERAGE:0.5:60:87600 \
  RRA:MIN:0.5:180:146000 \
  RRA:MAX:0.5:180:146000 \
  RRA:AVERAGE:0.5:180:146000 \
