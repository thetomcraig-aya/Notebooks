select count(*) 
FROM `candidates_candidate` cc
JOIN `candidates_candidateorganizationdata` co
  ON cc.npi_id = co.npi_id 
  where (
  co.hospital_address IS NULL or TRIM(co.hospital_address) = '' or
  co.hospital_state IS NULL or TRIM(co.hospital_state) = '' or
  cc.city IS NULL or TRIM(cc.city) = '' OR
cc.state IS NULL or TRIM(cc.state) = ''
  );

