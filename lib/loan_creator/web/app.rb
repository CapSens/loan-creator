require "sinatra/base"
require_relative "./helpers/application_helper"
require_relative "../../loan_creator"

module LoanCreator
  class Web < Sinatra::Base
    helpers LoanCreator::ApplicationHelper

    get "/" do
      parameters = fix_params_type(params)

      timetable =  case params[:type]
                    when 'in_fine'
                      LoanCreator::InFine.new(**parameters)
                    when 'bullet'
                      LoanCreator::Bullet.new(**parameters)
                    when 'linear'
                      LoanCreator::Linear.new(**parameters)
                    when 'standard'
                      LoanCreator::Standard.new(**parameters)
                    end

      terms =  if timetable
                  timetable.lender_timetable.terms
                else
                  []
                end

      erb :index, locals: { fixed_params: parameters, terms: terms }
    end
  end
end
