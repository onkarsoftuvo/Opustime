# if Rails.env.production?
#   Thread.new do
#     PID_FILE_PATH = '/home/deploy/Project_Zulu/shared/pids/faye.pid'
#     FAYE_PID = File.exist?(PID_FILE_PATH) ? File.open(PID_FILE_PATH, 'rb').read.to_i : nil
#     p '---------------start--------------------------------thread-------------------------'
#     Command.run("/bin/su - deploy -c 'kill -9 #{FAYE_PID}'") if FAYE_PID.present?
#     Command.run("/bin/su - deploy -c 'cd /home/deploy/Project_Zulu/current/ && bundle exec rackup faye.ru -d -E production -p 9292 -P #{PID_FILE_PATH} --daemonize '")
#     p '---------------end--------------------------------thread-------------------------'
#     Thread.exit
#   end
# end
#
#
