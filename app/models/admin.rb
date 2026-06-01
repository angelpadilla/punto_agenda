class Admin < ApplicationRecord
  audited max_audits: 1000

  devise :database_authenticatable,
  :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :trackable

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id full_name tipo email tel active]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end
end
