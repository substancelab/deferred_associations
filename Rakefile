task :default do |t|
  options = "--colour"
  files = FileList['spec/**/*_spec.rb'].map{|f| f.sub(%r{^spec/},'') }
  exit system("cd spec && spec #{options} #{files}") ? 0 : 1
end

begin
  require 'jeweler'
  project_name = 'deferred_associations'
  Jeweler::Tasks.new do |gem|
    gem.name = project_name
    gem.summary = "Makes ActiveRecord defer/postpone habtm or has_many associations"
    gem.description = "Makes ActiveRecord defer/postpone saving the records you add to an habtm (has_and_belongs_to_many) or has_many
                       association until you call model.save, allowing validation in the style of normal attributes. Additionally you
                       can check inside before_save filters, if the association was altered."
    gem.homepage = "http://github.com/MartinKoerner/deferred_associations"
    gem.email   = "martin.koerner@objectfab.de"
    gem.authors = ["Martin Koerner", "Tyler Rick", "Alessio Caiazza"]
    gem.add_dependency('activerecord')
    gem.add_development_dependency('rspec')
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
