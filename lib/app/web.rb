require "sinatra/base"
require_relative "./helpers/application_helper"
require 'pry'
require_relative "../loan_creator"

class Web < Sinatra::Base
  helpers ApplicationHelper

  get "/" do
    @params = fix_params_type(params)

    @timetable =  case params[:type]
                  when 'in_fine'
                    LoanCreator::InFine.new(**@params)
                  when 'bullet'
                    LoanCreator::Bullet.new(**@params)
                  when 'linear'
                    LoanCreator::Linear.new(**@params)
                  when 'standard'
                    LoanCreator::Standard.new(**@params)
                  end

    @terms =  if @timetable
                @timetable.lender_timetable.terms
              else
                []
              end

    erb :index, locals: { fixed_params: @params, terms: @terms }
  end
end
