namespace :bootstrap do
  desc 'Retrieve dependencies needed for project to run'
  task :dependencies do
    unless bundler_installed?
      puts "Project requires bundler to run: 'gem install bundler'"
      puts "Quitting .."
      next
    end

    unless npm_installed?
      puts "Project requires npm to run: 'brew install npm' "
      puts "Quitting .."
      next
    end

    sh 'bundle install'
    sh 'npm install -g lineman' unless lineman_installed?
    sh 'npm install -g bower' unless bower_installed?
    sh 'bower install'
  end

  desc "Create database.yml file"
  # don't add :environment here, you can't load Rails without database file
  task :config_files do
    unless File.exists?(File.join(Dir.pwd, "config", "database.yml"))
      source = File.join(Dir.pwd, "config", "database.example.yml")
      target = File.join(Dir.pwd, "config", "database.yml")
      FileUtils.cp_r source, target
      puts "Database.yml file created"
    else
      puts "Database.yml file already exists"
    end
  end

  desc "Setup database for test and development enviroment"
  task :db => :environment do
    %w(development test).each do |env|
      db = ActiveRecord::Base.configurations[env]['database']
      user = ActiveRecord::Base.configurations[env]['username']
      pass = ActiveRecord::Base.configurations[env]['password']

      create_db db, user, pass
      puts "Database #{user}@#{db} created for #{env}"
    end

    system('rake db:migrate') ? 'database migrated' : 'database migration failed'
  end

  desc 'Create user (optional arguments email)'
  task :create_user, [:email, :password] => :environment do |t, args|
    args.with_defaults[email: 'default@loomio.com', password: 'passcode1']
    if User.find_by(email: args[:email]).empty?
      User.create(args.to_hash)
      puts "Created user with email #{args[:email]} and password '#{args[:password]}'"
    else
      puts "User with #{args[:email]} already exist"
    end
  end

  task :run => :environment do
    #lunch rails here
    #lunch lineman here
    # https://loomio.gitbooks.io/tech-manual/content/using_development.html
  end

  private


  def npm_installed?
    `which npm`
    $?.success?
  end

  def bundler_installed?
    `which bundle`
    $?.success?
  end

  def lineman_installed?
    `which lineman`
    $?.success?
  end

  def bower_installed?
    `which bower`
    $?.success?
  end

  def create_db( db, user, pass )
    %x{createuser -d -l -R -S #{user} &>/dev/null}
    %x{psql -c "alter user #{user} with password '#{pass}';" &>/dev/null}
    %x{createdb -O #{user} #{db}}
  end
end

desc "Tries to onfigure and run application"
task :bootstrap do
  puts 'Hold on, project is starting'
  Rake::Task['bootstrap:dependencies'].invoke
  Rake::Task['bootstrap:config_files'].invoke
  Rake::Task['bootstrap:db'].invoke
  Rake::Task['bootstrap:create_user'].invoke
end
