note
	description: "Summary description for {SIF_PRODUCT_WEB_EWF_DUMMY}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_PRODUCT_WEB_EWF_DUMMY
		inherit
			SIF_PRODUCT_WEB_EWF
				redefine
					initialize
				end

create
	initialize

feature -- Creation

	initialize
		-- Create a dummy web product so clients have no void safe coding issues
		do
			create available_representations.make( 1 )
			create scheme.make_empty
			create base_url.make_empty
			create api_handlers.make_empty
			create link_list_media.make(0)
		end

feature -- Query

	persistence_storage_name: STRING
		do
			create Result.make_empty
		end

feature {NONE} -- Manufacturing


	manufacture_input_validators
		do
			-- Intended to be empty.
		end

	do_manufacture_representations
		do
			-- Intended to be empty.
		end

	is_authorisable: BOOLEAN
		do
			Result := false
		end

feature {SIF_SYSTEM_INTERFACE_WEB_EWF,SIF_WEB_API_REQUEST_HANDLER} -- Manufacturing web ewf specific

	do_manufacture_api_handlers
		do
			-- Intended to be empty.
		end

end
