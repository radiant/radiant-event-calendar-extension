class RecurrenceDataset < Dataset::Base  
  def load
    create_record RecurrenceRule, :date_limited, :period => 'weekly', :interval => 1, :limiting_date => DateTime.civil(2009, 2, 24)
    create_record RecurrenceRule, :count_limited, :period => 'monthly', :interval => 2, :limiting_count => 12
    create_record RecurrenceRule, :unlimited, :period => 'daily', :interval => 2
  end
end
