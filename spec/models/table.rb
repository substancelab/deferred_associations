class Table < ActiveRecord::Base
  belongs_to :room
  has_many_with_deferred_save :chairs
end