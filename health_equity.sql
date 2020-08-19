ALTER proc [dbo].[Health_Equity]
(
	@Start_Date date, 
	@End_Date  date
)

AS

--declare @Start_Date date = '20200601'
--declare @End_Date date = '20200630'

--drop table #s1, #s2, #epem, #g1, #g2, #g3, #cmp, #st, #th1, #gahtpt, #epemComb, #gahtComb, #cmpComb, #stComb, #th1Comb, #cf1, #core4, #core4Comb, #combine

SELECT distinct 
		lm.location_name, 
		pp.enc_id, 
		pp.person_id,
		pp.service_item_id, 
		cast(pe.create_timestamp as date) DOS, 
		p.date_of_birth, 
		CAST((CONVERT(INT,CONVERT(CHAR(8),cast(pe.create_timestamp as date),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) age, 
		p.sex,
		p.race, 
		p.ethnicity
INTO #s1
FROM ngprod.dbo.patient_procedure pp
JOIN ngprod.dbo.patient_encounter pe ON pp.enc_id = pe.enc_id
JOIN ngprod.dbo.person	p			 ON pp.person_id = p.person_id
join ngprod.dbo.location_mstr lm	 ON lm.location_id = pe.location_id
WHERE (cast(pe.create_timestamp as date) between @Start_Date AND @End_Date)
AND (lm.location_name <> 'PPPSW Lab' and lm.location_name <> 'Clinical Services Planned Parenthood')
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
AND pp.delete_ind = 'N'
AND (pe.billable_ind = 'Y' AND pe.clinical_ind = 'Y')

alter table #s1
add race_eth varchar(500), 
	sexual_practices varchar(500)

update #s1
set race_eth =case 
					when race like '%white%' AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'White' 
					when  (race = '2- African American' or race = '2- African American/Black') AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'African American'
					when (race = '3- Asian' ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Asian'					
					when  ( race = '4- Pacific Islander' ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Pacific Islander'
					when ( race = '7- Filipino'  ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Filipino'
					when  (race ='8- Middle Eastern'  ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Middle Eastern'
					when race = '5- Native American' AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Native American'
					--when (race = '7- Other' or race = '7-Other' or race = '6-Multi-racial' or race is NULL or race='' or race='race-other') AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'race-other'
					when (race LIKE '7-Other%' or race = '7- Other' or race like '%Multi-racial%' or race is NULL or race='' or race = '7- Other' or 
							race LIKE '6%' or race = '9- Declined To Specify' or race = '9- Declined To Specify' or  race='race-other' )  AND 
							(ethnicity != 'Hispanic or Latino' or ethnicity is null  ) 
							and race not like '%hispanic/latinx%' then 'Unknown/Declined to Specify'										
					when race is null and (ethnicity ='Unknown/Declined to specify' or ethnicity = 'Not Hispanic or Latino') then 'Unknown/Declined to Specify'										
					when race='6- Hispanic/Latinx' or race like '%hispanic/latinx%' or ethnicity = 'Hispanic or Latino' or race='Hispanic' then 'Hispanic'
					else concat(coalesce(race, ''), '-', coalesce(ethnicity, '')) 
				end 



update #s1
set sexual_practices = 'MM'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='m' 
and hpi.opt_sexual_partners = '1'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'MMW'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='m' 
and hpi.opt_sexual_partners = '3'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'WW'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='f' 
and hpi.opt_sexual_partners = '2'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'WMW'
from #s1 r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.enc_id = r.enc_id
where r.sex='f' 
and hpi.opt_sexual_partners = '3'
and r.DOS <='20181031'

update #s1
set sexual_practices = 'MM'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='m' 
and chk_sp_penis = '1' and (chk_sp_vulvas is null or chk_sp_vulvas = '0')
and a.DOS >'20181031'

update #s1
set sexual_practices = 'MMW'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='m' 
and chk_sp_penis = '1' and chk_sp_vulvas= '1'
and a.DOS >'20181031'

update #s1
set sexual_practices = 'WW'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='f' 
and chk_sp_vulvas= '1' and (chk_sp_penis is null or chk_sp_penis = '0')
and a.DOS >'20181031'

update #s1
set sexual_practices = 'WMW'
from #s1 a
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.enc_id = a.enc_id
where a.sex='f' 
and chk_sp_vulvas= '1' and chk_sp_penis ='1'
and a.DOS >'20181031'

update #s1
set sexual_practices = 'other'
where sexual_practices is null



/***********Care Coordination Stuff **************/

--drop table #cmp

--declare @Start_Date date = '20190101'
--declare @End_Date date = '20200630'

select distinct c.person_id, 
				cast(pe.create_timestamp as date) DOS, 
				p.date_of_birth, 
				CAST((CONVERT(INT,CONVERT(CHAR(8),cast(pe.create_timestamp as date),112))-CONVERT(CHAR(8),date_of_birth,112))/10000 AS varchar) age, 
				p.sex,
				p.race, 
				p.ethnicity
into #cmp
from ngprod.dbo.cm_plan_intervention_ c
join ngprod.dbo.patient_encounter pe on c.enc_id=pe.enc_id
join ngprod.dbo.person p on p.person_id=c.person_id
where cast(pe.create_timestamp as date) between @Start_Date and @End_Date
AND p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')

alter table #cmp
add race_eth varchar(500), 
	sexual_practices varchar(500)

update #cmp
set race_eth =case 
					when race like '%white%' AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'White' 
					when  (race = '2- African American' or race = '2- African American/Black') AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'African American'
					when (race = '3- Asian' ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Asian'					
					when  ( race = '4- Pacific Islander' ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Pacific Islander'
					when ( race = '7- Filipino'  ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Filipino'
					when  (race ='8- Middle Eastern'  ) AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Middle Eastern'
					when race = '5- Native American' AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'Native American'
					--when (race = '7- Other' or race = '7-Other' or race = '6-Multi-racial' or race is NULL or race='' or race='race-other') AND (ethnicity != 'Hispanic or Latino' or ethnicity is null) then 'race-other'
					when (race LIKE '7-Other%' or race = '7- Other' or race like '%Multi-racial%' or race is NULL or race='' or race = '7- Other' or 
							race LIKE '6%' or race = '9- Declined To Specify' or race = '9- Declined To Specify' or  race='race-other' )  AND 
							(ethnicity != 'Hispanic or Latino' or ethnicity is null  ) 
							and race not like '%hispanic/latinx%' then 'Unknown/Declined to Specify'										
					when race is null and (ethnicity ='Unknown/Declined to specify' or ethnicity = 'Not Hispanic or Latino') then 'Unknown/Declined to Specify'										
					when race='6- Hispanic/Latinx' or race like '%hispanic/latinx%' or ethnicity = 'Hispanic or Latino' or race='Hispanic' then 'Hispanic'
					else concat(coalesce(race, ''), '-', coalesce(ethnicity, '')) 
				end 

update #cmp
set sexual_practices = 'MM'
from #cmp r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='m' 
and hpi.opt_sexual_partners = '1'
and r.DOS <='20181031'

update #cmp
set sexual_practices = 'MMW'
from #cmp r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='m' 
and hpi.opt_sexual_partners = '3'
and r.DOS <='20181031'

update #cmp
set sexual_practices = 'WW'
from #cmp r 
join ngprod.dbo.hpi_sti_screening_ hpi  ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='f' 
and hpi.opt_sexual_partners = '2'
and r.DOS <='20181031'

update #cmp
set sexual_practices = 'WMW'
from #cmp r 
join ngprod.dbo.hpi_sti_screening_ hpi ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='f' 
and hpi.opt_sexual_partners = '3'
and r.DOS <='20181031'

update #cmp
set sexual_practices = 'MM'
from #cmp r
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='m' 
and chk_sp_penis = '1' and (chk_sp_vulvas is null or chk_sp_vulvas = '0')
and r.DOS >'20181031'

update #cmp
set sexual_practices = 'MMW'
from #cmp r
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='m' 
and chk_sp_penis = '1' and chk_sp_vulvas= '1'
and r.DOS >'20181031'

update #cmp
set sexual_practices = 'WW'
from #cmp r
join ngprod.dbo.psw_hpi_sti_screening_ hpi ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='f' 
and chk_sp_vulvas= '1' and (chk_sp_penis is null or chk_sp_penis = '0')
and r.DOS >'20181031'

update #cmp
set sexual_practices = 'WMW'
from #cmp r
join ngprod.dbo.psw_hpi_sti_screening_ hpi  ON hpi.person_id = r.person_id and cast(hpi.create_timestamp as date) = r.DOS
where r.sex='f' 
and chk_sp_vulvas= '1' and chk_sp_penis ='1'
and r.DOS >'20181031'

update #cmp
set sexual_practices = s.sexual_practices
from #cmp r
join #s1 s on r.person_id=s.person_id
where r.sexual_practices is null



/*******GAHT ********************************/


--drop table #g1, #g2, #g3

select s.*
into #g1
from #s1 s
join  ngprod.dbo.psw_hpi_gaht_ g on g.enc_id = s.enc_id
join ngprod.dbo.patient_encounter pe on g.enc_id=pe.enc_id
join ngprod.dbo.person p on p.person_id=g.person_id
 

select distinct a.*, m.medication_name, m.sig_desc
into #g2
from #g1 a
join ngprod.dbo.patient_medication m on m.enc_id=a.enc_id 

select distinct a.*					
into #g3
from #g2 a
join ppreporting.dbo.gaht_meds g on a.medication_name=g.gaht_med_name 


/*******Core 4 ********************************/

alter table #s1
add		GC_CT_test varchar(3), 
		GC_test varchar(3), 
		CT_Test varchar(3), 
		syph_test varchar(3), 
		hiv_test varchar(3)


update #s1
set GC_CT_test = 'yes' 
where  service_item_id LIKE '%L071%' --GC/CT Combo
		 OR service_item_id LIKE '%L103%'
		 OR service_item_id LIKE '%L104%'
		 OR service_item_id LIKE '%L105%'
		 OR service_item_id LIKE '%L073%'
	
update #s1
set GC_test = 'yes' 
where  service_item_id LIKE '%87591%' --GC
	   OR service_item_id LIKE '%L070%'

update #s1
set CT_test = 'yes' 
where service_item_id LIKE '%87491%' --CT
		OR service_item_id LIKE '%L031%'
		OR service_item_id LIKE '%L069%'
		
update #s1
set syph_test = 'yes' 
where   service_item_id = 'L026' --syph 

update #s1
set hiv_test = 'yes' 
where service_item_id like '%l023%'  -- hiv
	  or service_item_id like '%l099%' 
	  or service_item_id like '%86703%'
	  or service_item_id like '%87806%'	
	  or service_item_id like '%l159%' 	

--drop table #cf1
select person_id, max(gc_ct_test)gc_ct_test, max(gc_test) gc_test, max(ct_test) ct_test,max(syph_test) syph_test, max(hiv_test) hiv_test
into #cf1
from #s1
group by person_id

alter table #s1
add core_4_perf varchar(100)

update #s1 
set core_4_perf = 'yes'
from #s1 s
join #cf1 c on s.person_id = c.persoN_id
where (c.GC_CT_test is not null or (c.GC_test is not null and c.CT_Test is not null)) and 
			c.syph_test is not null and 
			c.hiv_test is not null



alter table #s1
add epem_visit varchar(100)

update #s1 
set epem_visit = 'yes' 
from #s1 s
join  ngprod.dbo.appointments a on s.enc_id=a.enc_id
where a.event_id='CE3629B3-6C17-4D48-8D29-71592D340D0E'-- epem 



alter table #s1
add syph_testing varchar(100)

update #s1
set syph_testing = 'yes'
where service_item_id = 'L026' --syph 

alter table #s1
add gaht varchar(100)

update #s1 
set gaht = 'yes'
from #s1 s 
join #g3 g on s.person_id = g.person_id


alter table #s1
add care_coord varchar(100)

--drop table #s2
select distinct 
		locatioN_name, 		
		person_id, 
		DOS, 
		age, 
		sex, 
		race_eth, 
		sexual_practices, 
		core_4_perf, 
		epem_visit, 
		syph_testing, 
		gaht
into #s2
from #s1

select * 
into #core4 
from #s2
where core_4_perf = 'yes'

select * 
into #epem
from #s2
where epem_visit = 'yes'

select * 
into #st
from #s2
where syph_testing = 'yes'


select * 
into #th1
from #s2
where location_name = 'telehealth'


select * 
into #gahtpt
from #s2
where gaht = 'yes'



/***************************CORE 4****************************/

select category_group = 'Core 4 LT 25', 
		category = 'Core 4', 
		[group] = 'Less Than 25 Yrs', 
		sortorder = 1,
		count(distinct person_id)countCore4LT25, 
		(select count(distinct person_id) from #core4) countCore4Total, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where age<25) countLT25Pt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #core4)  percCore4LT25Core4Pt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCore4LT25TotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where age<25)  percCore4LT25LT25Pt
into #core4Comb
from #core4
where age<25
union 
select category_group = 'Core 4 Not White, Unknown', 
		category = 'Core 4', 
		[group] = 'Not White, Unknown', 
		sortorder = 2,
		count(distinct person_id)countCore4NotWhiteUnknown, 
		(select count(distinct person_id) from #core4)  countCore4Total,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White')) countNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #core4)  percCore4NotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCore4NotWhiteUnknownTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White'))  percCore4NotWhiteUnknownNotWhiteUnknownPt
from #core4
where race_eth not in ('Unknown/Declined to Specify', 'White')
union 
select category_group = 'Core 4 Same Sex Partner', 
		category = 'Core 4', 
		[group] = 'Same Sex Partner', 
		sortorder = 3,
		count(distinct person_id)countCore4SameSexPartner, 
		(select count(distinct person_id) from #core4)  countCore4Total, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where sexual_practices !='other')countSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #core4)  percCore4SameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCore4SameSexPartnerTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where sexual_practices !='other')  percCore4samesexPartnersamesexPartnerPt
from #core4
where sexual_practices !='other'
union 
select category_group = 'Core 4 Black/African American', 
		category = 'Core 4', 
		[group] = 'Black/African American', 
		sortorder = 4,
		count(distinct person_id)countCore4BlackAfrAm, 
		(select count(distinct person_id) from #core4)  countCore4Total,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth = 'African American')countBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #core4)  percCore4BlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCore4BlackAfrAmTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth = 'African American')  percCore4BlackAfrAmBlackAfrAmPt
from #core4
where race_eth = 'African American'




/**********EPEM COUNTS ******************/


select  category_group = 'EPEM LT 25', 
		category = 'EPEM', 
		[group] = 'Less Than 25 Yrs', 
		sortorder = 5,
		count(distinct person_id)countepemLT25, 
		(select count(distinct person_id) from #epem) countepemTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where age<25) countLT25Pt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #epem)  percepemLT25epemPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percepemLT25TotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where age<25)  percepemLT25LT25Pt
into #epemComb
from #epem
where age<25
union 
select  category_group = 'EPEM Not White, Unknown', 
		category = 'EPEM', 
		[group] = 'Not White, Unknown', 
		sortorder = 6,
		count(distinct person_id)countepemNotWhiteUnknown, 
		(select count(distinct person_id) from #epem)  countepemTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White')) countNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #epem)  percepemNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percepemNotWhiteUnknownTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White'))  percepemNotWhiteUnknownNotWhiteUnknownPt
from #epem
where race_eth not in ('Unknown/Declined to Specify', 'White')
union 
select category_group = 'EPEM Same Sex Partner', 
		category = 'EPEM', 
		[group] = 'Same Sex Partner', 
		sortorder = 7,
		count(distinct person_id)countepemSameSexPartner, 
		(select count(distinct person_id) from #epem)  countepemTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where sexual_practices !='other')countSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #epem)  percepemSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percepemSameSexPartnerTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where sexual_practices !='other')  percepemsamesexPartnersamesexPartnerPt
from #epem
where sexual_practices !='other'
union 
select category_group = 'EPEM Black/African American', 
		category = 'EPEM', 
		[group] = 'Black/African American', 
		sortorder = 8,
		count(distinct person_id)countepemBlackAfrAm, 
		(select count(distinct person_id) from #epem)  countepemTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth = 'African American')countBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #epem)  percepemBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percepemBlackAfrAmTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth = 'African American')  percepemBlackAfrAmBlackAfrAmPt
from #epem
where race_eth = 'African American'





/**********SYPHILIS TESTING ******************/


select category_group = 'Syph Testing LT 25', 
		category = 'Syph Testing', 
		[group] = 'Less Than 25 Yrs', 
		sortorder = 9,
		count(distinct person_id)countstLT25, 
		(select count(distinct person_id) from #st) countstTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where age<25) countLT25Pt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #st)  percstLT25stPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percstLT25TotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where age<25)  percstLT25LT25Pt
into #stComb
from #st
where age<25
union 
select  category_group = 'Syph Testing Not White, Unknown', 
		category = 'Syph Testing', 
		[group] = 'Not White, Unknown', 
		sortorder = 10,
		count(distinct person_id)countstNotWhiteUnknown, 
		(select count(distinct person_id) from #st)  countstTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White')) countNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #st)  percstNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percstNotWhiteUnknownTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White'))  percstNotWhiteUnknownNotWhiteUnknownPt
from #st
where race_eth not in ('Unknown/Declined to Specify', 'White')
union 
select category_group = 'Syph Testing Same Sex Partner', 
		category = 'Syph Testing', 
		[group] = 'Same Sex Partner', 
		sortorder = 11,
		count(distinct person_id)countstSameSexPartner, 
		(select count(distinct person_id) from #st)  countstTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where sexual_practices !='other')countSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #st)  percstSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percstSameSexPartnerTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where sexual_practices !='other')  percstsamesexPartnersamesexPartnerPt
from #st
where sexual_practices !='other'
union 
select category_group = 'Syph Testing Black/African American', 
		category = 'Syph Testing', 
		[group] = 'Black/African American', 
		sortorder = 12,
		count(distinct person_id)countstBlackAfrAm, 
		(select count(distinct person_id) from #st)  countstTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth = 'African American')countBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #st)  percstBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percstBlackAfrAmTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth = 'African American')  percstBlackAfrAmBlackAfrAmPt
from #st
where race_eth = 'African American'




/**********CARE COORDINATION******************/


select category_group = 'Care Coord LT 25', 
		category = 'Care Coord', 
		[group] = 'Less Than 25 Yrs', 
		sortorder = 13,
		count(distinct person_id)countCareCoordLT25, 
		(select count(distinct person_id) from #cmp) countCareCoordTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where age<25) countLT25Pt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #cmp)  percCareCoordLT25stPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCareCoordLT25TotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where age<25)  percCareCoordLT25LT25Pt
into #cmpComb
from #cmp
where age<25
union 
select category_group = 'Care Coord Not White, Unknown', 
		category = 'Care Coord', 
		[group] = 'Not White, Unknown', 
		sortorder = 14,
		count(distinct person_id)countCareCoordNotWhiteUnknown, 
		(select count(distinct person_id) from #cmp)  countCareCoordTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White')) countNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #cmp)  percCareCoordNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCareCoordNotWhiteUnknownTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White'))  percCareCoordNotWhiteUnknownNotWhiteUnknownPt
from #cmp
where race_eth not in ('Unknown/Declined to Specify', 'White')
union 
select  category_group = 'Care Coord Same Sex Partner', 
		category = 'Care Coord', 
		[group] = 'Same Sex Partner', 
		sortorder = 15,
		count(distinct person_id)countCareCoordSameSexPartner, 
		(select count(distinct person_id) from #cmp)  countCareCoordTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where sexual_practices !='other')countSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #cmp)  percCareCoordSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCareCoordSameSexPartnerTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where sexual_practices !='other')  percCareCoordsamesexPartnersamesexPartnerPt
from #cmp
where sexual_practices !='other'
union 
select category_group = 'Care Coord Black/African American', 
		category = 'Care Coord', 
		[group] = 'Black/African American', 
		sortorder = 16,
		count(distinct person_id)countCareCoordBlackAfrAm, 
		(select count(distinct person_id) from #cmp)  countCareCoordTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth = 'African American')countBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #cmp)  percCareCoordBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percCareCoordBlackAfrAmTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth = 'African American')  percCareCoordBlackAfrAmBlackAfrAmPt
from #cmp
where race_eth = 'African American'




/**********TELEHEALTH******************/


select category_group = 'Telehealth LT 25', 
		category = 'Telehealth', 
		[group] = 'Less Than 25 Yrs', 		
		sortorder = 17,
		count(distinct person_id) counttelehealthLT25, 
		(select count(distinct person_id) from #th1) counttelehealthTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where age<25) countLT25Pt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #th1)  perctelehealthLT25stPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  perctelehealthLT25TotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where age<25)  perctelehealthLT25LT25Pt
into #th1Comb
from #th1
where age<25
union 
select category_group = 'Telehealth Not White, Unknown', 
		category = 'Telehealth', 
		[group] = 'Not White, Unknown', 		
		sortorder = 18,
		count(distinct person_id)counttelehealthNotWhiteUnknown, 
		(select count(distinct person_id) from #th1)  counttelehealthTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White')) countNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #th1)  perctelehealthNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  perctelehealthNotWhiteUnknownTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White'))  perctelehealthNotWhiteUnknownNotWhiteUnknownPt
from #th1
where race_eth not in ('Unknown/Declined to Specify', 'White')
union 
select  category_group = 'Telehealth Same Sex Partner', 
		category = 'Telehealth', 
		[group] = 'Same Sex Partner', 		
		sortorder = 19,
		count(distinct person_id)counttelehealthSameSexPartner, 
		(select count(distinct person_id) from #th1)  counttelehealthTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where sexual_practices !='other')countSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #th1)  perctelehealthSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  perctelehealthSameSexPartnerTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where sexual_practices !='other')  perctelehealthsamesexPartnersamesexPartnerPt
from #th1
where sexual_practices !='other'
union 
select category_group = 'Telehealth Black/African American', 
		category = 'Telehealth', 
		[group] = 'Black/African American', 		
		sortorder = 20,
		count(distinct person_id)counttelehealthBlackAfrAm, 
		(select count(distinct person_id) from #th1)  counttelehealthTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth = 'African American')countBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #th1)  perctelehealthBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  perctelehealthBlackAfrAmTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth = 'African American')  perctelehealthBlackAfrAmBlackAfrAmPt
from #th1
where race_eth = 'African American'

/**********GAHT******************/

select category_group = 'GAHT LT 25', 
		category = 'GAHT', 
		[group] = 'Less Than 25 Yrs', 	
		sortorder = 21,
		count(distinct person_id) countgahtLT25, 
		(select count(distinct person_id) from #gahtpt) countgahtTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where age<25) countLT25Pt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #gahtpt)  percgahtLT25stPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percgahtLT25TotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where age<25)  percgahtLT25LT25Pt
into #gahtcomb
from #gahtpt
where age<25
union 
select category_group = 'GAHT Not White, Unknown',
		category = 'GAHT', 
		[group] = 'Not White, Unknown', 	
		sortorder = 22, 
		count(distinct person_id)countgahtNotWhiteUnknown, 
		(select count(distinct person_id) from #gahtpt)  countgahtTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White')) countNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #gahtpt)  percgahtNotWhiteUnknownPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percgahtNotWhiteUnknownTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth not in ('Unknown/Declined to Specify', 'White'))  percgahtNotWhiteUnknownNotWhiteUnknownPt
from #gahtpt
where race_eth not in ('Unknown/Declined to Specify', 'White')
union 
select  category_group = 'GAHT Same Sex Partner', 
		category = 'GAHT', 
		[group] = 'Same Sex Partner', 	
		sortorder = 23,
		count(distinct person_id)countgahtSameSexPartner, 
		(select count(distinct person_id) from #gahtpt)  countgahtTotal, 
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where sexual_practices !='other')countSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #gahtpt)  percgahtSameSexPartnerPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percgahtSameSexPartnerTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where sexual_practices !='other')  percgahtsamesexPartnersamesexPartnerPt
from #gahtpt
where sexual_practices !='other'
union 
select category_group = 'GAHT Black/African American', 
		category = 'GAHT', 
		[group] = 'Black/African American', 
		sortorder = 24,
		count(distinct person_id)countgahtBlackAfrAm, 
		(select count(distinct person_id) from #gahtpt)  countgahtTotal,
		(select count(distinct persoN_id) from #s2) countTotalPt, 
		(select count(distinct persoN_id) from #s2 where race_eth = 'African American')countBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #gahtpt)  percgahtBlackAfrAmPt, 
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2)  percgahtBlackAfrAmTotalPt,
		count(distinct person_id) * 1.0 / (select nullif(count(distinct person_id),0) from #s2 where race_eth = 'African American')  percgahtBlackAfrAmBlackAfrAmPt
from #gahtpt
where race_eth = 'African American'

select Category_Group, 
		Category, 
		cast([Group] as varchar(1000)) [Group],
		sortorder, 
		countCore4LT25 countPtCategory, 
		countCore4Total countPtTotalCategory, 
		countTotalPt ,
		countLT25Pt countPtGroup, 
		percCore4LT25Core4Pt perc_PtCategory_countPtTotalCategory,
		percCore4LT25TotalPt perc_PtCategory_countTotalPt, 
		percCore4LT25LT25Pt perc_PTCategory_countPtGroup
into #combine
from #core4Comb
union 
select * 
from #epemComb
union 
select * 
from #stComb
union 
select * 
from #cmpComb
union 
select * 
from #th1Comb
union 
select * 
from #gahtComb

update #combine 
set [Group] = 'Not White, Unknown/Declined'
where [Group] = 'Not White, Unknown'

select * from #combine order by sortorder
