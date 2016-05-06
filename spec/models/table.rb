class Table < ActiveRecord::Base

  belongs_to :room
  belongs_to :room_with_autosave, class_name: 'Room', autosave: true, foreign_key: 'room_id'
  has_many_with_deferred_save :chairs

end
