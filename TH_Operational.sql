USE [ppreporting]
GO
/****** Object:  StoredProcedure [dbo].[Telehealth_Triage_CM_Calls]    Script Date: 8/6/2020 3:59:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



ALTER proc [dbo].[Telehealth_Triage_CM_Calls] (
	@Start_date datetime , 
	@End_date datetime
)

AS

--declare @Start_Date datetime = '20200727'
--declare @End_Date datetime = '20200803'


--drop table #cm_calls, #cm2, #cm3, #b1, #t1, #cm2_1, #cm4, #cm5
--drop table #appt, #r_av, #appt2, #appt3, #appt4, #appt5, #g1
--drop table #pestuff, #pestuff2, #bv, #bv1, #appt_bv, #avgVisitLength
--drop table #wklyAvgVisit, #wk_appt,#wklyAppts, #wklyAppts1, #appt5_1
--drop table #countBillable, #countVoided
--drop table #tfu_appt, #tfu_appt2
--drop table #tfu_appt3
--drop table #tfu_wklyAppt
--drop table #tfu_appt4
--drop table #tfu_wklyAppt1
--drop table #tfu_g1
--drop table #tfu_wklyAppt2
--drop table #tfu_daily
--drop table #tfu_daily1
--drop table #tfu_daily2
--drop table #tfu_daily3
--drop table #tfu_appt4_wkly
--drop table #tfub2_1, #tfub_total1, #tfub_total2
--drop table #avl_totalBooked_NewPt, #avl_totalBooked_NewPt1
--drop table #cm5_1
--drop table #tc1, #tc2
--drop table #avl_b1, #avl_a1, #avl_totalTemplate,#avl_d2,#avl_totalBooked,#avl_d1,#avl_totalBlocked,#avl_totalTemplate1,#avl_totalBlocked1,#avl_totalBooked1, #avl_totalTemplate2,#avl_totalTemplate3, #avl_totalTemplate4,  #avl_totalTemplatewkly, #avl_op1, #tfub1, #tfub2, #avl_totalTemplate2_1
--drop table #combine


select case when skillName in ('Nurse English',
								'Nurse Spanish',
								'URGENT English',
								'URGENT Spanish', 
								'CM Results') then 'Case Management Calls'
			when skillName in ('telehealth') then 'Telehealth Calls'
			end Skill_Category,
	   s.callsDate,
	   sum(cast(s.contactsOffered as int)) calls_presented, 
	   sum(cast(s.contactsHandled as int)) calls_handled, 
	   avg(cast(s.averageTalkTime as decimal(10,2))/60) averageTalkTime, 
	   avg(cast(s.averageInqueueTime as int) * 1.0 /60) as averageInqueueTime, 
	   c.countAgent
into #cm_calls
from skills_summary s
left join (  select c.callsDate,
					case when skillName in ('Nurse English',
								'Nurse Spanish',
								'URGENT English',
								'URGENT Spanish', 
								'CM Results') and a.teamName = 'Case Management' then 'Case Management Calls'
							when skillName in ('telehealth') then 'Telehealth Calls'
					end Skill_Category,
					 count(distinct agent) countAgent
					from calls_agent_skills c
					join skills_summary s on c.skillNo =s.skillId
					join calls_agents a on a.agentId = c.agent
					where s.skillName in (
								'Nurse English',
								'Nurse Spanish',
								'URGENT English',
								'URGENT Spanish', 
								'CM Results', 
								'telehealth'						
						)
					group by c.callsDate,  
								case when skillName in ('Nurse English',
												'Nurse Spanish',
												'URGENT English',
												'URGENT Spanish', 
												'CM Results') and a.teamName = 'Case Management'  then 'Case Management Calls'
									when skillName in ('telehealth') then 'Telehealth Calls'
								end 
		) c on c.callsDate = s.callsDate and case when skillName in ('Nurse English',
								'Nurse Spanish',
								'URGENT English',
								'URGENT Spanish', 
								'CM Results') then 'Case Management Calls'
			when skillName in ('telehealth') then 'Telehealth Calls'
			end  =c.skill_category 
where s.callsDate between @Start_Date and @End_Date and skillName in ('Nurse English',
								'Nurse Spanish',
								'URGENT English',
								'URGENT Spanish', 
								'CM Results', 
								'telehealth'
								)
group by s.callsDate,c.countAgent, case when skillName in ('Nurse English',
								'Nurse Spanish',
								'URGENT English',
								'URGENT Spanish', 
								'CM Results') then 'Case Management Calls' 
			when skillName in ('telehealth') then 'Telehealth Calls'
			end

select datepart(week, callsDate) weekNum, *, 
		case 
			when calls_presented = 0 then null  
			else calls_handled * 1.0 / calls_presented
		end perc_handled, 
		calls_presented * 1.0 / countAgent avg_calls_per_staff
into #cm2
from #cm_calls


alter table #cm2 
add vals float


select weekNum, 
		Skill_Category,
		sum(calls_presented) calls_presented,
		sum(calls_handled) calls_handled,
		avg(averageTalkTime) averageTalkTime,
		avg(averageInqueueTime) averageInqueueTime,
		sum(countAgent) countAgent,
		case when sum(calls_presented) = 0 then null else sum(calls_handled) * 1.0 / sum(calls_presented) end perc_handled, 
		case when sum(calls_presented) = 0 then null else sum(calls_handled) * 1.0 / sum(countAgent) end avg_calls_per_staff
into #t1
from #cm2
group by weekNum,Skill_Category

alter table #t1
add callsDate date, 
	vals float

select * 
into #cm2_1
from #cm2
union 
select weekNum, Skill_Category, callsDate, calls_presented, calls_handled, averageTalkTime, averageInqueueTime,countAgent, perc_handled, avg_calls_per_staff, vals
from #t1

create table #b1 (
	Skill_Category varchar(5000), 
	Call_Category varchar(5000)
)


insert into #b1
values ('Case Management Calls', 'Presented'), 
('Case Management Calls', 'Handled'), 
('Case Management Calls', '% Handled'),
('Case Management Calls', 'Avg Talk Time'),
('Case Management Calls', 'Number of Staff'),
('Case Management Calls', 'Avg Calls per Staff'),
('Case Management Calls', 'Avg Wait Time'),

('Telehealth Calls', 'Presented'), 
('Telehealth Calls', 'Handled'), 
('Telehealth Calls', '% Handled'),
('Telehealth Calls', 'Avg Talk Time'),
('Telehealth Calls', 'Number of Staff'),
('Telehealth Calls', 'Avg Calls per Staff'), 
('Telehealth Calls', 'Avg Wait Time')



select c.*, b.call_Category
into #cm3
from #cm2_1 c
left join #b1 b on c.skill_category = b.skill_category


update #cm3
set vals = calls_presented 
where call_category = 'Presented'

update #cm3
set vals = calls_handled
where call_category = 'Handled'

update #cm3
set vals = perc_handled
where call_category = '% Handled'

update #cm3
set vals = averageTalkTime
where call_category = 'Avg Talk Time'

update #cm3
set vals = countAgent
where call_category = 'Number of Staff'

update #cm3
set vals = avg_calls_per_staff
where call_category = 'Avg Calls per Staff'

update #cm3
set vals = averageInqueueTime
where call_category = 'Avg Wait Time'


--drop table #cm4
select distinct weekNum, 
		Skill_Category, 
		cast(LEFT(CONVERT(VARCHAR(100),callsDate, 1), 5) as varchar(100)) callsDate,  
		cast(LEFT(DATENAME(WEEKDAY,callsDate),3) as varchar(100)) wkDayName, 
		Call_Category, 
		Vals 
into #cm4
from #cm3
order by weekNum, Skill_Category, callsDate



update #cm4 
set callsDate = 'Wk Total'
where callsDate is null


update #cm4 
set wkdayName = concat('Wk Total', weekNum)
where wkdayName is null

alter table #cm4
add orderNum float

update #cm4
set orderNum = 1 
where call_category = 'Presented'

update #cm4
set orderNum = 2 
where call_category = 'Handled'

update #cm4
set orderNum = 3
where call_category = '% Handled'

update #cm4
set orderNum = 4
where call_category = 'Avg Talk Time'

update #cm4
set orderNum = 5
where call_category = 'Number of Staff'

update #cm4
set orderNum = 6
where call_category = 'Avg Calls per Staff'

update #cm4
set orderNum = 7
where call_category = 'Avg Wait Time'

 select datepart(week, cast(a.create_timestamp as date)) weekNum, 
		Skill_Category = 'Telehealth Calls', 
		cast(LEFT(CONVERT(VARCHAR(100),cast(a.create_timestamp as date), 1), 5) as varchar(100)) date_TH_booked, 
		cast(LEFT(DATENAME(WEEKDAY,cast(a.create_timestamp as date)),3) as varchar(100)) wkDayName, 
		Call_category = 'Appointments Created', 
		count(distinct appt_id) countTHBooked, 
		orderNum=7, 
		skill_order =3
 into #tc1
 from ngsqldata.ngprod.dbo.appointments a 
 join ngsqldata.ngprod.dbo.events ev on a.event_id=ev.event_id
 join ngsqldata.ngprod.dbo.person p on p.person_id=a.person_id
 where a.event_id in (
	select event_id 
	from ngsqldata.ngprod.dbo.events 
	where (event like '%telehealth%' and event not like '%f/u%') and 
			(event like '%telehealth%' and event not like '%follow up%') or 
			event_id = '5CCD259E-7100-4B53-82A2-DA82C17AC889'
 )
 and cast(a.create_timestamp as date) between @Start_Date and @End_Date
 and  p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
 group by cast(a.create_timestamp as date)


 select * 
 into #tc2
 from #tc1 
 union 
 select weekNum, 
		Skill_category = 'Telehealth Calls', 
		callsDate = 'Wk Total', 
		wkDayName = concat('Wk Total', weekNum), 
		 Call_Category , 
		sum(countTHBooked) countTHBooked, 
		orderNum = 7, 
		skill_order = 3
from #tc1 
group by weekNum, call_Category


--select * from #cm4 order by orderNum


/************Teleheath Appointments ****************************/

exec ppreporting.dbo.[PS_OpenSlotArchive]

--declare @Start_Date datetime = '20200727'
--declare @End_Date datetime = '20200802'

--drop table #appt

Select distinct Ev.Event, 
				cast(APP.Appt_Id as varchar(100)) Appt_Id , 
				cast(app.event_id as varchar(100)) event_id, 
				cast(app.person_id as varchar(100)) person_id, 
				cast(app.Appt_Date as date) Appt_Date, 
				app.begintime,
				app.enc_id, 
				app.delete_ind, 
				app.appt_kept_ind, 
				app.resched_ind, 
				app.cancel_ind, 
				r.description 
INTO #Appt
from ngsqldata.ngprod.dbo.appointments App
INNER JOIN ngsqldata.ngprod.dbo.Events Ev On ev.event_id = app.event_id 
join ngsqldata.ngprod.dbo.person p on p.person_id=app.person_id
left join ngsqldata.ngprod.dbo.appointment_members AM ON app.appt_id = AM.appt_id 
left join ngsqldata.ngprod.dbo.resources r on am.resource_id=r.resource_id
--	INNER Join ngsqldata.ngprod.dbo.user_mstr UM ON UM.user_id = app.created_by 
Where App.appt_date between cast(@Start_date as date) and cast(@End_Date as date) 
and app.event_id in (
						select  event_id
						from ngsqldata.ngprod.dbo.events 
						where event_id = '5CCD259E-7100-4B53-82A2-DA82C17AC889' or event_id = '36B09CAC-F6A7-4259-BB80-F355180094AE' or event_id = 'B6E41A57-DC5D-4891-9844-9F321170FA06' or 
							((event like '%telehealth%' and event not like '%f/u%' ) and 
							(event like '%telehealth%' and event not like '%follow up%' ))
						
					) 
and p.last_name not like '%test%'
and app.appt_date >= '20200328' 


--declare @Start_Date datetime = '20200727'
--declare @End_Date datetime = '20200802'

--drop table #r_av

select distinct SUBSTRING(pt.med_rec_nbr, PATINDEX('%[^0]%', pt.med_rec_nbr+'.'), LEN(pt.med_rec_nbr)) AS MRN, 
				a.description patient_name, 
				lm.location_name, 
				origEvent.event original_event, 
				reschEvent.event rescheduled_event,
				a.appt_date, 
				a.begintime appt_begin_time, 
				a.endtime appt_end_time,
				a.create_timestamp originalSchedDate, 
				a1.create_timestamp dateRescheduled, 
				datediff(day, a.create_timestamp, a1.create_timestamp) days_to_reschedule, 
				a.appt_id origAppt, 
				a1.appt_id reschedAppt, 
				a.enc_id origEnc, 
				a1.enc_id reschedEnc, 
				a1.delete_ind, 
				a1.appt_kept_ind, 
				a1.resched_ind, 
				a1.cancel_ind, 
				r.description 
into #r_av
from ngsqldata.ngprod.dbo.appointments a
left join ngsqldata.ngprod.dbo.appointments a1 on a.appt_id=a1.appt_resched_id  
		and a.event_id!=a1.event_id
		and a.appt_date=a1.appt_date 
		and a.begintime=a1.begintime
		and a.endtime=a1.endtime
		and a.resched_ind='Y' 
join ngsqldata.ngprod.dbo.patient pt on pt.person_id=a.person_id
join ngsqldata.ngprod.dbo.location_mstr lm on lm.location_id=a.location_id
join ngsqldata.ngprod.dbo.events origEvent on origEvent.event_id=a.event_id
left join ngsqldata.ngprod.dbo.events reschEvent on reschEvent.event_id=a1.event_id
left join ngsqldata.ngprod.dbo.appointment_members AM ON A.appt_id = AM.appt_id 
left join ngsqldata.ngprod.dbo.resources r on am.resource_id=r.resource_id
where a.appt_date between @Start_date and @End_date
and a.event_id in (
'5CCD259E-7100-4B53-82A2-DA82C17AC889'
)
and a1.event_id in (
'D33F1A54-AF74-497E-B3F1-04BC0D77A189'
)
and a1.delete_ind = 'N' and a1.appt_kept_ind = 'y' 
AND a1.enc_id  is not null -- (To match with Clinician and ma report we exclude enc_id blank)
and a1.cancel_ind = 'N' 

alter table #appt
add Appt_Kept varchar(50)

update #appt
set Appt_Kept ='Y' 
where delete_ind = 'N' and appt_kept_ind = 'y' 
AND enc_id is not null -- (To match with Clinician and ma report we exclude enc_id blank)
AND resched_ind='N' and cancel_ind = 'N' 

update #appt
set Appt_Kept ='R' 
where resched_ind='Y' 

update #appt
set Appt_Kept ='N' 
where appt_kept is null 

--select * from #appt where description = 'Telehealth-Translation'

alter table #appt 
add Kept_AV varchar(50)

update #appt
set Kept_AV = 'Y'
where event_id = '5CCD259E-7100-4B53-82A2-DA82C17AC889' and appt_kept = 'Y'

alter table #appt 
add Kept_Audio varchar(50)


update #appt
set Kept_Audio = 'Y'
where event_id = 'D33F1A54-AF74-497E-B3F1-04BC0D77A189' and [description] != 'Telehealth-Translation'
and appt_id not in (
	select reschedAppt from #r_av
) and appt_kept = 'y'

alter table #appt
add Kept_Translation varchar(50)

update #appt 
set Kept_Translation  = 'Y'
where event_id = 'D33F1A54-AF74-497E-B3F1-04BC0D77A189'  and [description] = 'Telehealth-Translation'
and appt_id not in (
	select reschedAppt from #r_av
) and appt_kept = 'y'



alter table #appt 
add Kept_AV_to_Audio varchar(50)

update #appt
set Kept_AV_to_Audio = 'Y'
where appt_id in (
	select reschedAppt from #r_av
) and appt_kept = 'y'

alter table #appt 
add Kept_MAB_Consult varchar(50), 
	Kept_GAHT varchar(50)

update #appt
set Kept_MAB_Consult = 'Y'
where event_id='063F928F-3D2F-4FA8-AFDE-D951815DA07B' and appt_kept = 'y'

update #appt
set Kept_GAHT = 'Y'
where event_id='A5FF273E-3BD9-4BA1-AC9E-000219B168AD' and appt_kept = 'y'


alter table #appt 
add Kept_MAB_Consult_Audio_only varchar(50), 
	Kept_MAB_Consult_Video_and_Audio varchar(50)

update #appt
set Kept_MAB_Consult_Audio_only = 'Y'
where event_id='B6E41A57-DC5D-4891-9844-9F321170FA06' and appt_kept = 'y'

update #appt
set Kept_MAB_Consult_Video_and_Audio = 'Y'
where event_id='36B09CAC-F6A7-4259-BB80-F355180094AE' and appt_kept = 'y'


/*
3FADCE5E-0629-4438-812D-6F5A2FAABAFD Telehealth GAHT Follow Up
A5FF273E-3BD9-4BA1-AC9E-000219B168AD Telehealth GAHT Consult
*/


delete from #appt where event_id = '2EA46C96-F55B-4661-955A-3E94F11B9456'


--drop table #appt2
select a.appt_date, 
		a.appt_kept, 
		count(distinct a.appt_id) countAppt, 
		t.countTotalAppt, 
		count(distinct a.appt_id) * 1.0 / t.countTotalAppt rate, 
		av.kept_av, 
		av.kept_audio, 
		av.kept_translation,
		av.kept_av_to_audio,
		av.Kept_MAB_Consult, 
		av.Kept_GAHT, 
		av.Kept_MAB_Consult_Audio_only, 
		av.Kept_MAB_Consult_Video_and_Audio,
		av.countAppAV
into #appt2
from #appt a
join (select appt_date, count(distinct appt_id) countTotalAppt 
		from #appt group by appt_date) t on a.appt_date = t.appt_date
left join (select a.appt_date, kept_av, kept_audio,kept_translation, kept_av_to_audio, Kept_MAB_Consult,Kept_GAHT,Kept_MAB_Consult_Audio_only,Kept_MAB_Consult_Video_and_Audio, count(distinct a.appt_id) countAppAV
			from #appt a
			group by a.appt_date, kept_av, kept_audio,kept_translation, kept_av_to_audio, Kept_MAB_Consult,Kept_GAHT,Kept_MAB_Consult_Audio_only,Kept_MAB_Consult_Video_and_Audio) av on av.appt_date = a.appt_date
group by a.appt_date, a.appt_kept, t.countTotalAppt,  av.kept_av,av.kept_translation, av.kept_audio, av.kept_av_to_audio, av.Kept_MAB_Consult, av.countAppAV, av.Kept_GAHT,av.Kept_MAB_Consult_Audio_only,av.Kept_MAB_Consult_Video_and_Audio


select appt_date, 
	   max(case when appt_kept = 'N' then countAppt end) as appt_kept_n, 
	   max(case when appt_kept = 'Y' then countAppt end) as appt_kept_y, 
	   max(case when appt_kept = 'R' then countAppt end) as appt_kept_r, 
	   max(case when appt_kept = 'N' then rate end) as no_show_rate,
	   max(case when kept_av = 'Y' then countAppAV end) as kept_AV,  	   
	   max(case when kept_Audio = 'Y' then countAppAV end) as kept_Audio,  
	   max(case when kept_translation = 'Y' then countAppAV end) as kept_Translation,  
	   max(case when kept_av_to_audio = 'Y' then countAppAV end) as kept_av_to_audio, 
	   max(case when Kept_MAB_Consult = 'Y' then countAppAV end) as Kept_MAB_Consult, 
		max(case when Kept_MAB_Consult_Audio_only = 'Y' then countAppAV end) as Kept_MAB_Consult_Audio_only, 
		max(case when Kept_MAB_Consult_Video_and_Audio = 'Y' then countAppAV end) as Kept_MAB_Consult_Video_and_Audio, 
		max(case when Kept_GAHT = 'Y' then countAppAV end) as Kept_GAHT
into #appt3
from #appt2
group by appt_date


select distinct pe.location_id, 
				pe.persoN_id, 
				pe.enc_id, 
				pe.billable_ind, 
				pe.clinical_ind, 
				pe.remarks, 
				cast(pe.create_timestamp as date) DOS, 
				pe.checkin_datetime, 
				pe.checkout_datetime,  
				DATEDIFF(mi, pe.checkin_datetime, pe.checkout_datetime) visit_length
into #pestuff
from ngsqldata.ngprod.dbo.patient_encounter pe 
join ngsqldata.ngprod.dbo.location_mstr lm on pe.location_id=lm.location_id
join ngsqldata.ngprod.dbo.person p on p.person_id=pe.person_id
where location_name ='telehealth' 
and cast(pe.create_timestamp as date) between @Start_Date and @End_Date

/*
void
dropped
discontinued
*/


select distinct *, 
		case 
			when billable_ind = 'y' then 'y' 
			else 'n' 
		end as billable_enc, 
		case when remarks like '%void%' or remarks like '%dropped%' or remarks like '%discontinued%'  then 'y' 
			else 'n' 
		end as voided
into #pestuff2
from #pestuff

alter table #pestuff2
add event_type varchar(1000)

update #pestuff2
set event_type = ev.event
from #pestuff2 p 
join ngsqldata.ngprod.dbo.appointments a on p.enc_id = a.enc_id
join ngsqldata.ngprod.dbo.events ev on a.event_id=ev.event_id



delete from #pestuff2  where event_type not in (
'FP-TH Video&Audio', 'Telehealth Audio Only', 'Telehealth MAB Consult', 'Telehealth GAHT Consult','TH-MAB Consult Video&Audio','TH-MAB Consult Audio Only'
)

select DOS, count(distinct enc_id) countBillable
into #countBillable
from #pestuff2
where billable_ind = 'y' and event_type is not null
group by DOS


select DOS, count(distinct enc_id) countVoided
into #countVoided
from #pestuff2
where voided = 'y' 
group by DOS

select b.DOS, b.countBillable, v.countVoided
into #bv1
from #countBillable b
left join #countVoided v on b.DOS = v.DOS

--drop table #bv
--select  b.DOS, b.billable_enc, v.voided, count(distinct b.enc_id) countbEnc, v.countVEnc
--into #bv
--from #pestuff2 b
--left join (select DOS, voided, count(distinct enc_id) countVEnc
--				from #pestuff2
--				group by DOS, voided) v on b.DOS = v.DOS 
--where event_Type is not null
--group by b.DOS, b.billable_enc, v.voided, v.countVEnc


--select * from #bv

--select DOS, billable_enc, voided, count(distinct enc_id) countEnc
--into #bv
--from #pestuff2
--group by DOS, billable_enc, voided


--select DOS, 
--		max(case 
--			when billable_enc = 'y' then countEnc 
--		end) as countBillable, 
--		max(case 
--			when voided = 'y' then countEnc 
--		end) as countVoided
--into #bv1
--from #bv
--group by DOS



select DOS, avg(visit_length *1.0) avgVisitLength
into #avgVisitLength
from #pestuff2  a
where a.billable_enc='y' and a.voided='n' and cast(a.checkin_datetime as date) = cast(a.checkout_datetime as date) 
	and a.checkin_datetime is not null and a.checkout_datetime is not null
group by DOS

select datepart(week, DOS) weekNum, avg(visit_length * 1.0) wklyAvgVisit
into #wklyAvgVisit
from #pestuff2 a
where a.billable_enc='y' and a.voided='n' and cast(a.checkin_datetime as date) = cast(a.checkout_datetime as date) 
	and a.checkin_datetime is not null and a.checkout_datetime is not null
group by datepart(week, DOS)

select a.*, l.avgVisitLength,bv.countBillable, countVoided
into #appt_bv
from #appt3 a
left join #avgVisitLength l on a.appt_date= l.DOS
left join #bv1 bv on bv.DOS = a.appt_date

select datepart(week, appt_date) weekNum, 
		appt_category = 'Telehealth Appts', 
		sum(kept_AV) kept_AV,
		sum(kept_Audio) kept_Audio, 
		sum(kept_translation) Kept_Translation, 
		sum(kept_av_to_audio) kept_av_to_audio, 
		sum(Kept_MAB_Consult) Kept_MAB_Consult, 
		sum(Kept_GAHT) Kept_GAHT, 
		sum(Kept_MAB_Consult_Video_and_Audio) Kept_MAB_Consult_Video_and_Audio,  
		sum(Kept_MAB_Consult_Audio_only) Kept_MAB_Consult_Audio_only, 
		sum(appt_kept_n) appt_kept_n,
		sum(appt_kept_y) appt_kept_y, 
		sum(appt_kept_r) appt_kept_r, 
		sum(appt_kept_n) * 1.0 / (sum(appt_kept_n) + sum(appt_kept_y) + + sum(appt_kept_r)) no_show_rate, 		
		sum(countBillable) countBillable, 
		sum(countVoided) countVoided
into #wk_appt
from #appt_bv
group by datepart(week, appt_date)


select w.*, wklyAvgVisit
into #wklyAppts
from #wk_appt w
left join #wklyAvgVisit w1 on w.weekNum = w1.weekNum


create table #g1 (
	Appt_Category varchar(5000), 
	Appt_Status varchar(5000)
)

insert into #g1
values 
('Telehealth Appts', '   Kept Audio & Video'), 
('Telehealth Appts', '   Kept Audio No Translation'),
('Telehealth Appts', '   Kept Audio Translation'),
('Telehealth Appts', '   Kept A&V to Audio'),
('Telehealth Appts', '   Kept MAB Consult'),  
('Telehealth Appts', '   Kept GAHT'),
('Telehealth Appts', '   Kept MAB Consult-Audio Only'),  
('Telehealth Appts', '   Kept MAB Consult-Audio & Video'),  
('Telehealth Appts', 'Total Kept'), 
('Telehealth Appts', 'No-Show'), 
('Telehealth Appts', 'Rescheduled'), 
('Telehealth Appts', 'No-show rate'), 
('Telehealth Appts', 'Billed'),
('Telehealth Appts', 'Void'),
('Telehealth Appts', 'Avg Time')


select datepart(week, appt_date) weekNum, 
		appt_category = 'Telehealth Appts' ,  
		cast(LEFT(CONVERT(VARCHAR(100),appt_date, 1), 5) as varchar(100)) appt_date, 
		cast(LEFT(DATENAME(WEEKDAY,appt_date),3) as varchar(100)) wkDayName, 
		kept_av, 
		kept_audio, 
		kept_translation, 
		kept_av_to_audio, 
		Kept_MAB_Consult,
		Kept_GAHT,
		Kept_MAB_Consult_Video_and_Audio,
		Kept_MAB_Consult_Audio_only,
		appt_kept_n, 
		appt_kept_y, 
		appt_kept_r, 
		no_show_rate, 
		avgVisitLength, 
		countBillable, 
		countVoided
into #appt4 
from #appt_bv a

select weekNum, 
		a.appt_category, 
		appt_date, 
		wkDayName, 	
		kept_av, 
		kept_audio, 
		kept_translation, 
		kept_av_to_audio, 
		Kept_MAB_Consult,
		Kept_GAHT,
		Kept_MAB_Consult_Video_and_Audio,
		Kept_MAB_Consult_Audio_only,
		appt_kept_n, 
		appt_kept_y,
		appt_kept_r, 
		no_show_rate, 
		avgVisitLength, 
		countBillable, 
		countVoided, 
		appt_Status
into #appt5_1
from #appt4 a 
join #g1 g on a.appt_category = g.appt_category

select weekNum, 
		w.appt_category, 
		appt_date = '', 
		wkDayName ='', 
		kept_av, 
		kept_audio, 
		kept_translation, 
		kept_av_to_audio, 
		Kept_MAB_Consult,
		Kept_GAHT,
		Kept_MAB_Consult_Video_and_Audio,
		Kept_MAB_Consult_Audio_only,
		appt_kept_n, 
		appt_kept_y, 
		appt_kept_r, 
		no_show_rate,
		wklyAvgVisit, 
		countBillable, 
		countVoided, 
		appt_status
into #wklyAppts1
from #wklyAppts w
join #g1 g on w.appt_category = g.appt_category


select * 
into #appt5
from #appt5_1
union all 
select * 
from #wklyAppts1


alter table #appt5 
add vals float

update #appt5 
set vals = kept_av 
where appt_status = '   Kept Audio & Video'


update #appt5 
set vals = kept_audio 
where appt_status = '   Kept Audio No Translation'

update #appt5 
set vals = kept_translation 
where appt_status = '   Kept Audio Translation'

update #appt5 
set vals = kept_av_to_audio 
where appt_status = '   Kept A&V to Audio'

update #appt5 
set vals = Kept_MAB_Consult 
where appt_status = '   Kept MAB Consult'

update #appt5 
set vals = Kept_GAHT
where appt_status = '   Kept GAHT'

update #appt5 
set vals = Kept_MAB_Consult_Audio_only
where appt_status = '   Kept MAB Consult-Audio Only'

update #appt5 
set vals = Kept_MAB_Consult_Video_and_Audio
where appt_status = '   Kept MAB Consult-Audio & Video'



update #appt5 
set vals = appt_kept_y 
where appt_status = 'Total Kept'


update #appt5 
set vals = appt_kept_n 
where appt_status = 'No-Show'

update #appt5 
set vals = appt_kept_r 
where appt_status = 'Rescheduled'

update #appt5 
set vals = no_show_rate
where appt_status = 'no-show rate'

update #appt5 
set vals = countBillable
where appt_status = 'Billed'

update #appt5 
set vals = countVoided
where appt_status = 'Void'


update #appt5 
set vals = avgVisitLength
where appt_status = 'Avg Time'

update #appt5 
set appt_date = 'Wk Total' 
where appt_date = ''

update #appt5 
set wkDayName = concat('Wk Total', weekNum)
where wkdayName =''

select * 
into #cm5_1
from #cm4 
union all 
select weekNum, 
		appt_category, 
		appt_date, 
		wkDayName, 
		appt_Status, 
		vals, 
		ordernum=null
 from #appt5

 alter table #cm5_1 
 add skill_order int


 update #cm5_1 
 set skill_order = 1 
 where skill_category = 'Case Management Calls'

 update #cm5_1 
 set skill_order = 2 
 where skill_category = 'Case Management calls'

 update #cm5_1 
 set skill_order = 3 
 where skill_category = 'Telehealth calls'

 update #cm5_1 
 set skill_order = 4
 where skill_category = 'Telehealth Appts'

 select * 
 into #cm5
 from #cm5_1 
 union 
 select * from #tc2

 
 
 /******************Telehealth Follow-Up Appointments ***************************/
 
Select distinct Ev.Event, 
				cast(APP.Appt_Id as varchar(100)) Appt_Id , 
				cast(app.event_id as varchar(100)) event_id, 
				cast(app.person_id as varchar(100)) person_id, 
				cast(app.Appt_Date as date) Appt_Date, 
				app.enc_id, 
				app.delete_ind, 
				app.appt_kept_ind, 
				app.resched_ind, 
				app.cancel_ind
INTO #tfu_Appt
from ngsqldata.ngprod.dbo.appointments App
INNER JOIN ngsqldata.ngprod.dbo.Events Ev On ev.event_id = app.event_id 
--	INNER Join ngsqldata.ngprod.dbo.user_mstr UM ON UM.user_id = app.created_by 
join ngsqldata.ngprod.dbo.person p on p.person_id=app.person_id
Where App.appt_date between cast(@Start_date as date) and cast(@End_Date as date) 
and app.event_id in (
						select event_id from ngprod.dbo.events where (event like '%telehealth%' and event like '%F/U%') or (event like '%telehealth%' and event like '%follow up%')
					) 
and p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')

alter table #tfu_appt
add Appt_Kept varchar(50)

update #tfu_appt
set Appt_Kept ='Y' 
where delete_ind = 'N' and appt_kept_ind = 'y' 
AND enc_id is not null -- (To match with Clinician and ma report we exclude enc_id blank)
AND resched_ind='N' and cancel_ind = 'N' 


update #tfu_appt
set Appt_Kept ='N' 
where appt_kept is null 

select a.event, a.appt_date, a.appt_kept, coalesce(count(distinct a.appt_id),0) countAppt, t.countTotalAppt, 
	coalesce(count(distinct a.appt_id),0) * 1.0 / t.countTotalAppt rate 
into #tfu_appt2
from #tfu_appt a
join (select appt_date, count(distinct appt_id) countTotalAppt 
		from #tfu_appt group by appt_date) t on a.appt_date = t.appt_date
group by a.appt_date, a.appt_kept, t.countTotalAppt, a.event


select appt_category = 'Telehealth Follow-Up Volume', event,appt_date, 
	   coalesce(max(case when appt_kept = 'N' then countAppt end),0) as appt_kept_n, 
	    coalesce(max(case when appt_kept = 'Y' then countAppt end),0) as appt_kept_y, 
	    coalesce(max(case when appt_kept = 'N' then rate end),0) as no_show_rate
into #tfu_appt3
from #tfu_appt2
group by appt_date, event


select appt_category = 'Telehealth Follow-Up Volume', appt_date, sum(appt_kept_n) appt_kept_n, sum(appt_kept_y) appt_kept_y, 
			sum(appt_kept_n) * 1.0 / (sum(appt_kept_n) + sum(appt_kept_y)) no_show_rate
into #tfu_daily
 from #tfu_appt3
 group by appt_date

 select datepart(week, appt_date) weekNum, 
		appt_category, 
		cast(LEFT(CONVERT(VARCHAR(100),appt_date, 1), 5) as varchar(100)) appt_date, 
		cast(LEFT(DATENAME(WEEKDAY,appt_date),3) as varchar(100)) wkDayName, 
		appt_kept_y,
		appt_kept_n,
		no_show_rate
into #tfu_daily1
 from #tfu_daily

 create table #tfu_g1 (
	Appt_Category varchar(5000), 
	Appt_Status varchar(5000)
)

insert into #tfu_g1
values ('Telehealth Follow-Up Volume', 'Total Kept'), 
 ('Telehealth Follow-Up Volume', 'Total No-Show'),
('Telehealth Follow-Up Volume', 'No-show rate')

 select t.weekNum, t.appt_category, t.appt_date, t.wkDayName, g.appt_status, t.appt_kept_y,t.appt_kept_n, t.no_show_rate
 into #tfu_daily2
 from  #tfu_daily1 t
  join #tfu_g1 g on g.appt_category = t.appt_category

alter table #tfu_daily2
add vals float

update #tfu_daily2 
set vals = appt_kept_y 
where appt_status ='Total kept'

update #tfu_daily2 
set vals = appt_kept_n
where appt_status ='Total No-Show'


update #tfu_daily2 
set vals = no_show_rate 
where appt_status ='No-show rate'


select distinct weekNum, appt_category, appt_date, wkDayName, appt_status, vals, orderNum = null, skill_order = 6
into #tfu_daily3
 from #tfu_daily2


select appt_category = 'Telehealth Follow-Up Volume', event, datepart(week, appt_date) weekNum, sum(appt_kept_n) appt_kept_n, sum(appt_kept_y) appt_kept_y, 
			sum(appt_kept_n) * 1.0 / (sum(appt_kept_n) + sum(appt_kept_y)) no_show_rate
into #tfu_wklyAppt
 from #tfu_appt3
 group by  datepart(week, appt_date), event



select datepart(week, appt_date) weekNum, 
		appt_category,
		cast(LEFT(CONVERT(VARCHAR(100),appt_date, 1), 5) as varchar(100)) appt_date, 
		cast(LEFT(DATENAME(WEEKDAY,appt_date),3) as varchar(100)) wkDayName, 
		event, 
		appt_kept_y Vals,
		orderNum = null, 
		skill_order = 6
into #tfu_appt4
from #tfu_appt3
union 
select datepart(week, appt_date) weekNum, 
		appt_category,
		cast(LEFT(CONVERT(VARCHAR(100),appt_date, 1), 5) as varchar(100)) appt_date, 
		cast(LEFT(DATENAME(WEEKDAY,appt_date),3) as varchar(100)) wkDayName, 
		concat(event, ' No-Show'), 
		appt_kept_n Vals,
		orderNum = null, 
		skill_order = 6
from #tfu_appt3


select weekNum, 
		appt_category, 
		appt_date = 'Wk Total',
		wkDayName = concat('Wk Total', weekNum), 		
		sum(appt_kept_y)  appt_kept_y,
		sum(appt_kept_n)  appt_kept_n, 
		sum(appt_kept_n) * 1.0 / (sum(appt_kept_n) + sum(appt_kept_y)) no_show_rate
into #tfu_wklyAppt1
from #tfu_wklyAppt
group by  weekNum, 
		appt_category



select w.*, g.appt_status
into #tfu_wklyAppt2
from #tfu_wklyAppt1 w
join #tfu_g1 g on w.appt_category= g.appt_category

alter table #tfu_wklyAppt2 
add vals float

update #tfu_wklyAppt2
set Vals = appt_kept_y 
where appt_status = 'Total Kept'


update #tfu_wklyAppt2
set Vals = appt_kept_n 
where appt_status = 'Total No-Show'


update #tfu_wklyAppt2
set Vals = no_show_rate 
where appt_status =  'No-show rate'

select weekNum, appt_category, appt_date = 'Wk Total', wkDayName = concat('Wk Total', weekNum), event, sum(Vals) Vals, orderNum, skill_order
into #tfu_appt4_wkly
from #tfu_appt4
group by weekNum, appt_category, event, orderNum, skill_order


/************Telehealth Follow-Up Created **************************************/

 select datepart(week, cast(a.create_timestamp as date)) weekNum, 
		Skill_Category = 'Telehealth Follow-Up Created', 
		cast(LEFT(CONVERT(VARCHAR(100),cast(a.create_timestamp as date), 1), 5) as varchar(100)) date_THFU_booked, 
		cast(LEFT(DATENAME(WEEKDAY,cast(a.create_timestamp as date)),3) as varchar(100)) wkDayName, 
		concat('   ',ev.event) Call_category, 
		count(distinct appt_id) countTHFUBooked, 
		orderNum=null, 
		skill_order =5		
 into #tfub1
 from ngsqldata.ngprod.dbo.appointments a 
 join ngsqldata.ngprod.dbo.events ev on a.event_id=ev.event_id
 join ngsqldata.ngprod.dbo.person p on p.person_id=a.person_id
 where ((ev.[event] like '%telehealth%' and ev.[event] like '%F/U%')  or (ev.[event] like '%telehealth%' and ev.[event] like '%follow up%')) 
 and cast(a.create_timestamp as date) between @Start_Date and @End_Date
 and  p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
 group by cast(a.create_timestamp as date), ev.event


 select * 
 into #tfub2_1
 from #tfub1 
 union 
 select weekNum, 
		Skill_category = 'Telehealth Follow-Up Created', 
		callsDate = 'Wk Total', 
		wkDayName = concat('Wk Total', weekNum), 
		 Call_Category , 
		sum(countTHFUBooked) countTHFUBooked, 
		orderNum = null, 
		skill_order = 5
from #tfub1 
group by weekNum, call_Category



 select datepart(week, cast(a.create_timestamp as date)) weekNum, 
		Skill_Category = 'Telehealth Follow-Up Created', 
		cast(LEFT(CONVERT(VARCHAR(100),cast(a.create_timestamp as date), 1), 5) as varchar(100)) date_THFU_booked, 
		cast(LEFT(DATENAME(WEEKDAY,cast(a.create_timestamp as date)),3) as varchar(100)) wkDayName, 
		Call_category = 'Total Created', 
		count(distinct appt_id) countTHFUBooked, 
		orderNum=null, 
		skill_order =5
 into #tfub_total1
 from ngsqldata.ngprod.dbo.appointments a 
 join ngsqldata.ngprod.dbo.events ev on a.event_id=ev.event_id
 join ngsqldata.ngprod.dbo.person p on p.person_id=a.person_id
 where  ((ev.[event] like '%telehealth%' and ev.[event] like '%F/U%')  or (ev.[event] like '%telehealth%' and ev.[event] like '%follow up%') )
 and cast(a.create_timestamp as date) between @Start_Date and @End_Date
 and  p.last_name NOT IN ('Test', 'zztest', '4.0Test', 'Test OAS', '3.1test', 'chambers test', 'zztestadult')
 group by cast(a.create_timestamp as date)




 select * 
 into #tfub_total2
 from #tfub_total1 
 union 
 select weekNum, 
		Skill_category = 'Telehealth Follow-Up Created', 
		callsDate = 'Wk Total', 
		wkDayName = concat('Wk Total', weekNum), 
		 Call_Category = 'Total Created' , 
		sum(countTHFUBooked) countTHFUBooked, 
		orderNum = null, 
		skill_order = 5
from #tfub_total1 
group by weekNum

select * 
into #tfub2
from #tfub2_1
union
select * 
from #tfub_total2




/********************Availablity *********************************/

	
	--exec ppreporting.dbo.[PS_OpenSlotArchive]
	
	--declare @Start_Date datetime = '20200727'
	--declare @End_Date datetime = '20200803'

	--drop table #avl_b1, #avl_a1

	select distinct lm.location_name,
						r.description as resource_description, 
						c.category, 
						case 
							when ev.event = 'Blocked' then 'Blocked'
							else 'Other'
						end as 'Event_Appt', 
						a.appt_id, 
						a.event_id, 
						a.person_id, 
						a.appt_date, 
						a.begintime, 
						a.endtime, 
						a.duration, 
						a.last_name, 
						a.first_name,
						a.description, 
						a.location_id, 						
						am.resource_id, 
						a.enc_id
		into #avl_b1
		from ngsqldata.ngprod.dbo.appointments a
		left join ngsqldata.ngprod.dbo.location_mstr lm on a.location_id=lm.location_id
		left join ngsqldata.ngprod.dbo.events ev on ev.event_id=a.event_id						
		left JOIN ngsqldata.ngprod.dbo.appointment_members AM ON A.appt_id = AM.appt_id 
		left JOIN ppreporting.dbo.[appt_slots_archive] asl ON asl.location_id = a.location_id 
			AND asl.resource_id = am.resource_id 
			and a.appt_date=asl.start_date		
			AND a.appt_date = asl.start_date AND a.begintime = asl.begintime
		left JOIN ngsqldata.ngprod.dbo.categories c on c.category_id=asl.category_id	
		left join ngsqldata.ngprod.dbo.resources r on am.resource_id=r.resource_id
		where a.appt_date between @Start_Date and @End_Date
		--and lm.location_name like '%escondido%'
		AND a.cancel_ind != 'Y'
		AND a.resched_ind != 'Y'
		AND a.delete_ind != 'Y'
		and a.event_id in (select event_id								
							from ngsqldata.ngprod.dbo.events 
							where event_id = '5CCD259E-7100-4B53-82A2-DA82C17AC889' or  event_id = '36B09CAC-F6A7-4259-BB80-F355180094AE' or event_id = 'B6E41A57-DC5D-4891-9844-9F321170FA06' or 
								((event like '%telehealth%' and event not like '%f/u%' ) and  
								(event like '%telehealth%' and event not like '%follow up%' ) )
								or ev.event = 'blocked')
		and lm.location_name = 'telehealth' 
		--and a.appt_date >= '20200328' and a.appt_date < cast(getdate() as date)
		

		delete from #avl_b1 where event_id = '2EA46C96-F55B-4661-955A-3E94F11B9456'

			
		select distinct lm.location_name, r.description as resource_description, c.category, a.*
		into #avl_a1 
		from ppreporting.dbo.appt_slots_archive a
		join ngsqldata.ngprod.dbo.resources r on a.resource_id=r.resource_id
		JOIN ngsqldata.ngprod.dbo.categories c on c.category_id=a.category_id
		join ngsqldata.ngprod.dbo.location_mstr lm on lm.location_id=a.location_id
		where start_date between @Start_Date and @End_Date 
		and location_name = 'telehealth'
		--and start_date >='20200328' and start_date < cast(getdate() as date) 
		--union  
		--select distinct lm.location_name, r.description as resource_description, c.category, a.*		
		--from ngsqldata.ngprod.dbo.appt_slots a
		--join ngsqldata.ngprod.dbo.resources r on a.resource_id=r.resource_id
		--JOIN ngsqldata.ngprod.dbo.categories c on c.category_id=a.category_id
		--join ngsqldata.ngprod.dbo.location_mstr lm on lm.location_id=a.location_id
		--where start_date = cast(getdate() as date) 
		--and location_name = 'telehealth'
		----and start_date = cast(getdate() as date) 
		
		--Total Template
		select location_name, category, cast(start_date as datetime) as start_date, sum(timeslot_count) as TotalTemplate
		into #avl_totalTemplate
		from #avl_a1
		group by location_name,category, start_date
						
		select distinct asl.location_name, asl.resource_description, asl.category, asl.location_id, asl.start_date, asl.begintime, asl.duration, asl.appt_count,
		b.event_appt, b.person_id, b.appt_date,  b.endtime, b.last_name, b.first_name, b.enc_id
		into #avl_d2
		from #avl_a1 asl
		left join #avl_b1 b on  asl.location_id = b.location_id 
			AND asl.resource_id = b.resource_id 
			and b.appt_date=asl.start_date		
			AND b.appt_date = asl.start_date AND b.begintime = asl.begintime
		where  event_appt is not null and person_id is not null and last_name is not null and first_name is not null

		alter table #avl_d2 
		add new_or_est_pt varchar(100)

		
		update #avl_d2 
		set New_or_Est_Pt = 'Est' 
		from #avl_d2 a 
		join ngprod.dbo.master_im_ m on a.enc_id= m.enc_id
		where m.newEstablished = 2

		update #avl_d2 
		set New_or_Est_Pt = 'New' 
		from #avl_d2 a 
		join ngprod.dbo.master_im_ m on a.enc_id= m.enc_id
		where m.newEstablished = 1
							
	
							
		--Total Booked
		--drop table #avl_totalBooked
		select location_name, category, cast(start_date as datetime) as start_date, count(*) as totalBooked
		into #avl_totalBooked
		from #avl_d2
		group by location_name,category, start_date
				
		select location_name, category, cast(start_date as datetime) as start_date, count(*) as totalBookedNewPt
		into #avl_totalBooked_NewPt
		from #avl_d2
		where New_or_Est_Pt = 'New'
		group by location_name,category, start_date
		
	
		select distinct asl.location_name, asl.resource_description, asl.category, asl.location_id, asl.start_date, asl.begintime, asl.duration, asl.appt_count,
		b.event_appt, b.person_id, b.appt_date,  b.endtime, b.last_name, b.first_name
		into #avl_d1
		from #avl_a1 asl
		left join #avl_b1 b on  asl.location_id = b.location_id 
			AND asl.resource_id = b.resource_id 
			and b.appt_date=asl.start_date		
			AND b.appt_date = asl.start_date AND b.begintime = asl.begintime
		where event_appt ='blocked' or (event_appt is null and appt_count >=1)
		

		--Total Blocked
		select location_name, category, cast(start_date as datetime) as start_date, count(*) as totalBlocked
		into #avl_totalBlocked
		from #avl_d1
		--where resource_description not like '%-ma%' and resource_description not like '%overflow%'
		group by location_name,category, start_date

		select location_name,category,datepart(week, start_date) as [Week], start_date, totalTemplate 
		into #avl_totalTemplate1
		from #avl_totalTemplate
				
		select location_name, category,datepart(week, start_date) as [Week],start_date, totalBlocked
		into #avl_totalBlocked1
		from #avl_totalBlocked

		select location_name, category, datepart(week, start_date) as [Week],start_date, totalBooked
		into #avl_totalBooked1
		from #avl_totalBooked	
		
		
		select location_name, category, datepart(week, start_date) as [Week],start_date, totalBookedNewPt
		into #avl_totalBooked_newPt1
		from #avl_totalBooked_newPt	

		update #avl_totalTemplate1
		set totalTemplate = 0 
		where category = 'telehealth overflow' 		


		select  datepart(week, template.start_date) weekNum,
				skill_category = 'Telehealth Appts',
				cast(LEFT(CONVERT(VARCHAR(100),template.start_date, 1), 5) as varchar(100)) appt_date, 
				cast(LEFT(DATENAME(WEEKDAY,template.start_date),3) as varchar(100)) wkDayName, 
				sum(coalesce(totalBooked,0)) as Booked, 				
				sum(coalesce(totalBookedNewPt,0)) as BookedNewPt, 				
				sum(totalTemplate - coalesce(totalBlocked,0) - coalesce(totalBooked,0)) [Open], 
				sum(coalesce(totalBlocked,0)) as Blocked, 
				sum(totalTemplate - coalesce(totalBlocked,0)) [Avl], 
				sum((totalTemplate - coalesce(totalBlocked,0) - coalesce(totalBooked,0) * 1.0))/ sum((totalTemplate - coalesce(totalBlocked,0) )) percOpen
		into #avl_totalTemplate2_1
		from #avl_totalTemplate1 template
		left join #avl_totalBooked1 booked on template.location_name = booked.location_name and template.category = booked.category and template.start_date=booked.start_date
		left join #avl_totalBlocked1 blocked on template.location_name = blocked.location_name and template.category = blocked.category and template.start_date=blocked.start_date
		left join #avl_totalBooked_newPt1 newPt on template.location_name = newPt.location_name and template.category = newPt.category and template.start_date=newPt.start_date
	--	where template.category not like '%-ma%' and template.category not like '%overflow%' and template.category not like '%refill%' and template.category not like '%meeting%'
		group by datepart(week, template.start_date) ,				
				cast(LEFT(CONVERT(VARCHAR(100),template.start_date, 1), 5) as varchar(100)) , 
				cast(LEFT(DATENAME(WEEKDAY,template.start_date),3) as varchar(100))				

		select weekNum, skill_category, appt_date, wkDayName, sum(Booked) Booked,sum(BookedNewPt) BookedNewPt, 
					sum([Open]) [Open], sum(Blocked) Blocked, 
					sum(Avl) Avl, (sum([Open] * 1.0) / sum(Avl) ) percOpen	
		into #avl_totalTemplate2
		 from #avl_totalTemplate2_1
		 group by weekNum, skill_category, appt_date, wkDayName		  

		 

create table #avl_op1 (
	Appt_Category varchar(5000), 
	Appt_metric varchar(5000)
)


insert into #avl_op1
values ('Telehealth Appts', 'Available'), 
 ('Telehealth Appts', 'Booked'), 
 ('Telehealth Appts', '   New Patients Booked'), 
('Telehealth Appts', 'Open'),
('Telehealth Appts', '% Open')

select t.*, op.appt_metric
into #avl_totaltemplate3
from #avl_totaltemplate2 t
join #avl_op1 op on t.skill_category = op.appt_category

alter table #avl_totalTemplate3 
add vals float

update #avl_totalTemplate3
set Vals = Avl 
where appt_metric = 'Available'

update #avl_totalTemplate3
set Vals = Booked 
where appt_metric = 'Booked'

update #avl_totalTemplate3
set Vals = BookedNewPt 
where appt_metric = '   New Patients Booked'

update #avl_totalTemplate3
set Vals = [Open] 
where appt_metric = 'Open'

update #avl_totalTemplate3
set Vals = percopen
where appt_metric = '% Open'

select weekNum, 
		skill_category, 
		appt_date = 'Wk Total', 
		wkDayName = concat('Wk Total', weekNum), 
		appt_metric, 
		case 
			when appt_metric != '% open' then sum(vals) 
			else sum([open]) * 1.0 / sum(avl) 
		end Vals, 
		orderNum = null, skillOrder = 4
into #avl_totalTemplatewkly
from #avl_totalTemplate3
group by weekNum, skill_category, appt_metric



select weekNum, skill_category, appt_date, wkDayName, appt_metric, vals, orderNum = null, skillOrder = 4
into #avl_totalTemplate4
from #avl_totalTemplate3


select *
into #combine 
from #cm5
union all
select weekNum, appt_category, appt_date, wkDayName, concat('   ',[event])[event],Vals, orderNum, skill_order
 from #tfu_appt4
union all 
select weekNum, appt_category, appt_date, wkDayName, concat('   ',[event])[event],Vals, orderNum, skill_order
from #tfu_appt4_wkly
union all 
select * from #tfu_daily3
union all 
select weekNum, appt_category, appt_date, wkDayName, appt_status, vals, orderNum = null, skillOrder = 6 
from #tfu_wklyAppt2
union all 
select * 
from #tfub2
union all 
select * from #avl_totalTemplate4
union all
select * from #avl_totaltemplatewkly

update #combine 
set orderNum = 1 
where Skill_category = 'Telehealth Appts' and call_category = 'Available'

update #combine 
set orderNum = 2 
where Skill_category = 'Telehealth Appts' and call_category = 'Booked'

update #combine 
set orderNum = 2.5 
where Skill_category = 'Telehealth Appts' and call_category = '   New Patients Booked'

update #combine 
set orderNum = 3 
where Skill_category = 'Telehealth Appts' and call_category = 'Open'

update #combine 
set orderNum = 4 
where Skill_category = 'Telehealth Appts' and call_category = '% Open'

update #combine 
set orderNum = 5
where Skill_category = 'Telehealth Appts' and call_category = '   Kept Audio & Video'

update #combine 
set orderNum = 6
where Skill_category = 'Telehealth Appts' and call_category = '   Kept Audio No Translation'


update #combine 
set orderNum = 6.3
where Skill_category = 'Telehealth Appts' and call_category = '   Kept Audio Translation'

update #combine 
set orderNum = 7
where Skill_category = 'Telehealth Appts' and call_category = '   Kept A&V to Audio'


update #combine 
set orderNum = 8
where Skill_category = 'Telehealth Appts' and call_category = '   Kept MAB Consult'

update #combine 
set orderNum = 8.2
where Skill_category = 'Telehealth Appts' and call_category = '   Kept MAB Consult-Audio Only'


update #combine 
set orderNum = 8.4
where Skill_category = 'Telehealth Appts' and call_category = '   Kept MAB Consult-Audio & Video'


update #combine 
set orderNum = 8.5
where Skill_category = 'Telehealth Appts' and call_category = '   Kept GAHT'


update #combine 
set orderNum = 9
where Skill_category = 'Telehealth Appts' and call_category = '   Kept Other'


update #combine 
set orderNum = 10
where Skill_category = 'Telehealth Appts' and call_category = 'Total Kept'

update #combine 
set orderNum = 11
where Skill_category = 'Telehealth Appts' and call_category = 'No-Show'

update #combine 
set orderNum = 12 
where Skill_category = 'Telehealth Appts' and call_category = 'Rescheduled'

update #combine 
set orderNum = 13 
where Skill_category = 'Telehealth Appts' and call_category = 'No-Show Rate'

update #combine 
set orderNum = 14
where Skill_category = 'Telehealth Appts' and call_category = 'Billed'

update #combine 
set orderNum = 15 
where Skill_category = 'Telehealth Appts' and call_category = 'Void'

update #combine 
set orderNum =16 
where Skill_category = 'Telehealth Appts' and call_category = 'Avg Time'

update #combine 
set Vals = 0 
where Vals is null and Skill_Category = 'Telehealth Appts'


update #combine 
set orderNum =9 
where Skill_category = 'Telehealth Follow-Up Volume' and call_category not like '%No-Show%' and (call_category like '%f/u%' or call_category like '%follow up%') 

update #combine 
set orderNum =10 
where Skill_category = 'Telehealth Follow-Up Volume' and call_category = 'Total Kept'


update #combine 
set orderNum =11 
where Skill_category = 'Telehealth Follow-Up Volume' and call_category like '%No-Show%' and (call_category like '%f/u%' or call_category like '%follow up%') 

update #combine 
set orderNum =12 
where Skill_category = 'Telehealth Follow-Up Volume' and call_category = 'Total No-Show' 

update #combine 
set orderNum =13 
where Skill_category = 'Telehealth Follow-Up Volume' and call_category = 'No-Show Rate'

update #combine 
set orderNum =14
where Skill_category = 'Telehealth Follow-Up Volume' and call_category = 'Appts Booked'

update #combine 
set orderNum =10
where Skill_category = 'Telehealth Follow-Up Created' and call_category = 'Total Created'

update #combine
set Skill_Category = 'Telehealth Appts*'
where Skill_Category = 'Telehealth Appts'

select *
from #combine 
where wkDayName != 'Sun'
order by skill_order, orderNum

--select * from #cm5
--union all
--select * from #tfu_appt4
--union all 
--select weekNum, appt_category, appt_date, wkDayName, appt_status, vals, orderNum = null, skillOrder = 5 
--from #tfu_wklyAppt2

