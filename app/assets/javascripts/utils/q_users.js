var cursor = db.profiles.find({"parent_type.email" : {$exists : true}}).sort({"fname" : -1});
var counter = 0;
print("First Name, Last Name, Email Id, Created Date, Last Accessed Date");

cursor.forEach(function(profile){
	db.users.find({"email" : profile.parent_type.email}).forEach(function(user){
		print( profile.parent_type.fname + ", " + profile.parent_type.lname + ", " + profile.parent_type.email + ", " + (profile.created_at? profile.created_at : "") + ", " + ( user.last_sign_in_at ? user.last_sign_in_at : ""));		
		counter+=1;
	});
});

print("Total=" + counter);