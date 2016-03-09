# powermon

Simplistic Power Monitor for LS110 devices republishing information to MQTT

Cronjobs:

`*  *  *   *   *     flock -n ~/github-c-base-powermon/powermon.lock ~/github-c-base-powermon/powermon.py`
`*  *  *   *   *     cd ~/github-c-base-powermon ; flock -n ~/github-c-base-powermon/graphloop.lock ~/github-c-base-powermon/graphloop.sh

Will automatically try to (re-)start the long-running daemons.
