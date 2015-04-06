# KidsLink Application #

KidsLink is an app for moms to document, manage, and share the daily aspects of their children's lives.

* Ruby 1.9.3
* Rails 3.2.11
* MongoDB
* JSON
* Html5
* Css3

##  Release v0.1 ##
Meducation v0.1 released on October 24th 2012

* Application developed with Static forms
* Added Peachtree Presbyterian Preschool for kidslink

##  Release v0.2 ##
Meducation v0.2 released on May 18th 2013

* Application changed to dynamic forms using JSON. We are building Forms and Documents with JSON content from Organization admin side.
* Multiple Seasons support, We can add multiple season for oranization.
* We changed some database modeling. 
* For new modeling we changed production data with rake tasks

Rake task to create aplication form with dynamic JSON data
```ruby
rake db:create_application_form
```
Rake task to Move membership enrollments to season top level instead of nested level in organization memberships
```ruby
rake db:remove_enrollment
```
Rake task to Move profile 'status' to organization memberships season level
```ruby
rake db:move_profile_status
```
Rake task to Assign Profile id to profile_kids_type_id in organization membership
```ruby
rake db:assign_profile_id
```
Rake task to Add key field to parent phone numbers
```ruby
rake db:add_key_to_phone_numbers
```
Rake task to Create default notification(Application form) for organization_membership(default application form status sumbitted)
```ruby
rake db:create_application_form_notification
```
Rake task to Create Acknowledgment for application form notification
```ruby
rake db:acknowledge_form
```
rake task to Move profile 'terms' to season
```ruby
rake db:move_profile_terms
```
Rake task to Create Photo graph of child document for organization
```ruby
rake db:create_photograph_of_child
```
Rake task to Send Photograph of child to all registered kids for organization
```ruby
rake db:send_photograph_of_child
```
Rake task to create weblinks for organization
```ruby
rake db:create_weblinks
```
## Patch release v0.2-p1  ##
We released patch changes on June 10th 2013

* We are supporting multiple organizations
* We implemented multi role support

## September Release ##

We need to run these rake tasks for september release

Rake task to change season year to season id over the application
```ruby
rake db:add_org_season_id
```
Rake task to add Profile id's to Notifications
```ruby
rake db:add_profile_id_to_notification
```
Rake task to move zipcode from kids_type to top level
```ruby
rake db:copy_zipcodes
```
Rake task to make old documents to support multi upload's
```ruby
rake db:add_multi_upload
```
Rake task to support, flexibility of restricting parents from accessing kids profile
```ruby
rake db:add_manageable_field
```
Rake task to Create Categories for documents
```ruby
rake db:create_categories
```

Rake task to adding category_id to production documents
```ruby
rake db:add_category_id
```

Rake task to recreate versions for kid's photograph
```ruby
rake db:recreate_photographs
```

Rake task to Parse bithdate from string to Date

```ruby
rake db:parse_birthdate_to_date
```

### Now we need to create hospital from super admin


Rake task to adding hospital to organization  (Note:  before this task,  need to add hospitals from super admin)

```ruby
rake db:add_hospital_id_to_org
```

Rake task to add hospital baranding to production data (Note:  before this task,  need to add hospitals from admin)

```ruby
rake db:add_partner_branding
```


##  To create Milestones, AE definations, Organizations login as Super Admin ##

To create Milestones, AE definations, Organizations login as Super Admin
email:  superadmin@maisasolutions.com
pass: 123456

Milestone Templates gist:  https://gist.github.com/maisaengineering/52b75778c8d97f2f06ee

##  Verification of Notifications ##
 
Rake task to verification of Forms request to kids from organization 

```ruby
rake db:check_forms_kids TemplateIds="pass JsonTemplate Ids with space seprator"
```

Rake task to get Detailed Report on duplicate notifications. (this includes photograph of child ) 
```ruby
rake db:find_multiple_form_requests TemplateIds="pass JsonTemplate Ids with space seprator"
```

Rake task to remove duplicate notifications for all froms except application form and Photograph of child

```ruby
rake db:remove_multiple_form_requests
```

##  Convert's Email's to Downcase##

Rake task to convert Email Id of all parent profile to down case

```ruby
rake db:emails_to_downcase
```

##  Version 2.05##

run below rake tasks

```ruby
rake db:add_snapshot_created_to_milestones
```


##  Version 2.07##

run below rake tasks

Enable document sharing b/w family for already existed profiles
```ruby
rake db:enable_document_sharing
```


insert season's created_at with org_mem.meta_data.kid_profile_created_at or parents user created_at if its nil
```ruby
rake db:fix_org_enrolles_application_date
```


##  Version 2.08##

to  make profile compatible to unsubscribe emails .
```ruby
rake db:add_unsubscribe_emails_field
```

##  Version 2.09##

to  move photographs from gridfs to Amazon s3 .
```ruby
rake db:move_photograph_to_s3 domain="<give domain name>"
```

