*! surveycto_api version 1.0.0 Christopher Boyer

** TO DO ** Add check to see if curl is installed
** TO DO ** Figure out how to get the terminal to not display
** TO SO ** Download in batches

program define surveycto_api, rclass
	/* This is a utility program for downloading data from SurveyCTO via
	   their API (http://surveycto.com) */

	syntax anything(name=formids id="formid(s)"), ///
		SERVER(string)      /// SurveyCTO servername
		USERname(string)    /// SurveyCTO username
		[CSVPATH(string)]   /// location to download csv to
		[MEDIAPATH(string)] /// location to download media files to
		[MEDIA(namelist)]   /// flag to download media files		
		[LONG]              /// flag to download data in long format
		[REPlace]

	preserve
	qui {

	local url = "https://`server'.surveycto.com/api/v1/forms"

	if mi("`csvpath'") {
		local csvpath = "."
	}

	if mi("`mediapath'") {
		local mediapath = "."
	}	

	nois di _newline
	nois di "Please enter your password.."  _request(_password)

	foreach formid in `formids' {
		nois di `"Downloading `formid' from {browse "https://`server'.surveycto.com":`server'} in `=cond(mi("`long'"), "WIDE", "LONG")' format..."'

		
		if !mi("`long'") {
			local shape = "csv"

			!curl `url'/files/`shape'/`formid' ///
				--digest -u `username':`password' ///
				--output "`c(tmpdir)'/files.csv" 

			import delimited using "`c(tmpdir)'/files.csv", varnames(nonames) clear

			forval i = 1 / `=_N' {
				local long_url = v1[`i']
				local long_id = subinstr("`long_url'", "`url'/data/`shape'/", "", .)
				local long_id = subinstr("`long_id'", "/", "_", .)
				local filename = "`long_id'" + ".csv"

				nois di _col(5) "Downloading LONG file `long_id' (`i' of `=_N')..."
				!curl `long_url' ///
					--digest -u `username':`password' ///
					--output "`csvpath'/`filename'" 

				if "`media'" != "" {
					import delimited using "`csvpath'/`filename'", clear
					foreach var in `media' {
						cap confirm variable `var'
						if !_rc {
							surveycto_api_media `var', ///
								username(`username') ///
								password(`password') ///
								path(`mediapath')
						}
					}
				}
			}
		} 

		else {
			local shape = "wide/csv"
			local filename = "`formid'" + ".csv"

			!curl `url'/data/`shape'/`formid' ///
				--digest -u `username':`password' ///
				--output "`csvpath'/`filename'" 

			if "`media'" != "" {
				import delimited using "`csvpath'/`filename'", clear
				foreach var in `media' {
					nois surveycto_api_media `var', ///
						username(`username') ///
						password(`password') ///
						path(`mediapath')
				}
			}
		}

	}
	}
	restore

end

program define surveycto_api_media, rclass
	/* This program assists in downloading the media attachment files 
	   for a SurveyCTO form using the API */

	syntax varname [if] [in], ///
		USERname(string)      /// SurveyCTO username/// SurveyCTO servername
		PASSword(string)      /// SurveyCTO password
		PATH(string)          /// location to download media files to
	
	qui {
	cap which parallel 
	if _rc {
		net install parallel, from("https://raw.github.com/gvegayon/parallel/master/") replace
		mata mata mlib index
	}

	local regex_ta "TA_[A-Za-z0-9\-]*.csv"
	local regex_image "[0-9]*.jpg"
	local regex_aa "AA_[A-Za-z0-9\-]*.[a-z0-9]"
	local regex_comment "Comments-[A-Za-z0-9\-]*.csv"

	
	tempvar files
	qui g `files' = regexs(1) ///
		if regexm(`varlist', "(`regex_ta'|`regex_image'|`regex_aa'|`regex_comment')")	
	
	nois di _col(5) "Downloading `=_N' media files in `varlist'..."

	forval i = 1/`=_N' {
		local url = `varlist'[`i']
		local file = `files'[`i']
		
		if !mi("`url'") {
		
			cap confirm "`path'/`file'"
			if _rc {
				scalar PROCEXEC_HIDDEN = 1
				!curl `url' ///
					--output "`path'/`file'" ///
					--digest -u `username':`password' ///
					--header "X-OpenRosa-Version: 1.0" 
				scalar pid = r(pid)
			}
		}
		nois di _col(5) "." _continue
	}
	drop `files'
	nois di _newline 
	return scalar pid = pid	
	}
end

