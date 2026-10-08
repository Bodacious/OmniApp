# frozen_string_literal: true

##
# Signing up, in and out: the domain's User and UserRepository, plus
# the Rails session that remembers who signed in.
class AccountsController < ApplicationController
  def sign_in_form
    return redirect_to('/', status: :see_other) if current_user

    render_page('sign_in')
  end

  def sign_in
    start_session(users.account_for(string_param(:email)).authenticate(string_param(:password), password_hasher))
  rescue InvalidInput => e
    render_page('sign_in', error: e.message, email: string_param(:email), status: :unprocessable_content)
  end

  def sign_up_form
    return redirect_to('/', status: :see_other) if current_user

    render_page('sign_up')
  end

  def sign_up
    start_session(users.add(User.register(id: users.next_identity, email: string_param(:email),
                                          password: string_param(:password), hasher: password_hasher)))
  rescue InvalidInput => e
    render_page('sign_up', error: e.message, email: string_param(:email), status: :unprocessable_content)
  end

  def sign_out
    reset_session
    redirect_to '/sign_in', status: :see_other
  end

  private

  # A fresh session for each sign-in, so a session id can't be fixed in
  # advance.
  def start_session(user)
    reset_session
    session[:user_id] = user.id
    redirect_to '/', status: :see_other
  end
end
