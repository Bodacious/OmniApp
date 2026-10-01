# frozen_string_literal: true

##
# The todos on one of the signed-in user's lists: each action opens the
# list through the domain's TodoService (which checks it's theirs) and
# runs one use case on it.
class TodosController < ApplicationController
  before_action :require_user

  def create
    change { |list| list.add(string_param(:title), string_param(:tags)) }
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
    change { |list| list.delete(params[:id]) }
  end

  private

  def change
    list = todo_service.list(current_user, params[:list_id])
    begin
      yield list
      redirect_to "/lists/#{list.id}", status: :see_other
    rescue InvalidInput => e
      render_page('list', list: list, error: e.message, status: :unprocessable_content)
    end
  end
end
