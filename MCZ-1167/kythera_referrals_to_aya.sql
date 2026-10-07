use dataintegrationssilver;
go

/*
NOTE: these file_year and file_month criteria are for example purposes only and not to be included in the production output.
for production output, we'll want to include all possible kythera file deliveries starting with 2015-01.
*/
declare @file_year varchar(10) = '2023';
declare @file_month varchar(10) = '01';

with
    Source as (
        SELECT
            a.referring_provider_npi,
            a.referral_to,
            COUNT(*) AS referral_count,
            MAX(YEAR (a.service_from_date)) AS referral_year
        FROM
            (
                SELECT
                  referring_provider_npi,
                  rendering_provider_npi AS referral_to,
                  rendering_provider_primarytaxonomycode as referring_taxonomycode,
                  service_from_date
                FROM
                    dbo.kythera_data
                WHERE 1=1
					and file_year = @file_year
					and file_month = @file_month
                    and rendering_provider_npi IS NOT NULL
                    AND service_from_date IS NOT NULL
                    AND organization_primarytaxonomydescription NOT IN (
                        'Organ Procurement Organization',
                        'Taxi',
                        'Peer Specialist',
                        'Home Health Aide',
                        'Public Health or Welfare',
                        'Ambulance Land Transport',
                        'Technician/Technologist Optician',
                        'Technician/Technologist Contact Lens',
                        'Contractor Vehicle Modifications',
                        'Blood Bank',
                        'Secured Medical Transport (VAN)',
                        'Respite Care Respite Care Camp',
                        'Clinical Ethicist',
                        'Technician/Technologist Ophthalmic',
                        'Technician/Technologist Ophthalmic Assistant',
                        'Mastectomy Fitter',
                        'Durable Medical Equipment & Medical Supplies Customized Equipment',
                        'Technician',
                        'Ambulance',
                        'Technician/Technologist Orthoptist',
                        'Clinical Medical Laboratory',
                        'Durable Medical Equipment & Medical Supplies Oxygen Equipment & Supplies',
                        'Occupational Therapy Assistant Driving and Community Mobility',
                        'Local Education Agency (LEA)',
                        'Program of All-Inclusive Care for the Elderly (PACE) Provider Organization',
                        'Technician/Technologist Optometric Assistant',
                        'Non-emergency Medical Transport (VAN)',
                        'Physiological Laboratory',
                        'Eyewear Supplier',
                        'Dental Laboratory',
                        'Technician/Technologist Contact Lens Fitter',
                        'In Home Supportive Care',
                        'Technician/Technologist Optometric Technician',
                        'Emergency Response System Companies',
                        'Private Vehicle',
                        'Occupational Therapy Assistant Low Vision',
                        'Case Management',
                        'Music Therapist',
                        'Religious Nonmedical Nursing Personnel',
                        'Physical Therapy Assistant',
                        'Voluntary or Charitable',
                        'Day Training, Developmentally Disabled Services',
                        'Hearing Aid Equipment',
                        'Assistant Behavior Analyst',
                        'Recreation Therapist',
                        'Dance Therapist',
                        'Driver',
                        'Audiologist Assistive Technology Supplier',
                        'Ambulance Water Transport',
                        'Hospice Care, Community Based',
                        'Early Intervention Provider Agency',
                        'Durable Medical Equipment & Medical Supplies',
                        'Supports Brokerage',
                        'Home Delivered Meals',
                        'Developmental Therapist',
                        'Transportation Broker',
                        'Technician Personal Care Attendant',
                        'Religious Nonmedical Practitioner',
                        'Home Infusion',
                        'Technician/Technologist Ocularist',
                        'Prosthetist',
                        'Contractor',
                        'Ambulance Air Transport',
                        'Non-Pharmacy Dispensing Site',
                        'Technician Attendant Care Provider',
                        'Recreational Therapist Assistant',
                        'Meals',
                        'Transportation Network Company',
                        'Assistant, Podiatric',
                        'Nursing Care',
                        'Interpreter',
                        'Contractor Home Modifications',
                        'Community/Behavioral Health',
                        'Home Health',
                        'Lactation Consultant, Non-RN',
                        'Specialist Research Study',
                        'Technician/Technologist',
                        'Durable Medical Equipment & Medical Supplies Nursing Facility Supplies',
                        'Pedorthist',
                        'Drama Therapist',
                        'Lodging',
                        'Medical Foods Supplier',
                        'Orthotist',
                        'Adult Companion',
                        'Eye Bank',
                        'Homemaker',
                        'Orthotic Fitter',
                        'Massage Therapist',
                        'Foster Care Agency',
                        'Durable Medical Equipment & Medical Supplies Parenteral & Enteral Nutrition',
                        'Behavior Technician',
                        'Occupational Therapy Assistant',
                        'Bus',
                        'Specialist Research Data Abstracter/Coder',
                        'Military Clinical Medical Laboratory',
                        'Durable Medical Equipment & Medical Supplies Dialysis Equipment & Supplies',
                        'Chore Provider',
                        'Prosthetic/Orthotic Supplier',
                        'Portable X-ray and/or Other Portable Diagnostic Imaging Supplier',
                        'Art Therapist',
                        'Personal Emergency Response Attendant'
                    )
                    AND referring_provider_npi IS NOT NULL
                    AND service_from_date IS NOT NULL
            ) AS a
            JOIN (
                SELECT DISTINCT
                    referring_provider_npi,
                    rendering_provider_primarytaxonomycode as rendering_taxonomycode
                FROM
                    dbo.kythera_data
				where
                    1=1
				    and file_year = @file_year
					and file_month = @file_month
            ) AS b ON a.referral_to = b.referring_provider_npi
        WHERE
            referring_taxonomycode = rendering_taxonomycode
        GROUP BY
            a.referring_provider_npi,
            a.referral_to
    ),
Grouped as (
SELECT
    referring_provider_npi,
    STRING_AGG (
        CASE
            WHEN referral_to COLLATE Latin1_General_100_CI_AS_SC_UTF8 != referring_provider_npi COLLATE Latin1_General_100_CI_AS_SC_UTF8
            AND referral_count > 10
            THEN CONCAT (
                '{"referral_to": "',
                referral_to COLLATE Latin1_General_100_CI_AS_SC_UTF8,
                '", "referral_count": ',
                referral_count,
                ', "referral_year": ',
                referral_year,
                '}'
            )
            ELSE NULL
        END,
        ','
    ) AS count_referral_to,
    (
        SELECT
            COUNT(*)
        FROM
            STRING_SPLIT (
                (
                    SELECT
                        STRING_AGG (
                            CASE
                                WHEN referral_to COLLATE Latin1_General_100_CI_AS_SC_UTF8 != referring_provider_npi COLLATE Latin1_General_100_CI_AS_SC_UTF8
                                AND referral_count > 10
                                THEN CONCAT (
                                    '{"referral_to": "',
                                    referral_to COLLATE Latin1_General_100_CI_AS_SC_UTF8,
                                    '", "referral_count": ',
                                    referral_count,
                                    ', "referral_year": ',
                                    referral_year,
                                    '}'
                                )
                                ELSE NULL
                            END,
                            ','
                        )
                ),
                ','
            )
    ) AS count_referral_to_length
from
    Source
GROUP BY
    referring_provider_npi
HAVING
    COUNT(referral_count) > 0
)
select
referring_provider_npi as provider_npi,
'[' + count_referral_to + ']' as count_referral_to
from Grouped
where count_referral_to_length  > 0;