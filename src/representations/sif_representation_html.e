note
	description: "Summary description for {SIF_REPRESENTATION_HTML}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_REPRESENTATION_HTML
	inherit
		SIF_REPRESENTATION
			undefine
				default_create
			select
				is_equal,
				copy
			end

		SIF_INTERACTION_ELEMENT_IDENTIFIERS_WEB

		SHARED_URL_ENCODER
			undefine
				default_create
			end


feature -- Status

	type: like {SIF_REPRESENTATION_ENUMERATION}.type
			-- Type of the representation by enumeration
		do
			Result := {SIF_REPRESENTATION_ENUMERATION}.html
		end

feature -- Parsing

	parse( req: WSF_REQUEST; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET; a_ie_set_to_publish: SIF_INTERACTION_ELEMENT_SORTED_SET ) : SIF_REPRESENTATION_PARSE_RESULT
			-- Positive result, if parseable and input validation succeeded and all mandatory elements are available and any optional elements match.			-- The interaction elements to publish needs to be filled with the mandatory and any optional interaction elements mapped from the input stream to the sorted set of interaction elements,
			-- so these can be used to publish to the interactor during interaction		
		do
			create Result
		end

feature {NONE} -- Implementation web page

	do_represent(req: WSF_REQUEST; res: WSF_RESPONSE; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET)
			-- Create a representation by using the interaction elements which contain the information for the content.
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			l_result_query_parameters: STRING
			l_to_be_redirected: BOOLEAN
			l_html_page_response: WSF_HTML_PAGE_RESPONSE
		do
			create l_result_query_parameters.make_empty
			from
				i := 1
			until
				i > a_sorted_set_of_interaction_elements.count
			loop
				a_sorted_set_of_interaction_elements.go_i_th (i)
				l_ie := a_sorted_set_of_interaction_elements.item
				if attached {SIF_IE_WEB_PAGE}l_ie as l_ie_web_page then
					if attached l_ie_web_page.web_page_representor as l_web_page_presentor then
						l_html_page_response := l_web_page_presentor.item(req)
						if l_to_be_redirected then
							l_html_page_response.set_status_code ({HTTP_STATUS_CODE}.found)
						end
						res.send (l_html_page_response)
					end
				end
				
				if attached {SIF_IE_TEXT}l_ie as l_ie_text then
					if l_ie_text.identifier = Iei_web_redirect then
						l_to_be_redirected := True
						if l_result_query_parameters.is_empty then
							res.redirect_now (l_ie_text.text)
						else
							res.redirect_now (l_ie_text.text + "?" + l_result_query_parameters)
						end
					else
						if l_result_query_parameters.is_empty then
							l_result_query_parameters.append (url_encoder.encoded_string (l_ie_text.descriptor) + "=" + url_encoder.encoded_string (l_ie_text.text))
						else
							l_result_query_parameters.append ("&" + url_encoder.encoded_string (l_ie_text.descriptor) + "=" + url_encoder.encoded_string (l_ie_text.text))
						end
					end
				end
				i := i + 1
			end
		end

end
