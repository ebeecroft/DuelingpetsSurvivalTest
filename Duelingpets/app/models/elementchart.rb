class Elementchart < ApplicationRecord
   #Elementcharts related
   #belongs_to :element, optional: true
   belongs_to :user, optional: true
   has_many :elementmaps, :foreign_key => "elementchart_id", :dependent => :destroy
end
