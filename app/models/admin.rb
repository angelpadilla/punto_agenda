class Admin < ApplicationRecord
  audited max_audits: 1000

  Roles = [
    [ "Super", 0 ],
    [ "Admin", 1 ],
    [ "Editor", 2 ],
    [ "Vendedor", 3 ]
  ]

  Roles2 = [
    [ "Admin", 1 ],
    [ "Editor", 2 ],
    [ "Vendedor", 3 ]
  ]

  devise :database_authenticatable,
  :recoverable, :rememberable, :validatable, :lockable, :timeoutable, :trackable

  scope :default, -> { order(full_name: :asc, created_at: :desc) }

  ## ransack search
  def self.ransackable_attributes(auth_object = nil)
    %w[id full_name tipo email tel active rol]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[]
  end

  def super?
    self.rol == 0
  end

  def admin?
    self.rol == 0 or self.rol == 1
  end

  def editor?
    self.rol == 2
  end

  def vendedor?
    self.rol == 3
  end
end
