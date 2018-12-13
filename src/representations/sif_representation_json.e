note
	description: "Summary description for {SIF_REPRESENTATION_JSON}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_REPRESENTATION_JSON
	inherit
		SIF_REPRESENTATION

		JSON_PARSER_ACCESS

		SHARED_LOG_FACILITY

feature -- Status

	type: like {SIF_REPRESENTATION_ENUMERATION}.type
			-- Type of the representation by enumeration
		do
			Result := {SIF_REPRESENTATION_ENUMERATION}.json
		end

feature -- Parsing

	parse( req: WSF_REQUEST; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET; a_ie_set_to_publish: SIF_INTERACTION_ELEMENT_SORTED_SET ) : SIF_REPRESENTATION_PARSE_RESULT
			-- Positive result, if parseable and input validation succeeded and all mandatory elements are available and any optional elements match.			-- The interaction elements to publish needs to be filled with the mandatory and any optional interaction elements mapped from the input stream to the sorted set of interaction elements,
			-- so these can be used to publish to the interactor during interaction		
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			l_parse_string: STRING
		do
			create l_parse_string.make_empty
			create Result
			if req.is_get_request_method then
				if not req.query_string.is_empty then
					l_parse_string := req.query_string
				end
			end
			if req.is_put_post_request_method or req.is_request_method ({HTTP_REQUEST_METHODS}.method_patch) or req.is_request_method ({HTTP_REQUEST_METHODS}.method_delete) then
				l_parse_string := retrieve_data (req)
			end
			write_information ("%T%T[JSON representation parser] String to parse: " + l_parse_string)
			if not req.query_string.is_empty or not l_parse_string.is_empty then
				create parser.make_with_string (l_parse_string)
				if attached parser as l_parser then
					if attached {JSON_OBJECT} l_parser.next_parsed_json_value as l_json_object then
						if l_parser.is_valid then
							from
								i := 1
								count_mandatory := 0
								count_parsed_mandatory := 0
							until
								i > a_sorted_set_of_interaction_elements.count or Result.failed
							loop
								a_sorted_set_of_interaction_elements.go_i_th (i)
								l_ie := a_sorted_set_of_interaction_elements.item
								if l_ie.is_mandatory then
									count_mandatory := count_mandatory + 1
									if l_json_object.has_key (l_ie.descriptor) then
										if attached {JSON_STRING}l_json_object.item(l_ie.descriptor) as l_item_string_mandatory then
										   	if l_ie.is_valid_input( l_item_string_mandatory.item ) then
												l_ie.put_input (l_item_string_mandatory.item)
												a_ie_set_to_publish.extend (l_ie )
												count_parsed_mandatory := count_parsed_mandatory + 1
										   	end
										end
										if attached {JSON_NUMBER}l_json_object.item(l_ie.descriptor) as l_item_string_mandatory then
										   	if l_ie.is_valid_input( l_item_string_mandatory.item ) then
												l_ie.put_input (l_item_string_mandatory.item)
												a_ie_set_to_publish.extend (l_ie )
												count_parsed_mandatory := count_parsed_mandatory + 1
										   	end
										end
									   	if attached {JSON_OBJECT}l_json_object.item(l_ie.descriptor) as l_item_object_mandatory and then
										   attached {SIF_IE_LIST}l_ie as l_ie_list_mandatory then
										   	a_ie_set_to_publish.extend (l_ie_list_mandatory )
										   	Result := handle_list(l_ie_list_mandatory.elements, l_item_object_mandatory, a_ie_set_to_publish)
										   	count_parsed_mandatory := count_parsed_mandatory + 1
									   	end
									else
										Result.set_invalid_mandatory
									end
								end
								if l_ie.is_optional then
									if l_json_object.has_key (l_ie.descriptor) then
										if attached {JSON_STRING}l_json_object.item(l_ie.descriptor) as l_item_string_optional then
											if l_ie.is_valid_input( l_item_string_optional.item ) then
												l_ie.put_input (l_item_string_optional.item)
									    		a_ie_set_to_publish.extend (l_ie )
									   		end
									   	end
										if attached {JSON_NUMBER}l_json_object.item(l_ie.descriptor) as l_item_string_mandatory then
										   	if l_ie.is_valid_input( l_item_string_mandatory.item ) then
												l_ie.put_input (l_item_string_mandatory.item)
												a_ie_set_to_publish.extend (l_ie )
										   	end
										end
										if attached {JSON_OBJECT}l_json_object.item(l_ie.descriptor) as l_item_object_optional and then
										   attached {SIF_IE_LIST}l_ie as l_ie_list_optional then
										   	a_ie_set_to_publish.extend (l_ie_list_optional )
										   	Result := handle_list(l_ie_list_optional.elements, l_item_object_optional, a_ie_set_to_publish)
									   	end
									end
								end
								i := i + 1
							end
							if count_mandatory /= count_parsed_mandatory then
								Result.set_invalid_mandatory
							end
						else
							Result.set_invalid_input
						end
					else
						Result.set_internal_server_error
					end
				else
					Result.set_internal_server_error
				end
			else
				Result.set_invalid_input
			end
		end

feature {NONE} -- Implementation

	handle_list(a_elements: like {SIF_IE_LIST}.elements; l_json_object: JSON_OBJECT; a_ie_set_to_publish: SIF_INTERACTION_ELEMENT_SORTED_SET): SIF_REPRESENTATION_PARSE_RESULT
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET
		do
			create Result
			across a_elements as ssie loop
				a_sorted_set_of_interaction_elements := ssie.item
				from
					i := 1
				until
					i > a_sorted_set_of_interaction_elements.count or Result.failed
				loop
					a_sorted_set_of_interaction_elements.go_i_th (i)
					l_ie := a_sorted_set_of_interaction_elements.item
					if l_ie.is_mandatory then
						count_mandatory := count_mandatory.item + 1
						if l_json_object.has_key (l_ie.descriptor) then
							if attached {JSON_STRING}l_json_object.item(l_ie.descriptor) as l_item_string_mandatory then
							   	if l_ie.is_valid_input( l_item_string_mandatory.item ) then
									l_ie.put_input (l_item_string_mandatory.item)
									a_ie_set_to_publish.extend (l_ie )
									count_parsed_mandatory := count_parsed_mandatory + 1
							   	end
							end
							if attached {JSON_NUMBER}l_json_object.item(l_ie.descriptor) as l_item_string_mandatory then
							   	if l_ie.is_valid_input( l_item_string_mandatory.item ) then
									l_ie.put_input (l_item_string_mandatory.item)
									a_ie_set_to_publish.extend (l_ie )
									count_parsed_mandatory := count_parsed_mandatory + 1
							   	end
							end
						   	if attached {JSON_OBJECT}l_json_object.item(l_ie.descriptor) as l_item_object_mandatory and then
							   attached {SIF_IE_LIST}l_ie as l_ie_list_mandatory then
							   	a_ie_set_to_publish.extend (l_ie_list_mandatory )
							   	Result := handle_list(l_ie_list_mandatory.elements, l_item_object_mandatory, a_ie_set_to_publish)
							   	count_parsed_mandatory := count_parsed_mandatory + 1
						   	end
						else
							Result.set_invalid_mandatory
						end
					end
					if l_ie.is_optional then
						if l_json_object.has_key (l_ie.descriptor) then
							if attached {JSON_STRING}l_json_object.item(l_ie.descriptor) as l_item_string_optional then
								if l_ie.is_valid_input( l_item_string_optional.item ) then
									l_ie.put_input (l_item_string_optional.item)
						    		a_ie_set_to_publish.extend (l_ie )
						   		end
						   	end
							if attached {JSON_NUMBER}l_json_object.item(l_ie.descriptor) as l_item_string_mandatory then
							   	if l_ie.is_valid_input( l_item_string_mandatory.item ) then
									l_ie.put_input (l_item_string_mandatory.item)
									a_ie_set_to_publish.extend (l_ie )
							   	end
							end
							if attached {JSON_OBJECT}l_json_object.item(l_ie.descriptor) as l_item_object_optional and then
							   attached {SIF_IE_LIST}l_ie as l_ie_list_optional then
							   	a_ie_set_to_publish.extend (l_ie_list_optional )
							   	Result := handle_list(l_ie_list_optional.elements, l_item_object_optional, a_ie_set_to_publish)
						   	end
						end
					end
					i := i + 1
				end
			end
		end

	do_represent(req: WSF_REQUEST; res: WSF_RESPONSE; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET)
			-- Create a representation by using the interaction elements which contain the information for the content.
		do
		end

	count_mandatory: INTEGER

	count_parsed_mandatory: INTEGER

feature {NONE} -- Parser

	parser: detachable JSON_PARSER

end
