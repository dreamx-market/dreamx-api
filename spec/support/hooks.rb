RSpec.configure do |config|
  config.around(:each) do |example|
    if Bullet.enable?
      Bullet.start_request
    end

    example.run

    revert_environment_variables
    Redis.current.flushdb
    Rails.application.load_redis_config_variables

    if Bullet.enable?
      Bullet.end_request
    end
  end

  config.around(:each, :onchain) do |example|
    sync_nonce
    snapshot_id = snapshot_blockchain

    example.run

    revert_blockchain(snapshot_id)
  end

  config.around(:each, :perform_enqueued) do |example|
    old_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true

    example.run

    ActiveJob::Base.queue_adapter = old_queue_adapter
  end
end