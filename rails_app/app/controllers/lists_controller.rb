# frozen_string_literal: true

class ListsController < ApplicationController
  def index
    lists = list_repository.all
    render template: 'lists/index', locals: { lists: lists }
  end

  def show
    list = list_repository.find_by(slug: params.require(:slug))
    list_items = list_item_repository.all_for_list(list)
    render template: 'lists/show', locals: { list: list, list_items: list_items }
  end

  def create
    list = List.new(**list_params)
    if list_repository.save(list)
      redirect_to action: :show, slug: list.slug
    else
      head :unprocessable_content
    end
  end

  def destroy
    list_repository.delete_by_slug(params.require(:slug))
    redirect_to root_url
  end

  protected

  def list_repository
    @list_repository ||= ListRepository.new(DB)
  end

  def list_item_repository
    @list_item_repository ||= ListItemRepository.new(DB)
  end

  def list_params
    params.require(:list).permit(:name)
  end
end
