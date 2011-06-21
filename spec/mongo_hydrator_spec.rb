require 'spec_helper'

# The heavy lifting is tested in DocumentHydrator's tests. Here we just
# make sure that things are fetched from the database as expected.

describe MongoHydrator, '#hydrate_document' do
  before(:each) do
    db = Mongo::Connection.new.db('mongo_hydrator_test')
    @users_collection = db['users']
    @users_collection.remove
    @users_collection.insert(:_id => 1, :name => 'Obi-Wan Kenobi', :occupation => 'Hermit')
    @users_collection.insert(:_id => 2, :name => 'Han Solo', :occupation => 'Smuggler')
    @users_collection.insert(:_id => 3, :name => 'Luke Skywalker', :occupation => 'Farmer')
    @users_collection.insert(:_id => 4, :name => 'Yoda', :occupation => 'Jedi Master')
  end

  context 'for a hydrator with no options' do
    before(:each) do
      @document = {
        "user_id" => 1,
        "text" => "May the Force be with you.",
        "liker_ids" => [3, 4],
        "comments" => [
          { "user_id" => 2,
            "text" => "Thanks, but I'll stick with my blaster."
          },
          { "user_id" => 3,
            "text" => "Hey, show some respect!"
          }
        ]
      }
      @hydrator = MongoHydrator.new(@users_collection)
    end

    it 'hydrates the document' do
      expected = @document.dup
      expected['user'] = @users_collection.find_one(:_id => expected.delete('user_id'))
      expected['likers'] = expected.delete('liker_ids').map do |user_id|
        @users_collection.find_one(:_id => user_id)
      end
      expected['comments'].each do |comment|
        comment['user'] = @users_collection.find_one(:_id => comment.delete('user_id'))
      end

      @hydrator.hydrate_document(@document, ['user_id', 'liker_ids', 'comments.user_ids'])
      @document.should == expected
    end
  end

  context 'for a hydrator with a limited field set' do
    before(:each) do
      @document = {
        "user_id" => 1,
        "text" => "May the Force be with you.",
        "liker_ids" => [3, 4],
        "comments" => [
          { "user_id" => 2,
            "text" => "Thanks, but I'll stick with my blaster."
          },
          { "user_id" => 3,
            "text" => "Hey, show some respect!"
          }
        ]
      }
      @options = { :fields => { :_id => 0, :name => 1 } }
      @hydrator = MongoHydrator.new(@users_collection, @options)
    end

    it 'hydrates the document, using only the requested fields' do
      expected = @document.dup
      expected['user'] = @users_collection.find_one({ :_id => expected.delete('user_id') }, @options)
      expected['likers'] = expected.delete('liker_ids').map do |user_id|
        @users_collection.find_one({ :_id => user_id }, @options)
      end
      expected['comments'].each do |comment|
        comment['user'] = @users_collection.find_one({ :_id => comment.delete('user_id') }, @options)
      end

      @hydrator.hydrate_document(@document, ['user_id', 'liker_ids', 'comments.user_ids'])
      @document.should == expected
    end
  end
end