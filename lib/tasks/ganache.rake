namespace :ganache do
 task :up do
  trap('SIGINT') { exit }
  system "rm -r -f .chaindata"
  system "cp -a chaindata/. .chaindata"
  system "ganache-cli -e 1000000 -m 'deputy venture tiny disagree love airport diamond trumpet ask action they gain' --db ./chaindata"
 end
end