note
	description: "Summary description for {SIF_REPRESENTATION_MEDIA}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_REPRESENTATION_MEDIA

inherit
	SIF_REPRESENTATION
		undefine
			default_create
		end

		SIF_INTERACTION_ELEMENT_IDENTIFIERS

create
	make

feature -- Initialization

	make
			-- Creation
		do
			default_create
		end

feature -- Status

	type: like {SIF_REPRESENTATION_ENUMERATION}.type
			-- Type of the representation by enumeration
		do
			Result := {SIF_REPRESENTATION_ENUMERATION}.media
		end

feature -- Parsing

	parse( req: WSF_REQUEST; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET; a_ie_set_to_publish: SIF_INTERACTION_ELEMENT_SORTED_SET ) : SIF_REPRESENTATION_PARSE_RESULT
			-- Positive result, if parseable and input validation succeeded and all mandatory elements are available and any optional elements match.			
			-- The interaction elements to publish needs to be filled with the mandatory and any optional interaction elements mapped from the input stream to the sorted set of interaction elements,
			-- so these can be used to publish to the interactor during interaction		
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			l_count_mandatory: INTEGER
			l_count_parsed_mandatory: INTEGER
		do
			from
				i := 1
				l_count_mandatory := 0
				l_count_parsed_mandatory := 0
				create Result
			until
				i > a_sorted_set_of_interaction_elements.count or Result.failed
			loop
				a_sorted_set_of_interaction_elements.go_i_th (i)
				l_ie := a_sorted_set_of_interaction_elements.item
				if l_ie.is_mandatory then
					l_count_mandatory := l_count_mandatory + 1
					if attached req.query_parameter (l_ie.descriptor) as l_item_query_mandatory then
					   	if l_ie.is_valid_input( l_item_query_mandatory.string_representation ) then
							l_ie.put_input (l_item_query_mandatory.string_representation)
							a_ie_set_to_publish.extend (l_ie)
							l_count_parsed_mandatory := l_count_parsed_mandatory + 1
					   	end
					else
						if attached req.path_parameter (l_ie.descriptor) as l_item_path_mandatory then
							l_ie.put_input (l_item_path_mandatory.string_representation)
							a_ie_set_to_publish.extend (l_ie)
							l_count_parsed_mandatory := l_count_parsed_mandatory + 1
						else
							Result.set_invalid_mandatory
						end
					end
				end
				i := i + 1
			end
			if l_count_mandatory /= l_count_parsed_mandatory then
				Result.set_invalid_mandatory
			end
		end

feature -- Representation

	do_represent(req: WSF_REQUEST; res: WSF_RESPONSE; a_handler: SIF_WEB_API_REQUEST_HANDLER; a_sorted_set_of_interaction_elements: SIF_INTERACTION_ELEMENT_SORTED_SET)
			-- Create a representation by using the interaction elements which contain the information for the content.
		local
			i: INTEGER
			l_ie: SIF_INTERACTION_ELEMENT
			l_file_response: WSF_FILE_RESPONSE
			l_media_path: PATH
		do
			if attached {SIF_IE_LIST}a_sorted_set_of_interaction_elements.interaction_element (Iei_media_list) as la_ie_media_file_list and then
			   la_ie_media_file_list.elements.count = 1 and then
			   attached la_ie_media_file_list.elements.at(1) as la_ie_media_files and then
			   attached {SIF_IE_FILE} la_ie_media_files.interaction_element (Iei_media) as la_ie_media_file then
				create {WSF_FILE_RESPONSE} l_file_response.make_with_path (la_ie_media_file.file.path)
				res.send (l_file_response)
			else
				check attached {SIF_IE_LIST}a_sorted_set_of_interaction_elements.interaction_element (iei_media_list) as la_ie_media_file_list and then la_ie_media_file_list.elements.count = 1 and then attached la_ie_media_file_list.elements.at(1) as la_ie_media_files and then attached {SIF_IE_FILE}la_ie_media_files.interaction_element (Iei_media) end
			end
		end

end
