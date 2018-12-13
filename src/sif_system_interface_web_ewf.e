note
	description: "Summary description for {SIF_SYSTEM_INTERFACE_WEB_EWF}."
	author: "Paul Gokke"
	date: "$Date$"
	revision: "$Revision$"
	library: "System Interface Framework (SIF)"
	legal: "See notice at end of class."

class
	SIF_SYSTEM_INTERFACE_WEB_EWF
	inherit
		SIF_SYSTEM_INTERFACE_WEB

		WSF_ROUTED_EXECUTION
			rename
				execute as wsf_routed_execution_execute
			redefine
				execute_default
			end

		REFACTORING_HELPER

		SIF_SHARED_COMMAND_MANAGER

		HTTP_REQUEST_METHODS

		HTTP_CONSTANTS

		WSF_ROUTED_URI_HELPER

		WSF_URI_TEMPLATE_HANDLER

		SIF_SHARED_PRODUCT_WEB_EWF

		SIF_SHARED_COMMAND_MANAGER

		SHARED_LOG_FACILITY

create
	make

feature {NONE} -- Initialization

	execute_default (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Dispatch requests without a matching handler.
		do
			res.set_status_code ({HTTP_STATUS_CODE}.not_found)
		end

	setup_router
		local
			l_content_type: STRING
		do
			create l_content_type.make_empty
			if attached request.content_type as l_request_content_type then
				l_content_type.append (l_request_content_type.string)
			end
			write_information ("HTTP request received -> " + request.debug_output +
			                             "%N%TContent-Type: " + l_content_type +
			                             "%N%TPath info: " + request.path_info +
			                             "%N%TQuery string: " + request.query_string +
			                             "%N%TRemote Address: " + request.remote_addr )
			web_api_handler := void
			web_api_handlers := void
			router.pre_execution_actions.force (agent pre_execute)
			across product_web.api_handlers as all_handlers loop
				if attached all_handlers.item as l_web_api_request_handler then
					router.handle (l_web_api_request_handler.resource_template.template, Current, l_web_api_request_handler.request_methods)	-- Create the web API from the web api handlers.
				end
			end
		end

	pre_execute(a_mapping: WSF_ROUTER_MAPPING)
			-- Find all web api handlers which match the resource string of the given mapping.
			-- One of the found web api handlers will be used during router execution.
			-- That one will need to match the request method.
		local
			i: INTEGER
			l_api_handler: SIF_WEB_API_REQUEST_HANDLER
			l_handlers: STRING
		do
			write_information ("%T" + "Performing pre execution, looking for -> " + a_mapping.associated_resource)
			from
				i := 1
				create l_handlers.make_from_string ("%T%T%T")
			until
				i > product_web.api_handlers.count
			loop
				l_api_handler := product_web.api_handlers.at (i)
				if l_api_handler.resource_template.template.is_equal ( a_mapping.associated_resource ) then
					if not attached web_api_handlers then
						create web_api_handlers.make(0)
					end
					if attached web_api_handlers as l_web_api_handlers then
						l_web_api_handlers.extend (l_api_handler)
						if attached command_manager.command (l_api_handler.command_identifier) as l_command then
							l_handlers.append (l_command.identifier.out + " - " + l_command.generator + "%T")
						end
					end
				end
				i := i + 1
			end
			if attached web_api_handlers as l_found_web_api_handlers then
				write_information ("%T%T%T" + "Found the following handler(s): ")
				write_information (l_handlers)
			else
				write_notice ("No handler found! for resource path: " + a_mapping.associated_resource + ". This will result in http status code: " + unauthorized.out )
			end
		end

	execute(req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute handler for `req' and respond in `res'.
			-- Due to the concurrent nature of the Eiffel Web Framework, it is possible that
		   	-- this execute_request_handler feature is called concurrently, meaning that a mapped URI (resource) of the
		   	-- correct web api handler to be executed needs to be run in it's own context.
		   	-- For this a new instance of the api handler is created during runtime.
		local
			l_api_handler: detachable SIF_WEB_API_REQUEST_HANDLER
			i: INTEGER
			l_api_handler_found: BOOLEAN
		do
			write_information ("%T" + "Trying to find a match between handler and request method, for the following request:")
			write_information ("%T%T" + req.debug_output)
			if product_web.is_query_string_based_command_executer then
				if attached {WSF_STRING}req.query_parameter(product_web.query_string_command_field_name) as l_query_string_command then

					if attached command_manager.command_by_descriptor(l_query_string_command.value) as l_command then
						from
							i := 1
						until
							i > product_web.api_handlers.count or l_api_handler_found
						loop
							l_api_handler := product_web.api_handlers.at (i)
							if l_api_handler.command_identifier = l_command.identifier and l_api_handler.request_methods.has (req.request_method) then
								l_api_handler_found := true
							else
								i := i + 1
							end
						end
					end
				end
			end

			if attached web_api_handlers as l_web_api_handlers then
				from
					i := 1
				until
					i > l_web_api_handlers.count or web_api_handler /= void
				loop
					if l_web_api_handlers.at (i).request_methods.has (req.request_method) then
						web_api_handler := l_web_api_handlers.at(i)
					end
					i := i + 1
				end

				if attached web_api_handler as la_api_handler and then
				   attached command_manager.command (la_api_handler.command_identifier) as l_matched_command then
					write_information ("%T%T" + "Found the following match, Method: " + req.request_method + " vs Handler for -> (Command) Identifier: " + l_matched_command.identifier.out + " Descriptor: " + l_matched_command.descriptor)
					-- Due to the concurrent nature of the Eiffel Web Framework, the command to be executed
				   	-- needs to be run in it's own context. The context is current, while current is created when a HTTP request is received by the framework
				   	-- So the found command will be twinned from the associated command of the found api handler.

				   	-- Note that the next line will create a new instance of the associated command during run-time...
					if attached {SIF_COMMAND}l_matched_command.create_new_context as la_command then
						executing_command := la_command
						web_api_handler := la_api_handler.create_new_context
						create query_table.make
						create interaction_table.make

						if attached web_api_handler as l_new_web_api_handler and
						   attached query_table as l_query_table then
							-- Important step to let the handler know about current as system interface
							l_new_web_api_handler.put_system_interface (Current)

							l_new_web_api_handler.execute(req, res)
						end
					end
				else
					write_notice ("No match found! for resource path. This will result in http status code: " + unauthorized.out )
				end
			end
		end


feature -- API DOC

	api_doc : STRING = ""


feature -- Documentation

	mapping_documentation (m: WSF_ROUTER_MAPPING; a_request_methods: detachable WSF_REQUEST_METHODS): WSF_ROUTER_MAPPING_DOCUMENTATION
		do
			create Result.make (m)
--			if a_request_methods /= Void then
--				if a_request_methods.has_method_get then
--					Result.add_description ("URI:/command/{commandid} METHOD: GET")
--				end
--			end
		end


feature -- Interaction

	interact(an_interaction_elements_set: SIF_INTERACTION_ELEMENT_SORTED_SET)
			-- interact through the set of interaction elements
		require else
			has_web_api_handler: web_api_handler /= void
		do
			if attached web_api_handler as l_web_api_handler and
			   attached interaction_table as l_interaction_table and
			   attached query_table as l_query_table and
			   attached executing_command as l_executing_command then
				-- Interact is called after execute and the execution of a command is called through the found api handler.
				-- While the interactor of the command will create interaction elements dynamically before interact is called
				-- all the interaction elements of the command are recreated and thus do not have any valid input values anymore
				-- this is why the interaction table is used. The values from this intermediate interaction table input elements are now duplicated
				-- into the newly created interaction elements of the running command context.
				across l_interaction_table as all_interaction_elements loop
					if attached all_interaction_elements.item as l_ie then
						if attached an_interaction_elements_set.interaction_element (l_ie.identifier) as la_ie then
							la_ie.duplicate (l_ie)    -- Here the actual duplicate of the element of the interaction table is created for the equivalent element in the command.
						end
					end
				end
				if attached l_executing_command.query_interaction_elements as l_query_interaction_elements then
					-- Do the same for the query interaction elements
					across l_query_table as all_query_interaction_elements loop
						if attached all_query_interaction_elements.item as l_ie_query then
							if attached l_query_interaction_elements.interaction_element (l_ie_query.identifier) as la_ie_query then
								la_ie_query.duplicate (l_ie_query)    -- Here the actual duplicate of the element of the query table is created for the equivalent element in the command.
							end
						end
					end
				end
			end
		end

	cleanup
		do
			if attached web_api_handler as l_new_web_api_handler and
			   attached query_table as l_query_table then
				l_new_web_api_handler.put_system_interface (void)
			end
			web_api_handler := void
			web_api_handlers := void
			interaction_table := void
			query_table := void
			executing_command := void
		end

	web_api_handlers: detachable ARRAYED_LIST[SIF_WEB_API_REQUEST_HANDLER]

	web_api_handler: detachable SIF_WEB_API_REQUEST_HANDLER

	interaction_table: detachable SIF_INTERACTION_ELEMENT_SORTED_SET

	query_table: detachable SIF_INTERACTION_ELEMENT_SORTED_SET

	executing_command: detachable SIF_COMMAND


feature -- Identification

	id : INTEGER
			-- Return the correct system interface identifier as defined in SIF_SYSTEM_INTERFACE_IDENTIFIERS
		do
			Result := Sii_web_api_interface_based_on_Eiffel_Web_Framework
		end

note
	copyright: "Copyright (c) 2014-2016, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end
