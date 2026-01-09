class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.to_csv
    csv_string = CSV.generate do |csv|
      csv << self.attribute_names

      self.all.each do |item|
        csv << item.attributes.values
      end
    end

    csv_string
  end
end
