require 'spec_helper'
require 'has_and_belongs_to_many_with_deferred_save'

if ar4_or_more?
  describe 'ActiveRecord4/5 specials' do
    before :all do
      #ActiveRecord::Base.logger = Logger.new(STDOUT) # uncomment for debugging statements
      @people = []
      @people << Person.create(name: 'Filbert')
      @people << Person.create(name: 'Miguel')
      @people << Person.create(name: 'Rainer')
      @room1 = Room.create! maximum_occupancy: 2, people: @people[1..2]
      @room2 = Room.create! maximum_occupancy: 2, people: @people[0..1]
      @room3 = Room.create! maximum_occupancy: 2
    end

    after :all do
      Person.delete_all
      Room.delete_all
      Person.connection.execute('DELETE FROM people_rooms')
    end

    describe 'queries' do #
      it 'should not preload, if option is not specified' do
        rooms = Room.where(id: [@room1.id, @room2.id, @room3.id])
        rooms = rooms.to_a # execute original query
        room1 = rooms.first
        room2 = rooms.second
        room3 = rooms.third

        # association is not autoloaded, but will be loaded on access
        expect(room1.people_without_deferred_save.loaded?).to be false
        expect(room2.people_without_deferred_save.loaded?).to be false
        expect(room3.people_without_deferred_save.loaded?).to be false

        # accessing the deferred assotiation will load it anyway
        expect(ActiveRecord::Base).to receive(:connection).at_least(:once).and_call_original
        expect(room1.people.loaded?).to be true

        expect(room1.people.map(&:name)).to match_array(%w(Miguel Rainer))
        expect(room2.people.map(&:name)).to match_array(%w(Filbert Miguel))
        expect(room3.people.map(&:name)).to match_array(%w())
      end

      it 'should preload, if option is specified' do
        rooms = Room.where(id: [@room1.id, @room2.id, @room3.id]).preload(:people)
        rooms = rooms.to_a # execute original query, together with preloading the association
        room1 = rooms.first
        room2 = rooms.second
        room3 = rooms.third

        # association is autoloaded
        expect(room1.people_without_deferred_save.loaded?).to be true
        expect(room2.people_without_deferred_save.loaded?).to be true
        expect(room3.people_without_deferred_save.loaded?).to be true

        expect(ActiveRecord::Base).not_to receive(:connection)
        # deferred association is also already loaded
        expect(room1.people.loaded?).to be true

        expect(room1.people.map(&:name)).to match_array(%w(Miguel Rainer))
        expect(room2.people.map(&:name)).to match_array(%w(Filbert Miguel))
        expect(room3.people.map(&:name)).to match_array(%w())
      end

      it 'should preload with non-deferred association' do
        rooms = Room.where(id: [@room1.id, @room2.id, @room3.id]).preload(:people_without_deferring)
        rooms = rooms.to_a # execute original query, together with preloading the association
        room1 = rooms.first
        room2 = rooms.second
        room3 = rooms.third
        # association is autoloaded
        expect(room1.people_without_deferring.loaded?).to be true
        expect(room2.people_without_deferring.loaded?).to be true
        expect(room3.people_without_deferring.loaded?).to be true

        expect(ActiveRecord::Base).not_to receive(:connection)

        expect(room1.people_without_deferring.map(&:name)).to match_array(%w(Miguel Rainer))
        expect(room2.people_without_deferring.map(&:name)).to match_array(%w(Filbert Miguel))
        expect(room3.people_without_deferring.map(&:name)).to match_array(%w())
      end
    end
  end
end
