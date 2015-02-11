require 'sinatra'
require 'regenwolke_autons'
require 'json'
require 'jwt'

UNPROTECTED_ENDPOINTS = ['/', '/log_in_template', '/log_in', '/new_deployment', '/services_template' ]

class RegenwolkeManager < Sinatra::Base

  set :show_exceptions, false
  set :raise_errors, true


  def admin_password
    ENV['ADMIN_PASSWORD'] || 'admin'
  end

  def jwt_secret
    ENV['JWT_SECRET'] || 'very_secret'
  end

  before do
    unless UNPROTECTED_ENDPOINTS.include?(request.path_info)
      jwt = (request.env['HTTP_AUTHORIZATION'] || 'Bearer ').split(' ')[1]
      begin
        @decoded_jwt = JWT.decode(jwt,jwt_secret)
      rescue JWT::DecodeError
        halt 401, 'not authorized'
      end
    end
  end

  get '/' do
    haml :index
  end

  get '/log_in_template' do
    haml :log_in
  end

  get '/status_template' do
    haml :status_template
  end

  get '/services_template' do
    haml :services_template
  end

  get '/new_service_modal' do
    haml :new_service_modal
  end


  get '/applications' do
    Celluloid::Actor[:nestene_core].get_state('regenwolke').serialized.fetch('applications').to_json
  end

  get '/services' do
    content_type :json
    [
      {
        name:'PostgreSQL',
        service_id: 'postgresql'
      }
    ].to_json
  end

  get '/services/:service_id' do
    content_type :json
    state = Celluloid::Actor[:nestene_core].get_state 'service:%s' % [params[:service_id]]
    state.serialized.fetch('instances').keys.to_json
  end

  post '/services/:service_id' do
    data = JSON.parse(request.body.read)
    Celluloid::Actor[:nestene_core].schedule_step 'service:%s' % [params[:service_id]], :create_instance, [data.fetch('name')]
    status 204
  end

  # get '/services/:service_id/instances' do

  # end


  post '/log_in' do
    content_type :text
    params = JSON.parse(request.body.read)
    if params == {'username' => 'admin', 'password' => admin_password}
      JWT.encode({'username' => 'admin'}, jwt_secret)
    else
      status 401
    end
  end

  get '/username' do
    content_type :json
    @decoded_jwt.first.to_json
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