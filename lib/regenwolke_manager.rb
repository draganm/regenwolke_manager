require 'sinatra'
require 'regenwolke_autons'
require 'json'

class RegenwolkeManager < Sinatra::Base

  set :show_exceptions, false
  set :raise_errors, true

  get '/' do
    haml :index
  end

  get '/log_in' do
    haml :log_in
  end


  post '/new_deployment' do


    params = JSON.parse(request.body.read)

    application_name = params.fetch('application')
    git_sha1 = params.fetch('git_sha1')
    step_id = Celluloid::Actor[:nestene_core].schedule_step 'regenwolke', :deploy_application, [application_name, git_sha1]
    Celluloid::Actor[:nestene_core].wait_for_execution_result 'regenwolke', step_id
    status 202
  end
end