require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe NotificationsController do

  # This should return the minimal set of attributes required to create a valid
  # Notification. As you add validations to Notification, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  describe "GET index" do
    it "assigns all notifications as @notifications" do
      notification = Notification.create! valid_attributes
      get :index
      assigns(:notifications).should eq([notification])
    end
  end

  describe "GET show" do
    it "assigns the requested notification as @notification" do
      notification = Notification.create! valid_attributes
      get :show, :id => notification.id.to_s
      assigns(:notification).should eq(notification)
    end
  end

  describe "GET new" do
    it "assigns a new notification as @notification" do
      get :new
      assigns(:notification).should be_a_new(Notification)
    end
  end

  describe "GET edit" do
    it "assigns the requested notification as @notification" do
      notification = Notification.create! valid_attributes
      get :edit, :id => notification.id.to_s
      assigns(:notification).should eq(notification)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Notification" do
        expect {
          post :create, :notification => valid_attributes
        }.to change(Notification, :count).by(1)
      end

      it "assigns a newly created notification as @notification" do
        post :create, :notification => valid_attributes
        assigns(:notification).should be_a(Notification)
        assigns(:notification).should be_persisted
      end

      it "redirects to the created notification" do
        post :create, :notification => valid_attributes
        response.should redirect_to(Notification.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved notification as @notification" do
        # Trigger the behavior that occurs when invalid params are submitted
        Notification.any_instance.stub(:save).and_return(false)
        post :create, :notification => {}
        assigns(:notification).should be_a_new(Notification)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Notification.any_instance.stub(:save).and_return(false)
        post :create, :notification => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested notification" do
        notification = Notification.create! valid_attributes
        # Assuming there are no other notifications in the database, this
        # specifies that the Notification created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Notification.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => notification.id, :notification => {'these' => 'params'}
      end

      it "assigns the requested notification as @notification" do
        notification = Notification.create! valid_attributes
        put :update, :id => notification.id, :notification => valid_attributes
        assigns(:notification).should eq(notification)
      end

      it "redirects to the notification" do
        notification = Notification.create! valid_attributes
        put :update, :id => notification.id, :notification => valid_attributes
        response.should redirect_to(notification)
      end
    end

    describe "with invalid params" do
      it "assigns the notification as @notification" do
        notification = Notification.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Notification.any_instance.stub(:save).and_return(false)
        put :update, :id => notification.id.to_s, :notification => {}
        assigns(:notification).should eq(notification)
      end

      it "re-renders the 'edit' template" do
        notification = Notification.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Notification.any_instance.stub(:save).and_return(false)
        put :update, :id => notification.id.to_s, :notification => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested notification" do
      notification = Notification.create! valid_attributes
      expect {
        delete :destroy, :id => notification.id.to_s
      }.to change(Notification, :count).by(-1)
    end

    it "redirects to the notifications list" do
      notification = Notification.create! valid_attributes
      delete :destroy, :id => notification.id.to_s
      response.should redirect_to(notifications_url)
    end
  end

end