require "domain/entities/list"

class ListTest < Minitest::Test
  def test_list_has_a_name
    list = List.new(name: "list-name")

    assert_equal "list-name", list.name
  end
end
