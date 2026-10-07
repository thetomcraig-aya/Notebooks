

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