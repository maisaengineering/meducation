cursor = db.users.find({"current_sign_in_at" : {$exists : true}}).sort({"current_sign_in_at" : -1});
var counter = 0;
cursor.forEach(function(user){
	var isParent = db.roles.find({"name": "Parent", "user_id" : user._id}).count();
	if(isParent > 0){
		print(  user.email + ", " + user.created_at + ", " + user.current_sign_in_at);
		counter += 1;
	}
});

print("Total=" + counter);