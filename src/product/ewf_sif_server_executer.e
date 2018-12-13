note
	description: "Summary description for {EWF_SIF_SERVER_EXECUTER}."
	author: "Paul Gokke"
	date: "$Date$"
	revision: "$Revision$"
	library: "System Interface Framework (SIF)"
	legal: "See notice at end of class."
	EIS: "src=http://www.eiffelweb.org/"

class
	EWF_SIF_SERVER_EXECUTER [G -> SIF_PRODUCT_WEB_EWF create initialize end]

inherit
	WSF_DEFAULT_SERVICE [SIF_SYSTEM_INTERFACE_WEB_EWF]
		-- When a http request is received by the web server, being nino, standalone, cgi or fcgi,
		-- it will instantiate an instance of an implementation of SIF_SYSTEM_INTERFACE_WEB_EWF.
		-- This means that concurrent requests, will each have their own instance of SIF_SYSTEM_INTERFACE_WEB_EWF.
		redefine
			initialize
		end

	SIF_SHARED_PRODUCT_WEB_EWF

create
	make

feature {NONE} -- Initialization

	make
		local
			l_web_product: G
			l_creator: LOG_FACILITY_CREATOR
		do
			print ("Using log facilities.%N")
			create l_creator.make (True)
			create l_web_product.initialize
			if l_web_product.is_initialized then
				Current.put_the_product(l_web_product)
				set_service_option ("port", l_web_product.port)
				make_and_launch
				-- Ater the above call is made, the application will wait for HTTP requests and will never return from the call... so any code after this statement will not be executed!!!
			end
		rescue
			if
				attached (create {EXCEPTION_MANAGER}).last_exception as la_exception and then
				attached la_exception.trace as la_trace then
					(create {SHARED_LOG_FACILITY}).write_emergency (la_trace)
			end
		end

	initialize
		do
		end

;note
	copyright: "Copyright (c) 2014-2016, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end
