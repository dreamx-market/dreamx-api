module Error
	class ValidationError < BadRequestError
		attr_reader :validation_errors

		def initialize(_validation_errors=[])
			super(101, 'Validation failed')
			@validation_errors = _validation_errors
		end
	end
end