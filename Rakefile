# encoding: utf-8

require 'airbrake/tasks'
require 'airbrake/rake_handler'

if ENV['CI']
  require 'ci/reporter/rake/rspec'
  require 'ci/reporter/rake/test_unit'
end

load 'lib/3scale/tasks/cubert.rake'

task :environment do
  require '3scale/backend'
  require '3scale/backend/stats/tasks'
end

def testable_environment?
  !%w(preview production).include?(ENV['RACK_ENV'])
end

if testable_environment?
  require 'rake/testtask'

  task :default => [:test, :spec]

  test_task_dependencies = ['test:unit', 'test:integration']
  test_task_dependencies.unshift('ci:setup:testunit') if ENV['CI']

  desc 'Run unit and integration tests'
  task :test => test_task_dependencies

  namespace :test do
    desc 'Run all tests (unit, integration and special)'
    task :all => ['test:unit', 'test:integration', 'test:special']

    Rake::TestTask.new(:unit) do |task|
      task.test_files = FileList['test/unit/**/*_test.rb']
      task.verbose = true
    end

    Rake::TestTask.new(:integration) do |task|
      task.test_files = FileList['test/integration/**/*_test.rb']
      task.verbose = true
    end

    Rake::TestTask.new(:special) do |task|
      task.test_files = FileList['test/special/**/*_test.rb']
      task.verbose = true
    end
  end

  require 'rspec/core/rake_task'
  desc 'Run specs'
  RSpec::Core::RakeTask.new
  task :spec => 'ci:setup:rspec' if ENV['CI']

  desc 'Generate API request documentation from API specs'
  RSpec::Core::RakeTask.new('docs:generate') do |t|
    t.pattern = 'spec/acceptance/**/*_spec.rb'
    t.rspec_opts = ["--format RspecApiDocumentation::ApiFormatter"]
  end

  desc 'Tag and push the current version'
  task :release => ['release:tag', 'release:push']

  namespace :release do
    task :tag do
      require File.dirname(__FILE__) + '/lib/3scale/backend/version'
      system "git tag v#{ThreeScale::Backend::VERSION}"
    end

    task :push do
      system "git push --tags"
    end
  end

  desc 'Seed, put info into redis using data/postfile3, plan :default'
  task :seed do
    system "ruby -Ilib bin/3scale_backend_seed -l -p data/postfile3"
  end

  desc 'Seed, put info into redis using data/postfile3, plan :user'
  task :seed_user do
    system "ruby -Ilib bin/3scale_backend_seed -u -l -p data/postfile3"
  end

  desc 'Start the backend server in development'
  task :start do
    system "ruby -Ilib bin/3scale_backend -p #{ENV['PORT'] || 3001} start"
  end

  desc 'Start a backend_worker in development'
  task :start_worker do
    system "ruby -Ilib bin/3scale_backend_worker_no_daemon"
  end

  desc 'Stop a backend_worker in development'
  task :stop_worker do
    system "ruby -Ilib bin/3scale_backend_worker stop"
  end

  desc 'Restart a backend_worker in development'
  task :restart_worker do
    system "ruby -Ilib bin/3scale_backend_worker restart"
  end
end

desc 'Reschedule failed jobs'
task :reschedule_failed_jobs => :environment do
  count = Resque::Failure.count
  (Resque::Failure.count-1).downto(0).each { |i| Resque::Failure.requeue(i) }
  Resque::Failure.clear
  puts "resque:failed size: #{Resque::Failure.count} (from #{count})"
end

namespace :cache do
  desc 'Caching enabled?'
  task :caching_enabled? => :environment do
    puts ThreeScale::Backend::Transactor.caching_enabled?
  end

  desc 'Disable caching'
  task :disable_caching => :environment do
    puts ThreeScale::Backend::Transactor.caching_disable
  end

  desc 'Enable caching'
  task :enable_caching => :environment do
    puts ThreeScale::Backend::Transactor.caching_enable
  end
end

namespace :stats do
  namespace :panic_mode do
    desc '!!! Delete all time buckets and keys after disabling storage stats'
    task :delete_all_buckets_and_keys => :environment do
      puts ThreeScale::Backend::Stats::Tasks.delete_all_buckets_and_keys_only_as_rake!
    end

    desc 'Disable stats batch processing on storage stats. Stops saving to storage stats and to redis'
    task :disable_storage_stats => :environment do
      puts ThreeScale::Backend::StorageStats.disable!
    end

    desc 'Enable stats batch processing on storage stats'
    task :enable_storage_stats => :environment do
      puts ThreeScale::Backend::StorageStats.enable!
    end

    desc 'Schedule a StatsJob, will process all pending buckets including current (that should be done automatically)'
    task :insert_stats_job => :environment do
      puts ThreeScale::Backend::Stats::Tasks.schedule_one_stats_job
    end
  end

  desc 'Number of stats buckets active in Redis'
  task :buckets_size => :environment do
    puts ThreeScale::Backend::Stats::Info.pending_buckets_size
  end

  desc 'Number of keys in each stats bucket in Redis'
  task :buckets_info => :environment do
    puts ThreeScale::Backend::Stats::Info.pending_keys_by_bucket.inspect
  end

  desc 'Buckets currently failing to be processed'
  task :failed_buckets => :environment do
    puts ThreeScale::Backend::Stats::Info.failed_buckets
  end

  desc 'All buckets that failed to be processed at least once, even if ok now'
  task :failed_buckets_once => :environment do
    puts ThreeScale::Backend::Stats::Info.failed_buckets_at_least_once
  end

  desc 'Activate saving to storage stats.'
  task :activate_saving_to_storage_stats => :environment do
    puts ThreeScale::Backend::StorageStats.activate!
  end

  desc 'Deactivate saving to storage stats. Do only if the storage stats is down or acting funny. Data is still saved in redis.'
  task :deactivate_saving_to_storage_stats => :environment do
    puts ThreeScale::Backend::StorageStats.deactivate!
  end

  desc 'Are stats saving to storage stats or just piling in redis?'
  task :storage_stats_saving_active? => :environment do
    puts ThreeScale::Backend::StorageStats.active?
  end

  desc 'Is storage stats batch processing enabled?'
  task :storage_stats_enabled? => :environment do
    puts ThreeScale::Backend::StorageStats.enabled?
  end

  desc 'Process failed buckets (one by one)'
  task :process_failed => :environment do
    v = ThreeScale::Backend::Stats::Info.failed_buckets
    if v.size==0
      puts "No failed buckets!"
    else
      puts "Saving bucket: #{v.first} ..."
      ThreeScale::Backend::StorageStats.save_changed_keys(v.first)
      puts "Done"
    end
  end

  desc 'check counter values for influxdb and redis, params: service_id, application_id, metric_id, time (optional)'
  task :check_counters, [:service_id, :app_id, :metric_id, :timestamp] => :environment do |t, args|
    timestamp    = Time.parse_to_utc(args[:timestamp]) || Time.now.utc
    info_message = "Params: service_id: #{args[:service_id]}, " +
                   "application_id: #{args[:application_id]}, " +
                   "metric_id #{args[:metric_id]}, timestamp #{timestamp}"

    puts info_message

    if args[:service_id].nil? || args[:app_id].nil? || args[:metric_id].nil? || timestamp.nil?
      ex_message = "Incorrect parameters: you must pass:" +
                   "service_id application_id metric_id timestamp (in full)." +
                   "For instance: service_id app_id metric_id \"2010-05-07 17:28:12'\""

      raise ArgumentError.new(ex_message)
    end

    values = ThreeScale::Backend::Stats::Tasks.check_values(args[:service_id],
                                                                      args[:app_id],
                                                                      args[:metric_id],
                                                                      timestamp)

    puts values.inspect
  end
end
