#Delayed::Worker.destroy_failed_jobs = false
#Delayed::Worker.sleep_delay = 60
Delayed::Worker.max_attempts = 3 # default 25 attempts
#Delayed::Worker.max_run_time = 5.minutes
#Delayed::Worker.read_ahead = 10
#Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.default_priority = 1 #using 0(i.e top priorty to strip operations)
Delayed::Worker.destroy_failed_jobs = false  #The failed jobs will be marked with non-null failed_at