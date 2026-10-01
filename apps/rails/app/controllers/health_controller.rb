# frozen_string_literal: true

# What's running, as the composition root built it.
class HealthController < ActionController::Base
  def show
    render json: Rails.configuration.x.omni.health
  end
end
