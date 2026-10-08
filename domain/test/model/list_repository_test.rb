# frozen_string_literal: true

require 'test_helper'
require 'model/list_repository'
require 'model/user'

class ListRepositoryTest < ActiveSupport::TestCase
  test "#fetch when the list is the owner's returns it" do
    list = List.new(id: 'l1', owner_id: 'ada', name: 'Groceries')
    repository = Class.new { include ListRepository }.new
    repository.stubs(:find).with('l1').returns(list)

    ada = User.new(id: 'ada', email: 'ada@example.com', password_digest: 'd')

    assert_same list, repository.fetch('l1', owner: ada)
  end

  test "#fetch when the list is someone else's raises NotFound" do
    repository = Class.new { include ListRepository }.new
    repository.stubs(:find).with('l1').returns(List.new(id: 'l1', owner_id: 'ada', name: 'Groceries'))
    bob = User.new(id: 'bob', email: 'bob@example.com', password_digest: 'd')

    error = assert_raises(NotFound) { repository.fetch('l1', owner: bob) }

    assert_equal 'No such list', error.message
  end

  test '#fetch when there is no such list raises NotFound' do
    repository = Class.new { include ListRepository }.new
    repository.stubs(:find).returns(nil)
    ada = User.new(id: 'ada', email: 'ada@example.com', password_digest: 'd')

    assert_raises(NotFound) { repository.fetch('missing', owner: ada) }
  end

  test '#fetch when the id is nil looks for an empty one' do
    repository = Class.new { include ListRepository }.new
    repository.expects(:find).with('').returns(nil)
    ada = User.new(id: 'ada', email: 'ada@example.com', password_digest: 'd')

    assert_raises(NotFound) { repository.fetch(nil, owner: ada) }
  end

  test 'the storage methods when not implemented raise NotImplementedError' do
    repository = Class.new { include ListRepository }.new

    [-> { repository.next_identity }, -> { repository.find('l1') }, -> { repository.owned_by(nil) },
     -> { repository.save(nil) }, -> { repository.remove(nil) }].each do |call|
      assert_raises(NotImplementedError, &call)
    end
  end
end
