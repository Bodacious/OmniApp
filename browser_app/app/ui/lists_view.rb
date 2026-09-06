# frozen_string_literal: true

require_relative 'dom'

##
# Renders the lists index and the selected list's detail panel into
# the DOM. Pure rendering: no event handling, no repository writes.
class ListsView
  def render(list_repository, list_item_repository, selected_list)
    render_lists(list_repository)
    render_detail(list_item_repository, selected_list)
  end

  private

  def render_lists(list_repository)
    rows = list_repository.all.map do |list|
      <<~HTML
        <li>
          <span data-action="select-list" data-slug="#{list.slug}">#{escape(list.name)}</span>
          <button data-action="delete-list" data-slug="#{list.slug}">Delete</button>
        </li>
      HTML
    end
    Dom.set_html('#lists', rows.join)
  end

  def render_detail(list_item_repository, selected_list)
    unless selected_list
      Dom.set_hidden('#list-detail', true)
      return
    end

    Dom.set_hidden('#list-detail', false)
    Dom.set_html('#list-detail-name', escape(selected_list.name))
    render_items(list_item_repository, selected_list)
  end

  def render_items(list_item_repository, selected_list)
    rows = list_item_repository.all_for_list(selected_list).map do |item|
      <<~HTML
        <li>
          #{escape(item.summary)}
          <button data-action="delete-item" data-id="#{item.id}">Remove</button>
        </li>
      HTML
    end
    Dom.set_html('#list-items', rows.join)
  end

  def escape(text)
    text.to_s
        .gsub('&', '&amp;')
        .gsub('<', '&lt;')
        .gsub('>', '&gt;')
        .gsub('"', '&quot;')
  end
end
