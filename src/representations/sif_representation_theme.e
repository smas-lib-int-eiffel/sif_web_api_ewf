note
	description: "Summary description for {SIF_REPRESENTATION_THEME}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_REPRESENTATION_THEME

inherit
	SIF_REPRESENTATION
--		undefine
--			default_create
--		select
--			is_equal,
--			copy
--		end

	--SIF_INTERACTION_ELEMENT_IDENTIFIERS_WEB

create
	make

feature -- Initialization

	make (a_path: PATH)
			--
		do
			default_create
			theme_path := a_path
		end

feature -- Status

	type: like {SIF_REPRESENTATION_ENUMERATION}.type
			-- <Precursor>: theme
		do
			Result := {SIF_REPRESENTATION_ENUMERATION}.theme
		end

feature -- Parsing

	parse (req: WSF_REQUEST; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET; a_ie_set_to_publish: SIF_INTERACTION_ELEMENT_SORTED_SET) : SIF_REPRESENTATION_PARSE_RESULT
			-- <Precursor>	
		do
			create Result
		end

feature -- Representation

	do_represent (req: WSF_REQUEST; res: WSF_RESPONSE; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET)
			-- <Precursor>
		local
			l_file_response: WSF_FILE_RESPONSE
		do
			create {WSF_FILE_RESPONSE} l_file_response.make_with_content_type_and_path ({HTTP_MIME_TYPES}.image_jpg, theme_path.appended (req.path_info))
			res.send (l_file_response)
		end

feature {NONE} -- Implementation

	theme_path: PATH

end
