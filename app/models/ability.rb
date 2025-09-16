# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, :to => :crud
    alias_action :create, :read, :to => :cr
    alias_action :create, :read, :update, :to => :cru
    alias_action :update, :destroy, :to => :ud
    alias_action :create, :update, :destroy, :to => :cud
    alias_action :read, :update, :destroy, :to => :rud

    user ||= User.new
    if user.admin?
      can :manage, :all
    end
  end
end
