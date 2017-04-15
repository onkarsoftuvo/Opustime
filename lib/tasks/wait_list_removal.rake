task :auto_remove_waitlist_on_expire => :environment do
  
  expired_wait_lists = WaitList.active_wait_list.where(["DATE(remove_on) <= ?",  Date.today])
  expired_wait_lists.each do |wait_list|
    wait_list.destroy
  end
end
