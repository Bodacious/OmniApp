# frozen_string_literal: true

module Lists
  class ItemsController < ApplicationController
    def create
      list_item = ListItem.new(**list_item_params)
      if list_item_repository.save_list_item_to_list(list_slug: params[:list_slug],
                                                     list_item: list_item)
        redirect_to("/lists/#{params[:list_slug]}")
      else
        head :unprocessable_content
      end
    end

    def destroy
      if list_item_repository.delete_list_item(list_slug: params.require(:list_slug),
                                               id: params.require(:id))
        redirect_to list_url(slug: params.require(:list_slug))
      else
        head :not_found
      end
    end

    private

    def list_item_params
      params.require(:list_item).permit(:summary)
    end

    def list_item_repository
      @list_item_repository ||= ListItemRepository.new(DB)
    end
  end
end
