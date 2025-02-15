module DatabaseTruncation
  def after_teardown
    DB[:lists].truncate
  end
end