namespace :block do
  task :process_new_confirmed_blocks => :environment do
    Block.process_new_confirmed_blocks
  end
end