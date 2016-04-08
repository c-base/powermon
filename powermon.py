#!/usr/bin/env python

import sys
import json
import time
import rrdtool
import requests
import paho.mqtt.client as mqtt

## load config
with open('/etc/c-base-powermon.json') as config_file:
    config = json.load(config_file)

# {
#    "powermon":"1.2.3.4",
#    "password":"password",
#    "mqtt_client_id": "secret",
#    "mqtt_host":"mqtt.host.name",
#    "mqtt_port":1883,
#    "mqtt_prefix":"system/powermon",
#    "rrdfile":"powermon.rrd",
#    "datafile":"powermon.json",
#    "frequency":15
# }

## our HTTP Client
httpc = requests.Session()

## our MQTT Client
mqttc = mqtt.Client(client_id=config['mqtt_client_id'], clean_session=False)

## try to get data from previous runs
data = {}
try:
    with open(config['datafile']) as data_file:
        data = json.load(data_file)
except:
    data = {
        'load_high'      : 0,
        'load_high_date' : '?',
        'load_low'       : 99999,
        'load_low_date'  : '?'
    }

# set up callbacks and connect
mqttc.connect(config['mqtt_host'], config['mqtt_port'])

## our main loop, update stuff
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
        parsed_data = result.json()
        # current load
        data['load'] = parsed_data['pwr']
        mqttc.publish("{0}/load".format(config['mqtt_prefix']), data['load'], retain=True)

        # compare with historic data
        if data['load'] and data['load'] <= data['load_low']:
            data['load_low'] = data['load']
            data['load_low_date'] = now
            mqttc.publish("{0}/load_low".format(config['mqtt_prefix']), data['load_low'], qos=1, retain=True)
            mqttc.publish("{0}/load_low_date".format(config['mqtt_prefix']), data['load_low_date'], qos=1, retain=True)
        if data['load'] >= data['load_high']:
            data['load_high'] = data['load']
            data['load_high_date'] = now
            mqttc.publish("{0}/load_high".format(config['mqtt_prefix']), data['load_high'], qos=1, retain=True)
            mqttc.publish("{0}/load_high_date".format(config['mqtt_prefix']), data['load_high_date'], qos=1, retain=True)

        # meter reading
        data['counter'] = "".join(parsed_data['cnt'].split()).replace(',','.')
        mqttc.publish("{0}/counter".format(config['mqtt_prefix']), data['counter'], retain=True)
        # useful summary
        data['last_update'] = now
        mqttc.publish(config['mqtt_prefix'], json.dumps(data), retain=True)
        with open(config['datafile'], 'w+') as data_file:
            data_file.write(json.dumps(data))
            data_file.write('\n')

        # update time
        mqttc.publish("{0}/last_update".format(config['mqtt_prefix']), now, retain=True)

        # store to RRD
        rrdtool.update(str(config['rrdfile']), 'N:{0}:{1}'.format(data['counter'].replace('.',''), data['load']))

        # sleep until we reached the next interval
        time.sleep(config['frequency']-(time.mktime(time.gmtime())%config['frequency']))
