
// while ( cursor.hasNext() ) {
// 	
//    printjson( cursor.next() );
// }


var drGrn = [];
db.hospital_memberships.find({"hospital_id" : ObjectId("5243de33d2006eb64b000001")}).forEach(function(hm){
	drGrn.push(hm.profile_id)
});

var today = new Date();

print("### Dr.Green ###");
cursor = db.profiles.find({"_id" : { $in: drGrn }});
var counter = 0;
cursor.forEach(function(profile){
	var kidDOB = profile.kids_type.birthdate;
	var ageInDays = daysBetween(kidDOB, today);
	print( profile.kids_type.kids_id + ", " + humanise(ageInDays) + ", " + profile.kids_type.zip);
	counter += 1;
});
print("Total Memberships=", counter);

var pmc = [];
db.hospital_memberships.find({"hospital_id" : ObjectId("524472e3b10e5c5bf6000019")}).forEach(function(hm){
	pmc.push(hm.profile_id)
});

print("### PMC ###");
cursor = db.profiles.find({"_id" : { $in: pmc }});
var counter = 0;
cursor.forEach(function(profile){
	var kidDOB = profile.kids_type.birthdate;
	var ageInDays = daysBetween(kidDOB, today);
	print( profile.kids_type.kids_id + ", " + humanise(ageInDays) + ", " + profile.kids_type.zip);
	counter += 1;
});
print("Total Memberships=", counter);


function daysBetween(first, second) {

    // Copy date parts of the timestamps, discarding the time parts.
    var one = new Date(first.getFullYear(), first.getMonth(), first.getDate());
    var two = new Date(second.getFullYear(), second.getMonth(), second.getDate());

    // Do the math.
    var millisecondsPerDay = 1000 * 60 * 60 * 24;
    var millisBetween = two.getTime() - one.getTime();
    var days = millisBetween / millisecondsPerDay;

    // Round down.
    return Math.floor(days);
}


function humanise (diff) {
  // The string we're working with to create the representation
  var str = '';
  // Map lengths of `diff` to different time periods
  var values = {
    ' year': 365, 
    ' month': 30, 
    ' day': 1
  };

  // Iterate over the values...
  for (var x in values) {
    var amount = Math.floor(diff / values[x]);

    // ... and find the largest time value that fits into the diff
    if (amount >= 1) {
       // If we match, add to the string ('s' is for pluralization)
       str += amount + x + (amount > 1 ? 's' : '') + ' ';

       // and subtract from the diff
       diff -= amount * values[x];
    }
  }

  return str;
}