# frozen_string_literal: true

module DatabaseTruncation
  def after_teardown
    DB[:lists].truncate
  end
end
