namespace :client do
  desc "Builds Loomio javascript client"
  task :build do
    puts "Building clientside assets..."
    run_commands(
      "rm -rf public/blient/*",
      "cd vue && npm i && npm run build && cd .."
    )
  end
end
