note
	description: "Summary description for {SIF_SHARED_PRODUCT_WEB_EWF}."
	author: "Paul Gokke"
	date: "$Date$"
	revision: "$Revision$"
	library: "System Interface Framework (SIF)"
	legal: "See notice at end of class."

class
	SIF_SHARED_PRODUCT_WEB_EWF

feature -- Access

	product_web: SIF_PRODUCT_WEB_EWF
			-- Singleton object
		require
			product_set: has_product
		do
			Result := internal_product.item
		end

feature {EWF_SIF_SERVER_EXECUTER} -- Element change

	put_the_product(the_product: like product_web)
			-- Put the product to be used as shared product.
		do
			internal_product.replace (the_product)
		ensure
			correct_product: has_product
		end


feature -- Query

	has_product: BOOLEAN
		do
			Result := not attached {SIF_PRODUCT_WEB_EWF_DUMMY}internal_product.item
		end

feature {NONE} -- Implementation

	internal_product: CELL[SIF_PRODUCT_WEB_EWF]
			-- We create a dummy product here. This is for convenience of the application programmers.
			-- By being sure an instance of a web product ewf exists, means that client inheriting don't have to write code
			-- for the product instance being attached. The class EWF_SIF_SERVER_EXECUTER will make sure the real instance
			-- is exchanged for the dummy created here.
		local
			l_dummy_product: SIF_PRODUCT_WEB_EWF_DUMMY
		once ("PROCESS")
			create l_dummy_product.initialize
			create Result.put(l_dummy_product)
		ensure
			singleton_not_void: Result.item /= Void
		end

;note
	copyright: "Copyright (c) 2014-2016, SMA Services"
	license:   "Eiffel Forum License v2 (see http://www.eiffel.com/licensing/forum.txt)"
	source: "[
			SMA Services
			Website: http://www.sma-services.com
		]"

end
