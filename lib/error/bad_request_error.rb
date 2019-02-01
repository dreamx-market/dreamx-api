module Error
	class BadRequestError < StandardError
		attr_reader :reason

		def initialize(_reason=nil)
			@reason = _reason || 'Bad Request'
		end
	end
end