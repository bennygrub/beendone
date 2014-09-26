resque: env TERM_CHILD=1 COUNT=1 QUEUE=* bundle exec rake resque:work 
worker: bundle exec rake resque:work QUEUE=*
scheduler: bundle exec rake resque:scheduler
