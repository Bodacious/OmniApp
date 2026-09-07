# frozen_string_literal: true

module DatabaseTruncation
  def after_teardown
    DB[:list_items].truncate
    DB[:lists].truncate
  end
end
