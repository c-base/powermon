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
#    "frequency":15
# }

## our HTTP Client
httpc = requests.Session()

## our MQTT Client
mqttc = mqtt.Client(client_id=config['mqtt_client_id'], clean_session=False)

## try to get historic peaks
# unrealistic defaults
load_high = 0
load_high_date = '?'
load_low  = 99999
load_low_date  = '?'

def on_message(client, userdata, message):
  global load_high, load_high_date, load_low, load_low_date
  if message.topic == '{0}/load_high'.format(config['mqtt_prefix']):
      load_high = int(message.payload)
  elif message.topic == '{0}/load_high_date'.format(config['mqtt_prefix']):
      load_high_date  = message.payload
  elif message.topic == '{0}/load_low'.format(config['mqtt_prefix']):
      load_low = int(message.payload)
  elif message.topic == '{0}/load_low_date'.format(config['mqtt_prefix']):
      load_low_date  = message.payload

def on_connect(client, userdata, flags, rc):
  mqttc.subscribe(('{0}/load_high'.format(config['mqtt_prefix'])),qos=1)
  mqttc.subscribe(('{0}/load_high_date'.format(config['mqtt_prefix'])),qos=1)
  mqttc.subscribe(('{0}/load_low'.format(config['mqtt_prefix'])),qos=1)
  mqttc.subscribe(('{0}/load_low_date'.format(config['mqtt_prefix'])),qos=1)

# set up callbacks and connect
mqttc.on_message = on_message
mqttc.on_connect = on_connect
mqttc.connect(config['mqtt_host'], config['mqtt_port'])

# try for 30 seconds or until we know
counter = 0
while (load_low == 99999 or load_high == 0 or load_low_date == "?" or load_high_date == "?") and counter < 30:
    mqttc.loop(timeout=1.0)
    counter += 1

# unsubscribe again. if we didn't get data - too bad :(
mqttc.unsubscribe('{0}/load_high'.format(config['mqtt_prefix']))
mqttc.unsubscribe('{0}/load_high_date'.format(config['mqtt_prefix']))
mqttc.unsubscribe('{0}/load_low'.format(config['mqtt_prefix']))
mqttc.unsubscribe('{0}/load_low_date'.format(config['mqtt_prefix']))


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
        data  = result.json()
        # current load
        load  = data['pwr']
        mqttc.publish("{0}/load".format(config['mqtt_prefix']), load, retain=True)

        # compare with historic data
        if load <= load_low:
            load_low = load
            load_low_date = now
            mqttc.publish("{0}/load_low".format(config['mqtt_prefix']), load_low, qos=1, retain=True)
            mqttc.publish("{0}/load_low_date".format(config['mqtt_prefix']), load_low_date, qos=1, retain=True)
        if load >= load_high:
            load_high = load
            load_high_date = now
            mqttc.publish("{0}/load_high".format(config['mqtt_prefix']), load_high, qos=1, retain=True)
            mqttc.publish("{0}/load_high_date".format(config['mqtt_prefix']), load_high_date, qos=1, retain=True)

        # meter reading
        count = "".join(data['cnt'].split()).replace(',','.')
        mqttc.publish("{0}/count".format(config['mqtt_prefix']), count, retain=True)
        # useful summary
        mqttc.publish(config['mqtt_prefix'],
          '{{"last_update":"{0}",'
            '"load":{1},'
            '"load_low":{2},'
            '"load_low_date":{3},'
            '"load_high":{4},'
            '"load_high_date":{5},'
            '"count":{6}'
          '}}'.format(
            now,
            load,
            load_low,
            load_low_date,
            load_high,
            load_high_date,
            count), retain=True)

        # update time
        mqttc.publish("{0}/last_update".format(config['mqtt_prefix']), now, retain=True)

        # store to RRD
        rrdtool.update(str(config['rrdfile']), 'N:{0}:{1}'.format(count.replace('.',''), load))

        # sleep until we reached the next interval
        time.sleep(config['frequency']-(time.mktime(time.gmtime())%config['frequency']))
