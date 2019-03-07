class ApplicationController < ActionController::API
  def extract_filters_from_query_params(filters)
    extracted = {}
    filters.each do |filter|
      extracted[filter] = params[filter] if params[filter]
    end
    return extracted
  end

  def check_if_readonly
    if ENV["READONLY"] === 'true'
      render json: "service is under maintainence", status: :service_unavailable
      return
    end
  end

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
