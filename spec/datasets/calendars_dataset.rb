class CalendarsDataset < Dataset::Base
  uses :calendar_sites if defined? Site
  
  def load
    create_calendar :dummy
  end
  
  helpers do
    def create_calendar(name, attributes={})
      attributes = calendar_attributes(attributes.update(:name => name))
      calendar = create_model Calendar, name.symbolize, attributes
    end
    
    def calendar_attributes(attributes={})
      name = attributes[:name] || "Default"
      symbol = name.symbolize
      attributes = {
        :name => name,
        :description => 'A dummy calendar',
        :category =>  'test',
        :slug => 'slug'
      }.merge(attributes)
      # attributes[:site] = sites(:test) if defined? Site
      attributes
    end
  end
end
