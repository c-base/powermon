#!/usr/bin/env python

import sys
import json
import time
import rrdtool
import requests
import paho.mqtt.client as mqtt

with open('/etc/c-base-powermon.json') as config_file:
    config = json.load(config_file)

# {
#    "powermon":"1.2.3.4",
#    "password":"password",
#    "mqtt_host":"mqtt.host.name",
#    "mqtt_port":1883,
#    "mqtt_prefix":"system/powermon",
#    "rrdfile":"powermon.rrd",
#    "frequency":15
# }

mqttc = mqtt.Client()
mqttc.connect(config['mqtt_host'], config['mqtt_port'])

httpc = requests.Session()

while True:
    result = httpc.get('http://{0}/a'.format(config['powermon']), params = {'f':'j'});
    if result.status_code == 403:
        time.sleep(1)
        result = httpc.get('http://{0}/'.format(config['powermon']), params = {'w':config['password']});
        if result.status_code != 200:
            print("Authentication failed.")
            sys.exit(1)
    elif result.status_code != 200:
        print("Something went wrong.")
        sys.exit(1)
    else:
        # '2016-03-02T22:16:44Z'
        now = time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        # {"cnt":"582955,703","pwr":7291,"lvl":5,"dev":"(&plusmn;1%)","det":"&bull;","con":"*","sts":"","raw":159}
        mqttc.publish("{0}/raw".format(config['mqtt_prefix']), result.text, retain=True)
        # cook data
        data  = result.json()
        # current load
        load  = data['pwr']
        mqttc.publish("{0}/load".format(config['mqtt_prefix']), load, retain=True)
        # meter reading
        count = "".join(data['cnt'].split()).replace(',','.')
        mqttc.publish("{0}/count".format(config['mqtt_prefix']), count, retain=True)
        # useful summary
        mqttc.publish(config['mqtt_prefix'], '{{"last_update":"{0}","load":{1},"count":{2}}}'.format(now, load, count), retain=True)
        # update time
        mqttc.publish("{0}/last_update".format(config['mqtt_prefix']), now, retain=True)

        # store to RRD
        rrdtool.update(str(config['rrdfile']), 'N:{0}:{1}'.format(count.replace('.',''), load))

        # sleep until we reached the next interval
        time.sleep(config['frequency']-(time.mktime(time.gmtime())%config['frequency']))
