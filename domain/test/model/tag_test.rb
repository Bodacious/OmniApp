# frozen_string_literal: true

require 'test_helper'
require 'model/tag'

class TagTest < Minitest::Test
  def test_it_is_normalised_to_lowercase_without_a_leading_hash
    assert_equal 'home', Tag.new('  #Home ').name
  end

  def test_tags_with_the_same_name_are_equal
    assert_equal Tag.new('home'), Tag.new('#HOME')
    assert_equal 1, [Tag.new('home'), Tag.new('Home')].uniq.size
  end

  def test_it_allows_letters_numbers_and_single_dashes
    %w[home q3 follow-up 2026-plans].each { |name| assert_equal name, Tag.new(name).name }
  end

  def test_malformed_tags_are_invalid
    ['not ok', 'bad!', '-dash', 'dash-', 'dou--ble', 'émoji✓'].each do |name|
      error = assert_raises(Tag::Invalid) { Tag.new(name) }

      assert_equal 'Tags can only use letters, numbers and dashes', error.message
    end
  end

  def test_a_blank_tag_is_invalid
    assert_raises(Tag::Invalid) { Tag.new(' # ') }
  end

  def test_a_long_tag_is_invalid
    error = assert_raises(Tag::Invalid) { Tag.new('a' * 25) }

    assert_equal 'Tags can be at most 24 characters', error.message
  end

  def test_invalid_tags_are_invalid_input
    assert_raises(InvalidInput) { Tag.new('bad!') }
  end

  def test_list_parses_free_text_into_sorted_unique_tags
    assert_equal %w[home urgent work], Tag.list('work, #Home urgent,,home').map(&:name)
  end

  def test_list_accepts_names_and_tags
    assert_equal %w[a b], Tag.list(['b', Tag.new('a'), 'B']).map(&:name)
  end

  def test_list_of_nothing_is_empty
    assert_empty Tag.list('  , ')
    assert_empty Tag.list(nil)
  end
end
