class ApplicationController < ActionController::API
	rescue_from Error::ValidationError do |error|
		@error = error
		render '/errors/validation_error', status: :unprocessable_entity
	end

	private

		def validate_pagination_params
			unless !params[:per_page] || Integer(params[:per_page]) < ENV['MAX_PER_PAGE'].to_i then
	  		raise Error::ValidationError.new([
	  			{
	  				:field => 'per_page',
	  				:reason => "should be less than or equal to #{ENV['MAX_PER_PAGE']}"
	  			}
	  		])
  		end
		end

		def serialize_active_record_validation_error(errors)
			serialized = []
    	errors.each do |key, array|
    		serialized << { :field => key, :reason => array }
    	end
    	raise Error::ValidationError.new(serialized)
		end
end
