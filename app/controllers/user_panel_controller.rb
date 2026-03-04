class UserPanelController < ApplicationController
  layout "user"
  before_action :authenticate_user!
  before_action :set_globals

  def home
  end


  private

  def set_globals
    @user = current_user
    @corp = @user.corp
  end
end
