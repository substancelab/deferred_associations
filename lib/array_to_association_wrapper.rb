class ArrayToAssociationWrapper < Array

  def defer_association_methods_to(owner, association_name)
    @association_owner = owner
    @association_name = association_name
  end

  # trick collection_name.include?(obj)
  # If you use a collection of SingleTableInheritance and didn't :select 'type' the
  # include? method will not find any subclassed object.
  def include_with_deferred_save?(obj)
    if @association_owner.present?
      if detect { |itm| itm == obj || (itm[:id] == obj[:id] && obj.is_a?(itm.class)) }
        return true
      else
        return false
      end
    else
      include_without_deferred_save?(obj)
    end
  end

  alias_method(:include_without_deferred_save?, :include?)
  alias_method(:include?, :include_with_deferred_save?)

  def find_with_deferred_save(*args)
    if @association_owner.present?
      collection_without_deferred_save.send(:find, *args)
    else
      find_without_deferred_save
    end
  end

  alias_method(:find_without_deferred_save, :find)
  alias_method(:find, :find_with_deferred_save)

  def first_with_deferred_save(*args)
    if @association_owner.present?
      collection_without_deferred_save.send(:first, *args)
    else
      first_without_deferred_save
    end
  end

  alias_method(:first_without_deferred_save, :first)
  alias_method(:first, :first_with_deferred_save)

  def last_with_deferred_save(*args)
    if @association_owner.present?
      collection_without_deferred_save.send(:last, *args)
    else
      last_without_deferred_save
    end
  end

  alias_method(:last_without_deferred_save, :last)
  alias_method(:last, :last_with_deferred_save)

  define_method :method_missing do |method, *args|
    # puts "#{self.class}.method_missing(#{method}) (#{collection_without_deferred_save.inspect})"
    if @association_owner.present?
      collection_without_deferred_save.send(method, *args) unless method == :set_inverse_instance
    else
      super
    end
  end

  def collection_without_deferred_save
    @association_owner.send("#{@association_name}_without_deferred_save")
  end

end
