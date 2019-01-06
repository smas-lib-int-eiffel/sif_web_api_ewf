note
	description: "Summary description for {SIF_REPRESENTATION_NVP}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_REPRESENTATION_NVP

inherit
	SIF_REPRESENTATION

	SHARED_URL_ENCODER
		undefine
			default_create
		end

feature -- Status

	type: like {SIF_REPRESENTATION_ENUMERATION}.type
			-- Type of the representation by enumeration
		do
			Result := {SIF_REPRESENTATION_ENUMERATION}.nvp
		end

feature -- Parsing

	parse( req: WSF_REQUEST; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET; a_ie_set_to_publish: SIF_INTERACTION_ELEMENT_SORTED_SET ) : SIF_REPRESENTATION_PARSE_RESULT
			-- Positive result, if parseable and input validation succeeded and all mandatory elements are available and any optional elements match.			
			-- The interaction elements to publish needs to be filled with the mandatory and any optional interaction elements mapped from the input stream to the sorted set of interaction elements,
			-- so these can be used to publish to the interactor during interaction
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			l_count_mandatory: INTEGER
			l_count_parsed_mandatory: INTEGER
		do
			create Result
			from
				l_count_mandatory := 0
				l_count_parsed_mandatory := 0
				i := 1
			until
				i > a_sorted_set_of_interaction_elements.count
			loop
				a_sorted_set_of_interaction_elements.go_i_th (i)
				l_ie := a_sorted_set_of_interaction_elements.item
				if l_ie.is_mandatory then
					l_count_mandatory := l_count_mandatory + 1
					if attached req.query_parameter (l_ie.descriptor) as l_query_item_mandatory then
					   	if l_ie.is_valid_input( l_query_item_mandatory.string_representation ) then
							l_ie.put_input (url_encoder.decoded_utf_8_string (l_query_item_mandatory.string_representation))
							a_ie_set_to_publish.extend (l_ie )
							l_count_parsed_mandatory := l_count_parsed_mandatory + 1
					   	end
					end
				end
				if l_ie.is_optional then
					if attached req.query_parameter (l_ie.descriptor) as l_query_item_optional then
					   	if l_ie.is_valid_input( l_query_item_optional.string_representation ) then
							l_ie.put_input (url_encoder.decoded_utf_8_string (l_query_item_optional.string_representation))
							a_ie_set_to_publish.extend (l_ie )
					   	end
					end
				end
				-- ToDo: Add other type of interaction elements: suggestion by Ricardo Barrera
				i := i + 1
			end

			if l_count_mandatory /= l_count_parsed_mandatory then
				Result.set_invalid_mandatory
			end
		end

feature {NONE} -- Implementation

	do_represent(req: WSF_REQUEST; res: WSF_RESPONSE; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET)
			-- Create a representation by using the interaction elements which contain the information for the content.
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			l_has_at_least_one_element: BOOLEAN
		do
			from
				i := 1
			until
				i > a_sorted_set_of_interaction_elements.count
			loop
				a_sorted_set_of_interaction_elements.go_i_th (i)
				l_ie := a_sorted_set_of_interaction_elements.item
				if attached l_ie as la_ie  then
					if not l_has_at_least_one_element then
						l_has_at_least_one_element := True
					else
						res.put_character ('&')
					end
					res.put_string (url_encoder.encoded_string (la_ie.descriptor) + "=" + url_encoder.encoded_string (la_ie.to_string))
				end
				i := i + 1
			end
		end

feature {NONE} -- Parser


end

