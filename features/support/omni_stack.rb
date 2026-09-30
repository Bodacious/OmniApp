# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

##
# The specs' view of the stack under test: where it is, what it should
# be, and the test-only reset endpoint every stack mounts when
# OMNI_ENV=test.
module OmniStack
  AXES = { 'app' => 'OMNI_APP', 'persistence' => 'OMNI_PERSISTENCE', 'interface' => 'OMNI_INTERFACE' }.freeze

  module_function

  def base_url
    ENV.fetch('OMNI_BASE_URL') do
      raise 'OMNI_BASE_URL is not set. Run the specs with bin/omni-test, which boots a stack and sets it.'
    end
  end

  # The stack OMNI_* says should be running, as { axis => value }.
  def expected
    AXES.to_h do |axis, name|
      [axis, ENV.fetch(name) { raise "#{name} is not set; the specs need it to know which stack to expect." }]
    end
  end

  def reset!
    response = Net::HTTP.post(uri('/__test__/reset'), '')
    return if response.is_a?(Net::HTTPSuccess)

    raise "POST /__test__/reset returned #{response.code}. Was the stack booted with OMNI_ENV=test?"
  end

  def verify_health!
    response = Net::HTTP.get_response(uri('/health'))
    raise "GET /health returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    actual = JSON.parse(response.body)
    return if actual == expected

    raise "The running stack is not the one under test.\n  expected (OMNI_*): #{expected}\n  actual (/health):  #{actual}"
  end

  def uri(path)
    URI.join(base_url, path)
  end
end
