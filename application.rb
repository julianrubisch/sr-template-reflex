require "action_controller/railtie"
require "action_cable/engine"
require "rails/command"
require "rails/commands/server/server_command"
require "cable_ready"
require "stimulus_reflex"

module ApplicationCable; end

class ApplicationCable::Connection < ActionCable::Connection::Base
  identified_by :session_id

  def connect
    self.session_id = request.session.id
  end
end

class ApplicationCable::Channel < ActionCable::Channel::Base; end

class ApplicationController < ActionController::Base; end

class ApplicationReflex < StimulusReflex::Reflex; end

class User
  attr_accessor :templates
  
  def initialize
    @templates = []
  end
end

class Template
  attr_reader :uuid
  
  def initialize
    @uuid = SecureRandom.urlsafe_base64
  end
  
  def render
    template = <<~HTML
    <div class="card mt-2" style="width: 18rem;">
      <div class="card-header d-flex justify-content-between">
        <span>#{@uuid}</span>
        <button type="button" class="btn-close" aria-label="Close" data-reflex="click->Template#remove" data-uuid=#{@uuid}></button>
      </div>
      <div class="card-body">
        <h5 class="card-title">Card title</h5>
        <p class="card-text">Some quick example text to build on the card title and make up the bulk of the card's content.</p>
      </div>
    </div>
    HTML
    template.html_safe
  end
end

class TemplateReflex < ApplicationReflex
  before_reflex do
    session[:user] ||= User.new
  end
  
  def insert
    session[:user].templates << Template.new
  end
  
  def remove
    session[:user].templates.delete_if { |template| template.uuid == element.dataset.uuid }
  end
end

class DemosController < ApplicationController
  def show
    session[:user] ||= User.new
    render inline: <<~HTML
      <html>
        <head>
          <title>TemplateReflex Pattern</title>
          <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/css/bootstrap.min.css" rel="stylesheet">
          <%= javascript_include_tag "/index.js", type: "module" %>
        </head>
        <body>
          <div class="container my-3">
            <h1>TemplateReflex</h1>
            <%= tag.a "Add Card", class: "btn btn-primary", data: { reflex: "click->Template#insert" } %>
            
            <%= session[:user].templates.map(&:render).join.html_safe %>
          </div>
        </body>
      </html>
    HTML
  end
end

class MiniApp < Rails::Application
  require "stimulus_reflex/../../app/channels/stimulus_reflex/channel"

  config.action_controller.perform_caching = true
  config.consider_all_requests_local = true
  config.public_file_server.enabled = true
  config.secret_key_base = "cde22ece34fdd96d8c72ab3e5c17ac86"
  config.secret_token = "bf56dfbbe596131bfca591d1d9ed2021"
  config.session_store :cache_store
  config.hosts.clear

  Rails.cache = ActiveSupport::Cache::RedisCacheStore.new(url: "redis://localhost:6379/1")
  Rails.logger = ActionCable.server.config.logger = Logger.new($stdout)
  ActionCable.server.config.cable = {"adapter" => "redis", "url" => "redis://localhost:6379/1"}

  routes.draw do
    mount ActionCable.server => "/cable"
    get '___glitch_loading_status___', to: redirect('/')    
    resource :demo, only: :show
    root "demos#show"
  end
end

Rails::Server.new(app: MiniApp, Host: "0.0.0.0", Port: ARGV[0]).start
