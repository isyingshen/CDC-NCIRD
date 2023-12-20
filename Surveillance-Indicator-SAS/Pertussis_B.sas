
 /***************************************************************************************/
 /*                                                                                     */
 /* Date Modified: 2021/Apr/6                                                           */
 /* Modified by: Ying Shen                                                              */
 /*    Changed pcrn to 6 because it was resolved to 5                                   */
 /*    Removed (where= ((&StartYear le Year le &EndYear) and (event = 10190)))          */
 /*           because the data pulled from "create" has defined year and event          */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/9                                                           */
 /* Modified by: Ying Pam and Sandy                                                     */
 /*            Changed to 6 variables instead of 9 variables because NETSS only has 6   */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/15                                                          */
 /* Modified by: Ying                                                                   */
 /*            Flagged pcr_unk, pcr_unk_collct_dt in DD                                 */
 /*            Solved the issue of missing reason_not_vax_per_ACIP not in dataset stpert*/
 /*                                                                                     */
 /* Date Modified: 2022/Jan/07                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Added # and pct confrmed output;                                           */
 /*                                                                                     */
 /* Date Modified: 2022/Jun/06                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Update the filter of proc means for median and mean                        */
 /*          - (onset_dt ge -70000) and (report_dt ge -70000)                           */
 /*          Output negative PertRepInt because it might be caused by human error       */
 /*                                                                                     */
 /* Date Modified: 2022/Jun/13                                                          */
 /* Modified by: Ying Shen                                                              */
 /*              Update date interval to absolute value                                 */
 /*                                                                                     */
 /* Date Modified: 2022/Jun/21                                                          */
 /* Modified by: Ying Shen                                                              */
 /*              Remove code to change . to 0 because we want to keep it blank and code */
 /*				  it NA in the Generate program                                          */
 /***************************************************************************************/


/*-------------------------
Read the Pertussis File.
---------------------------*/

DATA StPert;

set IndRpts.HL7_pertussis;

*only confirmed, probable, and unknown cases;
 if case_status in ('410605003','2931005','UNK') ; 

*only US states, DC, and NYC ;
if state le 56 or state = 975772; 
run;

data stpert2;
set stpert;

*create 'special numeric' values for structured numeric cough duration days variable;
format cough_duration_days1 3.;

cough_duration_days=compress(cough_duration_days);

remove=ifn(lengthn(compress(cough_duration_days, "`~!@#$%^&*()-_=+\|[]{};:',?/", 'ak'))>=1,1,0);

/*indicating >, >= + values and turning into number for .Y (numeric value >=14)*/
if anyalpha(cough_duration_days)<1 and (index(cough_duration_days, ">")>0 or index(cough_duration_days, ">=")>0 or index(cough_duration_days, "+")>0) then do; 
	remove=2; 
	cough_duration_days=compress(cough_duration_days, ">+="); 
end; 
/*indicating < values and turning into number for .N (numeric value but not >=14)*/
else if anyalpha(cough_duration_days)<1 and index(cough_duration_days, "<")>0 then do;
	remove=3;
	cough_duration_days=compress(cough_duration_days, "<");
end;

/*if remove=1 then cough_duration_days1=.E;*/
if remove ne 1 then cough_duration_days1=input(cough_duration_days, 3.);
/*if remove=2 and cough_duration_days1>=14 then cough_duration_days1=.Y;*/
/*if remove=3 then cough_duration_days1=.N;*/

drop remove cough_duration_days;
rename cough_duration_days1=cough_duration_days;

Run ;

/*----------------------------------------------------------------------------
Create a dataset with a record for 'United States' so you can easily create   
totals for the US just by doing your processing 'by state'.
----------------------------------------------------------------------------*/

Data USPert ;
	set StPert2; 
	output;
	state = 0 ;
	output ;
	run;

*setting up variables for lab test completeness;
proc sql noprint;
	
	*Culture;
	*Had to remove np because columns are out of order and can't do array when columns are out of order;
	select name into :cult  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USPERT' and (NAME like 'cult%') and type='char';

	select count(name) into :cultn
	from dictionary.columns
	where libname='WORK' and memname='USPERT' and (NAME like 'cult%') and type='char';

	select name into :dtcult  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USPERT' and (NAME like 'cult%') and format='MMDDYY10.';

	*PCR;
	*Had to remove np because columns are out of order and can't do array when columns are out of order;
	select name into :pcr  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USPERT' and (NAME like 'pcr%') and type='char';

	select count(name) into :pcrn
	from dictionary.columns
	where libname='WORK' and memname='USPERT' and (NAME like 'pcr%') and type='char';

	select name into :dtpcr  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USPERT' and (NAME like 'pcr%') and format='MMDDYY10.';

quit;
run;


data USpert; 
set USPert ;

/*---------------
9 key variables
-----------------*/

*1.clinical;

*cough information;
coughc = 0;
if cough in ('N','UNK') then coughc = 1;
if cough = 'Y' and ((0 < cough_duration_days < 999) or cough_duration_days in (.Y,.N)) then coughc = 1;

*1 of 4 symptoms;
sympc = 0;
if paroxysm in ('Y','N','UNK') or whoop in ('Y','N','UNK') or post_tuss_vomit in ('Y','N','UNK') 
	or (apnea in ('Y','N','UNK') and age < 1) then sympc = 1;

clin = 0;
clin = coughc*sympc;


*2.hospitalization & complications;
hcomp=0;
if hospitalized in ('N','UNK') then hcomp = 1;
if hospitalized = 'Y' and (0 < days_in_hosp < 999 or days_in_hosp =.Y) then hcomp = 1;

comp = 0;
if xray_result in ('10828004','260385009','UNK','385660001') or seizures in ('Y','N','UNK') or 
	encephalopathy in ('Y','N','UNK') or died in ('Y','N','UNK') or hcomp = 1 then comp = 1; 

*3.lab testing; 
lab=0;
if lab_test_done in ('N','UNK') then lab = 1;
if lab_test_done = 'Y' then do;
	*Information on culture testing, have to specify np separately because columns are out of order and can't do array when columns are out of order;
	array cultt{&cultn} &cult ;
	array cultdt{&cultn} &dtcult;
	do i=1 to &cultn;
		if cultdt{i} ne . and cultt{i} in ('10828004','260385009','82334004','I','385660001','26183002','UNK','OTH') then lab=1;
	end;
	if lab ne 1 then do;
		*Information on PCR testing, have to specify np separately because columns are out of order and can't do array when columns are out of order;
		array pcrt{&pcrn} &pcr;
		array pcrdt{&pcrn} &dtpcr;
		do i=1 to &pcrn;
			if pcrdt{i} ne . and pcrt{i} in ('10828004','260385009','82334004','I','385660001','26183002','UNK','OTH') then lab = 1; 
		end;
	end;
	if lab ne 1 then do;
		*Information on other testing (from NETSS);
		if n_otherlab in ('10828004','260385009','82334004','I','385660001','26183002','UNK','OTH') and n_method ne ' ' then lab = 1;
	end;
	if lab ne 1 then do;
		*Information on lab confirmation;
		if lab_confirmed in ('Y','N','UNK') then lab = 1;
	end;
end;

*4.vaccination;
vac = 0;
if received_vax in ('Y','N','UNK') then vac = 1;

*5.epilink/outbreak association;
epi=0;
if n_outbrel in ('N','UNK') or outbreak_assoc in ('N','UNK') or epi_link_labconf in ('Y','N','UNK') then epi = 1; 
if (n_outbrel = 'Y' or outbreak_assoc = 'Y') and outbreak_name ne ' ' then epi = 1;

*6.treatment;
treat = 0;
if antibiotics in ('N','UNK') then treat = 1;
if antibiotics = 'Y' then do;
	array txrcvd(5) TxRcvd1 - TxRcvd5;
	array txstartdt(5) TxStartDt1 -TxStartDt5;
	array TxDurationDays(5) TxDurationDays1 - TxDurationDays5;

	do i=1 to 5;
	if TxRcvd(i) in ('4053', '21212', '18631', '10395','3640','723','19711','733','70618','2193','2194','2551','OTH','10831','UNK','COTR','NONE') 
	or 	TxStartDt(i) ne . or 1 < TxDurationDays(i) < 999 or TxDurationDays(i) = .Y then treat = 1;
	end;
end;

*7.date case first reported to health dept/county/state;
report = 0;
if first_report_PHD_dt ne . or first_report_county_dt ne . or first_report_state_dt ne . then report = 1; 
                           
*8.birthdate/age;
ageok = 0;
if birth_dt ne . or (age_invest ne . and age_invest_units in ('a','d','mo','wk')) then ageok = 1;

*9.symptom/illness onset date;
onset = 0; 
if illness_onset_dt ne . or cough_dt ne . then onset = 1; 

*Create variable to indicate completeness for each record;
score = clin + comp + lab + vac + epi +treat;
*creating percentage score variable;
PertPctComp6 = int((score/6)*100);

*meeting clinical case def;
clinic1 = 0;
if cough = 'Y' and (13 < cough_duration_days < 999 ) and (paroxysm = 'Y' or whoop = 'Y' or post_tuss_vomit = 'Y') then clinic1 = 1;
else if (age < 1 and cough = 'Y') and (paroxysm = 'Y' or whoop = 'Y' or post_tuss_vomit = 'Y' or apnea = 'Y') then clinic1 = 1;

*lab testing done; 
testdone1 = 0;
*Culture testing done; 
do i=1 to &cultn;
	if cultdt{i} ne . and cultt{i} in ('10828004','260385009','82334004','I','26183002','OTH') then testdone1 = 1;
end;
if testdone1 ne 1 then do;
	*PCR testing done;
	do i=1 to &pcrn;
		if testdone1 ne 1 and pcrdt{i} ne . and pcrt{i} in ('10828004','260385009','82334004','I','26183002','OTH') then testdone1 = 1; 
	end;
end;
if testdone1 ne 1 then do;
	*other testing (from NETSS) done;
	if n_otherlab in ('10828004','260385009','82334004','I','26183002','OTH') and n_method ne ' ' then testdone1 = 1;
end;
if testdone1 ne 1 then do;
	*case is lab confirmed;
	if lab_confirmed = 'Y' then testdone1 = 1;
end;

*vaccine history completeness;
array vaxtype(10) vaxtype1 - vaxtype10;
array vaxmfr(10) vaxmfr1 - vaxmfr10;
array vaxdate(10) vaxdate1 - vaxdate10;
array vaccin (10);
array vaccinNVN(10);

do i=1 to 10;
	if vaxtype(i) in ('1','01','11','20','22','50','102','106','107','110','115','120','130','132','146','998','999','OTH','DT') and
	vaxmfr(i) in ('LED','CON','MA','MBL','SKB','NAV','PMC','OTH','UNK','MI') and vaxdate(i) ne . then vaccin(i) = 1;
	else vaccin(i) = 0;
end;
	
complete = 0;
if received_vax = 'Y' and num_vax_dose_prior_onset = 1 then complete = vaccin1;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 2 then complete = vaccin1*vaccin2;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 3 then complete = vaccin1*vaccin2*vaccin3;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 4 then complete = vaccin1*vaccin2*vaccin3*vaccin4;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 5 then complete = vaccin1*vaccin2*vaccin3*vaccin4*vaccin5;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 6 then complete = vaccin1*vaccin2*vaccin3*vaccin4*vaccin5*vaccin6;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 7 then complete = vaccin1*vaccin2*vaccin3*vaccin4*vaccin5*vaccin6*vaccin7;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 8 then complete = vaccin1*vaccin2*vaccin3*vaccin4*vaccin5*vaccin6*vaccin7*vaccin8;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 9 then complete = vaccin1*vaccin2*vaccin3*vaccin4*vaccin5*vaccin6*vaccin7*vaccin8*vaccin9;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 10 then complete = vaccin1*vaccin2*vaccin3*vaccin4*vaccin5*vaccin6*vaccin7*vaccin8*vaccin9*vaccin10;
else if received_vax = 'N' and reason_not_vax_per_ACIP in ('PHC96','397745006','PHC92','PHC82','PHC83','PHC1312','PHC95','OTH','UNK','PHC1313',
														'PHC1310','PHC1311','PHC94','PHC93','PHC1314','PHC1315')   then complete = 1; 
/*in ('PHC96','397745006','PHC92','PHC82','PHC83','PHC1312','PHC95','OTH','UNK','PHC1313',*/
/*															'PHC1310','PHC1311','PHC94','PHC93','PHC1314','PHC1315') */

else if received_vax = 'UNK' and age ge 7 then complete = 1;  
else if received_vax = 'UNK' and age < 7 then complete = 0;  *unknown is not a valid response for received_vax for cases <7;

*Determine the vaccine history completeness as above but do not include vaccine name requirements.;
do i=1 to 10;
	if vaxtype(i) in ('1','01','11','20','22','50','102','106','107','110','115','120','130','132','146','998','999','OTH','DT') 
	and vaxdate(i) ne . then vaccinNVN(i) = 1;
	else vaccinNVN(i) = 0;
end;

*creating indicator for completeness overall without requiring vaccine name ;
completeNVN = 0;
if received_vax = 'Y' and num_vax_dose_prior_onset = 1 then completeNVN = vaccinNVN1;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 2 then completeNVN = vaccinNVN1*vaccinNVN2;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 3 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 4 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3*vaccinNVN4;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 5 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3*vaccinNVN4*vaccinNVN5;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 6 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3*vaccinNVN4*vaccinNVN5*vaccinNVN6;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 7 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3*vaccinNVN4*vaccinNVN5*vaccinNVN6*vaccinNVN7;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 8 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3*vaccinNVN4*vaccinNVN5*vaccinNVN6*vaccinNVN7*vaccinNVN8;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 9 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3*vaccinNVN4*vaccinNVN5*vaccinNVN6*vaccinNVN7*vaccinNVN8*vaccinNVN9;
else if received_vax = 'Y' and num_vax_dose_prior_onset = 10 then completeNVN = vaccinNVN1*vaccinNVN2*vaccinNVN3*vaccinNVN4*vaccinNVN5*vaccinNVN6*vaccinNVN7*vaccinNVN8*vaccinNVN9*vaccinNVN10;
else if received_vax = 'N' and reason_not_vax_per_ACIP in ('PHC96','397745006','PHC92','PHC82','PHC83','PHC1312','PHC95','OTH','UNK','PHC1313',
															'PHC1310','PHC1311','PHC94','PHC93','PHC1314','PHC1315') then completeNVN = 1; 
else if received_vax = 'UNK' and  age ge 7 then completeNVN = 1; 
else if received_vax = 'UNK' and age < 7 then completeNVN = 0; *unknown is not a valid response for received_vax for cases <7;

*Calculate number of days between illness/symptom onset and public health report;  
report_dt = .;
if first_report_PHD_dt ne . then report_dt = first_report_PHD_dt;
	else if first_report_PHD_dt = . then report_dt = first_report_county_dt;
	else if first_report_PHD_dt = . and first_report_county_dt = . then report_dt = first_report_state_dt;
onset_dt = .;
if cough_dt ne . then onset_dt = cough_dt;
	else if cough_dt = . then onset_dt = illness_onset_dt;
if (report_dt ne .) and (onset_dt ne .) and (report_dt ge onset_dt) then PertRepInt = abs(report_dt - onset_dt);
else PertRepInt = .;
run;

proc sort data=USpert; by state; run ;
proc freq data=USpert noprint ; 
table state*year/out=PertCases(drop=percent rename=count=PertCases) sparse; 
run;

/*-----------------------------------------------------------------------------
Calculate the Mean Percentage of completed records based on the score from the 
6 indicator variables.  
-------------------------------------------------------------------------------*/
proc means data=USpert mean n min max nway noprint; 
     class state year;
     var PertPctComp6; 
     output out = PertPctComp6(keep= state year PertPctComp6) mean=PertPctComp6; 
     run;

/*-----------------------------------------------------------------------------
Compute the mean delay in reporting.
-------------------------------------------------------------------------------*/
proc means data=USpert mean n min max nway noprint ;
     where (PertRepInt ne .) and (onset_dt ge -70000) and (report_dt ge -70000) ;
     class state year;
     var PertRepInt; 
     output out=PertMeanRepInt(keep=state year PertMeanRepInt) mean=PertMeanRepInt; 
     run;

/*Output negative PertRepInt because it might be caused by human error*/
proc sql;
title 'USpert: negative PertRepInt';
select local_record_id
,report_jurisdiction
,state
,year
,first_report_PHD_dt
,first_report_county_dt
,first_report_state_dt
,cough_dt
,illness_onset_dt
,report_dt 
,onset_dt
,PertRepInt
from USpert
where PertRepInt < 0 and PertRepInt is not null;
quit;

/*proc value results */
/*      -999999-<0 = 'NA' */
/*     0 = [1.]*/
/*      other = [5.]*/
/*      ;*/

/*-----------------------------------------------------------------------------
Calculate the number of cases meeting the clinical case definition.  
-------------------------------------------------------------------------------*/
proc freq data=USpert noprint; 
by state;
table year*clinic1/missing nocol nopercent out=PertMeetClin outpct sparse; 
run;

data PertNumMeetClin(keep=state year PertNumMeetClin); set PertMeetClin;
     if clinic1 = 1;
     PertNumMeetClin = count;
     PertPctMeetClin = pct_row; 
     run;

/*-----------------------------------------------------------------------------
Calculate the percentage of clinically compatible cases with a lab test.
-------------------------------------------------------------------------------*/
proc freq data=USpert noprint;
     where clinic1 = 1;
     by state;
     table year*testdone1/missing nocol nopercent out=PertClinTest outpct sparse; run;

data PertPctClinTest (keep=state year PertPctClinTest); set PertClinTest; 
     if testdone1 = 1;
     PertPctClinTest = pct_row;
     PertNumClinTest = count; 
     run;

/*-----------------------------------------------------------------------------
Compute the percentage with complete vaccine history, with or without vaccine 
name.  
-------------------------------------------------------------------------------*/
proc freq data=USpert noprint; 
	table year*complete/missing nocol nopercent out=PertVaxComp outpct sparse;
	table year*completeNVN/missing nocol nopercent out=PertVaxCompNVN outpct sparse;
	by state;  
	run;

data PertPctVaxComp(keep=state year PertPctVaxComp); set PertVaxComp;
	if complete = 1;
	PertNumVaxComp = count;
	PertPctVaxComp = pct_row;
	drop count pct_row pct_col percent complete;
	run;

data PertPctVaxCompNVN (keep=state year PertPctVaxCompNVN); set PertVaxCompNVN ;
	if completeNVN = 1;
	PertNumVaxCompNVN = count;
	PertPctVaxCompNVN = pct_row;
	drop count pct_row pct_col percent completeNVN;
	run;

/*-----------------------------------------------------------------------------
Create a dataset for children < 7.  
-------------------------------------------------------------------------------*/

data pertu7; 
set USPert ;
if age < 7;
run;

/*-----------------------------------------------------------------------------
Compute the total number of cases (Numcasesu7) of those < 7 years.
-------------------------------------------------------------------------------*/
proc freq data=pertu7 noprint;
by state;
table year / out=PertCasesu7(rename=count=PertCasesu7 drop=percent ) ; 
run;

/*-----------------------------------------------------------------------------
Calculate the number of cases with complete vaccine history, with and without 
vaccine name.
-------------------------------------------------------------------------------*/
proc freq data=pertu7 noprint;
by state; 
table year*complete/missing nocol nopercent out=PertVaxCompu7 outpct sparse; 
table year*completeNVN/missing nocol nopercent out=PertVaxCompNVNu7 outpct sparse; 
run;

data PertPctVaxCompu7 (keep=state year PertNumVaxCompu7 PertPctVaxCompu7); set PertVaxCompu7;
     if complete = 1;
     PertNumVaxCompu7 = count;
     PertPctVaxCompu7 = pct_row;
     run;

data PertPctVaxCompNVNu7 (keep= state year PertNumVaxCompNVNu7 PertPctVaxCompNVNu7); set PertVaxCompNVNu7 ;
     if completeNVN  = 1;
     PertNumVaxCompNVNu7  = count;
     PertPctVaxCompNVNu7 = pct_row;
     run;

/*-----------------------------------------------------------------------------
Create a SAS Dataset with every state that will be reported on.  This will ensure
that a state will be in the report even if it has no cases. 
-------------------------------------------------------------------------------*/
Data States ;
do year = &StartYear to &EndYear ;
	do state = 0 to 975772 ;
     	if state in (3,7,14,43,52,71-975771) then continue ; * these state codes are not defined ;
        if state le 56 or state = 975772 then output ;
	end ;
end;
Run ;


*merging all together;
proc sort data=states ; by year state ; run;
proc sort data=PertCases; by year state; run;
proc sort data=PertPctComp6; by year state; run;
proc sort data=PertMeanRepInt; by year state; run;
proc sort data=PertPctVaxComp; by year state; run;
proc sort data=PertPctVaxCompNVN; by year state; run;
proc sort data=PertNumMeetClin; by year state; run;
proc sort data=PertPctClinTest ; by year state; run;
proc sort data=PertCasesu7 ; by year state ; run ;
proc sort data=PertPctVaxCompu7 ; by year state ; run ;
proc sort data=PertPctVaxCompNVNu7 ; by year state ; run ;

/*-----------------------------------------------------------------------------
Merge all the data together.  If a state has no cases then display a 0 for the 
number of cases and blanks for everything else.  Otherwise if a state has a   
missing value in any of the columns, then display a 0.  
-------------------------------------------------------------------------------*/
data IndRpts.Pertussis_HL7 ;
merge states (in=s) PertCases(in=n1) PertPctComp6(in=r) PertMeanRepInt(in=d) 
	  PertPctVaxComp(in=p1) PertPctVaxCompNVN(in=p2) PertNumMeetClin(in=n2) 
	  PertPctClinTest(in=p3) PertCasesu7(in=n2) PertPctVaxCompu7(in=p4) PertPctVaxCompNVNu7(in=p5) ;
by year state ;
if s and not n1 then do ;
     PertCases = 0 ;
     call missing(PertPctComp6, PertMeanRepInt, PertPctVaxComp, PertPctVaxCompNVN, PertNumMeetClin,
                   PertPctClinTest, PertCasesu7, PertPctVaxCompu7, PertPctVaxCompNVNu7) ;
     end ;
/*else do ;*/
/*     if PertPctComp6 = . then PertPctComp6 = 0 ;*/
/*     if PertMeanRepInt = . then PertMeanRepInt = 0 ;*/
/*	 if PertPctVaxComp = . then PertPctVaxComp = 0 ;*/
/*     if PertPctVaxCompNVN = . then PertPctVaxCompNVN = 0 ;*/
/*     if PertNumMeetClin = . then PertNumMeetClin = 0 ;*/
/*     if PertPctClinTest = . then PertPctClinTest = 0 ;*/
/*	 if PertCasesu7 = . then PertCasesu7 = 0 ;*/
/*     if PertPctVaxCompu7 = . then PertPctVaxCompu7 = 0 ;*/
/*     if PertPctVaxCompNVNu7 = . then PertPctVaxCompNVNu7 = 0 ;*/
/*     end ;*/
run;


*validation;
*%include '\\cdc\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\Surveillance Indicators_NNAD\SAS Code\Validation\pertussis validation.sas';


*# and pct confrmed output to dataset;

DATA CONFpert ;
SET USPERT(keep = report_jurisdiction mmwr_year case_status);

proc sort data=confpert;
by mmwr_year;
run;

ods rtf file = "&FilePath\Output\&Folder\confirmedpertussis.rtf";
proc freq data=confpert;
tables mmwr_year*case_status / sparse nocol nocum;
/*by mmwr_year;*/
/*where state =0;*/
title "Number and Percent Confirmed: &StartYear -&EndYear Pertussis";
run;
ods rtf close;
