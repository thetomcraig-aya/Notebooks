

SELECT	occupation.name as "Occupation",
		specialties.names as "specialties",
		city.name as "City",
		state.name as "State",
		zip_code.code as "Zip",
		npi_number,
		"user".id,
		resume_uploads.count as "Number of Resumes",
		resume_uploads.max as "Date that last resume was uploaded",
		job_seeker_profile.deactivated_at,
		"user".deleted_at,
		"user".status,
		board_certifications.names as "Board Certifications",
		state_licenses.licenses as "State Licenses",
		date_available,
		experience_years,
		preference_states.states as "Location Preference States",
		contact_info_private,
		include_in_search,
		phone_numbers_private,
		"user".created_at
FROM	job_seeker_profile
        JOIN occupation ON job_seeker_profile.occupation_id = occupation.id
        JOIN (
			SELECT	string_agg(specialty.name, ',') as names, profile_id
            FROM	specialty
                    JOIN job_seeker_profile_specialty ON specialty.id = job_seeker_profile_specialty.specialty_id
                    JOIN job_seeker_profile ON job_seeker_profile_specialty.profile_id = job_seeker_profile.id
            WHERE	job_seeker_profile.site_id = 1
            GROUP BY job_seeker_profile_specialty.profile_id) specialties ON specialties.profile_id=job_seeker_profile.id		
		JOIN "user" ON job_seeker_profile.job_seeker_id="user".id
		LEFT JOIN address ON "user".address_id = address.id
		LEFT JOIN city ON address.city_id = city.id
		LEFT JOIN zip_code ON address.zip_code_id = zip_code.id
		LEFT JOIN state ON address.state_id = state.id
        LEFT JOIN (
			SELECT count(1), max(resume.created_at), job_seeker_id
			FROM resume
			WHERE resume.deleted_at IS NULL
			AND resume.site_id=1
			GROUP BY job_seeker_id) resume_uploads ON resume_uploads.job_seeker_id = "user".id
		LEFT JOIN (
			SELECT	string_agg(board_certification.name, ',') as names, profile_id 
			FROM	board_certification
					JOIN job_seeker_profile_board_certification ON board_certification.id = job_seeker_profile_board_certification.board_certification_id
					JOIN job_seeker_profile ON job_seeker_profile_board_certification.profile_id = job_seeker_profile.id
					WHERE job_seeker_profile.site_id=1
					GROUP BY profile_id) board_certifications ON board_certifications.profile_id=job_seeker_profile.id
		LEFT JOIN (
			SELECT	job_seeker_profile.id,
					string_agg(DISTINCT license_state.abbreviation, ', ') as licenses
			FROM	job_seeker_profile
					JOIN job_seeker_profile_state_license ON job_seeker_profile.id = job_seeker_profile_state_license.profile_id
					JOIN state license_state ON job_seeker_profile_state_license.state_id = license_state.id
			WHERE	job_seeker_profile.site_id=1
			GROUP BY job_seeker_profile.id) state_licenses ON state_licenses.id = job_seeker_profile.id
         LEFT JOIN (
			SELECT job_seeker_profile.id,
					string_agg(DISTINCT preference_state.abbreviation, ', ') as "states"
			FROM	job_seeker_profile
					JOIN job_seeker_profile_location_preference ON job_seeker_profile.id = job_seeker_profile_location_preference.profile_id AND job_seeker_profile_location_preference.deleted_at IS NULL
					JOIN state preference_state ON job_seeker_profile_location_preference.state_id = preference_state.id
			GROUP BY job_seeker_profile.id) preference_states ON preference_states.id = job_seeker_profile.id
WHERE	"user".network_id=1
		AND "user".created_at >= (SELECT beginDate FROM datetimeline)
		AND "user".created_at <= (SELECT endDate FROM datetimeline)