note
	description: "Summary description for {SIF_REPRESENTATION_JSON_HAL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_REPRESENTATION_JSON_HAL
	inherit
		SIF_REPRESENTATION
			undefine
				default_create
			select
				is_equal,
				copy
			end

		JSON_PARSER_ACCESS
			undefine
				default_create
			end

		SHARED_EJSON
			undefine
				default_create
			end

		SHARED_URL_ENCODER
			undefine
				default_create
			end

		SIF_SHARED_PRODUCT_WEB_EWF
			undefine
				default_create
			end

		SIF_INTERACTION_ELEMENT_IDENTIFIERS_WEB


feature -- Status

	type: like {SIF_REPRESENTATION_ENUMERATION}.type
			-- Type of the representation by enumeration
		do
			Result := {SIF_REPRESENTATION_ENUMERATION}.json_hal
		end

feature -- Parsing

	parse (req: WSF_REQUEST; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET; a_ie_set_to_publish: SIF_INTERACTION_ELEMENT_SORTED_SET ) : SIF_REPRESENTATION_PARSE_RESULT
			-- Positive result, if parseable and input validation succeeded and all mandatory elements are available and any optional elements match.
			-- The interaction elements to publish needs to be filled with the mandatory and any optional interaction elements mapped from the input stream to the sorted set of interaction elements,
			-- so these can be used to publish to the interactor during interaction		
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
		do
			-- Search for any query values that match within the interaction elements of the query type
			from
				i := 1
			until
				i > a_sorted_set_of_interaction_elements.count
			loop
				a_sorted_set_of_interaction_elements.go_i_th (i)
				l_ie := a_sorted_set_of_interaction_elements.item
				if attached req.path_parameter (l_ie.descriptor) as l_path_query_item then
				   	if l_ie.is_valid_input( l_path_query_item.string_representation ) then
						l_ie.put_input (url_encoder.decoded_utf_8_string (l_path_query_item.string_representation))
						a_ie_set_to_publish.extend (l_ie)
				   	end
				end
				i := i + 1
			end

			from
				i := 1
			until
				i > a_sorted_set_of_interaction_elements.count
			loop
				a_sorted_set_of_interaction_elements.go_i_th (i)
				l_ie := a_sorted_set_of_interaction_elements.item
				if attached req.query_parameter (l_ie.descriptor) as l_query_query_item then
				   	if l_ie.is_valid_input( l_query_query_item.string_representation ) then
						l_ie.put_input (url_encoder.decoded_utf_8_string (l_query_query_item.string_representation))
						a_ie_set_to_publish.extend (l_ie)
				   	end
				end
				i := i + 1
			end

			create Result
		end

feature {NONE} -- Implementation

	redirect_url (a_set: SIF_INTERACTION_ELEMENT_SORTED_SET): detachable STRING
			-- Url used for redirection
			-- (Void if not relevant)
		local
			found: BOOLEAN
		do
			from
				a_set.start
			until
				found or else a_set.off
			loop
				if attached {SIF_IE_TEXT} a_set.item as la_ie_text then
					found := la_ie_text.identifier = Iei_web_redirect
					if found and then not la_ie_text.text.is_empty then
						Result := la_ie_text.text
					end
				end
				a_set.forth
			end
		end

	make_links (a_handler: SIF_WEB_API_REQUEST_HANDLER)
			-- Build `links' from the links associated with the current API request handler.
		local
			l_links: like links
			l_link_descriptors: STRING_TABLE [STRING]
		do
			create l_links.make (0)
			create l_link_descriptors.make (0)
			l_link_descriptors.compare_objects
			from
				a_handler.linked_handlers.start
			until
				a_handler.linked_handlers.off
			loop
				if
					attached {like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link} a_handler.linked_handlers.item as la_tuple_link and then
					attached {STRING} la_tuple_link.resource_path as la_resource_path
				then
					l_links.extend (create_link_descriptors (la_resource_path, la_tuple_link), la_resource_path)
				end
				a_handler.linked_handlers.forth
			end
			links := l_links
		end

	handle_links (a_handler: SIF_WEB_API_REQUEST_HANDLER; a_links: STRING_TABLE[ STRING_TABLE[STRING]]; a_res: HAL_RESOURCE)
			-- Add `a_links' representation to `a_res'.
		local
			l_str_link: STRING
			l_link_variable_descriptor_pairs: STRING_TABLE[STRING]
			j: INTEGER
			l_tag_found: BOOLEAN
			l_attribute: HAL_LINK_ATTRIBUTE
			l_link: HAL_LINK
		do
			from
				a_links.start
			until
				a_links.off
			loop
				create l_str_link.make_empty
				l_str_link.copy (a_links.key_for_iteration.to_string_8)
				l_link_variable_descriptor_pairs := a_links.item_for_iteration
				from
					l_link_variable_descriptor_pairs.start
				until
					l_link_variable_descriptor_pairs.off
				loop
					if
						attached l_link_variable_descriptor_pairs.item_for_iteration as l_field_descriptor and then
						attached {STRING} l_field_descriptor as l_readable_field_descriptor and then
					   	attached a_res.field_by_key (l_readable_field_descriptor) as l_field_value and then
					   	attached {STRING} l_field_value.out as l_readable_field_value
					then
					   		l_str_link.replace_substring_all ("{" + l_link_variable_descriptor_pairs.key_for_iteration + "}", url_encoder.encoded_string(l_readable_field_value))
					end
					l_link_variable_descriptor_pairs.forth
				end
				if not a_links.key_for_iteration.is_equal (l_str_link) then
					-- Only include the link when there was a substitution of a path variable with a HAL resource field value
					from
						j := 1
						l_tag_found := false
					until
						j > a_handler.linked_handlers.count or l_tag_found
					loop
						if attached {like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link} a_handler.linked_handlers.at(j) as l_tuple_link_1 then
							if attached {STRING} l_tuple_link_1.resource_path as l_resource_path_1 and then
							   attached {STRING} l_tuple_link_1.link_tag as l_tuple_tag then
							   	l_tag_found := l_resource_path_1.is_equal (a_links.key_for_iteration.to_string_8)
							   	create l_attribute.make (l_str_link)
								create l_link.make_with_attribute (l_tuple_tag, l_attribute)
								a_res.add_link (l_link)
							end
						end
						j := j + 1
					end
				end
				a_links.forth
			end
		end

	handle_pagination (a_set: SIF_INTERACTION_ELEMENT_SORTED_SET; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_res: HAL_RESOURCE)
			-- Add pagination links representation to `a_res'.
		local
			l_pagination_request: BOOLEAN
		do
			l_pagination_request :=
				attached {SIF_SYSTEM_INTERFACE_WEB_EWF} a_handler.system_interface as la_system_interface_web_ewf and then
				attached la_system_interface_web_ewf.query_table as la_query_table and then
				la_query_table.has_interaction_element (Iei_page_number)

			add_page_link (Iei_first, a_set, a_handler, a_res)
			if l_pagination_request then
				add_page_link (Iei_previous, a_set, a_handler, a_res)
				add_page_link (Iei_next, a_set, a_handler, a_res)
			end
			add_page_link (Iei_last, a_set, a_handler, a_res)
		end

	add_page_link (a_id: INTEGER_64; a_set: SIF_INTERACTION_ELEMENT_SORTED_SET; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_res: HAL_RESOURCE)
			-- Add pagination link representation specified by `a_id' to `a_res'.
		local
			l_ref: STRING
		do
		   	if attached a_set.interaction_element (a_id) as la_ie then
				l_ref := a_handler.resource_template.template + "?page=" + la_ie.to_string
				if la_ie.to_string.is_natural and then la_ie.to_string.to_natural > 0 then
					add_link (a_res, l_ref, la_ie.descriptor)
				end
			end
		end

	handle_list (a_ie_list: SIF_IE_LIST; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_res: HAL_RESOURCE)
			-- Add list's elements representation to `a_res'.
		local
			l_sub_res: HAL_RESOURCE
			l_resource_list: ARRAYED_LIST [HAL_RESOURCE]
			l_ref: STRING
		do
			create l_resource_list.make (0)
			if not a_ie_list.elements.is_empty then
				resources_found := true
				across a_ie_list.elements as la_elements loop
					if not la_elements.item.is_empty then
						create l_sub_res.make
						handle_list_elements (la_elements.item, l_sub_res)
						if attached la_elements.item.interaction_element (Iei_self_identifier) as la_ie_self_identifier then
							l_ref := "/v1/" + a_ie_list.descriptor
							if not la_ie_self_identifier.to_string.is_empty then
								l_ref.append ("/" + la_ie_self_identifier.to_string)
							end
							add_link_with_title (l_sub_res, l_ref, la_ie_self_identifier.descriptor, "self")
						end
						if attached links as l_links then
							handle_links (a_handler, l_links, l_sub_res)
						end
						l_resource_list.force (l_sub_res)
					end
				end
				a_res.add_embedded_resources_with_key (a_ie_list.descriptor, l_resource_list)
			end
		end

	handle_top_elements (a_set: SIF_INTERACTION_ELEMENT_SORTED_SET; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_res: HAL_RESOURCE)
			-- Add `a_set''s representation to `a_res'.
		do
			from
				a_set.start
			until
				a_set.off
			loop
				if attached {SIF_IE_OBJECT} a_set.item as la_ie_object then
					handle_object (la_ie_object, a_res)
				elseif attached {SIF_IE_LIST} a_set.item as la_ie_list then
					handle_list (la_ie_list, a_handler, a_res)
				elseif attached {SIF_IE_TEXT} a_set.item as la_ie_text and then la_ie_text.is_result then
					a_res.add_string_field (la_ie_text.descriptor, la_ie_text.to_string)
				elseif attached {SIF_IE_BOOLEAN} a_set.item as la_ie_boolean and then la_ie_boolean.is_result then
					a_res.add_string_field (la_ie_boolean.descriptor, la_ie_boolean.to_string)
				elseif attached {SIF_IE_NUMERIC} a_set.item as la_ie_numeric and then is_enabled_result (la_ie_numeric) then
					handle_numeric_item (la_ie_numeric, a_res)
				end
				a_set.forth
			end
		end

	handle_top_links (a_req: WSF_REQUEST; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_set: SIF_INTERACTION_ELEMENT_SORTED_SET; a_res: HAL_RESOURCE)
			-- Add top links representation to `a_res'.
		do
			add_link (a_res, a_req.request_uri, "self")
			if a_handler.pagination_capable then
				handle_pagination (a_set, a_handler, a_res)
			end
			if attached a_handler.search as la_search then
				add_link (a_res, la_search, "search")
			end
		end

	handle_sub_list (a_ie_list: SIF_IE_LIST; a_res: HAL_RESOURCE)
			-- Add `a_ie_list' representation to `a_res'.
		local
			l_resource_list: ARRAYED_LIST[HAL_RESOURCE]
			l_sub_res: HAL_RESOURCE
		do
			create l_resource_list.make (0)
			across a_ie_list.elements as l_list_item loop
				create l_sub_res.make
				handle_list_elements (l_list_item.item, l_sub_res)
				l_resource_list.force (l_sub_res)
			end
			a_res.add_embedded_resources_with_key (a_ie_list.descriptor, l_resource_list)
		end

	handle_list_elements (a_set: SIF_INTERACTION_ELEMENT_SORTED_SET; a_res: HAL_RESOURCE)
			-- Add `a_set' representation to `a_res'.
		do
			from
				a_set.start
			until
				a_set.off
			loop
				if attached {SIF_IE_OBJECT} a_set.item as la_ie_object then
					handle_object (la_ie_object, a_res)
				elseif attached {SIF_IE_TEXT} a_set.item as la_ie_text and then is_enabled_result (la_ie_text) then
					a_res.add_string_field (la_ie_text.descriptor, la_ie_text.to_string)
				elseif attached {SIF_IE_BOOLEAN} a_set.item as la_ie_boolean and then is_enabled_result (la_ie_boolean) then
					a_res.add_boolean_field (la_ie_boolean.descriptor, la_ie_boolean.boolean)
				elseif attached {SIF_IE_LIST_SINGLE_SELECT} a_set.item as la_ie_list_single_select and then is_enabled_result (la_ie_list_single_select) then
					a_res.add_string_field (la_ie_list_single_select.descriptor, convert_to_json_array_representation (la_ie_list_single_select))
				elseif attached {SIF_IE_NUMERIC} a_set.item as la_ie_numeric and then is_enabled_result (la_ie_numeric) then
					handle_numeric_item (la_ie_numeric, a_res)
				elseif attached {SIF_IE_LIST}a_set.item as la_ie_list_embedded and then is_enabled_result (la_ie_list_embedded) then
					handle_sub_list (la_ie_list_embedded, a_res)
				end
				a_set.forth
			end
		end

	handle_object (a_ie_object: SIF_IE_OBJECT; a_res: HAL_RESOURCE)
			--
		local
			l_table: STRING_TABLE [STRING]
		do
			create l_table.make (a_ie_object.fields.count)
			across
				a_ie_object.fields as l_fields
			loop
				l_table.put (l_fields.item.to_string, l_fields.item.descriptor)
			end
			a_res.add_object_field (a_ie_object.descriptor, l_table)
		end

	is_enabled_result (a_ie: SIF_INTERACTION_ELEMENT): BOOLEAN
			-- Is a_ie a result ie and is it enabled ?
		do
			Result := a_ie.is_result and a_ie.enabled
		end

	do_represent (req: WSF_REQUEST; res: WSF_RESPONSE; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET)
			-- Create a representation by using the interaction elements which contain the information for the content.
			--
			-- Explanation of this implementation:
			--    This algorithm needs to substitute the interaction elements in the
			--    a_sorted_set_of_interaction_elements to embedded links and resource information
			--    into a JSON+HAL resource description according to the specification of this.
			--
			--	  Also the information about links to other resources has to be processed.
			--    The links, if any, were configured in the product (inherited from SIF_PRODUCT_WEB_EWF) class of the system.
			--    First the links associated with the current API request handler are transformed in a list of links.
			--    For each link all related link descriptors are created, containing pairs of:
			--                key: path or query variable in the resource path (could be a templated path or a URI)
			--                item: descriptor which is a reference to the descriptor of the result interaction element value which needs to be replaced in the resulting link
			--
			--  Example: link configuration
			--
			--		resource path:   URI ->  /products/{location_code}/{date}		[This is an URI template]
			--			location_code is a path variable of the URI template
			--			date is a path variable of the URI template
			--      link list:
			--				1. link_type: 1									--> Intended to include as an embedded resource link
			--				   template_name: "location_code"				--> The name of the path variable in the URI template
			--                 descriptor: "code"						 	--> The descriptor of the associated interaction element
			--				2. link_type: 0									--> There is a query item, but it does not need to be replaced in the link representation
			--                 template_name: void							--> Not applicable
			--                 descriptor: ""								--> Not applicable
			--
			--   When the above preparation has been executed the resulting collection in a list is used to add links according to the configured prepared links.
			--
			--    The a_sorted_set_of_interaction_elements are in fact the results of a command being executed.
			--    These result set of interaction elements are investigated for having the following types:
			--       IE_TEXT: this is just a single result name value pair of the resource.
			--       IE_LIST: this is handled as a list of embedded resources
			--                The list normally contains one or more items describing a resource of the list.
			--				  They are added as an embedded HAL resource to the main HAL resource
			--                to be constructed as the resulting representation.
			--                For each resource/item in the list, it will be investigated if any link
			--				  is configured for the API request handler handling the current request.
			--				  If this is the case, the links will be created using the information from the preparation described above.
			--
		local
			l_json_hal_resource_converter: JSON_HAL_RESOURCE_CONVERTER
			l_res_main: HAL_RESOURCE
		do
			if attached redirect_url (a_sorted_set_of_interaction_elements) as la_url then
				res.redirect_now (la_url)
			else
				create l_json_hal_resource_converter.make
				create l_res_main.make
				make_links (a_handler)

				handle_top_elements (a_sorted_set_of_interaction_elements, a_handler, l_res_main)

				if not resources_found then
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
				else
					handle_top_links (req, a_handler, a_sorted_set_of_interaction_elements, l_res_main)

					if attached l_json_hal_resource_converter.to_json (l_res_main) as la_hal then
						if req.is_post_request_method then
							res.set_status_code ({HTTP_STATUS_CODE}.created)
						end
						res.header.put_content_type ("application/hal+json")
						res.put_string (la_hal.representation)
					end
				end
			end
		end

	resources_found: BOOLEAN
				--

	links: detachable STRING_TABLE[ STRING_TABLE[STRING]]
				-- Key: the resource path string. Item a STRING_TABLE of link descriptors where (key: path or query variable, item: field descriptor reference)

	add_link_with_title (a_res: HAL_RESOURCE; a_ref: STRING; a_title: detachable STRING; a_rel: STRING)
			-- Add a link to `a_res' with `a_ref' for the attribute and `a_rel' for the link.
			-- If not Void `a_title' is set to the attribute
		local
			l_link: HAL_LINK
			l_attribute: HAL_LINK_ATTRIBUTE
		do
			create l_attribute.make (a_ref)
			if attached a_title as la_title then
				l_attribute.set_title (la_title)
			end
			create l_link.make_with_attribute (a_rel, l_attribute )
			a_res.add_link (l_link)
		end

	add_link (a_res: HAL_RESOURCE; a_ref: STRING; a_rel: STRING)
			-- Add a link to `a_res' with `a_ref' for the attribute and `a_rel' for the link.
		do
			add_link_with_title (a_res, a_ref, Void, a_rel)
		end

	create_link_descriptors(a_resource_path: STRING; a_tuple_link: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link ): STRING_TABLE[STRING]
		local
			l_uri_template: like uri_template
			l_uri_with_query: like uri_with_query
			l_path_variable_names: LIST [STRING]
			l_query_value_template_name: STRING
		do
			create Result.make (0)
			l_uri_template := uri_template (a_resource_path)
			if attached {like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_list} a_tuple_link.link_list as l_tuple_link_list then
				if attached l_uri_template as la_uri_template then
					l_path_variable_names := la_uri_template.path_variable_names
					from
						l_path_variable_names.start
					until
						l_path_variable_names.off
					loop
						handle_link_variable(l_tuple_link_list, l_path_variable_names.item_for_iteration, Result)
						l_path_variable_names.forth
					end
					from
						la_uri_template.query_variable_names.start
					until
						la_uri_template.query_variable_names.off
					loop
						handle_link_variable(l_tuple_link_list, la_uri_template.query_variable_names.item_for_iteration, Result)
						la_uri_template.query_variable_names.forth
					end
				else
					l_uri_with_query := uri_with_query (a_resource_path)
					if attached l_uri_with_query as la_uri_with_query and then
					   attached la_uri_with_query.query_items as l_uri_query_items then
						from
							l_uri_query_items.start
						until
							l_uri_query_items.off
						loop
							if attached {READABLE_STRING_8}l_uri_query_items.item_for_iteration.value as l_value_template_name then
								create l_query_value_template_name.make_from_string (l_value_template_name)
								l_query_value_template_name.replace_substring_all ("{", "")
								l_query_value_template_name.replace_substring_all ("}", "")
								handle_link_variable(l_tuple_link_list, l_query_value_template_name, Result)
							end
							l_uri_query_items.forth
						end
					end
				end
			end
		end

	handle_link_variable (a_tuple_link_list: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_list; a_path_variable: STRING; a_result: like create_link_descriptors)
		do
			from
				a_tuple_link_list.start
			until
				a_tuple_link_list.off
			loop
				if attached {like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_descriptor} a_tuple_link_list.item as l_link_descriptor and then
				   attached {STRING}l_link_descriptor.template_name as l_link_template and then
				   attached {STRING}l_link_descriptor.descriptor as l_link_field_descriptor_reference and then
				   attached {INTEGER}l_link_descriptor.link_type as l_link_type then
				   	if l_link_template.is_equal(a_path_variable) and l_link_type = 1 and not a_result.has_key (l_link_template) then
						a_result.extend (l_link_field_descriptor_reference, l_link_template)
				   	end
				end
				a_tuple_link_list.forth
			end
		end


feature {NONE} -- Implementation

	uri_template (a_resource_path: STRING): detachable URI_TEMPLATE
			-- Result not void means, the current a_resource_path value is a uri_template and not just a uri.
		do
			create Result.make (a_resource_path)

			if Result.is_valid and then not Result.path_variable_names.is_empty and then Result.query_variable_names.is_empty then
				-- Result is a valid uri template!!
			else
				Result := void
			end
		end

	uri_with_query (a_resource_path: STRING): detachable URI
			-- Result not void means, the current a_resource_path value is a uri_template and not just a uri.
		do
			create Result.make_from_string (product_web.scheme + "://" + product_web.base_url + ":" + product_web.port.out + a_resource_path)

			if Result.is_valid and then Result.has_query then
				-- Result is a valid uri template!!
			else
				Result := void
			end
		end

	convert_to_json_array_representation (a_ie_list_single_select: SIF_IE_LIST_SINGLE_SELECT): STRING
		local
			l_json_array: JSON_ARRAY
			l_list_item_array: ARRAY[STRING]
			l_first: BOOLEAN
		do
			create Result.make_from_string ("[")
			create l_json_array.make (a_ie_list_single_select.list.count)
			across a_ie_list_single_select.list as list_item loop
				l_list_item_array := list_item.item
				if l_list_item_array.count = 1 then
					if not l_first then
						l_first := true
						Result.append( " " + l_list_item_array.at (1))
					else
						Result.append( ", " + l_list_item_array.at (1))
					end
				end
			end
			Result.append (" ]")
		end

	handle_numeric_item (l_ie_numeric: SIF_IE_NUMERIC; l_res: HAL_RESOURCE)
		do
			if l_ie_numeric.numeric_type.type = {SIF_ENUM_IE_NUMERIC}.enum_natural and then
			   l_ie_numeric.text.is_natural_64 then
			   	l_res.add_natural_field (l_ie_numeric.descriptor, l_ie_numeric.text.to_natural_64)
			else
				check no_correct_numerical_value: false end
			end
		end

end
