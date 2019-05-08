namespace :block do
  task :process_new_confirmed_blocks => :environment do
    p 'start Block.process_new_confirmed_blocks'
    Block.process_new_confirmed_blocks
    p 'finished Block.process_new_confirmed_blocks'
  end
end