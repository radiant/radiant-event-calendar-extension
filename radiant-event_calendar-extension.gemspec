# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "radiant-event_calendar-extension"

Gem::Specification.new do |s|
  s.name        = "radiant-event_calendar-extension"
  s.version     = RadiantEventCalendarExtension::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = RadiantEventCalendarExtension::AUTHORS
  s.email       = RadiantEventCalendarExtension::EMAIL
  s.homepage    = RadiantEventCalendarExtension::URL
  s.summary     = RadiantEventCalendarExtension::SUMMARY
  s.description = RadiantEventCalendarExtension::DESCRIPTION

  s.add_dependency "ri_cal"
  s.add_dependency "chronic"
  s.add_dependency "uuidtools"
  s.add_dependency "radiant-layouts-extension"

  ignores = if File.exist?('.gitignore')
    File.read('.gitignore').split("\n").inject([]) {|a,p| a + Dir[p] }
  else
    []
  end
  s.files         = Dir['**/*'] - ignores
  s.test_files    = Dir['test/**/*','spec/**/*','features/**/*'] - ignores
  # s.executables   = Dir['bin/*'] - ignores
  s.require_paths = ["lib"]

  s.post_install_message = %{
  Add this to your radiant project with:

    config.gem 'radiant-event_calendar-extension', :version => '~> #{RadiantEventCalendarExtension::VERSION}'

  }
end
