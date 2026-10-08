# frozen_string_literal: true

##
# The todos on one of the signed-in user's lists. A todo is part of its
# List, so each action fetches the list (which checks it's theirs),
# changes it and saves it.
class TodosController < ApplicationController
  before_action :require_user

  def create
    change { |list| list.add(id: lists.next_identity, title: string_param(:title), tags: string_param(:tags)) }
  end

  def complete
    change { |list| list.complete(params[:id]) }
  end

  def tag
    change { |list| list.tag(params[:id], string_param(:tags)) }
  end

  def untag
    change { |list| list.untag(params[:id], params[:tag]) }
  end

  def destroy
    change { |list| list.remove(params[:id]) }
  end

  private

  def change
    list = lists.fetch(params[:list_id], owner: current_user)
    begin
      yield list
      lists.save(list)
      redirect_to "/lists/#{list.id}", status: :see_other
    rescue InvalidInput => e
      render_page('list', list: list, error: e.message, status: :unprocessable_content)
    end
  end
end
