require 'warbler'
require './lib/ets_common/util/helpers'
Rake::TaskManager.record_task_metadata = true
include ETSUtilities
#set GLASSFISH_ROOT=C:\work\ETS\glassfish
#this is also the context root
#set RAILS_RELATIVE_URL_ROOT=/ets_tooling
#domain 1 is the default if is this is unset
#set GLASSFISH_DOMAIN=domain1
#glassfish console:
#http://localhost:4848/

namespace :devops do
  def env(env_var, default)
    ENV[env_var].nil? ? default : ENV[env_var]
  end


  default_name = to_snake_case(Rails.application.class.parent)
  default_war = "#{default_name}.war"
  context = env('RAILS_RELATIVE_URL_ROOT', "/#{default_name}")
  ENV['RAILS_RELATIVE_URL_ROOT'] = env('RAILS_RELATIVE_URL_ROOT', "/#{default_name}")
  ENV['RAILS_ENV'] = env('RAILS_ENV', 'test')
  domain = env('GLASSFISH_DOMAIN', 'domain1')


  desc "Start up glassfish"
  task :glass_start do |task|
    p task.comment
    Bundler.with_clean_env do
      #until I learn more we will not give glass fish any access to our environment
      sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin start-domain #{domain}"
    end
  end

  desc "Stop glassfish"
  task :glass_stop do |task|
    p task.comment
    sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin stop-domain #{domain}"
  end

  desc "Build war file"
  task :build_war do |task|
    p task.comment
    #Rake::Task['devops:bundle'].invoke#maven's automated build will do this for us
    Rake::Task['devops:compile_assets'].invoke
    # Rake::Task['devops:create_version'].invoke
    #sh "warble"
    Dir.mkdir(ETSUtilities::MAVEN_TARGET_DIRECTORY) unless File.exists?(ETSUtilities::MAVEN_TARGET_DIRECTORY)
    Warbler::Task.new
    Rake::Task['war'].invoke
  end
  #test fjfjfjfpjgwesjgsjsgjgpjgpjgrpjgpjgpjgpjgjgpjgpij
  desc "Build war file no bundle"
  task :build_war_only do |task|
    p task.comment
    Rake::Task['devops:compile_assets'].invoke
    Warbler::Task.new
    Rake::Task['war'].invoke
  end

  desc "Compile assets"
  task :compile_assets do |task|
    p task.comment
    Rake::Task['assets:clobber'].invoke
    Rake::Task['assets:precompile'].invoke
  end

  desc "Install bundle"
  task :bundle do |task|
    p task.comment
    sh "bundle install"
  end

  desc "Deploy ets_tooling rails to glassfish"
  task :deploy do |task|
    p task.comment
    Rake::Task['devops:build_war'].invoke
    sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin deploy --force true --contextroot #{context} #{default_war}"
  end

  desc "List glassfish applications"
  task :list_web_apps do |task|
    p task.comment
    sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin list-applications --type web"
  end

  desc "Undeploy ets_tooling rails from glassfish"
  task :undeploy do |task|
    puts task.comment
    sh "#{ENV['GLASSFISH_ROOT']}/glassfish4/bin/asadmin undeploy #{default_name}"
  end


  # task :create_version do
  #   desc "create ETS VERSION.  Use MAJOR_VERSION, MINOR_VERSION, BUILD_VERSION to override defaults"
  #   version_file = "#{Rails.root}/config/initializers/version2.rb"
  #   major = ENV["MAJOR_VERSION"] || ETS_VERSION.first
  #   minor = ENV["MINOR_VERSION"] || ETS_VERSION[1]
  #   build = ENV["BUILD_VERSION"] || `git describe --always --tags`
  #   version_string = "ETS_VERSION = #{[major.to_s, minor.to_s, build.strip]}\n"
  #   File.open(version_file, "w") {|f| f.print(version_string)}
  #   $maven_vs = major + "." + minor + "." + build
  #   $maven_vs.chomp!
  # end

end