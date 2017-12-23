Make ActiveRecord defer/postpone saving the records you add to an habtm (has_and_belongs_to_many) or has_many association
until you call model.save, allowing validation in the style of normal attributes.

[![Build Status](https://secure.travis-ci.org/MartinKoerner/deferred_associations.png?branch=master)](http://travis-ci.org/MartinKoerner/deferred_associations) [![Dependency Status](https://gemnasium.com/MartinKoerner/deferred_associations.png?travis)](https://gemnasium.com/MartinKoerner/deferred_associations)

How to install
==============

    gem install deferred_associations

Usage
=====

```ruby
class Room < ActiveRecord::Base
  has_and_belongs_to_many_with_deferred_save :people
  has_many_with_deferred_save :tables

  validate :usage
  before_save :check_change

  def usage
    if people.size > 30
      errors.add :people, "There are too many people in this room"
    end
    if tables.size > 15
      errors.add :tables, "There are too many tables in this room"
    end
    # Neither people nor tables are saved to the database, if a validation error is added
  end

  def check_change
    # you can check, if there were changes to the association
    if people != people_without_deferred_save
      self.update_some_relation_data(people)
    end
    
    # you can also use the rails-internal changes hash
    if changes.include?("people")
      self.do_stuff!
    end
  end
end
```

Compatibility
=============

Tested with Rails 2.3.18, 3.2.22, 4.1.16, 4.2.20, 5.1.4 on Ruby 1.9.3, 2.2.8, 2.3.5 and JRuby 1.7, JRuby 9.1.9.0

Note, that Rails 3.2.14 associations are partly broken under JRuby cause of https://github.com/rails/rails/issues/11595
You'll need to upgrade activerecord-jdbc-adapter to >= 1.3.0.beta1, if you want to use this combination.

Gotchas
=======

1. Be aware, that the habtm association objects sometimes asks the database instead of giving you the data directly from the array. So you can get something
like

    ```ruby
    room = Room.create
    room.people << Person.create
    room.people.first # => nil, since the DB doesn't have the association saved yet
    ```

2. Also it is good to know, that the array you set to an association is stored there directly, so after setting a list, the typical association
methods are not working:

    ```ruby
    room = Room.create
    room.people.klass   # => Person
    room.people = [Person.first]
    room.people.klass   # => undefined method klass for #Array:0x007fa3b9efc2c0`
    ```
    
3. If the association is changed, it's name is stored in the changes hash. Therefore, updated_at of the containing record will be set on the next update.
   If an association is updated with the same array again, if will not be marked as changed. But if the order is changed, it will be marked!
   
   ```ruby
   people = [Person.create, Person.create]
   room = Room.create
   room.people = [people.first, people.second]
   room.changed? # => true
   room.save!
   
   room.people = [people.first, people.second]
   room.changed? # => false
   room.save!
   room.updated_at # => is still the same as above
   
   room.people = [people.second, people.first]
   room.changed? # => true
   room.save!
   room.updated_at # => got touched!
   ```

4. If you use the ID getter, you get a copy of the IDs of the objects. So changing the entries in the array won't change
   the IDs for real.
   Rails 5 acts a little bit different - it lets you change the entry, but also doesn't save it.
   deferred_associations will act the same way as in Rails 3&4.

   ```ruby
   room = Room.find(...)
   room.people_ids # [1]
   room.people_ids << 2
   room.people_ids # Rails 4: [1]
   room.people_ids # Rails 5: [1, 2], but with deferred associations, it stays at [1]
   room.save!
   room.reload
   room.people_ids # Rails 4&5: [1] # even Rails 5 doesn't save the changed array
   ```

Bugs
====

http://github.com/MartinKoerner/deferred_associations/issues

History
======

Most of the code for the habtm association was written by TylerRick for his gem [has_and_belongs_to_many_with_deferred_save](https://github.com/TylerRick/has_and_belongs_to_many_with_deferred_save)
Mainly, I changed two things:

* added compatibility for ActiveRecord 3 and 4
* removed singleton methods, because they interfere with caching

License
=======

This plugin is licensed under the BSD license.

2016 (c) Martin Körner