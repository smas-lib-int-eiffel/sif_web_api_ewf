note
	description: "Summary description for {SIF_SYSTEM_INTERFACE_WEB_EWF_FAKE}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_SYSTEM_INTERFACE_WEB_EWF_FAKE

inherit
	SIF_SYSTEM_INTERFACE_WEB_EWF
		rename
			make as si_make
		redefine
			initialize
		end

create
	make

feature -- Initialization

	make
			--
		local
			vars: HASH_TABLE [STRING, STRING]
			input: WGI_LIBFCGI_INPUT_STREAM
			source: FCGI
			req: WGI_REQUEST_FROM_TABLE
			output: WGI_LIBFCGI_OUTPUT_STREAM
			target: FCGI
			res: WGI_RESPONSE_STREAM
		do
			create vars.make (0)
			create source.make
			create input.make (source)
			create req.make (vars, input, Void)
			create target.make
			create output.make (target)
			create res.make (output, Void)
			si_make (req, res)
		end

feature {NONE} -- Initialize

	initialize
			-- <Precursor>
		do
			create router.make (10)
		end

feature -- Access

	handler (sif_product: SIF_PRODUCT_WEB_EWF): SIF_WEB_API_REQUEST_HANDLER
			--
		do
			Result := sif_product.api_handlers [1]
		end

end
