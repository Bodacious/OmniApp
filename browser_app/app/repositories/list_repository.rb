# frozen_string_literal: true
# backtick_javascript: true
#
require "promise"
require 'json'

class ListRepository
  def all
    [{name: "Shopping list", id: 1}]
  end

  def find_by_name(name)
    all.then do |data|
      data.find { |list| list['name'] == name }
    end
  end
end
