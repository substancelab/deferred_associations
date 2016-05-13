class Room < ActiveRecord::Base

  attr_accessor :bs_diff_before_module
  attr_accessor :bs_diff_after_module
  attr_accessor :bs_diff_method

  before_save :diff_before_module

  has_and_belongs_to_many_with_deferred_save :people, before_add: :before_adding_person
  has_and_belongs_to_many :people2, class_name: 'Person'
  has_and_belongs_to_many_with_deferred_save :doors

  has_many_with_deferred_save :tables
  has_many_with_deferred_save :chairs, through: :tables # TODO: test compatibility with through associations


  before_save :diff_after_module

  validate :people_count

  def people_count
    errors.add :people, 'This room has reached its maximum occupancy' if maximum_occupancy && people.size > maximum_occupancy
  end

  # Just in case they try to bypass our new accessor and call people_without_deferred_save directly...
  # (This should never be necessary; it is for demonstration purposes only...)
  def before_adding_person(person)
    if people_without_deferred_save.size + [person].size > maximum_occupancy
      raise 'There are too many people in this room'
    end
  end

  def diff_before_module
    # should detect the changes
    self.bs_diff_before_module = (people.size - people_without_deferred_save.size) != 0
    true
  end

  def diff_after_module
    # should not detect the changes
    self.bs_diff_after_module = (people.size - people_without_deferred_save.size) != 0
    true
  end

  def before_save
    # old_style, should not detect the changes
    self.bs_diff_method = (people.size - people_without_deferred_save.size) != 0
    true
  end

end
