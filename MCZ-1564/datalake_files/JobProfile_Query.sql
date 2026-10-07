

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