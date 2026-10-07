

SELECT	npi_number, job_seeker_profile_work_experience.*
FROM	job_seeker_profile_work_experience
        JOIN job_seeker_profile ON job_seeker_profile_work_experience.profile_id = job_seeker_profile.id
WHERE	npi_number IS NOT NULL
        AND job_seeker_profile.site_id IN (1,2,3,4,5,6)
        AND job_seeker_profile_work_experience.created_at >= (SELECT beginDate FROM datetimeline)
        AND job_seeker_profile_work_experience.created_at <= (SELECT endDate FROM datetimeline)