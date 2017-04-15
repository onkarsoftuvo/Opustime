export PATH="/home/ubuntu/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
export PATH="/home/ubuntu/.rbenv/plugins/ruby-build/bin:$PATH"

/home/ubuntu/opustime/current/scripts/puma.sh production start
/home/ubuntu/opustime/current/scripts/sidekiq.sh production start
/home/ubuntu/opustime/current/scripts/faye.sh start
/home/ubuntu/opustime/current/scripts/delayed_job.sh production start

