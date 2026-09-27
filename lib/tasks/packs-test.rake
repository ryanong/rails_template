# typed: false

run_tests = ->(*args) do
  opts = ENV.key?("TESTOPTS") ? ENV["TESTOPTS"].shellsplit : []
  system("rails", "test", *args, *opts) || exit($?.exitstatus)
end

namespace :packs do
  desc "Run tests for all packs"
  task test: "test:prepare" do
    ENV["DEFAULT_TEST"] = "{#{Packs.all.map(&:relative_path).join(",")}}/test/**/*_test.rb"
    ENV["DEFAULT_TEST_EXCLUDE"] = "{#{Packs.all.map(&:relative_path).join(",")}}/test/{system,dummy}/**/*_test.rb"
    run_tests.call
  end

  namespace :test do
    desc "Run all tests for all packs including unit and integration"
    task all: "test:prepare" do
      run_tests.call(*Packs.all.map { |pack| pack.relative_path.join("test/**/*_test.rb").to_s })
    end

    desc "Run system tests for all packs"
    task system: "test:prepare" do
      run_tests.call(*Packs.all.map { |pack| pack.relative_path.join("test/system/**/*_test.rb").to_s })
    end

    Packs.all.each do |pack|
      desc "Run tests for #{pack.name} pack"
      task pack.name.parameterize => "test:prepare" do
        ENV["DEFAULT_TEST"] = pack.relative_path.join("test/**/*_test.rb").to_s
        ENV["DEFAULT_TEST_EXCLUDE"] = pack.relative_path.join("test/{system,dummy}/**/*_test.rb").to_s
        run_tests.call
      end

      namespace pack.name.parameterize do
        desc "Run all tests for #{pack.name} pack"
        task(all: "test:prepare") { run_tests.call(pack.relative_path.join("test/**/*_test.rb").to_s) }

        desc "Run system tests for #{pack.name} pack"
        task(system: "test:prepare") { run_tests.call(pack.relative_path.join("test/system/**/*_test.rb").to_s) }
      end
    end
  end
end
