class ImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false
  include Sidekiq::Lock::Worker

  sidekiq_options lock: {timeout: 1000*60, name: 'import_worker'}

  def perform(import_id)
    if lock.acquire!
      begin
        @import = Import.find_by_id(import_id)
        unless @import.nil?
          @import.delete_associated_records
          @import.destroy
        end
      ensure
        lock.release!
      end
    end
  end
end

