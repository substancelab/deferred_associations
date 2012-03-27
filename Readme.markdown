Make ActiveRecord defer/postpone saving the records you add to an habtm (has_and_belongs_to_many) or has_many association
until you call model.save, allowing validation in the style of normal attributes.

[![Build Status](https://secure.travis-ci.org/MartinKoerner/deferred_associations.png?branch=master)](http://travis-ci.org/MartinKoerner/deferred_associations) [![Dependency Status](https://gemnasium.com/MartinKoerner/deferred_associatons.png?travis)](https://gemnasium.com/MartinKoerner/deferred_associatons)

How to install
==============

    gem install deferred_associations

Usage
=====

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
          self.updated_at = Time.now.utc
        end
      end
    end

Compatibility
=============

Tested with Rails 2.3.14, 3.2.2 on Ruby 1.8.7, 1.9.3 and JRuby 1.6.6

Gotchas
=======

Be aware, that the habtm association objects sometimes asks the database instead of giving you the data directly from the array. So you can get something
like

    room = Room.new
    room.people << Person.create
    room.people.first # => nil, since the DB doesn't have the association saved yet

Bugs
====

http://github.com/MartinKoerner/deferred_associations/issues

History
======

Most of the code for the habtm association was written by TylerRick for his gem [has_and_belongs_to_many_with_deferred_save](https://github.com/TylerRick/has_and_belongs_to_many_with_deferred_save)
Mainly, I changed two things:

* added ActiveRecord 3 compatibility
* removed singleton methods, because they interfere with caching

License
=======

This plugin is licensed under the BSD license.

2012 (c) Martin Körner