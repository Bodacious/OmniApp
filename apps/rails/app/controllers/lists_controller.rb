# frozen_string_literal: true

##
# The signed-in user's lists, through the domain's ListRepository.
# Someone else's list is NotFound, which ApplicationController turns
# into a 404.
class ListsController < ApplicationController
  before_action :require_user

  def index
    render_page('lists')
  end

  def create
    list = lists.save(List.new(id: lists.next_identity, owner_id: current_user.id, name: string_param(:name)))
    redirect_to "/lists/#{list.id}", status: :see_other
  rescue InvalidInput => e
    render_page('lists', error: e.message, status: :unprocessable_content)
  end

  def show
    render_page('list', list: lists.fetch(params[:list_id], owner: current_user), tag: string_param(:tag))
  end

  def destroy
    lists.remove(lists.fetch(params[:list_id], owner: current_user))
    redirect_to '/', status: :see_other
  end
end
