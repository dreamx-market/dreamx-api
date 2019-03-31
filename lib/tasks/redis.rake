namespace :redis do
  task :set_nonce, [:number] do |task, args|
    p Redis.current.set('nonce', args[:number])
  end
end