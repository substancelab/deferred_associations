Make ActiveRecord defer/postpone saving the records you add to an habtm (has_and_belongs_to_many) association until you call model.save, allowing validation in the style of normal attributes.

How to install
==============

    sudo gem install deferred_associations

Usage
=====

    class Room < ActiveRecord::Base
      has_and_belongs_to_many_with_deferred_save :people
      has_many_with_deferred_save :tables # TODO this doesn't work yet
    end

Motivation
==========

Let's say you want to validate the room.people collections and prevent the user from adding more people to the room than will fit. If they do try to add more people than will fit, you want to display a nice error message on the page and let them try again...

This isn't possible using the standard has_and_belongs_to_many due to these two problems:

1. When we do the assignment to our collection (room.people = whatever), it immediately saves it in our join table (people_rooms) rather than waiting until we call room.save.

2. You can "validate" using habtm's :before_add option ... but it any errors added there end up being ignored/lost. The only way to abort the save from a before_add seems to be to raise an exception... 

But we don't want to raise an exception when the user violates our validation; we want validation of the people collection to be handled the same as any other field in the Room model: we want it to simply add an error to the Room model's error array which we can than display on the form with the other input errors.

has_and_belongs_to_many_with_deferred_save solves this problem by overriding the setter method for your collection (people=), causing it to store the new members in a temporary variable (unsaved_people) rather than saving it immediately.

You can then validate the unsaved collection as you would any other attribute, adding to self.errors if something is invalid about the collection (too many members, etc.).

The unsaved collection is automatically saved when you call save on the model.


Compatibility
=============

Tested with Rails 2.3.14, 3.2.2

Gotchas
=======

1. If you want to add before_save filters, which check the difference in your habtm's association, be sure to add them *before* the validation

   class Room
     before_save :check_diff
     has_and_belongs_to_many_with_deferred_save :people
     #before_save :check_diff  <-- this doesn't work, because the people array is saved already

     def check_diff
       if people != people_without_deferred_save
        # ...
       end
     end
   end

   Same applies for Rails 2.3's "before_save" method. When it is called, the before_save callbacks from the module were executed already and they wouldn't
   notice any change in the association.

2. Be aware, that tha habtm association objects sometimes asks the database instead of giving you the data directly from the array. So you can get something
   like

   room = Room.new
   room.people << Person.create
   room.people.first # => nil, since the DB doesn't have the association saved yet

Bugs
====

http://github.com/neogrande/deferred_associations/issues

Thanks
======

A huge Thank you goes to [TylerRick](https://github.com/TylerRick), which wrote the original has_and_belongs_to_many_with_deferred gem for Rails 2.3.
It helped us in many projects.

History
=======

It started as a [post](http://www.ruby-forum.com/topic/81095) to the Rails mailing list asking how to validate a has_and_belongs_to_many collection/association.

License
=======

This plugin is licensed under the BSD license.

2012 (c) neogrande
2010 (c) Contributors
2007 (c) QualitySmith, Inc.
