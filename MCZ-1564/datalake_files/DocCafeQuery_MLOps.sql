--Doc Cafe
--1. Job Activity Query
WITH datetimeline AS(
	SELECT 	CAST('2025-09-01 00:00:00' AS timestamp) AS beginDate,
			CAST('2025-09-30 23:59:59' AS timestamp) endDate
)

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


--2. Email activity Query
WITH datetimeline AS(
	SELECT 	CAST('2025-09-01 00:00:00' AS timestamp) AS beginDate,
			CAST('2025-09-30 23:59:59' AS timestamp) endDate
)

SELECT "user".id as user_id,
		npi_number,
		to_char(email_event_index.created_at, 'YYYY-MM-DD') as day,
		count(1) as "activity_count",
		'email_received' as "activity_type"
FROM	email_event_index
        JOIN "user" ON "user".id = ANY (email_event_index.recipient_users)
		JOIN job_seeker_profile ON "user".id=job_seeker_profile.job_seeker_id
WHERE	"user".network_id = 1 
		AND "user".role = 'ROLE_JOB_SEEKER' 
		AND email_event_index.created_at >= (SELECT beginDate FROM datetimeline)
		AND email_event_index.created_at <= (SELECT endDate FROM datetimeline)
GROUP BY day, "user".id, npi_number
UNION
SELECT	tracking_link_click_event.user_id,
		npi_number,
		to_char(tracking_link_click_event.created_at, 'YYYY-MM-DD') as day,
		count(1) as "activity_count",
		'email_link_click' as activity_type
FROM	tracking_link_click_event
        JOIN email_tracking_link ON tracking_link_click_event.tracking_link_id=email_tracking_link.id
        JOIN "user" ON email_tracking_link.user_id = "user".id
        JOIN job_seeker_profile ON "user".id=job_seeker_profile.job_seeker_id
WHERE	tracking_link_click_event.created_at >= (SELECT beginDate FROM datetimeline)
		AND tracking_link_click_event.created_at <= (SELECT endDate FROM datetimeline)
        AND "user".network_id=1 
		AND "user".role = 'ROLE_JOB_SEEKER'
GROUP BY day, tracking_link_click_event.user_id, npi_number
UNION
SELECT	"user".id as user_id,
		npi_number,
		to_char(email_open_event.created_at, 'YYYY-MM-DD') as day,
		count(1) as "acitivity_count",
		'email_open' as activity_type
FROM	email_open_event
        JOIN "user" ON email_open_event.user_id = "user".id
        JOIN job_seeker_profile ON "user".id=job_seeker_profile.job_seeker_id
WHERE	"user".network_id=1 
		AND email_open_event.created_at >= (SELECT beginDate FROM datetimeline)
        AND email_open_event.created_at >= (SELECT endDate FROM datetimeline)
		AND "user".role = 'ROLE_JOB_SEEKER'
GROUP BY day, "user".id, npi_number
GO

--3. Work History
WITH datetimeline AS(
	SELECT 	CAST('2025-09-01 00:00:00' AS timestamp) AS beginDate,
			CAST('2025-09-30 23:59:59' AS timestamp) endDate
)

SELECT	npi_number, job_seeker_profile_work_experience.*
FROM	job_seeker_profile_work_experience
        JOIN job_seeker_profile ON job_seeker_profile_work_experience.profile_id = job_seeker_profile.id
WHERE	npi_number IS NOT NULL
        AND job_seeker_profile.site_id IN (1,2,3,4,5,6)
        AND job_seeker_profile_work_experience.created_at >= (SELECT beginDate FROM datetimeline)
        AND job_seeker_profile_work_experience.created_at <= (SELECT endDate FROM datetimeline)
GO

--4. Profile
WITH datetimeline AS(
	SELECT 	CAST('2025-09-01 00:00:00' AS timestamp) AS beginDate,
			CAST('2025-09-30 23:59:59' AS timestamp) endDate
)

SELECT	job_seeker_profile.job_seeker_id as user_id,
		"day",
		activity_count,
		activity_type
FROM	(
		SELECT	to_char(job_seeker_job_application.created_at, 'YYYY-MM-DD') as day,
				job_seeker_profile.job_seeker_id as user_id,
				count(1) as activity_count, 'job_application' as activity_type
		FROM	job_seeker_job_application
				JOIN job_seeker_profile ON job_seeker_job_application.profile_id = job_seeker_profile.id
		WHERE	job_seeker_profile.created_at >= (SELECT beginDate FROM datetimeline)
				AND job_seeker_profile.created_at <= (SELECT endDate FROM datetimeline)
				AND job_seeker_profile.site_id = 1
		GROUP BY job_seeker_profile.job_seeker_id, day
		UNION
		SELECT	to_char(job_view.created_at, 'YYYY-MM-DD') as day, job_view.user_id, count(1) as activity_count,
				'job_view' as activity_type
		FROM	job_view
				JOIN "user" ON job_view.user_id = "user".id
		WHERE	"user".network_id = 1 
				AND job_view.created_at >= (SELECT beginDate FROM datetimeline)
				AND job_view.created_at <= (SELECT endDate FROM datetimeline)
		GROUP BY job_view.user_id, day
		UNION
		SELECT to_char(login_event.created_at, 'YYYY-MM-DD') as day, login_event.user_id,
				count(1) as activity_count, 'login_event' as activity_type
		FROM	login_event
				JOIN "user" ON login_event.user_id = "user".id
		WHERE	"user".role = 'ROLE_JOB_SEEKER' 
				AND login_event.created_at >= (SELECT beginDate FROM datetimeline)
				AND login_event.created_at <= (SELECT endDate FROM datetimeline)
				AND "user".network_id = 1
		GROUP BY login_event.user_id, day
		UNION
		SELECT	to_char(job_search_event.created_at, 'YYYY-MM-DD') as day, job_search_event.user_id,
				count(1) as activity_count,
				'job_search' as activity_type
		FROM	job_search_event
				JOIN "user" ON job_search_event.user_id = "user".id
		WHERE	"user".network_id = 1 
				AND job_search_event.created_at >= (SELECT beginDate FROM datetimeline)
				AND job_search_event.created_at <= (SELECT endDate FROM datetimeline)
		GROUP BY day, user_id
		UNION
		SELECT	to_char(job_seeker_saved_job.saved_at, 'YYYY-MM-DD') as day,
				job_seeker_saved_job.job_seeker_id as user_id,
				count(1) as activity_count,
				'saved_job' as activity_type
		FROM	job_seeker_saved_job
				JOIN "user" ON job_seeker_saved_job.job_seeker_id = "user".id
		WHERE	"user".network_id = 1 
				AND job_seeker_saved_job.saved_at >= (SELECT beginDate FROM datetimeline)
				AND job_seeker_saved_job.saved_at <= (SELECT endDate FROM datetimeline)
		GROUP BY job_seeker_saved_job.job_seeker_id, day
		UNION
		SELECT	to_char(job_seeker_saved_job_search.created_at, 'YYYY-MM-DD') as day,
				job_seeker_saved_job_search.job_seeker_id as user_id,
				count(1) as activity_count, 'saved_job_search' as activity_type
		FROM	job_seeker_saved_job_search
		WHERE	site_id = 1 
				AND job_seeker_saved_job_search.created_at >= (SELECT beginDate FROM datetimeline)
				AND job_seeker_saved_job_search.created_at <= (SELECT endDate FROM datetimeline)
		GROUP BY day, job_seeker_saved_job_search.job_seeker_id
		) activities
		JOIN job_seeker_profile ON activities.user_id = job_seeker_profile.job_seeker_id
WHERE	job_seeker_profile.site_id = 1
GO