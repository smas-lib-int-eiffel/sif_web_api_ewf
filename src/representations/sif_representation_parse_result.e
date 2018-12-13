note
	description: "Summary description for {SIF_REPRESENTATION_PARSE_RESULT}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_REPRESENTATION_PARSE_RESULT
	inherit
		ANY
			redefine
				default_create
			end

		HTTP_STATUS_CODE
			undefine
				default_create
			end

feature -- Initialization

	default_create
		do
			Precursor
			put_default
		end

feature -- Status

	passed: BOOLEAN
		do
			Result := code = {HTTP_STATUS_CODE}.ok
		end

	failed: BOOLEAN
		do
			Result := code /= {HTTP_STATUS_CODE}.ok
		end

feature -- Element Change

	reset
		do
			put_default
		end

	set_invalid_input
		do
			code := {HTTP_STATUS_CODE}.bad_request
		end

	set_invalid_mandatory
		do
			code := {HTTP_STATUS_CODE}.bad_request
		end

	set_internal_server_error
		do
			code := {HTTP_STATUS_CODE}.internal_server_error
		end

feature -- Implementation

	code: like {HTTP_STATUS_CODE}.ok

	tip: detachable STRING
			-- In case of failures, the tip can be used to inform the client what is wrong in the request made.

feature {NONE}-- Implementation

	put_default
		do
			code := {HTTP_STATUS_CODE}.ok
		end

note
	copyright: "Copyright (c) 2017-2017, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end
