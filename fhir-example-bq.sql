# Show all imaging studies for patients diagnosed with Malignant Neoplasm of breast who are HER2-, ER-, and PR-
# Joe Murray
# Schema: FHIR R4
# Bigquery syntax
#
-- create a view for patient
WITH patient as (
SELECT id as patientid, 
       i.value as MRN,
       birthDate,
       deceased.boolean as deceased_flag,
       us_core_birthsex.value.code as sex,
       n.given as firstname,
       n.family as lastname 
FROM `uca-dev-common.padre.Patient` ,
UNNEST(name) n,
UNNEST(identifier) i,
UNNEST(i.type.coding) it
 WHERE it.code = "MR"
   AND n.use = 'official'
),
-- create a view of all malignant neoplasm of breast conditions
condition as (
SELECT abatement.dateTime as abatement_dateTime, 
       category, 
       clinicalStatus, 
       code, 
       onset.dateTime as onset_dateTime, 
       subject.patientid as patientid
FROM `uca-dev-common.padre.Condition`,
     UNNEST(code.coding) as code
WHERE  code.system = 'http://snomed.info/sct'
   AND code.code = '254837009' # malignant neoplasm of breast
)
,
-- Create a view of all HER2- Observations.
her2_neg as (
  SELECT subject.patientid,
         value.quantity.value,
         value.quantity.unit,
         codeval.code as codeval_code,
         codeval.display as codeval_display,
         codeval.system as codeval_system,
         coding.system as codename_system,
         coding.code as codename_code,
         coding.display as codename_display
  FROM `uca-dev-common.padre.Observation`,
       UNNEST(code.coding) coding,
       UNNEST(value.codeableConcept.coding) codeval
  WHERE coding.system = 'http://loinc.org' 
    AND coding.code = '48676-1' # HER2 
    AND codeval.system = 'http://snomed.info/sct'
    and codeval.code = '260385009' # NEGATIVE
),
-- create a view for ER- Observations
er_neg as (
  SELECT subject.patientid,
         value.quantity.value,
         value.quantity.unit,
         codeval.code as codeval_code,
         codeval.display as codeval_display,
         codeval.system as codeval_system,
         coding.system as codename_system,
         coding.code as codename_code,
         coding.display as codename_display
  FROM `uca-dev-common.padre.Observation`,
       UNNEST(code.coding) coding,
       UNNEST(value.codeableConcept.coding) codeval
  WHERE coding.system = 'http://loinc.org' 
    AND coding.code = '85337-4' # ER receptor
    AND codeval.system = 'http://snomed.info/sct'
    and codeval.code = '260385009' # NEGATIVE
),
-- create a view for PR- Observations
pr_neg as (
  SELECT subject.patientid,
         value.quantity.value,
         value.quantity.unit,
         codeval.code as codeval_code,
         codeval.display as codeval_display,
         codeval.system as codeval_system,
         coding.system as codename_system,
         coding.code as codename_code,
         coding.display as codename_display
  FROM `uca-dev-common.padre.Observation`,
       UNNEST(code.coding) coding,
       UNNEST(value.codeableConcept.coding) codeval
  WHERE coding.system = 'http://loinc.org' 
    AND coding.code = '85339-0' # PR receptor
    AND codeval.system = 'http://snomed.info/sct'
    and codeval.code = '260385009' # NEGATIVE
)

-- find patients that are 'triple-negative' (HER2-, ER-, PR-) for all receptors, and have a malignant breast cancer Condition
SELECT patient.patientid, 
       patient.MRN, 
       patient.firstname,
       patient.lastname,
       patient.sex,
       patient.birthDate as birthDate_string,
       DATE_DIFF(CURRENT_DATE(),CAST(patient.birthDate AS DATE),YEAR) as patient_current_age,
       DATE_DIFF(CAST(SUBSTR(condition.onset_dateTime,1,10) AS DATE),CAST(patient.birthDate AS DATE),YEAR) as patient_age_at_onset,
       condition.onset_dateTime, 
       condition.code.code, 
       condition.code.display, 
       condition.code.system,
       her2_neg.codename_display,
       her2_neg.codeval_code, 
       her2_neg.codeval_display, 
       her2_neg.codeval_system,
       er_neg.codename_display,
       er_neg.codeval_code, 
       er_neg.codeval_display, 
       er_neg.codeval_system,
       pr_neg.codename_display,
       pr_neg.codeval_code, 
       pr_neg.codeval_display, 
       pr_neg.codeval_system
  FROM patient,
       condition,
       her2_neg,
       er_neg,
       pr_neg
 WHERE patient.patientid = condition.patientid
   AND patient.patientid = her2_neg.patientid
   AND patient.patientid = er_neg.patientid
   AND patient.patientid = pr_neg.patientid
 ORDER BY patient.lastname