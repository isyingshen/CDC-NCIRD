
 /*********************************************************************************************/
 /* Date Modified: 2021/May/05                                                                */
 /* Modified by: Hannah Fast                                                                  */
 /* Changes:    Transformed rubella B into rubella                                            */
 /*                                                                                           */
 /* Date Modified: 2021/May/06                                                                */
 /* Modified by: Ying Shen                                                                    */
 /* Changes: added proc sort before proc freq because it caused errors                        */
 /*                                                                                           */
 /* Date Modified: 2022/Jun/06                                                                */
 /* Modified by: Ying Shen                                                                    */
 /*              Update the filter of proc means for median and mean                          */
 /*              - first_report_PHD_dt > '31Jan1754'd and rash_onset_dt >'31Jan1754'd         */
 /*              - and illness_onset_dt > '31Jan1754'd                                        */
 /*              Output negative PertRepInt because it might be caused by human error         */
 /*                                                                                           */
 /* Date Modified: 2022/Jun/13                                                                */
 /* Modified by: Ying Shen                                                                    */
 /*              Solved the duplicated year issue in the report by                            */
 /*            changing rubellaPregStatus to rubellaPregStatusPct in Data IndRpts.rubella_HL7;*/
 /*                                                                                           */
 /* Date Modified: 2022/Jun/13                                                                */
 /* Modified by: Ying Shen                                                                    */
 /*              Update date interval to absolute value                                       */
 /*                                                                                           */
 /* Date Modified: 2022/Jun/21                                                                */
 /* Modified by: Ying Shen                                                                    */
 /*              Remove code to change . to 0 because we want to keep it blank and code       */
 /*				  it NA in the Generate program                                                */
 /*                                                                                           */
 /* Date Modified: 2023/Mar/16                                                                */
 /* Modified by: Ying Shen                                                                    */
 /*              Change Pregnant in ('Y','N','UNK') to Pregnant in ('Y','N')                  */
 /*				  Add the Number of Female as an indicator: RubellaNumFemale                   */
 /*********************************************************************************************/
 
/*libname indrpts "\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_Indicators_NNAD\Data\2021Currentdata.file";*/


/*-------------------------
Read the Rubella File.
---------------------------*/

/*Macro to convert the extract column to text*/
/*%macro toChar(dbname, varname);*/
/*data &dbname;*/
/*	set &dbname;*/
/*	newvar=vvalue(&varname);*/
/*	drop &varname;*/
/*	rename newvar=&varname;*/
/*run;*/
/*%mend toChar;*/

options nofmterr;
data Strubella;
	set IndRpts.hl7_rubella; 
	   /* only confirmed and unknown cases */
       if case_status in ('410605003','UNK');
	      /* only US states, DC, and NYC */
          if state le 56 or state=975772;   
run; 

/*------------------------------------------------------------------------------
Now create a "state" that represents the entire US so you can get totals without
extra coding.                                                                   
-------------------------------------------------------------------------------*/
Data USrubella;
	set Strubella;
	output;
	state=0;
	output;
run;

data USrubella;
   set USrubella;

    if (not missing(birth_dt) and not missing(rash_onset_dt)) then
      mageonst=floor((intck('month',birth_dt,rash_onset_dt)-(day(rash_onset_dt)<day(birth_dt))));
   else if (not missing(birth_dt) and not missing(illness_onset_dt)) then
      mageonst=floor((intck('month',birth_dt,illness_onset_dt)-(day(illness_onset_dt)<day(birth_dt))));
   else if (missing(rash_onset_dt) and missing(illness_onset_dt)) or missing(birth_dt) then do;
      if (age_invest_units='a') then
         mageonst=int(age_invest*12);
      if (age_invest_units='mo') then
         mageonst=age_invest;
   end;
   else mageonst=.; 

/*---------------
10 key variables
-----------------*/

   /* 1. Clinical case definition elements */
   klindef=0;
   if (not missing(fever) and not missing(rash) and 
      (not missing(n_arthralg) or not missing(lymphadenopathy) or not missing(conjunctivitis))) then
      klindef=1;

   /* 2. Hospitalization */
   inhosp=0;
   if (hospitalized in ('Y','N','UNK')) then
      inhosp=1;

   /* 3. Lab testing */
   labtok=0;
   if (lab_test_done in ('N','UNK')) then
      labtok=1;
   else if (lab_test_done='Y') then do;

        /* Information on igm testing */
		array igmt{4} igm_blood_1 igm_csf_1 igm_plasma_1 igm_serum_1;
		array igmdt{4} igm_blood_collct_dt_1 igm_csf_collct_dt_1 igm_plasma_collct_dt_1 igm_serum_collct_dt_1;
		do i=1 to 4;
			if igmdt{i} ne . and igmt{i} in ('10828004','260385009','82334004','I','385660001','UNK','OTH') then 
               labtok=1; 
		end;

		/* Information on igg or serology-unsp testing */
		array iggt{3} igg_acu_serum_1 igg_con_serum_1 igg_un_serum_1;
		array iggdt{3} igg_acu_serum_collct_dt_1 igg_con_serum_collct_dt_1 igg_un_serum_collct_dt_1;
		do i=1 to 3;
			if iggdt{i} ne . and iggt{i} in ('10828004','260385009','82334004','I','385660001','UNK','OTH','PHC401','PHC402') then
               labtok=1; 
		end;

        /* Information on other testing (from NETSS) */
		if n_otherlab in ('10828004','260385009','82334004','I','385660001','UNK','OTH','PHC401','PHC402','PHC126','PHC127') and n_method ne ' ' then
           labtok=1; 

		/* Information on lab confirmation */
        if (not missing(lab_confirmed)) then
           labtok=1;
   end;

   /* 4. Vaccine history */
   vacok=0;
   if (received_vax='UNK') then 
      vacok=1;
   else if (received_vax='N' and not missing(reason_not_vax_per_ACIP)) then
      vacok=1;
   else if (received_vax='Y') then do;
      if (not missing(vaxdate1) or not missing(vaxdate2) or not missing(vaxdate3) or
		  not missing(vaxdate4) or not missing(vaxdate5) or not missing(vaxdate6) or
		  not missing(vaxdate7) or not missing(vaxdate8) or not missing(vaxdate9) or
		  not missing(vaxdate10)) then
         vacok=1;
   end;

   /* 5. Outbreak related */
   /* outbreak_of_3 contains NETSS extended data, outbreak_assoc contains NETSS core and HL7 Genv2 data */

   related=0;
   if (outbreak_of_3 in ('N','UNK') or outbreak_assoc in ('N','UNK')) then
      related=1;
   else if (outbreak_of_3='Y' or outbreak_assoc='Y') then do;
      if (source_system=1 and not missing(outbreak_name) and not missing(n_source)) then
         related=1;
      else if (source_system NE 1 and not missing(outbreak_name)) then
         related=1;
   end;

   /* 6. Transmission setting */
   transset=0;
   if (source_system=1 and transmission_setting='OTH') then do;
      if not missing(n_setother) then
         transset=1;
   end;
   else if not missing(transmission_setting) then
      transset=1;

   /* 7. Date case first reported to health dept */
   reporthd=0;
   if (not missing(first_report_PHD_dt)) then
      reporthd=1;

   /* 8. Epilink information provided */
   linkok=0;
   if not missing(epi_link_confprob) then
      linkok=1;
 
   /* 9. Birthdate */
   dobok=0;
   if not missing(birth_dt) then
      dobok=1;

   /* 10. Symptom/illness onset date */
   dateok=0;
   if (not missing(illness_onset_dt) or not missing(rash_onset_dt)) then
      dateok=1;

   /*
   label klindef='+/- Clinical Definition Elements Present' inhosp='Hospitalized'
      labtok='+/- Lab Test Reported' vacok='Hx Vax Reported' reporthd='Date First Report To Hd Reported' 
      related='Outbreak Related' transset='Transmission Setting Reported' linkok='Linked To Import?'
      dobok='Birthdate Reported' dateok='Onset Date Reported';
   */

   /* Create variable to indicate completeness for each record */
   score=klindef+inhosp+labtok+vacok+reporthd+transset+related+linkok+dobok+dateok;
   rubellaPctComp10=int((score/10)*100);

   /* Calculate number of days between illness/symptom onset and public health report */  
   rubellaRepInt=.;   
   if not missing(rash_onset_dt) and not missing(first_report_PHD_dt) then
      rubellaRepInt=ABS(first_report_PHD_dt-rash_onset_dt);
   else if not missing(illness_onset_dt) and not missing(first_report_PHD_dt) then
      rubellaRepInt=ABS(first_report_PHD_dt-illness_onset_dt);

   /* Meeting clinical case def */
   /* 
   clinic1 = 0;
   if (parotit = 'Y' or sublingual_swell = 'Y' or submand_swell = 'Y') and (2 <= swelling_duration < 999 or swelling_duration = .Y) then clinic1 = 1;
   else if (orchitis = 'Y' or oophoritis = 'Y' or encephalitis = 'Y' or deafness = 'Y' or mastitis = 'Y' or pancreatitis = 'Y' or meningitis = 'Y') then clinic1 = 1;
   */

   ******This concept needs review******;
   clinic1=0;
   if (fever='Y' or rash='Y' or cough='Y' or coryza='Y' or conjunctivitis='Y') then 
      clinic1=1;

   /* Lab testing done */
   testdone1 = 0;

   /* IgM testing done */
   do i=1 to 4;
   if igmdt{4} ne . and igmt{4} in ('10828004','260385009','82334004','I','OTH') then 
      testdone1=1;
   end;

   if testdone1 ne 1 then do;
	/* IgG or unspecified serology testing done */
      do i=1 to 3;
	  if iggdt{3} ne . and iggt{i} in ('10828004','260385009','82334004','I','OTH','PHC401','PHC402') then 
         testdone1=1; 
	  end;
   end;

   if testdone1 ne 1 then do;
   /* other testing (from NETSS) done */
   if n_otherlab in ('10828004','260385009','82334004','I','OTH','PHC126','PHC127') and n_method ne ' ' then
      testdone1=1;
   end;

   if testdone1 ne 1 then do;
   /* case is lab confirmed */
   if lab_confirmed = 'Y' then testdone1 = 1;
   end;

*Calculate percent of cases with imported source;  
imported = 0;
if disease_acquired = 'C1512888' or import_status = 'Y' then imported = 1;
else imported = 0;

/*Calculate percent of cases with lab confirmed*/
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

/*-----------------------------------------------------------------------------
	COUNT is a variable that identifies how many cases the particular record reflects.
	Duplicate the record so that you can process the data as if it's one record per
	case. But you need a variable for Proc Summary to sum on, so create rubellaCases.
	-------------------------------------------------------------------------------*/
   rubellacases=1;
   do i=1 to input(n_count, BEST.);
		output;
   end;
   drop i;	
run ;


proc sort data=USrubella; by state; run;
proc freq data=USrubella noprint;
table state*year/out=rubellaCases(drop=percent rename=count=rubellaCases) sparse; 
run;

/*-----------------------------------------------------------------------------
Calculate the Mean Percentage of completed records based on the score from the 
9 indicator variables.  
-------------------------------------------------------------------------------*/
proc means data=USrubella mean n min max nway noprint;
class state year;
var rubellaPctComp10;
output out=rubellaPctComp10(keep= State Year rubellaPctComp10) mean=rubellaPctComp10; 
run;

/*-----------------------------------------------------------------------------
Compute the mean delay in reporting.
-------------------------------------------------------------------------------*/
proc means data=USrubella mean median n min max nway noprint;
where rubellaRepInt ne . and first_report_PHD_dt > '31Jan1754'd and rash_onset_dt > '31Jan1754'd and illness_onset_dt > '31Jan1754'd;
class state year;
var rubellaRepInt;
output out=rubellaMedianRepInt (keep = State Year rubellaMedianRepInt) median=rubellaMedianRepInt;
run;

/*Output negative measlesRepInt because it might be caused by human error*/
proc sql;
title 'USrubella: negative rubellaRepInt';
select local_record_id
,report_jurisdiction
,state
,year
,first_report_PHD_dt
,rash_onset_dt
,illness_onset_dt
,rubellaRepInt
from USrubella
where rubellaRepInt < 0 and rubellaRepInt is not null;
quit;


/*-----------------------------------------------------------------------------
Calculate the number of cases meeting the clinical case definition.  
-------------------------------------------------------------------------------*/
proc freq data=USrubella noprint;
by state;
table year*clinic1/missing nocol nopercent out=rubellaMeetClin outpct sparse; 
run;

data rubellaNumMeetClin(keep=state year rubellaNumMeetClin); set rubellaMeetClin;
     if clinic1 = 1;
     rubellaNumMeetClin = count;
     rubellaPctMeetClin = pct_row; 
     run;

/*-----------------------------------------------------------------------------
Calculate the percentage of clinically compatible cases with a lab test.
-------------------------------------------------------------------------------*/
proc freq data=USrubella noprint;
     where clinic1 = 1;
     by state;
     table year*testdone1/missing nocol nopercent out=rubellaClinTest outpct sparse; run;

data rubellaPctClinTest (keep=state year rubellaPctClinTest); set rubellaClinTest; 
     if testdone1 = 1;
     rubellaPctClinTest = pct_row;
     rubellaNumClinTest = count; 
     run;
/* ADDED FROM NETSS */
/*-----------------------------------------------------------------------------
Determine the percentage of females with pregnancy status of Y or N over all   
females.  Pregnant can have values "Y" "N" "UNK" or " ". 
-----------------------------------------------------------------------------*/
Proc Sort data=USRubella;
	by Year State;
Run;

/*Get the number of female*/
Proc sql;
create table RubellaNumFemale0 as
select Year
,State
,count(local_record_id) as RubellaNumFemale
from USRubella
Where Sex='F'
group by Year, State;
quit;

Proc Freq data=USRubella;
	Tables Pregnant / out=RubellaPregStatus sparse noprint missing ;
     by Year State;
	Where Sex='F' 
/*and State=0*/
;
	run ;

/*-------------------------------------------------------------------------------
We want to add up the percentages of those who have a value of Y/N in PregStatus.
-------------------------------------------------------------------------------*/
Proc Means data=RubellaPregStatus nway noprint ;
     Where Pregnant in ('Y','N') ;
     Class Year State ;
     Var Percent ;
     Output out=RubellaPregStatusPct (drop= _:) Sum=RubellaPregStatusPct  ;
     Run ;

/*Rename the variables*/
proc sql;
create table RubellaPregStatusPct0 as
select Year
,State
,RubellaPregStatusPct as RubellaPregStatusPct
from RubellaPregStatusPct;
quit;
/*----------------------------------------------------------------

/*-----------------------------------------------------------------------------
Calculate the percentage of lab-confirmed cases and Import status by Case Status.
Merge the results into the ReportTable dataset using only those cases that were
both lab-confirmed with a status of confirmed and those with Import=Intl Import
and any status that we're reporting on.
-------------------------------------------------------------------------------*/
ods output CrossTabFreqs=rubellaLabConfFreq(Keep=Year State Labconf casstat ColPercent) ;

/*proc sort data=USrubella;*/
/*	by Year State;*/
/*run;*/
/**/
/*Proc Freq Data = USrubella ;*/
/*  	Tables lab_confirmed * case_status /sparse  ;*/
/*  	by Year State ;*/
/*  	Title 'Serologic Confirmation And Importation Status';*/
/*  	Title2 "&StartYear-&EndYear Annual Rubella Data (Jan-Dec)";*/
/*	run ;*/

/*-------------------------------------------------------------------------------
Note: You can't suppress the output (e.g. use NOPRINT) or the output object is
not created. But you can clear the results window as soon as it's created if you
don't want to see it.
-------------------------------------------------------------------------------*/

dm odsresults 'clear' ;
dm output 'clear' ;

/*-----------------------------------------------------------------------------
Compute the percentage with complete vaccine history, with or without vaccine 
name.  
-------------------------------------------------------------------------------*/
proc sort data=USrubella;
	by State;
run;
proc freq data=USrubella noprint;
	table year*complete/missing nocol nopercent out=rubellaVaxComp outpct sparse;
	table year*completeNVN/missing nocol nopercent out=rubellaVaxCompNVN outpct sparse;
	by state;  
	run;

data rubellaPctVaxComp(keep=state year rubellaPctVaxComp); set rubellaVaxComp;
	if complete = 1;
	rubellaNumVaxComp = count;
	rubellaPctVaxComp = pct_row;
	drop count pct_row pct_col percent complete;
	run;

data rubellaPctVaxCompNVN (keep=state year rubellaPctVaxCompNVN); set rubellaVaxCompNVN ;
	if completeNVN = 1;
	rubellaNumVaxCompNVN = count;
	rubellaPctVaxCompNVN = pct_row;
	drop count pct_row pct_col percent completeNVN;
	run;

/*-----------------------------------------------------------------------------
Calculate the percentage of case with an imported source.
Merge the results using only those with Import=Intl Import.                              
-------------------------------------------------------------------------------*/
Proc sort data=USrubella; by year; run;
Proc Freq Data = USrubella  noprint;
  	Tables imported /missing list sparse out=rubellaImport(drop=Count) ;
  	by Year State ;
  	Run ;

Data rubellaImport2  ;
	set rubellaImport ;
	by Year State ;
	retain foundit 0 ; 
	drop Percent Foundit;
	if first.state then foundit=0;
	if imported = 1
	then do ;
		 foundit=1 ;
		 rubellaImportPct = Percent ;
		 output ;
		 end ;
	else do ;
		 if last.state and foundit=0 
		 then do ;
			  rubellaImportPct = 0 ;
			  output ;
			  end ;
		end ;
	Run ;

/*Percent of Confirmed Cases that are Lab Confirmed*/
Proc Freq Data = USrubella(where=(case_status ='410605003')) noprint;
  	Tables lab_conf /missing list sparse out=rubellaLabConf(drop=Count) ;
  	by Year State ;
  	Run ;

Data rubellaLabConf2;
	set rubellaLabConf;
	retain foundit ; drop foundit ;
	by Year State ;
	if first.state then foundit=0 ;
	if Lab_conf=1 then do ;
		foundit = 1 ;
		rubellaPctConf = Percent;
		output ;
		end ; 
	else do ;
		 if last.state and foundit=0 then do ;
			rubellaPctConf  = 0 ;
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
end ;
Run ;

*merging all together;
proc sort data=states ; by year state ; run;
proc sort data=rubellacases; by year state; run;
proc sort data=rubellaPctComp10; by year state; run;
proc sort data=rubellaMedianRepInt; by year state; run;
proc sort data=rubellaNumMeetClin; by year state; run;
proc sort data=rubellaPctClinTest; by year state; run;
proc sort data=rubellaPctVaxComp; by year state; run;
proc sort data=rubellaPctVaxCompNVN; by year state; run;
proc sort data=rubellaImport2; by year state; run;
proc sort data=rubellaLabConf2; by year state; run;

/*-----------------------------------------------------------------------------
Merge all the data together.  If a state has no cases then display a 0 for the 
number of cases and blanks for everything else.  Otherwise if a state has a   
missing value in any of the columns, then display a 0.  
-------------------------------------------------------------------------------*/

Data IndRpts.rubella_HL7;
Merge states (in=s) rubellaCases (in=n1) rubellaPctComp10(in=r) rubellaMedianRepInt (in=d)
	  rubellaPctVaxComp(in=p1) rubellaPctVaxCompNVN(in=p2) rubellaNumMeetClin(in=n2) 
	  rubellaPctClinTest(in=p3) rubellaImport2 (in=i) rubellaLabConf2(in=lab) RubellaNumFemale0 (in=fe) rubellaPregStatusPct0 (in=p);
by year state;
if r and not i then rubellaimportpct = -1 ;
if s and not n1 then do;
	rubellaCases = 0;
	call missing(rubellaPctComp10, rubellaMedianRepInt, rubellaImportPct, rubellaPctConf, rubellaPctVaxComp, rubellaPctVaxCompNVN,
					rubellaNumMeetClin, rubellaPctClinTest);
	end;
/*else do;*/
/*	if rubellaPctComp10 = . then rubellaPctComp10 = 0;*/
/*	if rubellaMedianRepInt = . then rubellaMedianRepInt = 0;*/
/*	if rubellaImportPct = . then rubellaImportPct = 0;*/
/*	if rubellaPctVaxComp = . then rubellaPctVaxComp = 0;*/
/*	if rubellaPctVaxCompNVN = . then rubellaPctVaxCompNVN = 0;*/
/*	if rubellaNumMeetClin = . then rubellaNumMeetClin = 0;*/
/*	if rubellaPctClinTest = . then rubellaPctClinTest = 0;*/
/*	if rubellaPctConf = . then rubellaPctConf = 0;*/
/*	end ;*/
drop imported;
run ;

*validation;
*%include '\\cdc\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\Surveillance Indicators_NNAD\SAS Code\Validation\rubella validation.sas';

