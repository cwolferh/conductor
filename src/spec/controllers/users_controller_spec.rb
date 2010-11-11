require 'spec_helper'

describe UsersController do

  before(:each) do
    Factory(:base_permission_object)
    @tuser = Factory :tuser
    @admin_permission = Factory :admin_permission
    @admin_permission.role.privileges << Privilege.new(:name => 'user_modify')
    @admin = @admin_permission.user
    Factory.create(:default_quota_metadata)
    Factory.create(:default_role_metadata)
    Factory.create(:default_pool_metadata)
    activate_authlogic
  end

  it "allows user to get to registration form for new user" do
    get :new
    response.should be_success
  end

  describe "#create" do
    context "user enters valid input" do
      it "creates user" do
        lambda do
          post :create, :user => {
            :login => "tuser2", :email => "tuser2@example.com",
            :password => "testpass",
            :password_confirmation => "testpass" }
        end.should change(User, :count).by(1)

        response.should redirect_to(dashboard_url)
      end

      it "fails to create pool" do
        lambda do
          post :create, :user => {}
        end.should_not change(User, :count)

        returned_user = assigns[:user]
        returned_user.errors.empty?.should be_false
        returned_user.should have(2).errors_on(:login)
        returned_user.should have(2).errors_on(:email)
        returned_user.should have(1).error_on(:password)
        returned_user.should have(1).error_on(:password_confirmation)

        response.should render_template('new')
      end
    end
  end

  it "allows an admin to create user" do
    UserSession.create(@admin)
    lambda do
      post :create, :user => {
        :login => "tuser3", :email => "tuser3@example.com",
        :password => "testpass",
        :password_confirmation => "testpass" }
    end.should change(User, :count)

    response.should redirect_to(users_url)
  end

  it "should not allow a regular user to create user" do
    UserSession.create(@tuser)
    lambda do
      post :create, :user => {
        :login => "tuser4", :email => "tuser4@example.com",
        :password => "testpass",
        :password_confirmation => "testpass" }
    end.should_not change(User, :count)
  end

  it "provides show view for user" do
    UserSession.create(@tuser)
    get :show

    response.should be_success
  end

  it "provides edit view for user" do
    UserSession.create(@tuser)
    get :edit, :id => @tuser.id

    response.should be_success
  end

  it "updates user with new data" do
    UserSession.create(@tuser)
    put :update, :id => @tuser.id, :user => {}, :commit => 'Save'

    response.should redirect_to(dashboard_path)
  end

  # checks whether proper error template is rendered when an exception raises
  # "layouts/error" template should be displayed for all non-ajax error
  # responses, "layouts/popup-error" should be displayed for ajax
  # (see "Fixed error handling" patch for details)
  it "should render error template when getting nonexisting user" do
    UserSession.create(@tuser)
    get :show, :id => "unknown_id"
    response.should render_template("layouts/error")
  end
end
