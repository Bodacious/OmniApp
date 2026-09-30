# frozen_string_literal: true

require_relative 'app'

composition = Omni::CompositionRoot.boot(app: Omni::SinatraApp::NAME)

use Rack::CommonLogger
map('/__test__/reset') { run composition.test_reset_endpoint } if composition.test_mode?
run Omni::SinatraApp.compose(composition)
