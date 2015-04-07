Meducation::Application.routes.draw do


  #added contraints to allow '.' and '/' operator in parameters
  get '/multimedia/:key'=>"multimedia#index", :constraints => { :key => /(.*|\/*)/ }

  resources :categories do
    collection do
      post 'get_child'
    end
  end
  #category related matches

  get "categories/:id/ancestors"=>"categories#ancestors",as: :category_ancestors
  get "categories/:id/edit-category-children"=>"categories#edit_category_children",as: :edit_category_children


  resources :organization_documents
  resources :forms


  namespace :admin do
    resources :coupons
    resources :hospitals
    resources :feeds
    resources :ae_definitions do
      collection do
        get 'schedule_new'
        put 'schedule_edit'
        get 'user_activity'
      end
    end
    get 'invitations/invitation_list'=>"invitations#invitation_list",:as=> :invitation_list
    get 'invitations/invitation_export'=>"invitations#invitation_export",:as=> :invitation_export
    get 'invitations/universal-invitations'=>"invitations#universal_invitations",:as=> :universal_invitations
    #resources :milestone_templates
    resources :invitations
    resources :user_instructions
    resources :user_tours
    scope ":template_image_id" do
      delete 'delete_prompt_image'=> "user_instructions#delete_prompt_image", as: :desrtoy_prompt_image
      delete 'delete_tour_image'=> "user_tours#delete_tour_image", as: :desrtoy_tour_image
    end

    get 'edit-email'=>"tasks#edit_email",as: :edit_email
    post 'update-email'=>"tasks#update_email",as: :update_email
    get 'search-parents'=>"tasks#search_parents",as: :search_parents

    get 'edit-phone-numbers'=>"tasks#edit_phone_numbers",as: :edit_phone_numbers
    post 'update-phone-numbers'=>"tasks#update_phone_numbers",as: :update_phone_numbers

    get 'organic-users'=>"tasks#organic_users",as: :organic_users
    patch 'organic-user'=>"tasks#set_as_organic",as: :set_organic_user
    patch 'organic-users'=>"tasks#unset_as_organic",as: :unset_organic_user

    get 'edit-user-data'=>"tasks#edit_user_data",as: :edit_user_data
    patch 'update-user-data/:id'=>"tasks#update_user_data",as: :update_user_data 


    # Invitation Requests(Distribute Invitations)
    get 'invitation_requests/:scope'=>"invitation_requests#index",:as=> :invitation_requests
    post 'invitation_requests/update_auto_distribution/:status'=>"invitation_requests#update_auto_distribution"
    post 'invitation_requests/update_exclude_auto_distribution/:status'=>"invitation_requests#update_exclude_auto_distribution"
    post 'invitation_requests/update_status'=>"invitation_requests#update_status",as: :update_invitation_requests
    post 'invitation_requests/update_redirection_url'=>"invitation_requests#update_redirection_url",as: :update_inv_reqs_redirection
    get 'invitation-requests/export-data'=>"invitation_requests#export",as: :export_invitation_requests

  end
  get "/access_denied"=>'home#access_denied',as: :access_denied
  get "/launch_app"=>'m/native_app#launch_app',as: :launch_app

  get 'payments/new' => 'payments#new', :as => :new_payment
  get 'payments/confirm' => 'payments#confirm', :as => :confirm_payment
  get 'payments/update_discount_price' => "payments#update_discount_price", :as=> :update_discount_price

  resources :organizations do
    member do
      get 'org_form_and_documents'
    end

    collection do
      get 'download_json'
      get 'normal_form'
      get 'profile_request'
      get 'org_dashboard'
      get 'org_enrollees'

      get 'change_status'
      post 'change_status_res'
      post 'org_form_edit'
      get 'org_form'
      get 'selected_season'
      get 'selected_data'
      get 'seasons_wise_data'
      get 'seasons_doc_data'
      get 'popup_send_form'
      post 'popup_send_form_res'
      get 'selected_session'
      get 'selected_session_for_status'
      get 'form_content'
      get 'form_preview'
      get 'set_as_application_form'
      get 'change_form'
      get 'change_workflow'
      get 'set_as_app'
      get 'automate'
      post 'update_app'
      get 'org_docdef_edit'
      get 'change_workflow_doc'
      get 'email_validate'
      get 'export_to_csv'
      get 'org_child_profile'
      post 'contact_vi_mail'
      post 'export_csv_season'
      get 'export_profile_data_csv'
      get 'add_select_boxes'
      get 'add'
      get 'show_lookups'
      get 'print_profile_data'
      get 'form_data'
      post 'update_form_res'
      get 'export_template'
      get 'get_season_fields'
      get 'selected_data_kid_ids'
    end
  end
  get 'organizations/:id/forms_and_documents'=>"organizations#org_form_and_documents",:as=> :org_form_and_documents
  get 'organizations/:id/invitations'=>"organizations#org_invitations",:as=> :org_invitations
  post 'organizations/:id/add_invitation'=>"organizations#add_invitation",:as=> :add_invitation
  get 'organizations/:id/org_invitation_new'=>"organizations#org_invitation_new",:as=> :org_invitation_new
  resources :profiles do
    collection do
      get 'membership_create'
      get 'top_dashboard'
      get 'child_dashboard'
      #get 'child_org_dashboard'
      get 'existing_apply_form'
      get 'launch'
      get 'form_data'
      post 'update_form_res'
      get 'validate_form'
      get 'child_org_document_upload'
      get 'child_org_document_upload_notemplates'
      get 'child_org_document_view'
      get 'child_org_form_attachments'
      get 'child_org_form_attachments_notemplates'
      post 'create_profile'
      get 'new_logged_in'
      post 'create_profile_logged_in'
      get 'edit_existing'
      post 'edit_existing_submit'
    end
  end

  devise_for :users do

  end

  get "home/index"

  devise_scope :user do
    root :to => "devise/sessions#new"
    get '/users/sign_out' => 'devise/sessions#destroy'
    get '/users/select_type' => 'devise/registrations#select_type'
    get '/users/forget_password_success' => 'devise/passwords#forget_password_success', as: :forget_password_success
    get '/users/reset_password_success' => 'devise/passwords#reset_password_success', as: :reset_password_success
  end

  #This will provide you with URLs such as /org_id/document_definitions/1
  # if organization name is uniq then replace id with name --> /peachtree/document_definitions
  scope ":organization_id" do
    resources :document_definitions,except: [:index,:show]  do
      post 'update_workflow',on: :collection
      get 'download_responses',on: :member
    end
  end

  ##==== routes with scope as proffile_id moved to down for some reason

  get 'dashboard/evaluate-password' => "dashboard#evaluate_password", as: :evaluate_password
  get 'dashboard/evaluate-name' => "dashboard#evaluate_name", as: :evaluate_name
  scope ":document_id" do
    scope ":category_id" do
      get 'document-buttons'=> "documents#document_buttons", as: :document_buttons
    end
  end
  # create or assign org_admin role to user for organization
  scope "/organizations/:id" do
    get "admins/new"=>"org_admins#new",as: :new_org_admin
    get "admins"=>"org_admins#index",as: :org_admins
    post "admins/create"=>"org_admins#create",as: :create_org_admins
  end


  get 'auth/:provider/callback', to: 'omniauth_callback#facebook'
  #----------- --- mobile routes------


  scope ":profile_id" do
    # Documents --------------------------------------------------------------------
    resources :documents do#,except: [:index,:show]
      get 'existing' ,on: :collection
      get 'share' ,on: :member
      post 'accept_and_save',on: :collection
      get 'child_node' ,on: :collection
      get 'multiple_documents' ,on: :collection
      get 'original_document' ,on: :member, as: :original
      post 'change_photo_id',on: :collection
      get 'full_view', on: :member, as: :full_view
      get 'bw_view', on: :member, as: :bw_view
    end

    #alerts and events -------------------------------------------------------------
    get 'top-alerts-and-events'=>"alerts_and_events#index",as: :alerts_and_events
    get 'alert-or-event/:notification_id'=>"alerts_and_events#show",as: :alert_or_event

    scope ":notification_id"  do
      get 'update-status' =>"alerts_and_events#update_status",as: :update_alert_or_event
    end

    # Dashboard --------------------------------------------------------------------
    get 'top-dashboard'=>"dashboard#index",as: :top_dashboard
    get 'child-dashboard'=>"dashboard#child_dashboard",as: :child_dashboard
    get 'document_vault_tabs'=> "dashboard#document_vault_tabs"
    get 'child-profile'=>"dashboard#child_profile",as: :child_profile
    get 'child-profile-edit' => "dashboard#child_profile_edit", as: :edit_child_profile
    post 'invite-mom' => "dashboard#invite_mom", as: :invite_mom
    patch 'update-child-profile' => "dashboard#update_child_profile", as: :update_child_profile
    get  'add-more-parents' => "dashboard#add_more_parents", as: :add_more_parents
    get 'opting-partner-branding' => "dashboard#opting_partner_branding", as: :opting_partner_branding
    get 'preferences'=> "dashboard#preferences", as: :preferences
    get 'trending'=>"dashboard#trending",as: :trending
    # profiles controller org related
    get 'org-dashboard'=>"profiles#child_org_dashboard",as: :child_org_dashboard

  end

  match '/invitation/request'=> "home#invitation_request", via:[:post, :get]

end
