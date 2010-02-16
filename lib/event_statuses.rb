module EventStatuses
  def self.included(base)
    base.class_eval {
      cattr_accessor :statuses
      extend ClassMethods
      include InstanceMethods
    }
    
    base.add_status(:id => 5, :name => 'Submitted')
    base.add_status(:id => 200, :name => 'Imported')
  end
  
  module ClassMethods
    def add_status(properties)
      statuses.push(Status.new(properties))
    end
  end

  module InstanceMethods
    def to_s
      id
    end
  end
end
