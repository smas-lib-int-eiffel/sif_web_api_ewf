note
	description: "Summary description for {SIF_WEB_EWF_UTILITY}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SIF_WEB_EWF_UTILITY
	inherit
		SIF_SHARED_PRODUCT_WEB_EWF

feature

--	media_image_uri (a_media_value: STRING; a_alternative: STRING; a_width: NATURAL; a_height: NATURAL): STRING
--			-- Construct a valid product related image source uri
--		do
--			create Result.make_from_string ("<img src=")
--			Result.append (product_web.scheme)
--			Result.append ("://")
--			Result.append (product_web.base_url)
--			Result.append (":")
--			Result.append (product_web.external_port.out)
--			Result.append ("/")
--			Result.append (product_web.media_path)
--			Result.append ("?")
--			Result.append (product_web.media_query_parameter_name)
--			Result.append ("=")
--			Result.append (a_media_value)
--			Result.append (" alt=")
--			Result.append (a_alternative)
--			Result.append (" style=width:")
--			Result.append (a_width.out)
--			Result.append ("px;height:")
--			Result.append (a_height.out)
--			Result.append ("px>")
--		end

--	media_source (a_media_value: STRING): STRING
--			-- Construct a valid media source product related uri
--		do
--			create Result.make_from_string (product_web.scheme)
--			Result.append ("://")
--			Result.append (product_web.base_url)
--			Result.append (":")
--			Result.append (product_web.external_port.out)
--			Result.append ("/")
--			Result.append (product_web.media_path)
--			Result.append ("?")
--			Result.append (product_web.media_query_parameter_name)
--			Result.append ("=")
--			Result.append (a_media_value)
--		end

note
	copyright: "Copyright (c) 2014-2017, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end
