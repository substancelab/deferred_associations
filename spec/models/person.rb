class Person < ActiveRecord::Base
  has_and_belongs_to_many_with_deferred_save :rooms, :validate => true

  attr     :do_extra_validation, true
  validate :extra_validation, :if => Proc.new() { do_extra_validation }

  def extra_validation
    rooms.each do |room|
      this_room_unsaved = rooms_without_deferred_save.include?(room) ? 0 : 1
      if room.people.size + this_room_unsaved > room.maximum_occupancy
        errors.add :rooms, "This room has reached its maximum occupancy"
      end
    end
  end
end
