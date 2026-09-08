# frozen_string_literal: true

require_relative 'dom'
require_relative 'lists_view'

##
# Wires the DOM to the domain models via a repository pair chosen at
# runtime, so switching the "Persistence backend" dropdown swaps List
# and ListItem storage without reloading the page -- proving the same
# domain model works against multiple persistence backends, this time
# entirely client-side.
#
# Takes its backends as a Hash of name => callable returning a
# [list_repository, list_item_repository] pair, so it never learns
# what any of them are actually backed by.
class ListsApp
  def initialize(backends)
    @backends = backends
  end

  def start
    @backend_key = 'memory'
    @repositories = {}
    @selected_list = nil
    @view = ListsView.new

    bind_events
    render
  end

  private

  def bind_events
    bind_backend_selector
    bind_list_events
    bind_item_events
  end

  def bind_backend_selector
    Dom.on('#backend-select', 'change') do |_event|
      @backend_key = Dom.value('#backend-select')
      @selected_list = nil
      render
    end
  end

  def bind_list_events
    Dom.on('#new-list-form', 'submit') do |event|
      Dom.prevent_default(event)
      create_list
    end

    Dom.on_delegated('#lists', 'click', '[data-action="select-list"]') do |element, _event|
      @selected_list = list_repository.find_by_slug(Dom.data(element, 'slug'))
      render
    end

    Dom.on_delegated('#lists', 'click', '[data-action="delete-list"]') do |element, _event|
      delete_list(Dom.data(element, 'slug'))
    end

    Dom.on('#delete-list-button', 'click') do |_event|
      delete_list(@selected_list.slug) if @selected_list
    end
  end

  def bind_item_events
    Dom.on('#new-item-form', 'submit') do |event|
      Dom.prevent_default(event)
      create_item
    end

    Dom.on_delegated('#list-items', 'click', '[data-action="delete-item"]') do |element, _event|
      list_item_repository.delete(Dom.data(element, 'id').to_i)
      render
    end
  end

  def create_list
    name = Dom.value('#new-list-name')
    return if name.strip.empty?

    list_repository.save(List.new(name: name))
    Dom.set_value('#new-list-name', '')
    render
  end

  def create_item
    return unless @selected_list

    summary = Dom.value('#new-item-summary')
    return if summary.strip.empty?

    list_item_repository.save(ListItem.new(summary: summary, list_id: @selected_list.id))
    Dom.set_value('#new-item-summary', '')
    render
  end

  def delete_list(slug)
    list_repository.delete_by_slug(slug)
    @selected_list = nil if @selected_list&.slug == slug
    render
  end

  def list_repository
    repositories_for(@backend_key)[0]
  end

  def list_item_repository
    repositories_for(@backend_key)[1]
  end

  def repositories_for(key)
    @repositories[key] ||= backends.fetch(key).call
  end

  attr_reader :backends

  def render
    @view.render(list_repository, list_item_repository, @selected_list)
  end
end
