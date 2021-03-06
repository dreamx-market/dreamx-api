class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
  rescue_from Error::ValidationError do |error|
    @error = error
    render '/errors/validation_error', status: :unprocessable_entity
  end
  before_action :authorize_request, :validate_pagination_params

  def authorize_request
    @limit = ENV['RATE_LIMIT'].to_i
    duration = ENV['RATE_LIMIT_DURATION'].to_i
    @ip = request.remote_ip
    @current_requests = Redis.current.incr(@ip)
    set_response_headers

    if Redis.current.ttl(@ip) < 0
      Redis.current.expire(@ip, duration)
    end

    if @current_requests > @limit
      render json: "too many requests", status: :too_many_requests
      return
    end
  end

  def set_response_headers
    remaining_requests = @limit - @current_requests
    current_timestamp = Time.now.to_i
    ttl = Redis.current.ttl(@ip).to_i
    expiry = current_timestamp + ttl
    response.set_header("X-RateLimit-Limit", @limit)
    response.set_header("X-RateLimit-Remaining", remaining_requests)
    response.set_header("X-RateLimit-Reset", expiry)
  end

  def extract_filters_from_query_params(filters)
    extracted = {}
    filters.each do |filter|
      extracted[filter] = params[filter] if params[filter]
    end
    return extracted
  end

  def check_if_readonly
    if Config.get('read_only') == 'true'
      render json: "service is under maintainence", status: :service_unavailable
      return
    end
  end

	private

    def record_not_found(error)
      render json: { error: error.message }, status: :not_found
    end

		def validate_pagination_params
			unless !params[:per_page] || Integer(params[:per_page]) <= ENV['MAX_PER_PAGE'].to_i then
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
