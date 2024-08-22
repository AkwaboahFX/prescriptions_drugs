--- 1.a
SELECT 
	npi, 
	SUM(total_claim_count) AS total_claims
FROM 
	prescription
GROUP BY 
	npi 
ORDER BY 
	total_claims DESC
LIMIT 1;


--- 1.b
SELECT 
    p.npi, 
    pr.nppes_provider_first_name, 
    pr.nppes_provider_last_org_name, 
    pr.specialty_description, 
    MAX(p.total_claim_count) AS total_claims
FROM 
    prescription p
JOIN 
    prescriber pr ON p.npi = pr.npi
GROUP BY 
    p.npi, 
    pr.nppes_provider_first_name, 
    pr.nppes_provider_last_org_name, 
    pr.specialty_description
ORDER BY 
    total_claims DESC


--- 2.a
SELECT
	 p.npi,
	 pr.specialty_description,
	 MAX(total_claim_count) AS total_claims	 
FROM 
	prescriber pr
JOIN
	prescription p  
	ON pr.npi = p.npi
GROUP BY 
	p. npi,
    pr. specialty_description
ORDER BY
    total_claims DESC;


--- 2.b
SELECT
	MAX(total_claim_count) AS total_claims,
	specialty_description	
FROM 
	prescriber 
INNER JOIN
	prescription USING (npi)
INNER JOIN
	drug USING (drug_name) 
WHERE 
	opioid_drug_flag = 'Y'		
GROUP BY 
	specialty_description
ORDER BY 
   total_claims DESC;


--- 2.c
SELECT
    specialty_description
FROM 
    prescriber
LEFT JOIN
    prescription USING (npi)
GROUP BY
	specialty_description
HAVING SUM
    (total_claim_count) IS NULL;


--- 2.d
SELECT
	specialty_description,
	ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' 
	THEN total_claim_count END)/SUM(total_claim_count)*100, 2) 
	AS percent_opioids
FROM 
	prescriber
INNER JOIN
	prescription USING (npi)
INNER JOIN 
	drug USING (drug_name)
GROUP BY 
	specialty_description	
ORDER BY
	percent_opioids DESC NULLS LAST;


--- 3.a
SELECT 
    generic_name,
	SUM(total_drug_cost)::money AS total_cost 
FROM 
	prescription
INNER JOIN
	drug USING (drug_name)
GROUP BY 
    generic_name
ORDER BY
    total_cost DESC;


--- 3.b
SELECT 
	generic_name,
	ROUND(MAX(total_drug_cost/total_day_supply),2)::money AS cost_per_day
FROM 
	prescription
JOIN 
	drug USING(drug_name)
GROUP BY 
	generic_name 
ORDER BY 
	cost_per_day DESC;


--- 4.a
SELECT drug_name,
	CASE
	WHEN 
	opioid_drug_flag ='Y' THEN 'opioid'
	WHEN 
	antibiotic_drug_flag = 'Y' THEN 'antibiotic'
ELSE 'neither' 
END AS 
	drug_type
FROM 
	drug;


--- 4.b
SELECT
    d.drug_name,
    SUM(CASE WHEN d.opioid_drug_flag = 'opioid' THEN p.total_drug_cost ELSE 0 END)::money AS total_opioid_cost,
    SUM(CASE WHEN d.antibiotic_drug_flag = 'antibiotic' THEN p.total_drug_cost ELSE 0 END)::money AS total_antibiotic_cost
FROM 
    drug d
INNER JOIN 
    prescription p USING (drug_name)
GROUP BY
    d.drug_name;


WITH TotalCosts AS (
    SELECT 
        SUM(p.total_drug_cost)::money AS total_cost,
        'Opioid' AS category
    FROM 
        drug d
    INNER JOIN 
        prescription p USING (drug_name)
    WHERE 
        d.opioid_drug_flag = 'opioid'
    UNION ALL
    SELECT 
        SUM(p.total_drug_cost)::money AS total_cost,
        'Antibiotic' AS category
    FROM 
        drug d
    INNER JOIN 
        prescription p USING (drug_name)
    WHERE 
        d.antibiotic_drug_flag = 'antibiotic'
)
SELECT
    CASE 
        WHEN (SELECT total_cost FROM TotalCosts WHERE category = 'Opioid') >
             (SELECT total_cost FROM TotalCosts WHERE category = 'Antibiotic')
        THEN 'More was spent on opioids.'
        WHEN (SELECT total_cost FROM TotalCosts WHERE category = 'Opioid') <
             (SELECT total_cost FROM TotalCosts WHERE category = 'Antibiotic')
        THEN 'More was spent on antibiotics.'
        ELSE 'The spending on opioids and antibiotics is equal.'
    END AS ComparisonResult;


--- 5.a
SELECT 
	COUNT(cbsaname) AS cbsa_tennessee
FROM 
	cbsa
WHERE 
	cbsa = 'Tennessee';


--- 5.b
SELECT c.cbsaname, 
	MAX(p.population) AS max_cbsa_pop
FROM 
	cbsa c
JOIN 
	population p 
	ON 
	c.fipscounty = p.fipscounty
GROUP BY 
	c.cbsaname 
ORDER BY 
	max_cbsa_pop DESC;


--- 5.c
SELECT fc.county, 
	MAX(p.population) AS max_fips_pop
FROM 
	population p
LEFT JOIN 
	fips_county fc 
	ON p.fipscounty = fc.fipscounty
WHERE 
	fc.county IS NOT NULL
GROUP BY 
	fc.county 
ORDER BY 
	max_fips_pop DESC,
	fc.county;


--- 6.a
SELECT drug_name, 
	SUM(total_claim_count) AS total_claims
FROM 
	prescription
WHERE 
	total_claim_count >= 3000
GROUP BY 
	drug_name 
ORDER BY 
	total_claims


--- 6.b
SELECT 
    p.drug_name, 
    SUM(p.total_claim_count) AS total_claims,
    CASE 
        WHEN d.drug_name IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS is_opioid
FROM 
    prescription p
LEFT JOIN 
    drug d
ON 
    p.drug_name = d.drug_name
WHERE 
    p.total_claim_count >= 3000
GROUP BY 
    p.drug_name,
	d.drug_name
ORDER BY 
    total_claims;


--- 6.c
SELECT 
    p.drug_name, 
    SUM(p.total_claim_count) AS total_claims,
    CASE 
        WHEN d.drug_name IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS is_opioid,
    pr.nppes_provider_first_name,
    pr.nppes_provider_last_org_name
FROM 
    prescription p
LEFT JOIN 
     drug d 
	ON p.drug_name = d.drug_name
LEFT JOIN 
    prescriber pr 
	ON p.npi = pr.npi
WHERE 
    p.total_claim_count >= 3000
GROUP BY
	d.drug_name,
    p.drug_name, 
	pr.nppes_provider_first_name, 
	pr.nppes_provider_last_org_name
ORDER BY 
    total_claims;


--- 7.a
SELECT 
    pr.npi, 
    p.drug_name
FROM 
    prescriber pr
JOIN 
    prescription p ON pr.npi = p.npi
JOIN 
    drug d ON p.drug_name = d.drug_name
WHERE 
    pr.specialty_description = 'Pain Management' AND
    pr.nppes_provider_city = 'NASHVILLE' AND
    d.opioid_drug_flag = 'Y';


--- 7.b
SELECT 
	pr.npi,
	p.drug_name,
	SUM (p.total_claim_count) AS num_of_claims
FROM 
	prescriber pr
JOIN 
	prescription p
ON 
	pr.npi = p.npi
GROUP BY 
	pr.npi, 
	p.drug_name
ORDER BY 
	num_of_claims DESC;


--- 7.c
SELECT 
    pr.npi, 
    p.drug_name,
    COALESCE(p.total_claim_count, 0) AS total_claim_count
FROM 
    prescriber pr
JOIN 
    prescription p ON pr.npi = p.npi
JOIN 
    drug d ON p.drug_name = d.drug_name
WHERE 
    pr.specialty_description = 'Pain Management' AND
    pr.nppes_provider_city = 'NASHVILLE' AND
    d.opioid_drug_flag = 'Y';


--- 8
SELECT 
    COUNT(DISTINCT pr.npi) AS npi_count
FROM 
     prescriber pr
LEFT JOIN 
     prescription p 
ON 
	pr.npi = p.npi
WHERE 
    p.npi IS NULL;


--- 9.a
SELECT 
	d.generic_name, 
	pr.specialty_description
FROM 
	drug d
JOIN 
	prescription p
ON 
	d.drug_name = p.drug_name
JOIN 
	prescriber pr
ON 
	pr.npi = p.npi
WHERE 
	pr.specialty_description = 'Family Practice'
GROUP BY 
	d.generic_name, 
	pr.specialty_description
LIMIT 5;


--- 9.b
SELECT 
	d.generic_name, 
	pr.specialty_description
FROM 
	drug d
JOIN 
	prescription p
ON 
	d.drug_name = p.drug_name
JOIN 
	prescriber pr
ON 
	pr.npi = p.npi
WHERE 
	pr.specialty_description = 'Cardiology'
GROUP BY 
	d.generic_name, 
	pr.specialty_description
LIMIT 5;


--- 9.c
SELECT 
    p.drug_name   
FROM 
    prescription p
JOIN 
    prescriber pr ON p.npi = pr.npi
WHERE 
    pr.specialty_description IN ('Family Practice', 'Cardiologist')
GROUP BY 
    p.drug_name
LIMIT 5;


--- 10.a
SELECT 
	pr.nppes_provider_city, 
	SUM(p.total_claim_count) AS num_of_claims, 
	p.npi
FROM 
	prescriber pr
JOIN 
	prescription p USING (npi)
WHERE 
	pr.nppes_provider_city = 'NASHVILLE'
GROUP BY 
	pr.nppes_provider_city, 
	p.npi
ORDER BY 
	num_of_claims DESC
LIMIT 5;


--- 10.b
SELECT 
	pr.nppes_provider_city, 
	SUM(p.total_claim_count) AS num_of_claims, 
	p.npi
FROM 
	prescriber pr
JOIN 
	prescription p USING (npi)
WHERE 
	pr.nppes_provider_city = 'MEMPHIS'
GROUP BY 
	pr.nppes_provider_city, 
	p.npi
ORDER BY 
	num_of_claims DESC
LIMIT 5;


--- 10.c
SELECT 
	pr.nppes_provider_city, 
	SUM(p.total_claim_count) AS num_of_claims, 
	p.npi
FROM 
	prescriber pr
JOIN 
	prescription p USING (npi)
WHERE 
	pr.nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILL', 'CHATTANOOGA')
GROUP BY 
	pr.nppes_provider_city, 
	p.npi
ORDER BY 
	num_of_claims DESC;


--- 11
SELECT 
    fc.county, 
    SUM(ov.overdose_deaths) AS overdose
FROM 
    fips_county AS fc
JOIN 
    overdose_deaths AS ov
ON 
    CAST(fc.fipscounty AS INTEGER) = ov.fipscounty
GROUP BY 
    fc.county
ORDER BY 
    overdose DESC;


--- 12.a
SELECT 
	fc.state, 
	SUM(p.population) AS total_population
FROM 
	fips_county fc
LEFT JOIN 
	population p  
ON 
	p.fipscounty = fc.fipscounty
WHERE 
	fc.state ='TN'
GROUP BY 
	fc.state


--- 12.b
WITH total_pop AS (
    SELECT 
        SUM(p.population) AS total_population
    FROM 
        fips_county fc
    JOIN 
        population p ON fc.fipscounty = p.fipscounty
    WHERE 
        fc.state = 'TN'
)
SELECT 
    fc.county AS county_name, 
    p.population AS county_population,
    (p.population / total_pop.total_population * 100) AS population_percentage
FROM 
    fips_county fc
JOIN 
    population p ON fc.fipscounty = p.fipscounty
JOIN 
    total_pop ON true
WHERE 
    fc.state = 'TN'
ORDER BY 
    population_percentage DESC;









