# frozen_string_literal: true

module Assertions
  ##
  # Assert that the page has given content (text)
  # @param [String] content The content to test for
  # @param [String] message A message to display if content not found
  # @return [void]
  def assert_content(content, message = nil)
    message ||= "Expected page to have content '#{content}' but did not"

    assert page.has_content?(content.to_s), message
  end

  def refute_content(content, message = nil)
    message ||= "Expected page to not have content '#{content}' but did"

    refute page.has_content?(content.to_s), message
  end

  def assert_current_path(path, message = nil)
    message ||= "Expected current path to be '#{content}' but #{current_path}"

    assert_equal path, current_path, message
  end
end
