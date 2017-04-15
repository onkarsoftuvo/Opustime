#!/bin/bash
env=$1
cmd=$2
PROJECT_DIR=/home/ubuntu/opustime
PIDFILE=$PROJECT_DIR/shared/pids/sidekiq.pid
cd $PROJECT_DIR/current

start_function(){
  LOGFILE=$PROJECT_DIR/shared/log/sidekiq.log
  echo "Starting sidekiq..."
  RAILS_ENV=$env bundle exec sidekiq -d -C config/sidekiq.yml -L $LOGFILE -P $PIDFILE
}

stop_function(){

 if [ -f $PIDFILE ] && kill -0 `cat $PIDFILE`> /dev/null 2>&1; then
       RAILS_ENV=$env bundle exec sidekiqctl stop $PIDFILE
   else
     echo 'Skip stopping sidekiq (no pid file found)'
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
