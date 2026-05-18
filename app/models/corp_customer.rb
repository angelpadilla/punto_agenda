class CorpCustomer < ApplicationRecord
  belongs_to :corp
  belongs_to :customer

  enum :source, manual: "manual", compra: "compra",
                event: "event", self_registered: "self_registered"
end
