module Error
	class BadRequestError < StandardError
		attr_reader :code, :reason

		def initialize(_code=nil,_reason=nil)
			@code = _code || 400
			@reason = _reason || 'Bad Request'
		end
	end
end