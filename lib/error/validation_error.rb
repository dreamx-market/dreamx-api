module Error
	class ValidationError < BadRequestError
		attr_reader :code, :validation_errors

		def initialize(_validation_errors=[])
			super('Validation failed')
			@code = 100
			@validation_errors = _validation_errors
		end
	end
end