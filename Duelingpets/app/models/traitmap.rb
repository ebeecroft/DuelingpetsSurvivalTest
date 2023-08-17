class Traitmap < ApplicationRecord
   #Traitmap related
   belongs_to :traittype, optional: true
   belongs_to :entitytype, optional: true
end
