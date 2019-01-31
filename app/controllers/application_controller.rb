class ApplicationController < ActionController::API
	rescue_from Error::ValidationError do |error|
		@error = error
		render '/errors/validation_error'
	end

	private

		def validate_pagination_params
  		raise Error::ValidationError.new([
  			{
  				:field => 'per_page',
  				:code => 1004,
  				:reason => "per_page should be less than or equal to #{Rails.application.config.MAX_PER_PAGE}"
  			}
  		]) unless !params[:per_page] || Integer(params[:per_page]) < Rails.application.config.MAX_PER_PAGE
		end
end
