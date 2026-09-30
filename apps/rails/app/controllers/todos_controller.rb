# frozen_string_literal: true

##
# The Rails app layer: HTTP in, use case calls on the domain's
# TodoService, a shared template out. The template comes from
# adapters/interface/, chosen by the composition root; Rails only adds
# its CSRF token.
class TodosController < ActionController::Base
  protect_from_forgery with: :exception

  prepend_view_path File.dirname(Rails.configuration.x.omni.template_path)

  def index
    render_page(tag: string_param(:tag))
  end

  def create
    todo_service.add(string_param(:title), string_param(:tags))
    redirect_to '/', status: :see_other
  rescue InvalidInput => e
    render_page(error: e.message, status: :unprocessable_content)
  end

  def complete
    change { todo_service.complete(params[:id]) }
  end

  def tag
    change { todo_service.tag(params[:id], string_param(:tags)) }
  end

  def untag
    change { todo_service.untag(params[:id], params[:tag]) }
  end

  def destroy
    change { todo_service.delete(params[:id]) }
  end

  def health
    render json: omni.health
  end

  private

  def omni
    Rails.configuration.x.omni
  end

  def todo_service
    omni.todo_service
  end

  # Runs a use case on an existing todo, then back to the list.
  def change
    yield
    redirect_to '/', status: :see_other
  rescue InvalidInput => e
    render_page(error: e.message, status: :unprocessable_content)
  rescue TodoService::NotFound
    render plain: 'No such todo', status: :not_found
  end

  # A scalar string or nil, as strong params would allow. Whether it's
  # valid (blank titles included) is for the domain to judge, so this
  # doesn't use expect/require, which would reject blanks first.
  def string_param(name)
    value = params[name]
    value if value.is_a?(String)
  end

  def render_page(error: nil, tag: nil, status: :ok)
    context = omni.view_context(error: error, tag: tag, hidden_fields: csrf_hidden_field)
    locals = context.locals.merge(stylesheet: context.stylesheet.html_safe) # rubocop:disable Rails/OutputSafety
    render template: 'index', layout: false, locals: locals, status: status
  end

  def csrf_hidden_field
    helpers.tag.input(type: 'hidden', name: request_forgery_protection_token, value: form_authenticity_token,
                      autocomplete: 'off')
  end
end
