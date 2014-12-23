$LOAD_PATH << '.'
$LOAD_PATH << 'lib'

# require 'regenwolke_manager'
require 'nestene'
require 'regenwolke_autons'
require 'regenwolke_manager'

Dir.mkdir('regenwolke') unless File.exists?('regenwolke')
Dir.mkdir('regenwolke/storage') unless File.exists?('regenwolke/storage')

# storage = Rails.env.test? ? Nestene::MemoryStorage.new : Nestene::DiskStorage.new('regenwolke/storage')

storage = Nestene::DiskStorage.new('regenwolke/storage')
Nestene::start_nestene(storage)
RegenwolkeAutons::Core.init()


# SCRIPT_NAME
class SetScriptName
  def initialize(app)
    @app = app
  end

  def call(env)
    old_script_name = env['SCRIPT_NAME']
    env['SCRIPT_NAME'] = 'nestene'
    result = @app.call(env)
    env['SCRIPT_NAME'] = old_script_name
    result
  end
end

class RedirectToSlash

  def initialize(app)
    @app = app
  end

  def call(env)
    unless env['REQUEST_PATH'] == '/nestene'
      @app.call(env)
    else
      res = Rack::Response.new
      res.redirect("/nestene/")
      res.finish
    end
  end
end

map '/nestene' do
  use RedirectToSlash
  use SetScriptName
  run Nestene::Ui::App
end

run RegenwolkeManager
