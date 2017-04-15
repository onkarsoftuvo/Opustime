#!/bin/bash
env=$1
cmd=$2
PROJECT_DIR=/home/ubuntu/opustime
PIDFILE=$PROJECT_DIR/shared/pids/delayed_job.pid
cd $PROJECT_DIR/current

start_function(){
  echo "Starting delayed_job..."
  RAILS_ENV=$env bundle exec bin/delayed_job start
}

stop_function(){

 if [ -f $PIDFILE ] && kill -0 `cat $PIDFILE`> /dev/null 2>&1; then
         RAILS_ENV=$env bundle exec bin/delayed_job stop
   else
     echo 'Skip stopping delayed_job (no pid file found)'
 fi


}

case "$cmd" in
  start)
    start_function
    ;;
  stop)
    stop_function
    ;;
  restart)
    stop_function && start_function;
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart}"
esac
