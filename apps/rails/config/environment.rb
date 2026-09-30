# frozen_string_literal: true

require_relative 'application'

# The composition root reads OMNI_* and builds the adapters before Rails
# initializes, so routes and controllers can use what it built.
Rails.application.config.x.omni = Omni::CompositionRoot.boot(app: 'rails')

Rails.application.initialize!
