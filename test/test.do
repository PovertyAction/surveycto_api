cap program drop surveycto_api surveycto_api_media
include surveycto_api.ado

cd "test_1"
surveycto_api hh_listing_2, ///
	server(ipahq) ///
	user(cboyer@poverty-action.org) 
cd ".."

cd "test_2"
surveycto_api rm_survey_2017, ///
	server(ipahq) ///
	user(cboyer@poverty-action.org) ///
	long
cd ".."

cd "test_3"
surveycto_api gst_kenya_household_survey, ///
	server(ipahq) ///
	user(cboyer@poverty-action.org) ///
	media(consent_sign) 
cd ".."
