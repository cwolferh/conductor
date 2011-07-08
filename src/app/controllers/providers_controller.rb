class ProvidersController < ApplicationController
  before_filter :require_user
  before_filter :set_view_envs, :only => [:show, :index]

  def top_section
    :administer
  end

  def index
    clear_breadcrumbs
    save_breadcrumb(providers_path)
    @params = params
    @search_term = params[:q]

    if @search_term.blank?
      load_providers
    else
      @providers = Provider.search { keywords(params[:q]) }.results
    end

    respond_to do |format|
      format.html
      format.xml { render :partial => 'list.xml' }
    end
  end

  def new
    require_privilege(Privilege::CREATE, Provider)
    @provider = Provider.new
  end

  def edit
    @provider = Provider.find_by_id(params[:id])
    require_privilege(Privilege::MODIFY, @provider)
  end

  def show
    load_providers
    @provider = Provider.find(params[:id])
    @hardware_profiles = @provider.hardware_profiles
    @realm_names = @provider.realms.collect { |r| r.name }

    require_privilege(Privilege::VIEW, @provider)
    @tab_captions = ['Properties', 'HW Profiles', 'Realms', 'Provider Accounts', 'Services', 'History', 'Permissions']
    @details_tab = params[:details_tab].blank? ? 'properties' : params[:details_tab]

    if params.delete :test_provider
      test_connection(@provider)
    end

    save_breadcrumb(provider_path(@provider), @provider.name)

    respond_to do |format|
      format.js do
        if params.delete :details_pane
          render :partial => 'layouts/details_pane' and return
        end
        render :partial => @details_tab and return
      end
      format.html { render :action => 'show' }
    end
  end

  def create
    require_privilege(Privilege::CREATE, Provider)
    if params[:provider].has_key?(:provider_type_codename)
      provider_type = params[:provider].delete(:provider_type_codename)
      provider_type = ProviderType.find_by_codename(provider_type)
      params[:provider][:provider_type_id] = provider_type.id
    end
    @provider = Provider.new(params[:provider])
    if !@provider.connect
      flash[:warning] = "Failed to connect to Provider"
      render :action => "new"
    else
      if @provider.save && @provider.populate_hardware_profiles
        @provider.assign_owner_roles(current_user)
        flash[:notice] = "Provider added."
        redirect_to providers_path
      else
        flash[:warning] = "Cannot add the provider."
        render :action => "new"
      end
    end
  end

  def update
    @provider = Provider.find_by_id(params[:id])
    require_privilege(Privilege::MODIFY, @provider)
    @provider.update_attributes(params[:provider])
    if !@provider.connect
      flash[:warning] = "Failed to connect to Provider"
      render :action => "edit"
    else
      if @provider.errors.empty? and @provider.save
        flash[:notice] = "Provider updated."
        redirect_to providers_path
      else
        flash[:warning] = "Cannot update the provider."
        render :action => 'edit'
      end
    end
  end

  def multi_destroy
    deleted = []
    not_deleted = []
    Provider.find(params[:provider_selected]).each do |provider|
      check_privilege(Privilege::MODIFY, provider)
      if provider.destroy
        deleted << provider.name
      else
        not_deleted << provider.name
      end
    end

    unless deleted.empty?
      flash[:notice] = "These Realms were deleted: #{deleted.join(', ')}"
    end
    unless not_deleted.empty?
      flash[:error] = "Could not deleted these Realms: #{not_deleted.join(', ')}"
    end

    redirect_to providers_url
  end

  def destroy
    provider = Provider.find(params[:id])
    require_privilege(Privilege::MODIFY, provider)
    provider.destroy

    respond_to do |format|
      format.html { redirect_to providers_path }
    end
  end

  def test_connection(provider)
    @provider.errors.clear
    if @provider.connect
      flash[:notice] = "Successfuly Connected to Provider"
    else
      flash[:warning] = "Failed to Connect to Provider"
      @provider.errors.add :url
    end
  end

  protected
  def set_view_envs
    @header = [
      {:name => '', :sortable => false},
      {:name => t("providers.index.provider_name"), :sort_attr => :name},
      {:name => t("providers.index.provider_url"), :sort_attr => :name},
      {:name => t("providers.index.provider_type"), :sort_attr => :name},
    ]
  end

  def load_providers
    @providers = Provider.list_for_user(@current_user, Privilege::VIEW)
  end
end
