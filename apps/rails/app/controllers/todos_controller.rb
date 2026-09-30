# frozen_string_literal: true

##
# The Rails app layer: HTTP in, use case calls on the domain's TodoList,
# a shared template out. The template comes from adapters/interface/,
# chosen by the composition root; Rails only adds its CSRF token.
class TodosController < ActionController::Base
  protect_from_forgery with: :exception

  prepend_view_path File.dirname(Rails.configuration.x.omni.template_path)

  def index
    render_page
  end

  def create
    todo_list.add(title_param)
    redirect_to '/', status: :see_other
  rescue Todo::Invalid => e
    render_page(error: e.message, status: :unprocessable_content)
  end

  def complete
    todo_list.complete(params[:id])
    redirect_to '/', status: :see_other
  rescue TodoList::NotFound
    render plain: 'No such todo', status: :not_found
  end

  def destroy
    todo_list.delete(params[:id])
    redirect_to '/', status: :see_other
  rescue TodoList::NotFound
    render plain: 'No such todo', status: :not_found
  end

  def health
    render json: omni.health
  end

  private

  def omni
    Rails.configuration.x.omni
  end

  def todo_list
    omni.todo_list
  end

  # A scalar title or nil. Blank is for the domain to judge, so this
  # doesn't use expect/require, which would reject it first.
  def title_param
    params.permit(:title)[:title]
  end

  def render_page(error: nil, status: :ok)
    context = omni.view_context(error: error, hidden_fields: csrf_hidden_field)
    locals = context.locals.merge(stylesheet: context.stylesheet.html_safe) # rubocop:disable Rails/OutputSafety
    render template: 'index', layout: false, locals: locals, status: status
  end

  def csrf_hidden_field
    helpers.tag.input(type: 'hidden', name: request_forgery_protection_token, value: form_authenticity_token,
                      autocomplete: 'off')
  end
end
