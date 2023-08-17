class Tagable < ApplicationRecord
   belongs_to :tag, optional: true
end
