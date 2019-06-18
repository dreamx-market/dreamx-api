class ApplicationController < ActionController::API
  def extract_filters_from_query_params(filters)
    extracted = {}
    filters.each do |filter|
      extracted[filter] = params[filter] if params[filter]
    end
    return extracted
  end

  def check_if_readonly
    if Config.get('read_only') === 'true'
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
      if errors.is_a?(Array)
        errors.each do |record|
          record_errors = []
          record.each do |key, reasons|
            record_errors << { :field => key, :reason => reasons }
          end
          serialized << record_errors
        end
      else
      	errors.each do |key, reasons|
      		serialized << { :field => key, :reason => reasons }
      	end
      end
    	raise Error::ValidationError.new(serialized)
		end
end
