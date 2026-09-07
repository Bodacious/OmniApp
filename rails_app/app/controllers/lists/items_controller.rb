# frozen_string_literal: true

module Lists
  class ItemsController < ApplicationController
    def create
      list = list_repository.find_by_slug(params[:list_slug])
      return head(:not_found) unless list

      list_item = ListItem.new(**list_item_params)
      list_item.list_id = list.id
      list_item_repository.save(list_item)
      redirect_to("/lists/#{params[:list_slug]}")
    end

    def destroy
      item = owned_item(params.require(:list_slug), params.require(:id))

      if item && list_item_repository.delete(item.id)
        redirect_to list_url(slug: params[:list_slug])
      else
        head :not_found
      end
    end

    private

    def owned_item(list_slug, id)
      list = list_repository.find_by_slug(list_slug)
      return unless list

      item = list_item_repository.find(id.to_i)
      item if item&.list_id == list.id
    end

    def list_item_params
      params.require(:list_item).permit(:summary)
    end

    def list_repository
      @list_repository ||= ListRepository.new(DB)
    end

    def list_item_repository
      @list_item_repository ||= ListItemRepository.new(DB)
    end
  end
end
