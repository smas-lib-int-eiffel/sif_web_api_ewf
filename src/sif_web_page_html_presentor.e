note
	description: "Summary description for {SIF_WEB_PAGE_HTML_PRESENTOR}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	SIF_WEB_PAGE_HTML_PRESENTOR
	inherit
		SIF_WEB_EWF_UTILITY

		SHARED_LOG_FACILITY

feature -- HTML Representation

	represent(a_req: WSF_REQUEST): WSF_HTML_PAGE_RESPONSE
		deferred
		end

end
