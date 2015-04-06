logs = db.activity_logs.find({"user" : "jane.doe@test.com"}).sort({"created_at" : -1});
print("User Email, Request IP, Controller, Action, Created At ");
logs.forEach(function(log){


        print(  log.user + ", "+ log.ip_address + ", " + log.controller + ", " + log.action + ", "+ log.created_at );

});
