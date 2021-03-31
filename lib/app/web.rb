require "sinatra/base"
require_relative "./helpers/application_helper"
require 'pry'

class Web < Sinatra::Base
  helpers ApplicationHelper

  get "/" do
    if params[:initial_values].nil?
      @params = fix_params_type(params.merge({initial_values:{}}))
    else
      @params =  fix_params_type(params)
    end

    #binding.pry
    erb :index, locals: { fixed_params: @params }
  end
end
