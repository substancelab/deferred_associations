class Person < ActiveRecord::Base

  has_and_belongs_to_many_with_deferred_save :rooms, validate: true

  attr_accessor :do_extra_validation
  validate      :extra_validation, if: :do_extra_validation

  def extra_validation
    rooms.each do |room|
      this_room_unsaved = rooms_without_deferred_save.include?(room) ? 0 : 1
      if room.people.size + this_room_unsaved > room.maximum_occupancy
        errors.add :rooms, 'This room has reached its maximum occupancy'
      end
    end
  end

end
