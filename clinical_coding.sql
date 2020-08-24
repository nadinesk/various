

ALTER proc [dbo].[Clinical_Coding_Audit]
(
	@Start_Date datetime,
	@End_Date datetime
)

AS


--drop table #a1
--drop table  #pd, #multi_dx, #one_dx, #dx_codes, #multi_dx1, #dxCodes
--drop table #lab1
--drop table #pregTestResults
--drop table #gu_exams 
--drop table #const_exams 
--drop table #psych_exams 
--drop table #const_psych_exams
--drop table #const_pysch_exams_only
--drop table #const_pysch_gu_exams
--drop table #ach, #achw
--drop table #a2
--drop table #dxEnc,#dxEnc1
--drop table #rfvEnc
--drop table #enc_meds, #enc_medications,#one_med, #enc_meds, #multi_med,#multi_med2,#enc_provOC

--declare @Start_Date date = '20200815'
--declare @End_Date date = '20200822'

SELECT	distinct 
		lm.location_name, 
		SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr)) AS MRN,
		pp.enc_id, 
		pp.person_id,       
		cast(pe.create_timestamp as date) DOS, 
		pm.description provider_name, 
		pp.service_item_id
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
and pe.rendering_provider_id in ()


alter table #a1
add event_id uniqueidentifier

update #a1
set event_id = app.event_id
from #a1 a 
join ngprod.dbo.appointments app on a.enc_id = app.enc_id



delete from #a1
where event_id in (
'36B09CAC-F6A7-4259-BB80-F355180094AE',
'B6E41A57-DC5D-4891-9844-9F321170FA06',
'3FADCE5E-0629-4438-812D-6F5A2FAABAFD',
'A5FF273E-3BD9-4BA1-AC9E-000219B168AD',
'D33F1A54-AF74-497E-B3F1-04BC0D77A189',
'2EA46C96-F55B-4661-955A-3E94F11B9456',
'974E785C-F9FC-498C-838F-D041443C7248',
'063F928F-3D2F-4FA8-AFDE-D951815DA07B',
'95D3CA7C-27C2-4B15-A87E-9275E3835F19',
'3F16CCAF-0A4A-4159-9A30-DC4B437195DE',
'470C9A55-AEB2-4EA3-BA79-B0BF00453648',
'C311107D-89D2-4C37-8481-3B3E05ABE86D',
'17815F5D-CDD2-4F7F-BC93-FBD5A41B3600',
'5CCD259E-7100-4B53-82A2-DA82C17AC889'
)


alter table #a1 
drop column event_id



delete from #a1 
where concat(person_id, DOS) in (
					select concat(person_id,DOS)
					from #a1 a				
					where service_item_id in ('S0199','S0199A') or
						  service_item_id like '%59840A%' or 
						  service_item_id like '%59841[C-N]%' or 
						  service_item_id in ('11981', -- Implant Insert
												'11976', -- Implant Removal
												'58300', -- IUC Insert
												'58301') -- IUC Removal

)


alter table #a1 
drop column service_item_id

/*
select distinct pe.person_id, 				
				nor.enc_id,
				nor.test_desc norTestdesc,
				obr.test_desc, -- test description
				obx.obs_id,
				obx.observ_value, -- result
				obx.result_desc -- Quest result							
into #lab1			
from #a1 a
join ngprod.dbo.lab_nor nor on a.enc_id = nor.enc_id
where nor.delete_ind <> 'Y' and 					
		nor.ngn_status != 'Cancelled'	and 
		nor.test_status != 'Cancelled'	and 		
		(nor.test_desc like '%Chlamydia%' or 
		  nor.test_desc like '%Gonorrhea%' or
		  nor.test_desc like '%hiv%' or
		  nor.test_desc like '%rpr%'
		  )
*/


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
	'99396'	,
	'99401'
)

delete from #a1 where EM_Code in ('99401', '99201')

delete from #a1 where RFV1 = 'Reversible Contraception' and EM_Code = '99211'


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
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
where 	
	(service_item_id LIKE '%L071%' --GC/CT Combo
	 OR service_item_id LIKE '%L103%'
	 OR service_item_id LIKE '%L104%'
	 OR service_item_id LIKE '%L105%'
	 OR service_item_id LIKE '%L073%'
	 OR service_item_id LIKE '%87491%' --CT
	 OR service_item_id LIKE '%L031%'
	 OR service_item_id LIKE '%L069%'
	 OR service_item_id LIKE '%87591%' --GC
	 OR service_item_id LIKE '%L070%') 
	

update #a1 
set rpr = 'Y'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
where service_item_id in ('L026','L111','L112') 



update #a1 
set hiv = 'Y'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
where (
			service_item_id like '%l023%' or
			service_item_id like '%l099%' or
			service_item_id like '%l159%' or
			service_item_id like '%86703%' or
			service_item_id like '%87806%' or
			service_item_id like '%86701%' 
	)




update #a1 
set pregTestResult = p.obsValue
from #a1 a 
join #pregTestResults p on a.enc_id = p.encounterId

delete from #a1 where RFV1 in ('Pregnancy Test', 'Preg Test') and pregTestResult = 'negative' and EM_Code = '99211'


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
add time_code_correct varchar(100)


/*###### New Patient, STI Screen, STI Treatment, Reversible Contraception, EC, Pregnancy Test #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'STI Screen',
			'STI Treatment',			
			'Emergency Contraception'			
		) and 
		EM_Code = '99202'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'STI Screen',
			'STI Treatment',			
			'Emergency Contraception'			
		) and 
		(EM_Code != '99202' or EM_Code is null)


update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'New' and 
		RFV1 in (			
			'Reversible Contraception'			
		) and 		
		(time_phrase is null or time_phrase not like '%spent a total of 30 min%')  and
		EM_Code = '99202' 


update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'New' and 
		RFV1 in (			
			'Reversible Contraception'			
		) and 		
		(time_phrase is null or time_phrase not like '%spent a total of 30 min%')  and
		(EM_Code != '99202' or EM_Code is null)

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'New' and 
		RFV1 in (			
			'Reversible Contraception'			
		) and 		
		(time_phrase like '%spent a total of 30 min%')  and
		EM_Code = '99203' 

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'New' and 
		RFV1 in (			
			'Reversible Contraception'			
		) and 		
		(time_phrase like '%spent a total of 30 min%')  and
		(EM_Code != '99203' or EM_Code is null)


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
		(time_phrase is null) and 
		(GC_CT is null and RPR is null and hiv is null) and 
		EM_Code = '99212'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
			(time_phrase is null ) and 
		 GC_CT is null and RPR is null and hiv is null and 
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
set time_code_correct = 'N'
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



update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		time_phrase like '%spent a total of 25%' and 
		EM_Code = '99214'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Reversible Contraception'
		) and 
		time_phrase like '%spent a total of 25%' and 
		(EM_Code != '99214' or EM_Code is null)


/*###### Est Patient, Emergency Contraception without STI Testing#####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		(time_phrase is null or time_phrase not like '%spent a total of 15 min%') and 
		 (GC_CT is null and RPR is null and hiv is null) and 
		EM_Code = '99212'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		(time_phrase is null or time_phrase not like '%spent a total of 15 min%') and 
		 GC_CT is null and RPR is null and hiv is null and 
		(EM_Code != '99212' or EM_Code is null)

/*###### Est Patient, Emergency Contraception without STI Testing#####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		(time_phrase like '%spent a total of 15 min%') and 
		 (GC_CT is null and RPR is null and hiv is null) and 
		EM_Code = '99213'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Emergency Contraception'
		) and 
		(time_phrase like '%spent a total of 15 min%') and 
		 GC_CT is null and RPR is null and hiv is null and 
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

/*###### New Patient, Pregnancy Test, negative #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		pregTestResult = 'negative' and 
		EM_Code = '99202'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		pregTestResult = 'negative' and 
		(EM_Code != '99202' or EM_Code is null)



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
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		pregTestResult = 'negative' and 
		(EM_Code != '99212' or EM_Code is null)


/*###### New Patient, Pregnancy Test, positive,  STI Testing #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		pregTestResult = 'positive' and 
		EM_Code = '99202'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'New' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		pregTestResult = 'positive' and 
		(EM_Code != '99202' or EM_Code is null)

/*###### Est Patient, Pregnancy Test, positive, STI Testing #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		pregTestResult = 'positive' and 
		EM_Code = '99213'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'Pregnancy Test', 
			'Preg Test'
		) and 
		(GC_CT ='Y' or RPR ='Y' or hiv ='y') and 
		pregTestResult = 'positive' and 
		(EM_Code != '99213' or EM_Code is null)


/*###### Est Patient, HCG , no Time Phrase #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'HCG'
		) and 
		(time_phrase is null) and 		
		EM_Code = '99212'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'HCG'
		) and 
			(time_phrase is null ) and 		 
		(EM_Code != '99212' or EM_Code is null)

/*###### Est Patient, HCG , w 15 min Time Phrase #####*/

update #a1 
set time_code_correct = 'Y'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'HCG'
		) and 
		(time_phrase like '%spent a total of 15 min%') and 		
		EM_Code = '99213'

update #a1 
set time_code_correct = 'N'
where New_or_Est_Pt = 'Est' and 
		RFV1 in (
			'HCG'
		) and 
			(time_phrase like '%spent a total of 15 min%') and 		 
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


--drop table #const_exams, #psych_exams, #gu_exams, #const_psych_exams, #const_pysch_exams_only, #const_pysch_gu_exams

select distinct c.enc_id, pe = 'Constitutional'
into #const_exams
from #a1 a 
join ngprod.dbo.[pecon_ ] c on c.enc_id = a.enc_id

select distinct c.enc_id, pe = 'Pyschiatric'
into #psych_exams
from #a1 a 
join ngprod.dbo.pe_psych_ c on c.enc_id = a.enc_id


select distinct c.enc_id, pe = 'Genitourinary'
into #gu_exams
from #a1 a 
join ngprod.dbo.pe_gu_male_ c on c.enc_id = a.enc_id
union 
select distinct c.enc_id, pe = 'Genitourinary'
from #a1 a 
join ngprod.dbo.pe_gu_female_ c on c.enc_id = a.enc_id

select distinct c.enc_id
into #const_psych_exams
from #const_exams c
join #psych_exams p on c.enc_id = p.enc_id 


select distinct enc_id
into  #const_pysch_exams_only
from #const_psych_exams
where enc_id not in (
	select enc_id from #gu_exams
)

select distinct c.enc_id
into #const_pysch_gu_exams
from #const_exams c 
join #psych_exams p on c.enc_id = p.enc_id
join #gu_exams g on c.enc_id = g.enc_id


alter table #a1 
add gu_exam varchar(20), 
	const_exam varchar(20), 
	pysch_exam varchar(20)


update #a1 
set gu_exam = 'Y'
 where enc_id in (
 select enc_id from #gu_exams
 )

 update #a1 
set const_exam = 'Y'
 where enc_id in (
 select enc_id from #const_exams
 )

  update #a1 
set pysch_exam = 'Y'
 where enc_id in (
 select enc_id from #psych_exams
 )

 alter table #a1 
 add med_dec_correct varchar(20)


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



/*################# Candida Vulvo Constitutional, Psych, No Meds, New Patient ###########################################*/

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
		) and 
		(EM_Code != '99213'  or EM_Code is null)

/*################# Candida Vuvlo Constitutional, Psych, GU, No Meds, New Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id		
		) and 
		EM_Code = '99203' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code = 'b37.3'  and
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (		
			select a.enc_id
			from #a1 a
			join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id		
		) and 
		(EM_Code != '99203' or EM_Code is null)

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
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
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
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
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
		) and 
		(EM_Code != '99213' or EM_Code is null)


/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, Psych,GU, Meds, New Patient ###########################################*/


--select d1.enc_id
--into #ach
--from #dxCodes d1
--join (select * from #dxCodes where dx_code = 'r30.0') d2 on d1.enc_id = d2.enc_id
--join (select * from #dxCodes where dx_code = 'r35.0') d3 on d1.enc_id = d3.enc_id
--where d1.dx_code = 'n30.00'

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.00', 'r30.0', 'r35.0') and 
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
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.00', 'r30.0', 'r35.0') and 
		New_or_Est_Pt = 'New' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 		
		(EM_Code != '99203' or EM_Code is null)


/*################# Acute Cystitis, Dysuria, Urinary Frequency, Const, GU, Psych,Meds, Est Patient ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.00', 'r30.0', 'r35.0') and 
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
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.00', 'r30.0', 'r35.0') and 
		New_or_Est_Pt = 'Est' and 
		(medication_name like '%Ciprofloxacin%' or 
					medication_name like '%Nitrofurantoin%' or 
					medication_name like '%Sulfamethoxazole%' or 
					medication_name like '%Monurol%' or 
					medication_name like '%Amoxicillin%'
		) and 
		(EM_Code != '99214' or EM_Code is null)



/*################# Acute Cystitis without Hematuria, Dysuria, Urinary Frequency, Const, Psych,GU, No Meds, NewPatient ###########################################*/


update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.01', 'r30.0', 'r35.0') and 
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		) and 		
		EM_Code = '99202' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.01', 'r30.0', 'r35.0') and 
		New_or_Est_Pt = 'New' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		) and 		
			(EM_Code != '99202' or EM_Code is null)



/*################# Acute Cystitis without Hematuria, Dysuria, Urinary Frequency, Const, Psych,GU, No Meds, Est Patient ###########################################*/


update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.01', 'r30.0', 'r35.0') and 
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		) and 		
		EM_Code = '99213' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n30.01', 'r30.0', 'r35.0') and 
		New_or_Est_Pt = 'Est' and 
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
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
/*
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


*/
/*################# Abnormal Uterine Bleeding, New###########################################*/
/*
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
						'm027','m112'--provera
							
		) and 
		EM_Code = '99203' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'New' and 
		pp.service_item_id in (
		'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'm027','m112'--provera
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
							'm027','m112'--provera
		) and 
		(EM_Code = '99214' or EM_Code is null)


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n93.9') and
		New_or_Est_Pt = 'Est' and 
		pp.service_item_id in (
		'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
							'm027','m112'--provera
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
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id			
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
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id			
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
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id			
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
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id			
		) and 		
		(EM_Code != '99213' or EM_Code is null)

*/
/*################# Vulvar Ulcer, Constitutional and Psych, Meds, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 
		EM_Code = '99202' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 		
		(EM_Code != '99202' or EM_Code is null)



/*################# Vulvar Ulcer, Constitutaional and Psychiatric, Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 
		EM_Code = '99214' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 		
		(EM_Code != '99214' or EM_Code is null)


/*################# Vulvar Ulcer, Constitutional, Psych, GU, Meds, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 
		EM_Code = '99203' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 		
		(EM_Code != '99203' or EM_Code is null)



/*################# Vulvar Ulcer, Constitutional, Psychiatric, GU, Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 
		EM_Code = '99214' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Acyclovir%' or 
			p.medication_name like '%Valacyclovir%' or 
			p.medication_name like '%Famciclovir%' ) and 		
		(EM_Code != '99214' or EM_Code is null)


/*################# Vulvar Ulcer, Constitutional and Psychiatric, No Meds, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
		EM_Code = '99202' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
				(EM_Code != '99202' or EM_Code is null)


/*################# Vulvar Ulcer, Constitutional and Psychiatric, No Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
		EM_Code = '99213' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
				(EM_Code != '99213' or EM_Code is null)



/*################# Vulvar Ulcer, Constitutional, Psychiatric, GU, No Meds, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
		EM_Code = '99203' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'New' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
				(EM_Code != '99203' or EM_Code is null)


/*################# Vulvar Ulcer, Constitutional, Psychiatric, GU, No Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
		EM_Code = '99213' 


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n76.6') and
		New_or_Est_Pt = 'Est' and 		
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id =p.enc_id
		)		and 		
				(EM_Code != '99213' or EM_Code is null)

/*################# NGU, Urethritis, Constitutional and Psychiatric, Meds, New###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_exams_only c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n34.2', 'n34.1') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 
		EM_Code = '99202' 


update #a1 
set med_dec_correct ='N'
from #a1 a 
join #const_pysch_exams_only c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 		
		(EM_Code != '99202' or EM_Code is null)



/*################# NGU,Urethritis, Const and Psych, Meds, Est not FPACT###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_exams_only c on a.enc_id = c.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 
		EM_Code = '99214' and 
		financial_class != 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_exams_only c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 		
		financial_class != 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'	and 
		(EM_Code != '99214' or EM_Code is null)

/*################# NGU,Urethritis, Const and Psych, Meds, Est, FPACT###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_exams_only c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 
		financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF' and 
		EM_Code = '99213'  
	
update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_exams_only c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 		
		financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'	and 
		(EM_Code != '99213' or EM_Code is null)


/*################# NGU, Urethritis, Constitutional, Psychiatric, GU, Meds, New###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n34.2', 'n34.1') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 
		EM_Code = '99203' 


update #a1 
set med_dec_correct ='N'
from #a1 a 
join #const_pysch_gu_exams c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'New' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 		
		(EM_Code != '99203' or EM_Code is null)



/*################# NGU,Urethritis, Const, Psych, GU, Meds, Est not FPACT###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
join #const_pysch_gu_exams c on a.enc_id = c.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 
		EM_Code = '99214' and 
		financial_class != 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_gu_exams c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 		
		financial_class != 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'	and 
		(EM_Code != '99214' or EM_Code is null)

/*################# NGU,Urethritis, Const, Psych, GU, Meds, Est, FPACT###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 
		financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF' and 
		EM_Code = '99213'  
		


update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_gu_exams c on a.enc_id = c.enc_id
join #dxCodes d on d.enc_id = a.enc_id
join ngprod.dbo.patient_medication p on p.enc_id = a.enc_id
join ngprod.dbo.patient_encounter pe on pe.enc_id = a.enc_id
left join ngprod.dbo.payer_mstr pm on pe.cob1_payer_id = pm.payer_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 		
			(p.medication_name like '%Ceftriaxone%' or 
			p.medication_name like '%Azithromycin%' or 
			p.medication_name like '%Doxycycline%' or
			p.medication_name like '%Gentamycin%' ) and 		
		financial_class = 'CAA60319-6277-4F0D-831E-5CB21A4B0BBF'	and 
		(EM_Code != '99213' or EM_Code is null)


/*################# NGU, Urethritis, Const and Psych, No Meds, New###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2', 'n34.1') and
		New_or_Est_Pt = 'New' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 			
		EM_Code = '99202' 

update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'New' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 					
		(EM_Code != '99202' or EM_Code is null)



/*################# NGU, Urethritis, Const and Psych, No Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 			
		EM_Code = '99213' 



update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_exams_only c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 					
		(EM_Code != '99213' or EM_Code is null)

/*################# NGU, Urethritis, Const, Psych, GU, No Meds, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'New' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 			
		EM_Code = '99203' 



update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'New' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 					
		(EM_Code != '99203' or EM_Code is null)


/*################# NGU, Urethritis, Const, Psych, GU, No Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 			
		EM_Code = '99213' 



update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #const_pysch_gu_exams c on c.enc_id = a.enc_id
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n34.2','n34.1') and
		New_or_Est_Pt = 'Est' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 					
		(EM_Code != '99213' or EM_Code is null)


/*################# Other Non-Inflammatory Vagi, No Meds, New ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n89.8') and
		New_or_Est_Pt = 'New' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 			
		EM_Code = '99202' 



update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n89.8') and
		New_or_Est_Pt = 'New' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 					
		(EM_Code != '99202' or EM_Code is null)


/*################# Other Non-Inflammatory Vagi, No Meds, Est ###########################################*/

update #a1 
set med_dec_correct = 'Y'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n89.8') and
		New_or_Est_Pt = 'Est' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 			
		EM_Code = '99213' 



update #a1 
set med_dec_correct = 'N'
from #a1 a 
join #dxCodes d on d.enc_id = a.enc_id
where d.dx_code in( 'n89.8') and
		New_or_Est_Pt = 'Est' and 	
		a.enc_id not in (
			select a.enc_id
			from #a1 a 
			join ngprod.dbo.patient_medication p on a.enc_id = p.enc_id
		)	and 					
		(EM_Code != '99213' or EM_Code is null)


update #a1 
set med_dec_correct = 'NA' 
where med_dec_correct is null


select distinct a.enc_id, m.medication_name
into #enc_meds
from #a1 a 
join ngprod.dbo.patient_medication m on a.enc_id = m.enc_id 
--where medication_name like '%fluconazole%' or 
--		medication_name like '%Clotrimazole%' or 
--		medication_name like '%Miconazole%' or 
--		medication_name like '%Terconazole%' or 
--		medication_name like '%Metronidazole%' or 
--		medication_name like '%Cleocin%' or 
--		medication_name like '%Tinidazole%' or 
--		medication_name like '%Ciprofloxacin%' or 
--		medication_name like '%Nitrofurantoin%' or 
--		medication_name like '%Sulfamethoxazole%' or 
--		medication_name like '%Monurol%' or 
--		medication_name like '%Amoxicillin%' or 
--		medication_name like '%Ceftriazone%' or 
--		medication_name like '%Doxycycline%' or 
--		medication_name like '%Metronidazole%' or 
--		medication_name like '%Acyclovir%' or 
--		medication_name like '%Valacyclovir%' or 
--		medication_name like '%Famciclovir%' or 
--		medication_name like '%Azithromycin%' or 
--		medication_name like '%Doxycycline%' or 
--		medication_name like '%Gentamycin%' 


select a.enc_id, medication_name='provera/oc'
into #enc_provOC
from #a1 a 
join ngprod.dbo.patient_procedure pp on a.enc_id = pp.enc_id
where pp.service_item_id in (	'AUBRA','AUBRAEQ','Brevicon',
							'CHATEAL','CHATEALEQ','Cyclessa','CyclessaNC','CYRED','CYREDEQ','Desogen','DesogenNC','Gildess','Levora','LEVORANC','LYZA','Mgestin','MGESTINNC','Micronor','Micronornc','Modicon',
						'ModiconNC','NO777','NORTREL','OCELL','OCEPT','ON135','ON135NC','ON777','ON777NC','ORCYCLEN','ORCYCLENNC','OTRICYCLEN','OTRINC','RECLIPSEN','Tarina','Trilo','TRILONC','TriVylibra','Tulana','Vylibra',
								'm027','m112'--provera
							)

select *
into #multi_med
from #enc_meds
where enc_id in (
	select enc_id from (
		select enc_id, count(distinct medication_name) countMeds
		from #enc_meds
		group by enc_id
		having count(distinct medication_name) > 1
		) a
)

SELECT enc_id,  med_names= STUFF(
             (SELECT ', ' + medication_name
              FROM #multi_med t1
              WHERE t1.enc_id = t2.enc_id
              FOR XML PATH (''))
             , 1, 1, '') 
into #multi_med2
from #multi_med t2
group by enc_id

select *
into #one_med
from #enc_meds
where enc_id in (
	select enc_id from (
		select enc_id, count(distinct medication_name) countDxCode
		from #enc_meds
		group by enc_id
		having count(distinct medication_name) = 1
		) a
)


select * 
into #enc_medications
from #multi_med2
union 
select * 
from #one_med

alter table #a1 
add medsDxCodes varchar(max), 
	ocProv varchar(100)

update #a1 
set medsDxCodes = med_names
from #a1 a 
join #enc_medications m on a.enc_id = m.enc_id

update #a1 
set ocProv = medication_name
from #a1 a 
join #enc_provOC m on a.enc_id = m.enc_id

update #a1
set time_phrase = REPLACE(REPLACE(time_phrase, CHAR(13), ''), CHAR(10), '')

select distinct * from #a1 


