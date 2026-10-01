# frozen_string_literal: true

##
# The Rails app layer's shared plumbing: who is signed in (kept in the
# Rails session; the domain only ever sees a User), rendering the shared
# page template, and Rails' CSRF token, which reaches every form through
# the template's hidden_fields.
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  prepend_view_path File.dirname(Rails.configuration.x.omni.template_path)

  rescue_from TodoService::NotFound do |error|
    render plain: error.message, status: :not_found
  end

  private

  def omni
    Rails.configuration.x.omni
  end

  def accounts
    omni.accounts
  end

  def todo_service
    omni.todo_service
  end

  def current_user
    @current_user ||= accounts.find(session[:user_id])
  end

  def require_user
    redirect_to '/sign_in', status: :see_other unless current_user
  end

  # A scalar string or nil, as strong params would allow. Whether it's
  # valid (blank titles included) is for the domain to judge, so this
  # doesn't use expect/require, which would reject blanks first.
  def string_param(name)
    value = params[name]
    value if value.is_a?(String)
  end

  def render_page(page, status: :ok, **options)
    context = omni.view_context(page, user: current_user, hidden_fields: csrf_hidden_field, **options)
    locals = context.locals.merge(stylesheet: context.stylesheet.html_safe) # rubocop:disable Rails/OutputSafety
    render template: 'index', layout: false, locals: locals, status: status
  end

  def csrf_hidden_field
    helpers.tag.input(type: 'hidden', name: request_forgery_protection_token, value: form_authenticity_token,
                      autocomplete: 'off')
  end
end
