note
	description: "Ancestor of all ECR WEB API commands."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIF_COMMAND_WEB_API

inherit

	SIF_COMMAND
		redefine
			make_command
		end

	SIF_COMMAND_IDENTIFIERS
		undefine
			default_create
		end

feature -- Initialization

	make_command (a_command_identifier: INTEGER_64)
			-- <Precursor>
		do
			Precursor(a_command_identifier)
			create resource_name.make_empty
		end

feature -- Access

	resource_name: STRING
			-- Name of the resource to be queried

feature -- Interaction

	do_publish_caption (an_ie_caption: SIF_IE_EVENT)
			-- <Precursor>
		do
			check attached command_descriptors.item (identifier) as la_descriptor then
				an_ie_caption.event_label.publish (la_descriptor)
			end
		end

feature {NONE} -- Interaction elements

	do_prepare_interaction_elements
			-- <Precursor>
		do
			create_interaction_elements
		end

	create_interaction_elements
			-- Prepare the necessary interaction elements for the interactor
		deferred
		end

end -- class SIF_COMMAND_WEB_API
