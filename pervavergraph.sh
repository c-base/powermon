#!/bin/bash
#
# why THE FUCK am I doing this in shell?
#
# .. ah .. right .. brute force .. and .. "just get the data in"

TMPDIR=`mktemp -d`
trap "rm -rf $TMPDIR" EXIT

/usr/bin/rrdtool xport --json -m 100 -s now-1day DEF:counter=powermon.rrd:counter:MAX XPORT:counter|/bin/sed -e 's% about:% "about":%g' -e 's% meta:% "meta":%g' -e "s%'%\"%g"|/usr/local/bin/json data|/usr/local/bin/json -ac 'this[0]'|/usr/local/bin/json -g > "${TMPDIR}/1day"
/usr/bin/rrdtool xport --json -m 100 -s now-1week DEF:counter=powermon.rrd:counter:MAX XPORT:counter|/bin/sed -e 's% about:% "about":%g' -e 's% meta:% "meta":%g' -e "s%'%\"%g"|/usr/local/bin/json data|/usr/local/bin/json -ac 'this[0]'|/usr/local/bin/json -g > "${TMPDIR}/1week"
/usr/bin/rrdtool xport --json -m 100 -s now-30days DEF:counter=powermon.rrd:counter:MAX XPORT:counter|/bin/sed -e 's% about:% "about":%g' -e 's% meta:% "meta":%g' -e "s%'%\"%g"|/usr/local/bin/json data|/usr/local/bin/json -ac 'this[0]'|/usr/local/bin/json -g > "${TMPDIR}/30days"

DAY=`/usr/local/bin/json -f "${TMPDIR}/1day" [-1] [0]|/usr/bin/xargs /bin/echo|/bin/sed -e 's% %-%'|/usr/bin/xargs -iFOO /bin/echo '(FOO)/24'|/usr/bin/bc`
WEEK=`/usr/local/bin/json -f "${TMPDIR}/1week" [-1] [0]|/usr/bin/xargs /bin/echo|/bin/sed -e 's% %-%'|/usr/bin/xargs -iFOO /bin/echo '(FOO)/(7*24)'|/usr/bin/bc`
MONTH=`/usr/local/bin/json -f "${TMPDIR}/30days" [-1] [0]|/usr/bin/xargs /bin/echo|/bin/sed -e 's% %-%'|/usr/bin/xargs -iFOO /bin/echo '(FOO)/(30*24)'|/usr/bin/bc`

if [ ${MONTH} -gt 100000 ]; then
    MONTH='U'
fi

/usr/bin/rrdtool update pervavergraph.rrd "N:${DAY}:${WEEK}:${MONTH}"
