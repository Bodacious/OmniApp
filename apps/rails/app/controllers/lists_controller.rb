# frozen_string_literal: true

##
# The signed-in user's lists, through the domain's TodoService. Someone
# else's list is TodoService::NotFound, which ApplicationController
# turns into a 404.
class ListsController < ApplicationController
  before_action :require_user

  def index
    render_page('lists')
  end

  def create
    list = todo_service.create_list(current_user, string_param(:name))
    redirect_to "/lists/#{list.id}", status: :see_other
  rescue InvalidInput => e
    render_page('lists', error: e.message, status: :unprocessable_content)
  end

  def show
    render_page('list', list: todo_service.list(current_user, params[:list_id]), tag: string_param(:tag))
  end

  def destroy
    todo_service.delete_list(current_user, params[:list_id])
    redirect_to '/', status: :see_other
  end
end
