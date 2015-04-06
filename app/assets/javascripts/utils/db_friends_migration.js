//to migrate from friends to relationships

db.friends.renameCollection("relationships")
db.relationships.update({},{$set:{_type:'Friend'}}, {multi:true})