# powermon

Simplistic Power Monitor for LS110 devices republishing information to MQTT

Cronjob:

`*  *  *   *   *     flock -n ~/github-c-base-powermon/powermon.lock ~/github-c-base-powermon/powermon.py`

Will automatically try to (re-)start the long-running daemon.

