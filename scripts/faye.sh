#!/bin/bash
cmd=$1
PROJECT_DIR=/home/ubuntu/opustime
PIDFILE=$PROJECT_DIR/shared/pids/faye.pid
cd $PROJECT_DIR/current

start_function(){
  echo "Starting faye server..."
  nohup bundle exec rackup faye.ru -E production -p 9292 -P $PIDFILE --daemonize
}

stop_function(){

    if [ -f $PIDFILE ] && kill -KILL `cat $PIDFILE`> /dev/null 2>&1; then
            echo 'Faye server stopped gracefully'
           else
            echo 'Skip stopping faye server (no pid file found)'
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
