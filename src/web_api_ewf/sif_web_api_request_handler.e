note
	description: "Summary description for {SIF_WEB_API_REQUEST_HANDLER}."
	author: "Paul Gokke"
	date: "$Date$"
	revision: "$Revision$"
	library: "System Interface Framework (SIF)"
	legal: "See notice at end of class."

class
	SIF_WEB_API_REQUEST_HANDLER

inherit

		SIF_INTERACTION_ELEMENT_IDENTIFIERS

		SIF_REPRESENTATION_ENUMERATION
			undefine
				default_create
			end

		HTTP_REQUEST_METHODS
			undefine
				default_create
			end

		SIF_SHARED_COMMAND_MANAGER
			undefine
				default_create
			end

		SIF_SHARED_PRODUCT_WEB_EWF
			undefine
				default_create
			end

		SHARED_LOG_FACILITY
			undefine
				default_create
			end

		HTTP_STATUS_CODE_MESSAGES
			undefine
				default_create
			end

		SHARED_URL_ENCODER
			undefine
				default_create
			end

create

	make

feature {NONE} -- Initialization

	make(a_command_identifier : INTEGER_64; a_request_methods: WSF_REQUEST_METHODS; a_resource_template: URI_TEMPLATE; a_pagination_capable: like pagination_capable; a_search: like search)
		require
			command_identifier_is_not_0: a_command_identifier /= 0
			valid_resource_template: a_resource_template.is_valid
		do
			--
			-- Important!!!!: only create instances of objects which do not change dynamically here.
			-- this is due to the concurrent nature of the EWF framework and current is only created once in
			-- the system, but executed through a dynamically created object of class SIF_SYSTEM_INTERFACE_WEB_EWF.
			--
			default_create
			command_identifier := a_command_identifier
			request_methods := a_request_methods
			pagination_capable := a_pagination_capable
			search := a_search

			resource_template := a_resource_template

			-- Following lines to make compiler happy for void safeness
			create tuple_link_list.make (0)
			create tuple_link
			create tuple_link_descriptor

			create linked_handlers.make (0)
			representation_response := {SIF_REPRESENTATION_ENUMERATION}.json  -- Assumming JSON is the most used!
		end

feature -- Initialization run time creation

	create_new_context: SIF_WEB_API_REQUEST_HANDLER
			-- Create a new context, meaning create a new instance of Current and a new set of references for a new context
		do
			Result := Current.deep_twin
		end

feature -- API

	resource_template: URI_TEMPLATE
			-- This is the description of the specific resources which needs to be a valid URI template, it's a direct part of the web API.

	request_methods: WSF_REQUEST_METHODS
			-- The associated HTTP request methods, being one or more of the methods of class HTTP_REQUEST_METHODS of the Eiffel Web Framework (EWF).

feature -- Web execution

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
		require
			has_system_interface: attached system_interface
		local
			l_representation_type: like {SIF_REPRESENTATION_ENUMERATION}.type
			l_http_status_code: like {HTTP_STATUS_CODE}.ok
			l_content_type_string: STRING
			l_content_type_undefined: STRING
			l_media_path_comparer: STRING
			l_media_path_index_first_template_char: INTEGER
			l_command_cpy: SIF_INTERACTOR
		do
			write_information ("%T[Web Api handler] Executing handler.")
			l_http_status_code := {HTTP_STATUS_CODE}.ok
			if attached req.path_info as l_path_info and
			   attached {SIF_SYSTEM_INTERFACE_WEB_EWF}system_interface as l_system_interface_web_ewf and then
			   attached {SIF_PRODUCT_WEB_EWF}l_system_interface_web_ewf.product_web as l_product_web_ewf and then
			   attached {SIF_REPRESENTATION}l_product_web_ewf.available_representations.at(representation_response) as l_representation_result and then
			   attached l_system_interface_web_ewf.interaction_table as interaction_table and then
			   attached l_system_interface_web_ewf.executing_command as la_command  and then
			   attached l_system_interface_web_ewf.query_table as l_query_table then
				l_representation_type := {SIF_REPRESENTATION_ENUMERATION}.undefined
				if attached req.content_type as l_content_type then
					create l_content_type_string.make_from_string (l_content_type.type)
					l_content_type_string.append ("/")
					l_content_type_string.append (l_content_type.subtype)
					if is_content_type_mappable (l_content_type_string) then
						l_representation_type := map_content_type_to_sif_representation_type (l_content_type_string)
					end
				else
					-- No Content-Type available, are there query parameters involved?
					if req.path_info.starts_with ("/themes") then
						l_representation_type := {SIF_REPRESENTATION_ENUMERATION}.theme
					elseif req.is_request_method (method_get) then
						if product_web.has_media then
							create l_media_path_comparer.make_from_string (product_web.media_resource_path)
							l_media_path_index_first_template_char := product_web.media_resource_path.index_of ('{', 1)
							l_media_path_comparer.keep_head (l_media_path_index_first_template_char - 2)
						   	if req.path_info.starts_with (l_media_path_comparer) then
								l_representation_type := {SIF_REPRESENTATION_ENUMERATION}.media
							end
						else
							if not req.query_string.is_empty then
								l_representation_type := {SIF_REPRESENTATION_ENUMERATION}.nvp
							end
						end
					end
				end
				if l_representation_type /= {SIF_REPRESENTATION_ENUMERATION}.undefined then
					write_information ("%T[Web Api handler] Found a matching representation type -> " + representation_type_as_string(l_representation_type))
				end
				if attached {SIF_REPRESENTATION}l_product_web_ewf.available_representations.at(l_representation_type) as l_representation then
					write_information ("%T[Web Api handler] Found an available representation for parsing the request for type: " + representation_type_as_string(l_representation_type))
					l_http_status_code := l_representation.parse (req, la_command.interaction_elements, interaction_table).code
					if l_http_status_code = {HTTP_STATUS_CODE}.ok then
						write_information ("%T[Web Api handler] Successfully parsed the request.")
					else
						-- Notity situation: requested representation type/content type was available in the product, but the request could not be parsed...
						write_notice ("%T[Web Api handler] Requested representation type/content type was available in the product, but the request could not be parsed!")
					end
				else
					-- No representation was found until now, let's try to find one that will parse the request, so we can still execute the request
					-- through the command found.
					--
					-- For now we only try HTML.
					write_information ("%T[Web Api handler] Trying HTML as representation for parsing the request.")
					if attached {SIF_REPRESENTATION}l_product_web_ewf.available_representations.at({SIF_REPRESENTATION_ENUMERATION}.html) as l_representation_try then
						l_http_status_code := l_representation_try.parse (req, la_command.interaction_elements, interaction_table).code
						if l_http_status_code = {HTTP_STATUS_CODE}.ok then
							write_information ("%T[Web Api handler] Successfully parsed the request using the " + representation_type_as_string({SIF_REPRESENTATION_ENUMERATION}.html) + " representation.")
						else
							write_information ("%T[Web Api handler] Parsing the request failed using the " + representation_type_as_string({SIF_REPRESENTATION_ENUMERATION}.html) + " representation.")
						end
					end
				end
				if req.is_get_request_method then
					l_http_status_code := parse_query_parameters(req, la_command.query_interaction_elements, l_query_table).code
				end

				if l_representation_type /= {SIF_REPRESENTATION_ENUMERATION}.undefined then
					if l_http_status_code = {HTTP_STATUS_CODE}.ok then
						if l_http_status_code = {HTTP_STATUS_CODE}.ok then
							write_information ("%T[Web Api handler] Going to execute the command.")
							la_command.set_pagination_capable (pagination_capable)

							la_command.execute (l_system_interface_web_ewf)
							if not la_command.is_ended then
								if attached {SIF_IE_EVENT}la_command.interaction_elements.interaction_element (Iei_confirm) as l_ie_confirm then
									l_ie_confirm.event.publish
								end
							end
							if la_command.execution_result.passed then
								write_information ("%T[Web Api handler] Command was executed succesfully, trying to find an available representation to create a response.")
								if req.is_delete_request_method then
									l_http_status_code := {HTTP_STATUS_CODE}.gone
									write_information ("%T[Web Api handler] It was a proper deletion, so no representation available be default.")
								else
									if attached la_command.result_interaction_elements as l_result_ies then
									   	write_information ("%T[Web Api handler] Trying to make a representation for type: " + representation_type_as_string(representation_response))
										l_representation_result.represent(req, res, Current, l_result_ies)
									else
										write_notice ("%T[Web Api handler] Did not find an available representation to create a response for representation type: " + representation_type_as_string(representation_response))
										l_http_status_code := internal_server_error
									end
								end
							else
								if la_command.execution_result.excepted then
									write_notice ("%T[Web Api handler] Command has been excepted as to create a valid execution result. Something really bad happend, probably some infrastructural problem, like a database being down!!!")
									l_http_status_code := internal_server_error
								else
									l_http_status_code := {HTTP_STATUS_CODE}.not_found
									write_information ("%T[Web Api handler] The resource was not found.")
								end
							end
						else
							write_notice ("%T[Web Api handler] Failed to parse the query parameters correctly according to command query interaction elements.")
						end
					else
						write_notice ("%T[Web Api handler] Did not execute a command.")
					end
				else
					create l_content_type_undefined.make_from_string("Content-type not available")
					if attached req.content_type as la_content_type then
						l_content_type_undefined.make_from_string (la_content_type.string)
					end
					write_notice ("%T[Web Api handler] Did not find an available representation type for " + l_content_type_undefined)
					l_http_status_code := {HTTP_STATUS_CODE}.bad_request
				end
				l_system_interface_web_ewf.cleanup
			end
			if res.status_committed or res.status_code /= {HTTP_STATUS_CODE}.ok then
				l_http_status_code := res.status_code
			else
				res.set_status_code (l_http_status_code)
			end
			if attached http_status_code_message(l_http_status_code) as l_http_status_code_message then
				log_string.make_from_string (l_http_status_code_message)
			end
			write_information ("%T[Web Api handler] Status code = [" + l_http_status_code.out + "] " + log_string)
		end

feature -- Representation

	put_representation_result( a_representation_type: like representation_response )
			-- Put a new representation type for representing the response
		require
			valid_type: is_type_valid( a_representation_type )
		do
			representation_response := a_representation_type
		end

feature -- Interaction

	put_system_interface(a_system_interface_web_ewf: detachable SIF_SYSTEM_INTERFACE_WEB_EWF)
			-- Attach the system interface
		do
			system_interface := a_system_interface_web_ewf
		end

	system_interface: detachable SIF_SYSTEM_INTERFACE_WEB_EWF

feature -- Query specific

	parse_query_parameters(req: WSF_REQUEST; a_query_interaction_elements: like {SIF_COMMAND[SIF_DAO[ANY]]}.query_interaction_elements; a_query_table: SIF_INTERACTION_ELEMENT_SORTED_SET): SIF_REPRESENTATION_PARSE_RESULT
			-- Parse the possibilties for query parameters, so the command can filter on any available to
			-- have a response which could be a sub collection of the complete resources collection.
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			l_count_mandatory: INTEGER
			l_count_parsed_mandatory: INTEGER
			l_uri_template: URI_TEMPLATE
			l_use_uri_template_path_variables: BOOLEAN
		do
			create Result
			if attached a_query_interaction_elements as l_query_iess then
				create l_uri_template.make (req.path_info)
				l_use_uri_template_path_variables := l_uri_template.is_valid and then not l_uri_template.path_variable_names.is_empty and then l_uri_template.query_variable_names.is_empty
				from
					l_count_mandatory := 0
					l_count_parsed_mandatory := 0
					i := 1
				until
					i > l_query_iess.count
				loop
					l_query_iess.go_i_th (i)
					l_ie := l_query_iess.item
					if l_ie.is_mandatory then
						l_count_mandatory := l_count_mandatory + 1
						if attached req.query_parameter (l_ie.descriptor) as l_query_item_mandatory then
						   	if l_ie.is_valid_input( url_encoder.decoded_utf_8_string (l_query_item_mandatory.string_representation) ) then
								l_ie.put_input (url_encoder.decoded_utf_8_string (l_query_item_mandatory.string_representation))
								a_query_table.extend (l_ie)
								l_count_parsed_mandatory := l_count_parsed_mandatory + 1
						   	else
						   		Result.set_invalid_input
						   	end
						else
							if attached req.path_parameter (l_ie.descriptor) as l_path_parameter_item and then
							   l_path_parameter_item.is_string then
							   	if l_ie.is_valid_input( url_encoder.decoded_utf_8_string (l_path_parameter_item.as_string.value) ) then
									l_ie.put_input (url_encoder.decoded_utf_8_string (l_path_parameter_item.as_string.value))
									a_query_table.extend (l_ie)
									l_count_parsed_mandatory := l_count_parsed_mandatory + 1
							   	else
							   		Result.set_invalid_input
							   	end
							end
						end
					end
					if l_ie.is_optional then
						if attached req.query_parameter (l_ie.descriptor) as l_query_item_optional then
						   	if l_ie.is_valid_input( url_encoder.decoded_utf_8_string (l_query_item_optional.string_representation) ) then
								l_ie.put_input (url_encoder.decoded_utf_8_string (l_query_item_optional.string_representation))
								a_query_table.extend (l_ie)
						   	else
						   		Result.set_invalid_input
						   	end
						else
							if attached req.path_parameter (l_ie.descriptor) as l_path_parameter_item and then
							   l_path_parameter_item.is_string then
							   	if l_ie.is_valid_input( url_encoder.decoded_utf_8_string (l_path_parameter_item.as_string.value) ) then
									l_ie.put_input (url_encoder.decoded_utf_8_string (l_path_parameter_item.as_string.value))
									a_query_table.extend (l_ie)
							   	else
							   		Result.set_invalid_input
							   	end
							end
						end
					end
					i := i + 1
				end
			end
			if l_count_mandatory /= l_count_parsed_mandatory then
				Result.set_invalid_mandatory
			end
		end

feature -- Implementation

	command_identifier: INTEGER_64
			-- A unique command identifier, which refers to the command to be executed for this request handler.

	linked_handlers: ARRAYED_LIST[like tuple_link]
			-- The linked/related/associated handlers for Current.

	tuple_link: TUPLE[resource_path:STRING;
					  link_list: like tuple_link_list;
					  link_tag:STRING]

	tuple_link_descriptor: TUPLE[link_type: INTEGER; template_name: STRING; descriptor: STRING]

	tuple_link_list: ARRAYED_LIST[like tuple_link_descriptor]

	pagination_capable: BOOLEAN
			-- True, when the handler is capable of handling pagination for large result collections of resources

	search: detachable STRING
			-- If available, it describes how resources of this kind can be searched by a client

feature {NONE} -- Implementation

	representation_response: like {SIF_REPRESENTATION_ENUMERATION}.type

invariant

	valid_representation_response_type: is_type_valid( representation_response )
	correct_paginatin_availablity: pagination_capable implies request_methods.has_method_get
	correct_use_of_search: attached search implies request_methods.has_method_get

;note
	copyright: "Copyright (c) 2014-2017, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end

