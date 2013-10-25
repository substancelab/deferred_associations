require 'spec_helper'

describe 'has_many_with_deferred_save' do

  before :each do
    @room    = Room.create(:maximum_occupancy => 2)
    @table1  = Table.create(:room_id => @room.id)
    @table2  = Table.create
    @chair1  = Chair.create(:table_id => @table1.id, :name => "First")
    @chair2  = Chair.create(:table_id => @table2.id, :name => "Second")
  end

  it 'should work with tables obj setter/getter' do
    @room.tables.should == [@table1]
    @room.tables = [@table1, @table2]
    Room.find(@room.id).tables.should == [@table1] # not saved yet
    @room.save.should be_true
    Room.find(@room.id).tables.should == [@table1, @table2]
  end

  it 'should work with tables obj setter/getter, used twice' do
      @room.tables.should == [@table1]
      @room.tables = [@table1]
      @room.tables = [@table1, @table2]
      Room.find(@room.id).tables.should == [@table1] # not saved yet
      @room.save.should be_true
      Room.find(@room.id).tables.should == [@table1, @table2]
    end

  it 'should work with tables id setter/getter' do
    @room.table_ids.should == [@table1.id]
    @room.table_ids = [@table1.id, @table2.id]
    Room.find(@room.id).table_ids.should == [@table1.id] # not saved yet
    @room.save.should be_true
    Room.find(@room.id).table_ids.should == [@table1.id, @table2.id]
  end

  it 'should work with tables id setter/getter, used twice' do
      @room.table_ids.should == [@table1.id]
      @room.table_ids = [@table1.id]
      @room.table_ids = [@table1.id, @table2.id]
      Room.find(@room.id).table_ids.should == [@table1.id] # not saved yet
      @room.save.should be_true
      Room.find(@room.id).table_ids.should == [@table1.id, @table2.id]
    end

  it 'should work with array methods' do
    @room.tables.should == [@table1]
    @room.tables << @table2
    Room.find(@room.id).tables.should == [@table1] # not saved yet
    @room.save.should be_true
    Room.find(@room.id).tables.should == [@table1, @table2]
    @room.tables -= [@table1]
    Room.find(@room.id).tables.should == [@table1, @table2]
    @room.save.should be_true
    Room.find(@room.id).tables.should == [@table2]
  end

  it 'should reload temporary objects' do
    @room.tables << @table2
    @room.tables.should == [@table1, @table2]
    @room.reload
    @room.tables.should == [@table1]
  end

  it "should be dumpable with Marshal" do
    lambda { Marshal.dump(@room.tables) }.should_not raise_exception
    lambda { Marshal.dump(Room.new.tables) }.should_not raise_exception
  end

  describe 'with through option' do
    it 'should have a correct list' do
      # TODO these testcases need to be improved
      @room.chairs.should == [@chair1] # through table1
      @room.tables << @table2
      @room.save.should be_true
      @room.chairs.should == [@chair1] # association doesn't reload itself
      @room.reload
      @room.chairs.should == [@chair1, @chair2]
    end

    it 'should defer association methods' do
      @room.chairs.first.should == @chair1
      if ar4?
        @room.chairs.where(:name => "First").should == [@chair1]
      else
        @room.chairs.find(:all, :conditions => {:name => "First"}).should == [@chair1]
      end

      lambda {
        @room.chairs.create(:name => "New one")
      }.should raise_error(ActiveRecord::HasManyThroughCantAssociateThroughHasOneOrManyReflection)
    end

    it "should be dumpable with Marshal" do
      lambda { Marshal.dump(@room.chairs) }.should_not raise_exception
      lambda { Marshal.dump(Room.new.chairs) }.should_not raise_exception
    end
  end
end