
-- all with previous missing data, updated in etl run on sand
SELECT 
cc.id,
cc.updated_at,

-- UPDATED!
-- candidate detail header and sketch show location as city, state
cc.state,
-- UPDATED!
-- candidate detail header and sketch show location as city, state
cc.city,

-- UPDATED!
-- may not be used
cc.address,

cc.zipcode,
cc.latitude,
cc.longitude,
cc.npi_id,
cc.degree,
cc.specialty,
cc.sub_specialty,
cc.phy_role,

-- used with Hospital objects for claims history section
cc.hosp_history_affiliation,

-- -- candidate sketch page shows in "Majority Billing Organization"
-- -- used in add project
-- ch.hospital_name,
-- -- candidate sketch page shows in "Majority Billing Organization"
-- ch.hospital_id,
-- -- list filter options
-- -- used in add project
-- ch.hospital_address,
-- -- may not be used
-- ch.hospital_address1,
-- -- used with candidate object object for claims history section
-- ch.hospital_state,
-- -- used with candidate object object for claims history section
-- ch.hospital_city,
-- -- may not be used
-- ch.hospital_zipcode,

-- UPDATED!
-- candidate sketch page shows in "Majority Billing Organization"
co.billing_hosp_name,
-- UPDATED!
-- candidate sketch page shows in "Majority Billing Organization"
co.billing_hosp_id,
-- UPDATED!
-- may not be used
co.hospital_address,
-- may not be used?
co.hospital_address1,
-- UPDATED!
-- may not be used?
co.hospital_state,
-- UPDATED!
-- may not be used?
co.hospital_city,
-- UPDATED!
-- may not be used?
co.hospital_zipcode

FROM `candidates_candidate` cc
JOIN `candidates_candidateorganizationdata` co
  ON cc.npi_id = co.npi_id 

-- JOIN JSON_TABLE(cc.hosp_history_affiliation, '$[*]'
--   COLUMNS (inner_arr JSON PATH '$')
-- ) outer_jt
-- JOIN JSON_TABLE(outer_jt.inner_arr, '$[*]'
--   COLUMNS (hosp_id BIGINT PATH '$')
-- ) hosp_jt
-- JOIN candidates_hospital ch
--   ON ch.id = hosp_jt.hosp_id

  where 

  cc.updated_at >= '2026-02-02  23:59:59'

  and (
  co.hospital_address IS NULL or TRIM(co.hospital_address) = '' or
  co.hospital_state IS NULL or TRIM(co.hospital_state) = '' or
  cc.city IS NULL or TRIM(cc.city) = '' OR
cc.state IS NULL or TRIM(cc.state) = ''
  );


-- --   and cc.npi_id in (
-- -- 1902471089,
-- -- 1720614647,
-- -- 1356859979,
-- -- 1760118939,
-- -- 1790010338,
-- -- 1801548029,
-- -- 1679921340,
-- -- 1932957586,
-- -- 1013274869,
-- -- 1588343123 ,
-- -- 1871271155,
-- -- 1669777561,
-- -- 1568759868  ,
-- -- 1437521366  ,
-- -- 1386148633 ,
-- -- 1174359251 ,
-- -- 1164049110,
-- -- 1174229595,
-- -- 1619694056,
-- -- 1477200426,
-- -- 1659053189,
-- -- 1588272470,
-- -- 1457904385,
-- -- 1518464973,
-- -- 1619554839,
-- -- 1629500152,
-- -- 1992388789,
-- -- 1518645647,
-- -- 1407534795,
-- -- 1558049825,
-- -- 1780362053,
-- -- 1588469126,
-- -- 1851063531,
-- -- 1699921163,
-- -- 1326627902,
-- -- 1578669362,
-- -- 1891468500,
-- -- 1669044517,
-- -- 1639637689,
-- -- 1205324530,
-- -- 1366964827,
-- -- 1104312842,
-- -- 1457931933,
-- -- 1326605213,
-- -- 1770938540,
-- -- 1508407313,
-- -- 1922847417,
-- -- 1861569659
-- -- );



