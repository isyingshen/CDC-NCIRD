 /*This is a revision of NETSS Mumps.sas*/

 /***************************************************************************************/
 /* Date Modified: 2021/Mar/30                                                          */
 /* Modified by: Ying Shen                                                              */
 /* Changes: updated vaxtype1-10 to the same data type                                  */
 /*          updated vaxmfr1-10 to the same data type                                   */
 /*          updated vaxdate1-10 to the same data type                                  */
 /*          removed macro startyear and endyear because they are defined in "create" program */
 /*          removed libname indrpts because it is definded in "create" program         */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/06                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Removed (where= ((&StartYear le Year le &EndYear) and (event = 10590)))    */
 /*           because the data pulled from "create" has defined year and event          */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/08                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Changed mean to median for Number of Days from Symptom Onset to            */
 /*          Public Health Report                                                       */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/08                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Added the percent of confirmed cases that are lab confirmed                */
 /*                                                                                     */
 /* Date Modified: 2022/Jan/07                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Added # and pct confrmed output;                                           */
 /*                                                                                     */
 /* Date Modified: 2022/Jun/06                                                          */
 /* Modified by: Ying Shen                                                              */
 /*              Update the filter of proc means for median and mean                    */
 /*              - (onset_dt ge -70000) and (report_dt ge -70000)                       */
 /*              Output negative date interval because it might be caused by human error*/
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

/*libname indrpts "\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_Indicators_NNAD\Data\2021Currentdata.file";*/
/*-------------------------
Read the Mumps File.
---------------------------*/
/*%let startyear=2018;*/
/*%let endyear=2019;*/


options nofmterr;
DATA StMumps ;
	set IndRpts.hl7_mumps; 
	   /* only confirmed, probable, and unknown cases */
       if case_status in ('410605003','2931005','UNK');
	      /* only US states, DC, and NYC */
          if state le 56 or state = 975772;   
run; 


/*------------------------------------------------------------------------------
Now create a "state" that represents the entire US so you can get totals without
extra coding.                                                                   
-------------------------------------------------------------------------------*/
Data USMumps;
	set StMumps;
	output;
	state = 0;
	output;
run;

/* setting up variables for lab test completeness */  
proc sql noprint;
	
	*Culture;
	*Had to remove np because columns are out of order and can't do array when columns are out of order;
	select name into :cult  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'cult%' and NAME not like '%np%' 
																	  and NAME not like '%blood%'
																	  and NAME not like '%body%'
																	  and NAME not like '%bronc%'
																	  and NAME not like '%crust%'
																	  and NAME not like '%lavage%'
																	  and NAME not like '%lesion%'
																	  and NAME not like '%mac%'
																	  and NAME not like '%scab%'
																	  and NAME not like '%vesc%') and type='char';

	select count(name) into :cultn
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'cult%' and NAME not like '%blood%'
																	  and NAME not like '%body%'
																	  and NAME not like '%bronc%'
																	  and NAME not like '%crust%'
																	  and NAME not like '%lavage%'
																	  and NAME not like '%lesion%'
																	  and NAME not like '%mac%'
																	  and NAME not like '%scab%'
																	  and NAME not like '%vesc%') and type='char';

	select name into :dtcult  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'cult%' and NAME not like '%np%' 
																	  and NAME not like '%blood%'
																	  and NAME not like '%body%'
																	  and NAME not like '%bronc%'
																	  and NAME not like '%crust%'
																	  and NAME not like '%lavage%'
																	  and NAME not like '%lesion%'
																	  and NAME not like '%mac%'
																	  and NAME not like '%scab%'
																	  and NAME not like '%vesc%') and format='MMDDYY10.';

	*Serology - IgM;
	select name into :igm  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS'  and type='char' and (NAME like 'igm%');

	select count(name) into :igmn
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and type='char' and (NAME like 'igm%');

	select name into :dtigm  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and format='MMDDYY10.' and (NAME like 'igm%');

	*Serology - IgG/Unspecified;
	select name into :igg  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS'  and type='char' and (NAME like 'igg%' or NAME like 'ser_unsp%');

	select count(name) into :iggn
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and type='char' and (NAME like 'igg%' or NAME like 'ser_unsp%');

	select name into :dtigg  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and format='MMDDYY10.' and (NAME like 'igg%' or NAME like 'ser_unsp%');

	*PCR;
	*Had to remove np because columns are out of order and can't do array when columns are out of order;
	select name into :pcr  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'pcr%' and NAME not like '%np%'
																	 and NAME not like '%blood%'
																	 and NAME not like '%body%'
																	 and NAME not like '%crust%'
																	 and NAME not like '%lesion%'
																	 and NAME not like '%mac%'
																	 and NAME not like '%scab%'
																	 and NAME not like '%vesc%') and type='char';

	select count(name) into :pcrn
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'pcr%' and NAME not like '%blood%'
																	 and NAME not like '%body%'
																	 and NAME not like '%crust%'
																	 and NAME not like '%lesion%'
																	 and NAME not like '%mac%'
																	 and NAME not like '%scab%'
																	 and NAME not like '%vesc%') and type='char';

	select name into :dtpcr  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'pcr%' and NAME not like '%np%' 
																	 and NAME not like '%blood%'
																	 and NAME not like '%body%'
																	 and NAME not like '%crust%'
																	 and NAME not like '%lesion%'
																	 and NAME not like '%mac%'
																	 and NAME not like '%scab%'
																	 and NAME not like '%vesc%') and format='MMDDYY10.';

	*Typing;
	*Had to remove np because columns are out of order and can't do array when columns are out of order;
	select name into :typ  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'typing%' and NAME not like '%np%' 
																	    and NAME not like '%crust%'
																	    and NAME not like '%lesion%'
																	    and NAME not like '%mac%'
																	    and NAME not like '%scab%'
																	    and NAME not like '%vesc%') and type='char';

	select count(name) into :typn
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'typing%' and NAME not like '%crust%'
																	    and NAME not like '%lesion%'
																	    and NAME not like '%mac%'
																	    and NAME not like '%scab%'
																	    and NAME not like '%vesc%') and type='char';

	select name into :dttyp  separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='USMUMPS' and (NAME like 'typing%' and NAME not like '%np%' 
																	    and NAME not like '%crust%'
																	    and NAME not like '%lesion%'
																	    and NAME not like '%mac%'
																	    and NAME not like '%scab%'
																	    and NAME not like '%vesc%') and format='MMDDYY10.';

quit;
run;

data USMumps;
set USMumps;

/*---------------
10 key variables
-----------------*/

/* 1. Clinical case definition elements */
clin = 0;
   if (parotit NE "") then clin = 1;

/* 2. Hospitalization */
hosp = 0;
   if hospitalized in ('Y','N','UNK') then hosp = 1;

/* 3. Lab testing */
lab=0;
   if lab_test_done in ('N','UNK') then lab = 1;

   else if lab_test_done = 'Y' then do;

        /* Information on igm testing */
		array igmt{&igmn} &igm;
		array igmdt{&igmn} &dtigm;
		do i=1 to &igmn;
			if igmdt{i} ne . and igmt{i} in ('10828004','260385009','82334004','I','385660001','UNK','OTH') then lab = 1; 
		end;

		/* Information on igg or serology-unsp testing */
		array iggt{&iggn} &igg;
		array iggdt{&iggn} &dtigg;
		do i=1 to &iggn;
			if iggdt{i} ne . and iggt{i} in ('10828004','260385009','82334004','I','385660001','UNK','OTH','PHC401','PHC402') then lab = 1; 
		end;

        /* Information on other testing (from NETSS) */
		if n_otherlab in ('10828004','260385009','82334004','I','385660001','UNK','OTH','PHC401','PHC402','PHC126','PHC127') and n_method ne ' ' then lab = 1; 

		/* Information on lab confirmation */
		if lab_confirmed NE " " then lab = 1;
   end;

/* 4. Vaccine history */
vac = 0;
   if received_vax = 'UNK' then vac = 1;
      else if received_vax = 'N' and (reason_not_vax_per_acip NE " ") then vac = 1;
      else if received_vax = 'Y' then do;
         if (vaxdate1 NE " ") or (vaxdate2 NE " ") or (vaxdate3 NE " ") or (vaxdate4 NE " ") then vac = 1;
      end; 

/* 5. Outbreak related */
epi = 0;
   if n_outbrel in ('N','UNK') or outbreak_assoc in ('N','UNK' ) then epi = 1;
   else if n_outbrel = 'Y' or outbreak_assoc = 'Y' then do;
      if source_system = 1 and (outbreak_name NE " ") and (n_source NE " ") then epi = 1;
	  else if source_system NE 1 and (outbreak_name NE " ") then epi = 1;
   end;

/* 6. Transmission setting */
/*Remove the first if statement in the new way NNAD*/
transset = 0;
   if source_system = 1 and transmission_setting = 'OTH' then do;
     if (n_setother NE " ") then transset = 1;
   end;
   else if (transmission_setting NE " ") then transset = 1;

/* 7. Date case first reported to health dept/county/state */
report = 0;
   if first_report_PHD_dt NE . then report = 1; 
 
/* 8. Epilink information provided */
link = 0;
   if epi_link_confprob NE " " then link = 1;
 
/* 9. Birthdate */
dobok = 0;
   if birth_dt NE . then dobok = 1;

/* 10. Symptom/illness onset date */
onset = 0; 
   if illness_onset_dt NE . or rash_onset_dt NE . then onset = 1; 

/* Create variable to indicate completeness for each record */
Score = clin + hosp + lab + vac + epi + transset + report + link + dobok + onset;
MumpsPctComp10 = Int((Score/10)*100);


/* Meeting clinical case def */
clinic1 = 0;
if (parotit = 'Y' or sublingual_swell = 'Y' or submand_swell = 'Y') and (2 <= swelling_duration < 999 or swelling_duration = .Y) then clinic1 = 1;
else if (orchitis = 'Y' or oophoritis = 'Y' or encephalitis = 'Y' or deafness = 'Y' or mastitis = 'Y' or pancreatitis = 'Y' or meningitis = 'Y') then clinic1 = 1;


/* Lab testing done */
testdone1 = 0;

	/* IgM testing done */
	do i=1 to &igmn;
		if igmdt{i} ne . and igmt{i} in ('10828004','260385009','82334004','I','OTH') then testdone1 = 1; 
	end;

if testdone1 ne 1 then do;
	/* IgG or unspecified serology testing done */
	do i=1 to &iggn;
		if iggdt{i} ne . and iggt{i} in ('10828004','260385009','82334004','I','OTH','PHC401','PHC402') then testdone1 = 1; 
	end;
end;

if testdone1 ne 1 then do;
	/* other testing (from NETSS) done */
	if n_otherlab in ('10828004','260385009','82334004','I','OTH','PHC126','PHC127') and n_method ne ' ' then testdone1 = 1;
end;
if testdone1 ne 1 then do;
	/* case is lab confirmed */
	if lab_confirmed = 'Y' then testdone1 = 1;
end;


*Calculate percent of cases with imported source;  
imported = 0;
if disease_acquired = 'C1512888' or import_status = 'Y' then imported = 1;
else imported = 0;


/*Calculte percent of cases with lab confirmed*/
lab_conf = 0;
if Lab_confirmed = 'Y' and case_status in ('410605003') then lab_conf= 1;
else lab_conf = 0;


*vaccine history completeness;
array vaxtype(10) vaxtype1 - vaxtype10;
array vaxmfr(10) vaxmfr1 - vaxmfr10;
array vaxdate(10) vaxdate1 - vaxdate10;
array vaccin (10);
array vaccinNVN(10);

do i=1 to 10;
if vaxtype(i) in ('3','03','7','07','38','94','998','999','OTH','UNK') and 
vaxmfr(i) ne ' ' and vaxdate(i) ne . then vaccin(i) = 1; *9.14.18 - for now, just allow mfr to not be missing, valid values to come;
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
															'PHC1310','PHC1311','PHC94','PHC93','PHC1314','PHC1315') then complete = 1; 
else if received_vax = 'UNK' then complete = 1;

*Determine the vaccine history completeness as above but do not include vaccine name requirements;
do i=1 to 10;
if vaxtype(i) in ('3','03','7','07','38','94','998','999','OTH','UNK') and vaxdate(i) ne . then vaccinNVN(i) = 1; 
else vaccinNVN(i) = 0;
end;

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
else if received_vax = 'UNK' then completeNVN = 1; 

*Calculate number of days between illness/symptom onset and public health report;  
report_dt=.;
   if first_report_PHD_dt NE . then report_dt = first_report_PHD_dt;
   if illness_onset_dt NE . then onset_dt = illness_onset_dt;
   if (report_dt ne .) and (onset_dt ne .) then MumpsRepInt = ABS(report_dt - onset_dt);
      else MumpsRepInt = .;
run;

Proc sort data=USMumps; by state; run;
Proc freq data=USMumps noprint;
table state*year/out=MumpsCases(drop=percent rename=count=MumpsCases) sparse; 
run;

/*-----------------------------------------------------------------------------
Calculate the Mean Percentage of completed records based on the score from the 
10 indicator variables.  
-------------------------------------------------------------------------------*/
proc means data=USMumps mean n min max nway noprint;
class state year;
var MumpsPctComp10;
output out=MumpsPctComp10(keep= State Year MumpsPctComp10) mean=MumpsPctComp10; 
run;

/*-----------------------------------------------------------------------------
Compute the mean delay in reporting.
-------------------------------------------------------------------------------*/
proc means data=USMumps mean median n min max nway noprint;
where (MumpsRepInt ne .) and (onset_dt ge -70000) and (report_dt ge -70000);
class state year;
var MumpsRepInt;
output out=MumpsMedianRepInt (keep = State Year MumpsMedianRepInt) median=MumpsMedianRepInt;
run;


/*Output negative measlesRepInt because it might be caused by human error*/
proc sql;
title 'USMumps: negative MumpsRepInt';
select local_record_id
,report_jurisdiction
,state
,year
,first_report_PHD_dt
,illness_onset_dt
,report_dt
,onset_dt
,MumpsRepInt
from USMumps
where MumpsRepInt < 0 and MumpsRepInt is not null;
quit;


/*-----------------------------------------------------------------------------
Calculate the number of cases meeting the clinical case definition.  
-------------------------------------------------------------------------------*/
proc freq data=USMumps noprint;
by state;
table year*clinic1/missing nocol nopercent out=MumpsMeetClin outpct sparse; 
run;

data MumpsNumMeetClin(keep=state year MumpsNumMeetClin); set MumpsMeetClin;
     if clinic1 = 1;
     MumpsNumMeetClin = count;
     MumpsPctMeetClin = pct_row; 
     run;

/*-----------------------------------------------------------------------------
Calculate the percentage of clinically compatible cases with a lab test.
-------------------------------------------------------------------------------*/
proc freq data=USMumps noprint;
     where clinic1 = 1;
     by state;
     table year*testdone1/missing nocol nopercent out=MumpsClinTest outpct sparse; run;

data MumpsPctClinTest (keep=state year MumpsPctClinTest); set MumpsClinTest; 
     if testdone1 = 1;
     MumpsPctClinTest = pct_row;
     MumpsNumClinTest = count; 
     run;

/*-----------------------------------------------------------------------------
Compute the percentage with complete vaccine history, with or without vaccine 
name.  
-------------------------------------------------------------------------------*/
proc freq data=USmumps noprint;
	table year*complete/missing nocol nopercent out=MumpsVaxComp outpct sparse;
	table year*completeNVN/missing nocol nopercent out=MumpsVaxCompNVN outpct sparse;
	by state;  
	run;

data MumpsPctVaxComp(keep=state year MumpsPctVaxComp); set MumpsVaxComp;
	if complete = 1;
	MumpsNumVaxComp = count;
	MumpsPctVaxComp = pct_row;
	drop count pct_row pct_col percent complete;
	run;

data MumpsPctVaxCompNVN (keep=state year MumpsPctVaxCompNVN); set MumpsVaxCompNVN ;
	if completeNVN = 1;
	MumpsNumVaxCompNVN = count;
	MumpsPctVaxCompNVN = pct_row;
	drop count pct_row pct_col percent completeNVN;
	run;

/*-----------------------------------------------------------------------------
Calculate the percentage of case with an imported source.
Merge the results using only those with Import=Intl Import.                              
-------------------------------------------------------------------------------*/
Proc sort data=USMumps; by year; run;
Proc Freq Data = USMumps  noprint;
  	Tables imported /missing list sparse out=MumpsImport(drop=Count) ;
  	by Year State ;
  	Run ;

Data MumpsImport2  ;
	set MumpsImport ;
	by Year State ;
	retain foundit 0 ; 
	drop Percent Foundit;
	if first.state then foundit=0;
	if imported = 1
	then do ;
		 foundit=1 ;
		 MumpsImportPct = Percent ;
		 output ;
		 end ;
	else do ;
		 if last.state and foundit=0 
		 then do ;
			  MumpsImportPct = 0 ;
			  output ;
			  end ;
		end ;
	Run ;


/*Percent of Confirmed Cases that are Lab Confirmed*/
Proc Freq Data = USMumps(where=(case_status ='410605003')) noprint;
  	Tables lab_conf /missing list sparse out=MumpsLabConf(drop=Count) ;
  	by Year State ;
  	Run ;

Data MumpsLabConf2;
	set MumpsLabConf;
	retain foundit ; drop foundit ;
	by Year State ;
	if first.state then foundit=0 ;
	if Lab_conf=1 then do ;
		foundit = 1 ;
		MumpsPctConf = Percent;
		output ;
		end ; 
	else do ;
		 if last.state and foundit=0 then do ;
			MumpsPctConf  = 0 ;
			output ;
			end ;
		end ;
run ;


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
proc sort data=Mumpscases; by year state; run;
proc sort data=MumpsPctComp10; by year state; run;
proc sort data=MumpsMedianRepInt; by year state; run;
proc sort data=MumpsNumMeetClin; by year state; run;
proc sort data=MumpsPctClinTest; by year state; run;
proc sort data=MumpsPctVaxComp; by year state; run;
proc sort data=MumpsPctVaxCompNVN; by year state; run;
proc sort data=MumpsImport2; by year state; run;
proc sort data=MumpsLabConf2; by year state; run;

/*-----------------------------------------------------------------------------
Merge all the data together.  If a state has no cases then display a 0 for the 
number of cases and blanks for everything else.  Otherwise if a state has a   
missing value in any of the columns, then display a 0.  
-------------------------------------------------------------------------------*/

Data IndRpts.Mumps_HL7;
Merge states (in=s) MumpsCases (in=n1) MumpsPctComp10(in=r) MumpsMedianRepInt (in=d)
	  MumpsPctVaxComp(in=p1) MumpsPctVaxCompNVN(in=p2) MumpsNumMeetClin(in=n2) 
	  MumpsPctClinTest(in=p3) MumpsImport2 (in=i) MumpsLabConf2(in=p4);
by year state;
if r and not i then Mumpsimportpct = -1 ;
if s and not n1 then do;
	MumpsCases = 0;
	call missing(MumpsPctComp10, MumpsMedianRepInt, MumpsImportPct, MumpsPctConf,MumpsPctVaxComp, MumpsPctVaxCompNVN,
					MumpsNumMeetClin, MumpsPctClinTest);
	end;
/*else do;*/
/*	if MumpsPctComp10 = . then MumpsPctComp10 = 0;*/
/*	if MumpsMedianRepInt = . then MumpsMedianRepInt = 0;*/
/*	if MumpsImportPct = . then MumpsImportPct = 0;*/
/*	if MumpsPctVaxComp = . then MumpsPctVaxComp = 0;*/
/*	if MumpsPctVaxCompNVN = . then MumpsPctVaxCompNVN = 0;*/
/*	if MumpsNumMeetClin = . then MumpsNumMeetClin = 0;*/
/*	if MumpsPctClinTest = . then MumpsPctClinTest = 0;*/
/*	if MumpsPctConf = . then MumpsPctConf = 0;*/
/*	end ;*/
drop imported;
run ;

*validation;
*%include '\\cdc\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\Surveillance Indicators_NNAD\SAS Code\Validation\mumps validation.sas';

*# and pct confrmed output to dataset;


data confmump;
set usmumps (keep = report_jurisdiction mmwr_year case_status);

proc sort data=confmump;
by mmwr_year;
run;

ods rtf file = "&FilePath\Output\&Folder\confirmedmumps.rtf";
Proc freq data=confmump;
tables mmwr_year * case_status / sparse nocol nocum;
/*by ;*/
/*where report_jurisdiction ='0';*/
title "Number and Percent Confirmed: &StartYear -&EndYear Mumps";
run;
ods rtf close;
