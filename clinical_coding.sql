USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[Telehealth_Scoring_Audit]    Script Date: 8/13/2020 9:46:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--ALTER proc [dbo].[clinical_coding_audit]
--(
--	@Start_Date datetime,
--	@End_Date datetime
--)

--AS

declare @Start_Date date = '20200801'
declare @End_Date date = '20200810'

drop table #a1
drop table  #pd, #multi_dx, #one_dx, #dx_codes, #multi_dx1, #dxCodes
drop table #lab1
drop table #pregTestResults
drop table #gu_exams 
drop table #const_exams 
drop table #psych_exams 
drop table #const_pysch_exams
drop table #const_pysch_exams_only
drop table #const_pysch_gu_exams
drop table #ach, #achw
drop table #a2
drop table #dxEnc
drop table #rfvEnc


SELECT	distinct 
		lm.location_name, 
		SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr)) AS MRN,
		pp.enc_id, 
		pp.person_id,       
		cast(pe.create_timestamp as date) DOS, 
		pm.description provider_name
INTO #a1
FROM ngprod.dbo.patient_encounter pe
JOIN ngprod.dbo.patient_procedure pp ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
join ngprod.dbo.location_mstr lm	 ON lm.location_id = pe.location_id
join ngprod.dbo.patient pt			 ON pt.person_id = pe.person_id
join ngprod.dbo.provider_mstr pm     ON pm.provider_id = pe.rendering_provider_id
WHERE cast(pe.create_timestamp as date) between @Start_Date and @End_Date
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.delete_ind = 'N'
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')
AND (lm.location_name <> 'PPPSW Lab' and lm.location_name <> 'Clinical Services Planned Parenthood' and lm.location_name <> 'Telehealth')


select distinct pe.person_id, 				
				nor.enc_id,
				obr.test_desc, -- test description
				obx.obs_id,
				obx.observ_value, -- result
				obx.result_desc -- Quest result							
into #lab1			
from #a1 a
join ngprod.dbo.lab_nor nor on a.enc_id = nor.enc_id
join ngprod.dbo.patient_encounter pe on nor.enc_id=pe.enc_id
join ngprod.dbo.lab_results_obr_p obr on obr.ngn_order_num=nor.order_Num
join ngprod.dbo.lab_results_obx obx on obx.unique_obr_num=obr.unique_obr_num
join ngprod.dbo.person p on p.person_id=pe.person_id
where nor.delete_ind <> 'Y' and 					
		nor.ngn_status != 'Cancelled'	and 
		nor.test_status != 'Cancelled'	and 
		p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult') and
		((obx.result_desc LIKE '%GC%' OR obx.result_desc = 'CT' or result_desc like '%TRACHOMATIS%' OR obs_id like '%Gonor%' OR obs_id like '%Chlam%' ) or 
		  (obx.obs_id like '%rpr%') or 
		  (obx.result_desc like '%hiv%')
		  ) 

select distinct 
		o.encounterID, 
		o.actText, 
		o.obsValue
into #pregTestResults
from #a1 a
join ngprod.dbo.order_ o on a.enc_id=o.encounterID --and obsValue is not null
where (actText = 'Pregnancy Test' or actCode='81025K')
		
alter table #a1
add RFV1 varchar(1000), 
	EM_Code varchar(50),
	New_or_Est_Pt varchar(500),
	DX_Codes varchar(500),
	GC_CT varchar(20), 
	RPR varchar(20), 
	hiv varchar(20),
	pregTestResult varchar(500),
	time_phrase varchar(max)


update #a1 
set RFV1 = m.chiefcomplaint1
from #a1 a
join ngprod.dbo.master_im_ m on m.enc_id=a.enc_id 

update #a1 
set EM_Code =pp.service_item_id
from #a1 a 
join ngprod.dbo.patient_procedure pp on pp.enc_id= a.enc_id 
where service_item_id in (
	'99201',
	'99202',
	'99203',
	'99204', 
	'99211',
	'99212', 
	'99213', 
	'99214',
	'99215', 
	'99384', 
	'99385', 
	'99386', 
	'99394', 
	'99395', 
	'99396',
	'99401'
)

update #a1 
set New_or_Est_Pt = 'Est' 
from #a1 a 
join ngprod.dbo.master_im_ m on a.enc_id= m.enc_id
where m.newEstablished = 2

update #a1 
set New_or_Est_Pt = 'New' 
from #a1 a 
join ngprod.dbo.master_im_ m on a.enc_id= m.enc_id
where m.newEstablished = 1

update #a1 
set GC_CT = 'Y'
from #a1 a 
join #lab1 l on a.enc_id = l.enc_id
where (l.result_desc LIKE '%GC%' OR l.result_desc = 'CT' or l.result_desc like '%TRACHOMATIS%' OR l.obs_id like '%Gonor%' OR l.obs_id like '%Chlam%' )

update #a1 
set rpr = 'Y'
from #a1 a 
join #lab1 l on a.enc_id = l.enc_id
where (l.obs_id like '%rpr%' )

update #a1 
set hiv = 'Y'
from #a1 a 
join #lab1 l on a.enc_id = l.enc_id
where (l.result_desc like '%hiv%' )

update #a1 
set pregTestResult = p.obsValue
from #a1 a 
join #pregTestResults p on a.enc_id = p.encounterId

update #a1 
set time_phrase = ap.txt_description
from #a1 a 
join ngprod.dbo.assessment_impression_plan_ ap on a.enc_id=ap.enc_id and ap.detail_type='Provider Plan' 
 and ap.txt_description like '%spent a total%' 

  --Spent a total of 15 minutes 


select distinct a.enc_id,  d.icd9cm_code_id
into #pd
from #a1 a
left join ngprod.dbo.patient_diagnosis d on a.enc_id=d.enc_id

select *
into #multi_dx
from #pd
where enc_id in (
	select enc_id from (
		select enc_id, count(distinct icd9cm_code_id) countDxCode
		from #pd
		group by enc_id
		having count(distinct icd9cm_code_id) > 1
		) a
)

SELECT enc_id,  DX_Codes= STUFF(
             (SELECT ', ' + icd9cm_code_id
              FROM #multi_dx t1
              WHERE t1.enc_id = t2.enc_id
              FOR XML PATH (''))
             , 1, 1, '') 
into #multi_dx1
from #multi_dx t2
group by enc_id

select *
into #one_dx
from #pd
where enc_id in (
	select enc_id from (
		select enc_id, count(distinct icd9cm_code_id) countDxCode
		from #pd
		group by enc_id
		having count(distinct icd9cm_code_id) = 1
		) a
)


select * 
into #dx_codes
from #multi_dx1
union 
select * 
from #one_dx

update #a1
set DX_Codes = d.DX_Codes
from #a1 a 
join #dx_codes d on a.enc_id=d.enc_id

alter table #a1 
add time_code_correct varchar(100), 
	med_dec_correct varchar(100)

/*###### New Patient, STI Screen, STI Treatment, Reversible Contraception, EC, Pregnancy Test #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'STI Screen',
			'STI Treatment',
			'Reversible Contraception',
			'Emergency Contraception',
			'Pregnancy Test',
			'Preg Test'
		) and 
		EM_Code = '99202'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'STI Screen',
			'STI Treatment',
			'Reversible Contraception',
			'Emergency Contraception',
			'Pregnancy Test',
			'Preg Test'
		) and 
		(EM_Code != '99202' or EM_Code is null)


/*###### Est Patient, STI Screen, STI Treatment #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'STI Screen',
			'STI Treatment'			
		) and 
		EM_Code = '99213'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'STI Screen',
			'STI Treatment'			
		) and 
		(EM_Code != '99213' or EM_Code is null)

/*###### Est Patient, Reversible Contraception without STI Testing, no Time Phrase #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		(time_phrase is null or time_phrase not like '%spent a total%') and GC_CT is null and RPR is null and hiv is null and 
		EM_Code = '99212'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		(time_phrase is null or time_phrase not like '%spent a total%') and GC_CT is null and RPR is null and hiv is null and 
		(EM_Code != '99212' or EM_Code is null)


/*###### Est Patient, Reversible Contraception without STI Testing, with 15-minute time phrase #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		time_phrase like '%spent a total of 15%' and  GC_CT is null and RPR is null and hiv is null and
		EM_Code = '99213'

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		time_phrase like '%spent a total of 15%' and  GC_CT is null and RPR is null and hiv is null and 
		(EM_Code != '99213' or  EM_Code is null)


/*###### Est Patient, Reversible Contraception with STI Testing #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		EM_Code = '99213'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		(EM_Code != '99213' or EM_Code is null)

/*###### Est Patient, Emergency Contraception without STI Testing#####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		 GC_CT is null and RPR is null and hiv is null and 
		EM_Code = '99212'

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		time_phrase like '%spent a total of 15%' and  GC_CT is null and RPR is null and hiv is null and 
		(EM_Code != '99213' or EM_Code is null)

/*###### Est Patient, Emergency Contraception with STI Testing #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		EM_Code = '99213'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		(EM_Code != '99213' or EM_Code is null)


/*###### Est Patient, Pregnancy Test, negative #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		pregTestResult = 'negative' and 
		EM_Code = '99212'

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		pregTestResult = 'negative' and 
		(EM_Code != '99212' or EM_Code is null)


/*###### Est Patient, Pregnancy Test, positive #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		pregTestResult = 'positive' and 
		EM_Code = '99213'

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		pregTestResult = 'positive' and 
		(EM_Code != '99213' or EM_Code is null)



update #a1 
set time_code_correct = 'NA'
where time_code_correct is null

--update #a1 set med_dec_correct = null



/***********************************************************************************/
--drop table #dxCodes
select distinct a.enc_id, d.icd9cm_code_id dx_code
into #dxCodes
from #a1 a 
join ngprod.dbo.patient_diagnosis d on a.enc_id=d.enc_id


/*################# Exams ###########################################*/

select distinct m.enc_id, m.ros_system
into #gu_exams
from #a1 a 
join ngprod.dbo.[ngkbm_ros_findings_] m on m.enc_id = a.enc_id
where ros_system = 'GU'

select distinct c.enc_id, c.ros_system
into #const_exams
from #a1 a 
join ngprod.dbo.[ngkbm_ros_findings_] c on c.enc_id = a.enc_id
where ros_system = 'Constitutional'

select distinct c.enc_id, c.ros_system
into #psych_exams
from #a1 a 
join ngprod.dbo.[ngkbm_ros_findings_] c on c.enc_id = a.enc_id
where ros_system = 'Psych'

select distinct c.enc_id
into #const_pysch_exams
from #const_exams c 
join #psych_exams p on c.enc_id = p.enc_id


select * 
into  #const_pysch_exams_only
from #const_pysch_exams
where enc_id not in (
	select enc_id from #gu_exams
)

select distinct c.enc_id
into #const_pysch_gu_exams
from #const_exams c 
join #psych_exams p on c.enc_id = p.enc_id
join #gu_exams g on c.enc_id = g.enc_id


/*################# Candida Vuvlo Constitutional and Psych Only, Meds, New Patient ###########################################*/
update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		EM_Code = '99202' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		(EM_Code != '99202'  or EM_Code is null)



/*################# Candida Vuvlo Constitutional and Psych Only, Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		EM_Code = '99214' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		(EM_Code != '99214'  or EM_Code is null)

/*################# Candida Vuvlo Constitutional, Psych, GU, Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		EM_Code = '99203' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		(EM_Code != '99203'  or EM_Code is null)


/*################# Candida Vuvlo Constitutional, Psych, GU, Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		EM_Code = '99214' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%fluconazole%' or 
		medication_name like '%Clotrimazole%' or 
		medication_name like '%Miconazole%' or 
		medication_name like '%Terconazole%'
		) and 
		(EM_Code != '99214'  or EM_Code is null)



/*################# Candida Vuvlo Constitutional, Psych, No Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%fluconazole%' or 
					medication_name like '%Clotrimazole%' or 
					medication_name like '%Miconazole%' or 
					medication_name like '%Terconazole%'
		) and 
		EM_Code = '99202' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%fluconazole%' or 
					medication_name like '%Clotrimazole%' or 
					medication_name like '%Miconazole%' or 
					medication_name like '%Terconazole%'
		) and 
		(EM_Code != '99202' or EM_Code is null)


/*################# Candida Vuvlo Constitutional, Psych, No Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%fluconazole%' or 
					medication_name like '%Clotrimazole%' or 
					medication_name like '%Miconazole%' or 
					medication_name like '%Terconazole%'
		) and 
		EM_Code = '99213' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%fluconazole%' or 
					medication_name like '%Clotrimazole%' or 
					medication_name like '%Miconazole%' or 
					medication_name like '%Terconazole%'
		) and 
		(EM_Code != '99213'  or EM_Code is null)

/*################# Candida Vuvlo Constitutional, Psych, GU, No Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%fluconazole%' or 
					medication_name like '%Clotrimazole%' or 
					medication_name like '%Miconazole%' or 
					medication_name like '%Terconazole%'
		) and 
		EM_Code = '99213' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%fluconazole%' or 
					medication_name like '%Clotrimazole%' or 
					medication_name like '%Miconazole%' or 
					medication_name like '%Terconazole%'
		) and 
		(EM_Code != '99213' or EM_Code is null)


/*################# Bacterial Vaginosis, Const and Psych, Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		EM_Code = '99202' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		(EM_Code != '99202' or EM_Code is null)

/*################# Bacterial Vaginosis, Const and Psych, Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		EM_Code = '99214' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		(EM_Code != '99214'  or EM_Code is null)


/*################# Bacterial Vaginosis, Const, Psych,GU, Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		EM_Code = '99203' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		(EM_Code != '99203'  or EM_Code is null)


/*################# Bacterial Vaginosis, Const, Psych,GU, Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		EM_Code = '99214' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Metronidazole%' or 
		medication_name like '%Cleocin%' or 
		medication_name like '%Clindamycin%' or 
		medication_name like '%Tinidazole%'
		)  and 
		(EM_Code != '99214' or EM_Code is null)

/*################# Bacterial Vaginosis, Const, Psych, No Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		EM_Code = '99202' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		(EM_Code != '99202' or EM_Code is null)


/*################# Bacterial Vaginosis, Const, Psych, No Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		EM_Code = '99213' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		(EM_Code != '99213' or EM_Code is null)


/*################# Bacterial Vaginosis, Const, Psych, GU, No Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		EM_Code = '99203' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		(EM_Code != '99203' or EM_Code is null)

/*################# Bacterial Vaginosis, Const, Psych, GU, No Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		EM_Code = '99213' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'n76.0'  and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Metronidazole%' or 
					medication_name like '%Cleocin%' or 
					medication_name like '%Clindamycin%' or 
					medication_name like '%Tinidazole%'
		) and 
		(EM_Code != '99213' or EM_Code is null)


/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, Psych,Meds, New Patient ###########################################*/


select d1.enc_id
into #ach
from #dxCodes d1
join (select * from #dxCodes where dx_code = 'r30.0') d2 on d1.enc_id = d2.enc_id
join (select * from #dxCodes where dx_code = 'r35.0') d3 on d1.enc_id = d3.enc_id
where d1.dx_code = 'n30.00'

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99202' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99202' or EM_Code is null)


/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, Psych,Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99214' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99214' or EM_Code is null)

/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, GU,Psych,Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99203' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99203'  or EM_Code is null)

/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, GU,Psych,Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99214' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #ach d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99214' or EM_Code is null)


/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, Psych, No Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99202' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99202' or EM_Code is null)


/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, Psych, No Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99213' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #ach d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99213' or EM_Code is null)


/*################# Acute Cystitis without Hematuria, Dysuria, Urinary Frequency, Const, Psych,GU, No Meds, NewPatient ###########################################*/


select d1.enc_id
into #achw
from #dxCodes d1
join (select * from #dxCodes where dx_code = 'r30.0') d2 on d1.enc_id = d2.enc_id
join (select * from #dxCodes where dx_code = 'r35.0') d3 on d1.enc_id = d3.enc_id
where d1.dx_code = 'n30.01'

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #achw d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99202' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #achw d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99202' or EM_Code is null)


/*################# Acute Cystitis without Hematuria, Dysuria, Urinary Frequency, Const, Psych,GU, No Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #achw d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		EM_Code = '99213' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #achw d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where 
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			where medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99213' or EM_Code is null)


/*################# PID, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n70.93') and
		New_or_Est_Pt = 'New' and 
		(m.medication_name like '%ceftriazone%' or 
			m.medication_name like '%Doxycycline%' or 
			m.medication_name like '%Metronidazole%' ) and 
		EM_Code = '99203' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n70.93') and
		New_or_Est_Pt = 'New' and 
		(m.medication_name like '%ceftriazone%' or 
			m.medication_name like '%Doxycycline%' or 
			m.medication_name like '%Metronidazole%' ) and 
		(EM_Code != '99203' or EM_Code is null)



/*################# PID, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n70.93') and
		New_or_Est_Pt = 'Est' and 
		(m.medication_name like '%ceftriazone%' or 
			m.medication_name like '%Doxycycline%' or 
			m.medication_name like '%Metronidazole%' ) and 
		EM_Code = '99214' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n70.93') and
		New_or_Est_Pt = 'Est' and 
		(m.medication_name like '%ceftriazone%' or 
			m.medication_name like '%Doxycycline%' or 
			m.medication_name like '%Metronidazole%' ) and 
		(EM_Code != '99214' or EM_Code is null)




/*################# Pelvic Pain, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n94.89') and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			)		and 
		EM_Code = '99203' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n94.89') and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			 )		and 
		(EM_Code != '99203' or EM_Code is null)



/*################# Pelvic Pain, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n94.89') and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
			 )		and 
		EM_Code = '99213' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n94.89') and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
 )		and 
		(EM_Code != '99213' or EM_Code is null)

/*################# Abnormal Uterine Bleeding, New###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'New' and 
		pp.service_item_id in (
		'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
		) and 
		EM_Code = '99203' 


update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'New' and 
		pp.service_item_id in (
		'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
		) and 
		(EM_Code != '99203' or EM_Code is null)

/*################# Abnormal Uterine Bleeding, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'Est' and 
		pp.service_item_id in (
		'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
		) and 
		(EM_Code = '99214' or EM_Code is null)


update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'Est' and 
		pp.service_item_id in (
		'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
		) and 
		(EM_Code != '99214' or EM_Code is null)



/*################# Abnormal Uterine Bleeding, No Meds, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (
			select a.enc_id 
			from #a1 a 
			join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
			where pp.service_item_id in (
			'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
			)
		) and 
		EM_Code = '99202' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (
			select a.enc_id 
			from #a1 a 
			join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
			where pp.service_item_id in (
			'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
			)
		) and 
		(EM_Code != '99202' or EM_Code is null)


/*################# Abnormal Uterine Bleeding, No Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (
			select a.enc_id 
			from #a1 a 
			join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
			where pp.service_item_id in (
			'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
			)
		) and 
		EM_Code = '99213' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (
			select a.enc_id 
			from #a1 a 
			join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
			where pp.service_item_id in (
			'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'J1050' --Depo
			)
		) and 
		(EM_Code != '99213' or EM_Code is null)

update #a1 
set med_dec_correct = 'NA' 
where med_dec_correct is null


select distinct enc_id, provider_name, location_name, MRN, DOS, RFV1 RFV, EM_COde, New_or_Est_Pt, DX_Codes, time_code_correct, med_dec_correct
into #a2
from #a1 



select *
into #rfvEnc
from #a1
where RFV1 in (
	'STI Screen', 
	'STI Treatment', 
	'Reversible Contraception', 
	'Emergency Contraception', 
	'Pregnancy Test', 
	'Preg Test'
)



select a.*
into #dxEnc
from #a1 a
join #dxCodes d on a.enc_id = d.enc_id
where a.enc_id in (
	select enc_id from #ach
) or a.enc_id in (
	select enc_id from #achw
	) or 
	d.dx_code in (
	'B37.3', 
	'n76.0', 
	'n70.93', 
	'n94.89', 
	'n93.9'	
	)

--delete from #rfvEnc where em_code is null
--delete from #dxEnc where em_code is null



select top 10 * from #dxEnc
select * from #rfvEnc where time_code_correct = 'na'
