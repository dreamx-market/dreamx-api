module Error
	class ConflictError < BadRequestError
		attr_reader :validation_errors

		def initialize(_reason)
			super(104, _reason)
		end
	end
end