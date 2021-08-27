require_relative './app'

module Rack
  class CommonLogger
    def call(env)
      @app.call(env)
    end
  end
end

use Rack::Logger
use Rack::CommonLogger
run Isucondition::App

