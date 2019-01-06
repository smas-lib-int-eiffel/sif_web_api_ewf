note
	description: "Summary description for {SIF_PRODUCT_WEB_EWF}."
	author: "Paul Gokke"
	date: "$Date$"
	revision: "$Revision$"
	library: "System Interface Framework (SIF)"
	legal: "See notice at end of class."

deferred class
	SIF_PRODUCT_WEB_EWF

	inherit
		SIF_PRODUCT_WEB_API
			redefine
				initialize,
				launch,
				manufacture,
				manufacture_commands
			end

		HTTP_REQUEST_METHODS

feature {NONE} -- Manufacturing

	initialize
		-- Do product specific initializations
		do
			create api_handlers.make_empty
			create link_list_media.make(0)
			Precursor
		end

	launch
		do
			-- Not necessary in a Eiffel Web framework environment.
			-- Applications are launched through a web server like, stand-alone, Nino, Apache, IIS, NGinX etc....
		end

	manufacture
			-- Manufacture the specific product
			-- Default manufacturing is overriden here. An Eiffel Web Framework based product will only build commands
			-- on the fly when a request is received. When a request is received by the httpd server of EWF, it will create a router and
			-- execute the executer, in the case of  SIF it will create an instance of a system interface of type SIF_SYSTEM_INTERFACE_WEB_EWF.
			-- This system interface for the Eiffel web framework will interact through an api request handler, which will be indentified by the URI of the request.
			-- This router will get the needed URI mappings through the web api request handlers. This is the part where EWF meets SIF.
			-- Each api request handler knows it's corresponding command, which will be executed in case of  proper request.
		do
			manufacture_input_validators
			manufacture_representations
			manufacture_api_handlers

			log_web_product_information

			log_commands

			log_resource_routes
		end


	manufacture_system_interfaces
		do
			-- Due to the nature of the eiffel web framework, interfaces will be created only when necessary.
			-- Each session in a httpd server will create a new web system interface.
			-- This is controlled by class EWF_SIF_SERVER_EXECUTER. This class uses the system interface as
			-- the executer. Each time a http request is received the eiffel web framework will create a new
			-- instance of the executer in this case an instance of the system interface for that session.
			-- This way it is possible to comply to concurrent implementations.
		end

	manufacture_api_handler(a_command: SIF_COMMAND[SIF_DAO[ANY]]; a_methods: WSF_REQUEST_METHODS;
							a_resource_path: STRING; a_representation_type: like {SIF_REPRESENTATION_ENUMERATION}.type;
							a_pagination_capable: like {SIF_WEB_API_REQUEST_HANDLER}.pagination_capable;
							a_search: like {SIF_WEB_API_REQUEST_HANDLER}.search)
			-- Manufacture an api handler according to the given arguments. Each API handler is a direct part of
			-- this web product's API. Handling incoming http requests and map them to the correct command to be
			-- executed through the created interaction elements from the representation.
			--
			-- The resource path is to be considered as the route to a certain resource of the API of the web product
			-- The resource path always starts with a / (forward slash) character and can also have templates within
			-- curly brackets.
			-- Examples are : /transactions
			--                /documents/{document_id}
		local
			l_api_handler: SIF_WEB_API_REQUEST_HANDLER
		do
			if attached available_representations.at (a_representation_type) as l_available_representation then
				l_api_handler := create {SIF_WEB_API_REQUEST_HANDLER}.make( a_command.identifier, a_methods, create {URI_TEMPLATE}.make (a_resource_path), a_pagination_capable, a_search )
				l_api_handler.put_representation_result(a_representation_type)
				api_handlers.force (l_api_handler, api_handlers.count + 1)
				last_api_handler := l_api_handler
			end
		end

	last_api_handler: detachable SIF_WEB_API_REQUEST_HANDLER
			-- Last api handler created by manufacture_api_handler

feature {NONE} frozen -- Frozen manufacturing

	manufacture_commands
		do
			-- Must stay empty!!!!!
			-- Commands are attached to web api handlers, to be able to run them in the multi processor fashion of the Eiffel Web Framework.
			-- They are created upon receiving a proper HTTP request through reflection of api handler objects from the command manager,
			-- identified by the command identifier which is known from configuration for each specific api handler.
		end

feature {SIF_SYSTEM_INTERFACE_WEB_EWF,SIF_WEB_API_REQUEST_HANDLER} -- Manufacturing web ewf specific

	manufacture_api_handlers
			-- Create the necessary handlers for this web API.
		local
			--l_representations_media: like internal_representation
			l_representation_media: SIF_REPRESENTATION_MEDIA
			l_command_web_media : SIF_COMMAND_MEDIA
			l_api_handler: SIF_WEB_API_REQUEST_HANDLER
			l_link_list: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_list
			l_link_descriptor: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_descriptor
			l_representation_json_hal: SIF_REPRESENTATION_JSON_HAL
			l_representation_json: SIF_REPRESENTATION_JSON
			l_command : SIF_COMMAND[SIF_DAO[ANY]]
		do
			if use_logging then
				if not attached available_representations.at ({SIF_REPRESENTATION_ENUMERATION}.json_hal) as l_available_representation then
					create l_representation_json_hal
					available_representations.extend (l_representation_json_hal, {SIF_REPRESENTATION_ENUMERATION}.json_hal)
				end
				if not attached available_representations.at ({SIF_REPRESENTATION_ENUMERATION}.json) as l_available_representation then
					create l_representation_json
					available_representations.extend (l_representation_json, {SIF_REPRESENTATION_ENUMERATION}.json)
				end
				l_command := create{SIF_COMMAND_LOG_FACILITY_EXTENDED}.make
				manufacture_api_handler(l_command, method_patch, "/log_facility", {SIF_REPRESENTATION_ENUMERATION}.json_hal, false, void)
			end
			if has_media then
				create l_representation_media.make
				available_representations.extend (l_representation_media, {SIF_REPRESENTATION_ENUMERATION}.media)

				l_command_web_media := create{SIF_COMMAND_MEDIA}.make
				l_api_handler := create {SIF_WEB_API_REQUEST_HANDLER}.make( l_command_web_media.identifier, method_get, create {URI_TEMPLATE}.make (media_resource_path), false, void )  -- e.g.  http://localhost:9090/assets/media_name=image_name.extension
				l_api_handler.put_representation_result({SIF_REPRESENTATION_ENUMERATION}.media)
				api_handlers.force (l_api_handler, api_handlers.count + 1)

				create l_link_descriptor
				l_link_descriptor.link_type := 1
				l_link_descriptor.template_name := media_query_value_template_name
				l_link_descriptor.descriptor := media_query_parameter_name
				link_list_media.extend (l_link_descriptor)
			end
			do_manufacture_api_handlers
		end

	link_list_media: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_list

	do_manufacture_api_handlers
			-- Do create the necessary handlers for this web API.
		deferred
		end

	api_handlers: ARRAY[SIF_WEB_API_REQUEST_HANDLER]
			-- These handlers are to be used when a web api is created with the Eiffel Web Framework.
			-- A Web API is an API which can be called through HTTP. A web API only serves resources.
			-- It can be used by web based clients for information interchange based on web technology (read HTTP).
			-- Each handler has a relation with a command. The handler is reponsible for all web specific parts,
			-- like a representation of the resource. The command is the functionality part of the System Interface Framework,
			-- it will interact through the interaction elements. The interaction elements are used as a bidirectional communication
			-- medium between the commands and the api handlers. So commands don't have any knowledgde that they are interacting with
			-- a web API. Rememember that Commands are reusable functionality parts of the SIF, which can be (re)used on all available
			-- and future System Interfaces.

	manufacture_links(a_resource_path_to_handler: STRING; a_resource_path_for_link: STRING; a_link_tag: STRING; a_link_descriptors: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_list)
			-- Initialize links associated with the give resource a_resource_path.
			--
			-- a_resource_path_to_handler is used to find the handler to which the link should be associated as embedded link
			-- a_resource_path_for_link is used for dynamic creation of the embedded link during creation of the response
			-- a_link_tag holds the name of the link
			-- a_link_descriptors is a list of link descriptors, describing the dynamic substitution to be made between template
			--    path variable name and result interaction element descriptor
		local
			i: INTEGER
			found: BOOLEAN
			l_link: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link
			l_link_list: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_list
			l_link_descriptor: like {SIF_WEB_API_REQUEST_HANDLER}.tuple_link_descriptor
		do
			from
				i := 1
			until
				i > api_handlers.count or found
			loop
				found := api_handlers.at (i).resource_template.template.is_equal (a_resource_path_to_handler)
				if found then
					create l_link
					l_link.resource_path := a_resource_path_for_link
					l_link.link_tag := a_link_tag
					l_link.link_list := a_link_descriptors
					api_handlers.at (i).linked_handlers.force (l_link)
				else
					i := i + 1
				end
			end
		end

feature {NONE} -- Logging

	log_resource_routes
		local
			l_first: BOOLEAN
			l_command: SIF_COMMAND[SIF_DAO[ANY]]
		do
			if api_handlers.count > 1 then
				write_information ("Added the following resource routes for the above commands:")
				api_handlers.do_all (agent log_resource_route)
			end
		end

	log_resource_route(a_api_handler: SIF_WEB_API_REQUEST_HANDLER)
		local
			i: INTEGER
			l_resources: STRING
			l_methods: STRING
		do
			if attached command_manager.command (a_api_handler.command_identifier) as l_command then
				write_information ("%T" + "Command Identifier: " + l_command.identifier.out + "%T" + l_command.generator)
				write_information ("%T%T" + "Resources route: " + a_api_handler.resource_template.template)
				write_information ("%T%T" + "HTTP methods: ")
				from
					i := 1
					create l_methods.make_from_string ("%T%T%T")
				until
					i > a_api_handler.request_methods.methods.count
				loop
					if attached a_api_handler.request_methods.methods.at (i) as l_request_method then
						l_methods.append (l_request_method + "%T")
					end
					i := i + 1
				end
				write_information (l_methods)
			end
		end

;note
	copyright: "Copyright (c) 2014-2017, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end
