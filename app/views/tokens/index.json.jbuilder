json.total @tokens.length
json.page Integer(@tokens.current_page)
json.per_page @tokens.per_page
json.records @tokens, partial: 'tokens/token', as: :token
