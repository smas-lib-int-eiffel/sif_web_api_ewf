note
	description: "Summary description for {SIF_PRODUCT_WEB_API}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIF_PRODUCT_WEB_API

inherit
	SIF_PRODUCT_WEB
	redefine
		initialize,
		manufacture,
		log_web_product_information
	end

feature {SIF_WEB_API_REQUEST_HANDLER} -- Used by handlers and web products only

	available_representations: HASH_TABLE[SIF_REPRESENTATION, like {SIF_REPRESENTATION_ENUMERATION}.type]

feature -- Status

	has_representation_type ( a_type: like {SIF_REPRESENTATION_ENUMERATION}.type ): BOOLEAN
			-- Does the product service the requested representation
		do
			Result := available_representations.has (a_type)
		end

feature {NONE} -- Manufacturing

	initialize
		-- Do product specific initializations
		do
			create available_representations.make( 1 )
			Precursor
		end

	manufacture
			-- Manufacture the specific product
		do
			manufacture_representations
			Precursor
		end

	manufacture_representations
			-- Manufacture the needed representations for the web product.
			-- Name value pair is always needed in case of GET requests with query parameters.
		local
			l_representation_nvp: SIF_REPRESENTATION_NVP
		do
			create l_representation_nvp
			available_representations.extend (l_representation_nvp, {SIF_REPRESENTATION_ENUMERATION}.nvp)

			do_manufacture_representations
		end

	do_manufacture_representations
			-- Manufacture the needed representations for the web product.
		deferred
		end

	manufacture_api_handler(a_command: SIF_COMMAND[SIF_DAO[ANY]]; a_methods: WSF_REQUEST_METHODS;
							a_resource_path: STRING; a_representation_type: like {SIF_REPRESENTATION_ENUMERATION}.type;
							a_pagination_capable: like {SIF_WEB_API_REQUEST_HANDLER}.pagination_capable;
							a_search: like {SIF_WEB_API_REQUEST_HANDLER}.search)
			-- Manufacture a api handler according to the given arguments. Each API handler is a direct part of
			-- this web product's API.
		require
			representation_type_exists: has_representation_type (a_representation_type)
		deferred
		end

feature {NONE} -- Implementation

	log_web_product_information
		local
			l_representation_type: SIF_REPRESENTATION_ENUMERATION
		do
			Precursor
			log_string.make_empty
			create l_representation_type
			from
				available_representations.start
			until
				available_representations.off
			loop
				log_string.append ("[" + l_representation_type.representation_type_as_string(available_representations.key_for_iteration) + "]" + " ")
				available_representations.forth
			end
			write_information ("%TAvailable representations: " + log_string )
		end

end
