#!/bin/sh

DEFAULT_NTP="time.cloudflare.com"
CHRONY_CONF_FILE="/etc/chrony/chrony.conf"

# confirm correct permissions on chrony run directory
if [ -d /run/chrony ]; then
  chown -R chrony:chrony /run/chrony
  chmod o-rx /run/chrony
  # remove previous pid file if it exist
  rm -f /var/run/chrony/chronyd.pid
fi

# confirm correct permissions on chrony variable state directory
if [ -d /var/lib/chrony ]; then
  chown -R chrony:chrony /var/lib/chrony
fi

## dynamically populate chrony config file.
{
  echo "# https://github.com/cturra/docker-ntp"
  echo
  echo "# chrony.conf file generated by startup script"
  echo "# located at /opt/startup.sh"
  echo
  echo "# time servers provided by NTP_SERVER environment variables."
} > ${CHRONY_CONF_FILE}


# NTP_SERVERS environment variable is not present, so populate with default server
if [ -z "${NTP_SERVERS}" ]; then
  NTP_SERVERS="${DEFAULT_NTP}"
fi

# LOG_LEVEL environment variable is not present, so populate with chrony default (0)
# chrony log levels: 0 (informational), 1 (warning), 2 (non-fatal error) and 3 (fatal error)
if [ -z "${LOG_LEVEL}" ]; then
  LOG_LEVEL=0
else
  # confirm log level is between 0-3, since these are the only log levels supported
  if [ "${LOG_LEVEL}" -gt 3 ]; then
    # level outside of supported range, let's set to default (0)
    LOG_LEVEL=0
  fi
fi

IFS=","
for N in $NTP_SERVERS; do
  # strip any quotes found before or after ntp server
  echo "server "${N//\"}" iburst" >> ${CHRONY_CONF_FILE}
done

# final bits for the config file
{
  echo
  echo "driftfile /var/lib/chrony/chrony.drift"
  echo "makestep 0.1 3"
  echo "rtcsync"
  echo
  echo "allow all"
} >> ${CHRONY_CONF_FILE}


if [ "${OFFLINE}"= "true" ]; then

  echo "local stratum 10" >> ${CHRONY_CONF_FILE}
  sed -i s/^server/#server/g  ${CHRONY_CONF_FILE}

fi


## startup chronyd in the foreground
exec /usr/sbin/chronyd -u chrony -d -x -L ${LOG_LEVEL}
