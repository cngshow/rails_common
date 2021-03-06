require 'fileutils'

namespace :devops do
  ENV['NODE_ENV'] = Rails.env
  cleanup = 'Cleanup react on rails'
  setup = 'Set up react on rails'

  task :custom_environment  do
    # special initialization stuff here
    # or call another initializer script
  end

  desc cleanup
  task :cleanup_react => :custom_environment do
    w_d = './app/assets/webpack/'
    n_m = './client/node_modules'
    begin
      FileUtils.remove_dir(w_d)
      puts "#{w_d} removed."
    rescue => ex
      puts "Failed to remove #{w_d}, error: #{$!}"
    end
    begin
      FileUtils.remove_dir(n_m)
      puts "#{n_m} removed."
    rescue => ex
      puts "Failed to remove #{n_m}, error: #{$!}"
    end
  end

  desc setup
  task :set_up_react  => :custom_environment do
    Rake::Task['devops:cleanup_react'].invoke
    Dir.chdir('./client') do
      sh 'yarn install --frozen-lockfile --ignore-engines' #https://github.com/akveo/ng2-admin/issues/717
    end

      puts "Running: yarn run build:#{Rails.env}"
      Dir.chdir('./client') do
        sh "yarn run build:#{Rails.env}"
      end
      puts 'Done..'
      #unix land, we assume we are on the build server
      #rake react_on_rails:assets:webpack
      #puts 'Running: react_on_rails:assets:webpack'
      #Rake::Task['react_on_rails:assets:webpack'].invoke
      #puts 'Done..'
  end

  desc cleanup
  task :c => :cleanup_react

  desc setup
  task :s => :set_up_react

end
