# frozen_string_literal: true

##
# Raised when input breaks one of the model's rules: a blank title, a
# malformed tag, too many tags. The message is written for the person
# who typed the input, so apps show it as it is.
class InvalidInput < StandardError; end
