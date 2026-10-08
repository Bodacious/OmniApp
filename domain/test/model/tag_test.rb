# frozen_string_literal: true

require 'test_helper'
require 'model/tag'

class TagTest < ActiveSupport::TestCase
  test '.new normalises the name to lowercase without a leading hash' do
    assert_equal 'home', Tag.new('  #Home ').name
  end

  test '.new allows letters, numbers and single dashes' do
    %w[home q3 follow-up 2026-plans].each { |name| assert_equal name, Tag.new(name).name }
  end

  test '.new when the name is malformed raises Invalid' do
    ['not ok', 'bad!', '-dash', 'dash-', 'dou--ble', 'émoji✓'].each do |name|
      error = assert_raises(Tag::Invalid) { Tag.new(name) }

      assert_equal 'Tags can only use letters, numbers and dashes', error.message
    end
  end

  test '.new when the name is blank raises Invalid' do
    assert_raises(Tag::Invalid) { Tag.new(' # ') }
  end

  test '.new when the name is too long raises Invalid' do
    error = assert_raises(Tag::Invalid) { Tag.new('a' * 25) }

    assert_equal 'Tags can be at most 24 characters', error.message
  end

  test '.new when the name is malformed raises InvalidInput' do
    assert_raises(InvalidInput) { Tag.new('bad!') }
  end

  test '.list parses free text into sorted, unique tags' do
    assert_equal %w[home urgent work], Tag.list('work, #Home urgent,,home').map(&:name)
  end

  test '.list accepts names and tags' do
    assert_equal %w[a b], Tag.list(['b', Tag.new('a'), 'B']).map(&:name)
  end

  test '.list of blank text is empty' do
    assert_empty Tag.list('  , ')
  end

  test '.list of nil is empty' do
    assert_empty Tag.list(nil)
  end

  test '#== when the names normalise the same is true' do
    assert_equal Tag.new('home'), Tag.new('#HOME')
  end

  test '#hash when the names normalise the same is the same' do
    assert_equal 1, [Tag.new('home'), Tag.new('Home')].uniq.size
  end

  test '#<=> orders tags by name' do
    assert_equal %w[a b c], [Tag.new('c'), Tag.new('a'), Tag.new('b')].sort.map(&:name)
  end

  test '#to_s is the name' do
    assert_equal 'home', Tag.new('#Home').to_s
  end
end
