/**
 * Created by maisapride786 on 30/6/14.
 */

db.oauth_access_tokens.update({"expires_in" : {"$lt" :2592000}}, {"$set": {"expires_in": "2592000"}}, {multi: true})