#!/bin/bash
env=$1
cmd=$2
PROJECT_DIR=/home/ubuntu/opustime
PIDFILE=$PROJECT_DIR/shared/pids/puma.pid
cd $PROJECT_DIR/current

start_function(){
  echo "Starting puma server..."
  RAILS_ENV=$env bundle exec pumactl -F config/puma.rb restart
}

stop_function(){

 if [ -f $PIDFILE ] && kill -0 `cat $PIDFILE`> /dev/null 2>&1; then
         RAILS_ENV=$env bundle exec pumactl -F config/puma.rb stop
   else
     echo 'Skip stopping puma server (no pid file found)'
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
    stop_function && sleep 4 && start_function;
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart}"
esac
