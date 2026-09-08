# frozen_string_literal: true

module DatabaseTruncation
  def after_teardown
    DATABASE[:list_items].truncate
    DATABASE[:lists].truncate
  end
end
