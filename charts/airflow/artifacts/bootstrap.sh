#!/usr/bin/env bash
CMD="airflow"
TRY_LOOP="10"
RABBITMQ_HOST="rabbitmq"
CONFIG_DIR="/tmp/config"
FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)")
mkdir -p $AIRFLOW_HOME/dags && mkdir -p $AIRFLOW_HOME/logs

# Copying and preparing artifacts
for f in airflow.cfg requirements.txt probe.sh ; do
  if [[ -e ${CONFIG_DIR}/$f ]]; then
    cp ${CONFIG_DIR}/$f $AIRFLOW_HOME/$f
  else
    echo "ERROR: Could not find $f in $CONFIG_DIR"
    exit 1
  fi
done
chmod +x $AIRFLOW_HOME/probe.sh

# install additional Python libraries
if [ $( wc -l < $AIRFLOW_HOME/requirements.txt ) -gt 0 ]; then 
    pip install -r $AIRFLOW_HOME/requirements.txt
fi

# wait for rabbitmq
export RABBITMQ_CREDS=$RABBITMQ_DEFAULT_USER:$RABBITMQ_DEFAULT_PASS
if [ "$1" = "webserver" ] || [ "$1" = "worker" ] || [ "$1" = "scheduler" ] || [ "$1" = "flower" ] ; then
  j=0
  while ! curl -sI -u $RABBITMQ_CREDS http://$RABBITMQ_HOST:15672/api/whoami | grep '200 OK'; do
    j=`expr $j + 1`
    if [ $j -ge $TRY_LOOP ]; then
      echo "$(date) - $RABBITMQ_HOST still not reachable, giving up"
      exit 1
    fi
    echo "$(date) - waiting for RabbitMQ... $j/$TRY_LOOP"
    sleep 5
  done
fi

# instantiating postgres credentials
if [[ -z "${POSTGRES_DEPLOY}" ]]; then
  echo not using postgres deployment
else
  export AIRFLOW_DB=psycopg2+postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_SVC_PORT_5432_TCP_ADDR:5432/$POSTGRES_DB
fi

# overwriting airflow config values
export RABBITMQ_URI=amqp://$RABBITMQ_CREDS@$RABBITMQ_RABBITMQ_PORT_5672_TCP_ADDR:$RABBITMQ_SVC_PORT_5672_TCP_PORT/$RABBITMQ_DEFAULT_VHOST
sed -i -e "s#REPLACE_WITH_POSTGRES_URI#$AIRFLOW_DB#" $AIRFLOW_HOME/airflow.cfg
sed -i -e "s#REPLACE_WITH_FERNET_KEY#$FERNET_KEY#" $AIRFLOW_HOME/airflow.cfg
sed -i -e "s#REPLACE_WITH_RABBITMQ_URI#$RABBITMQ_URI#" $AIRFLOW_HOME/airflow.cfg

# actually running Airflow
case "$1" in
    -webserver)
        echo "Initialize database..."
        $CMD initdb
        $CMD webserver
        ;;
    -worker)
        $CMD worker
        ;;
    -flower)
        $CMD flower
        ;;
    -scheduler)
        $CMD scheduler
        ;;
    *)
        echo $"Usage: $0 {-webserver|-worker|-scheduler|-flower}"
        exit 1
esac