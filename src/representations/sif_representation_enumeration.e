note
	description: "Summary description for {SIF_REPRESENTATION_ENUMERATION}."
	author: "Paul Gokke"
	date: "$Date$"
	revision: "$Revision$"
	library: "System Interface Framework (SIF)"
	legal: "See notice at end of class."

class
	SIF_REPRESENTATION_ENUMERATION
	inherit
		HTTP_MIME_TYPES

feature -- Types

	undefined: like type = 0
			-- No type defined

	json: like type = 1
			-- JSON

	xml: like type = 2
			-- XML

	html: like type = 3
			-- HTML

	nvp: like type = 4
			-- Name Value Pair

	tlv: like type = 5
			-- Tag Length Value

	multipart_form: like type = 6
			-- Form data passed as multipart_form

	media: like type = 7
			-- A media representation, like images, videos etc.

	json_hal: like type = 8
			-- JSON+HAL

	theme: like type = 9
			-- Resources used in HTML, like css, js, ...

feature -- Contract support

	is_type_valid (a_type: like type): BOOLEAN
			-- If `a_type' valid?
		do
			inspect a_type
			when undefined, json, xml, html, nvp, tlv, multipart_form, media, json_hal, theme then
				Result := True
			else
			end
		end

feature -- Query

	is_content_type_mappable( a_content_type: STRING ): BOOLEAN
			-- Is content type normally found in a http header, mappable to a known SIF representation type?
		do
			a_content_type.to_lower
			if a_content_type.is_equal (application_json) or
			   a_content_type.is_equal ("application/vnd.api+json") or
			   a_content_type.is_equal ("application/x-resource+json") or
			   a_content_type.is_equal ("application/x-collection+json") then
				Result := True
			end
			if a_content_type.is_equal (application_xml) or
			   a_content_type.is_equal ("application/x-resource+xml") or
			   a_content_type.is_equal ("application/x-collection+xml") then
				Result := True
			end
			if a_content_type.is_equal (text_html) then
				Result := True
			end
			if a_content_type.is_equal (multipart_form_data) then
				Result := True
			end
			if a_content_type.is_equal ("application/nvp") then
				Result := True
			end
			if a_content_type.is_equal ("application/tlv") then
				Result := True
			end
			if a_content_type.is_equal ("image/*") or
			    a_content_type.is_equal (image_bmp) or
				a_content_type.is_equal (image_gif) or
				a_content_type.is_equal (image_jpeg) or
				a_content_type.is_equal (image_jpg) or
				a_content_type.is_equal (image_png) or
				a_content_type.is_equal (image_svg_xml) or
				a_content_type.is_equal (image_tiff) or
				a_content_type.is_equal (image_x_ico) then
				Result := True
			end
			if a_content_type.is_equal ("application/json+hal") then
				Result := True
			end
		end

	map_content_type_to_sif_representation_type( a_content_type: STRING ): like type
			-- Map the content type normally found in a http header, to a general SIF representation type
		require
			content_is_mappable: is_content_type_mappable( a_content_type )
		do
			a_content_type.to_lower
			if a_content_type.is_equal (application_json) or
			   a_content_type.is_equal ("application/vnd.api+json") or
			   a_content_type.is_equal ("application/x-resource+json") or
			   a_content_type.is_equal ("application/x-collection+json") then
				Result := json
			end
			if a_content_type.is_equal (application_xml) or
			   a_content_type.is_equal ("application/x-resource+xml") or
			   a_content_type.is_equal ("application/x-collection+xml") then
				Result := xml
			end
			if a_content_type.is_equal (text_html) then
				Result := html
			end
			if a_content_type.is_equal (multipart_form_data) then
				Result := multipart_form
			end
			if a_content_type.is_equal ("application/nvp") then
				Result := nvp
			end
			if a_content_type.is_equal ("application/tlv") then
				Result := tlv
			end
			if a_content_type.is_equal ("image/*") or
				a_content_type.is_equal (image_bmp) or
				a_content_type.is_equal (image_gif) or
				a_content_type.is_equal (image_jpeg) or
				a_content_type.is_equal (image_jpg) or
				a_content_type.is_equal (image_png) or
				a_content_type.is_equal (image_svg_xml) or
				a_content_type.is_equal (image_tiff) or
				a_content_type.is_equal (image_x_ico) then
				Result := media
			end
			if a_content_type.is_equal ("application/hal+json") then
				Result := json_hal
			end
		end

	representation_type_as_string( a_type: like type ): STRING
			-- Result is a string representation of a_type.
		do
			create Result.make_empty
			inspect a_type
			when undefined then
				create Result.make_from_string("undefined")
			when json then
				create Result.make_from_string(application_json)
			when xml then
				create Result.make_from_string(application_xml)
			when html then
				create Result.make_from_string(text_html)
			when nvp then
				create Result.make_from_string("application/nvp")
			when tlv then
				create Result.make_from_string("application/tlv")
			when multipart_form then
				create Result.make_from_string(multipart_form_data)
			when media then
				create Result.make_from_string("special media using ?media_name=")
			when json_hal then
				create Result.make_from_string("application/hal+json")
			when theme then
				create Result.make_from_string("theme resource")
			end
		end

feature frozen -- Type information

	type : INTEGER

;note
	copyright: "Copyright (c) 2014-2016, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end

