
guard :rspec, cmd: 'rspec' do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  watch('lib/has_and_belongs_to_many_with_deferred_save.rb') { %w(spec/habtm_ar4_spec.rb
                                                                  spec/has_and_belongs_to_many_with_deferred_save_spec.rb)
  }

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)
end
