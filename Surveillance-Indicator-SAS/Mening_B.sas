 /* Mening B */
 /*********************************************************************************************/
 /* Date Modified: 2021/May/10                                                                */
 /* Modified by: Hannah Fast                                                                  */
 /* Changes:    Transformed Hflu into Mening                                            */
 /*********************************************************************************************/

/*libname indrpts "\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_Indicators_NNAD\Data\2021Currentdata.file";*/


/*-------------------------
Read the Mening File.
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
data StMening;
	set IndRpts.hl7_N_meningitidis; 
	   /* only confirmed and probable cases */
       if case_status in ('410605003','2931005');
	      /* only US states, DC, and NYC */
          if state le 56 or state=975772;   
run; 

/*------------------------------------------------------------------------------
Now create a "state" that represents the entire US so you can get totals without
extra coding.                                                                   
-------------------------------------------------------------------------------*/
Data USMening;
	set StMening;
	output;
	state=0;
	output;
run;

data USMening;
   set USMening;

* dis=put(event,eventn.);
* mmwr_wk=(mmwr_year*100) + mmwr_week;
* mmtowk format is not defined;
* cdate=put(mmwr_wk,mmtowk.);
* rptdate=input(cdate,yymmdd9.);

onsetdt=put(illness_onset_dt,yymmdd9.);

if (age_invest_units='mo') then do;
   agetype=0;
   age=int(age_invest/12);
end;
else if age_invest_units='wk' then do;
   agetype=0;
   age=int(age_invest/52);
end;
else if age_invest_units='d' then do;
    agetype=0;
    age=int(age_invest/365);
end;
if (missing(age_invest)) then 
   agegroup=13;  /* Age Not Reported */
else if (n_rectype='S') then 
   agegroup=13;
else if (age_invest=9999 or age_invest_units='UNK') then 
   agegroup=12; /* Age Unknown */

else if age_invest_units in ('a','CNS') then do;
    if (age_invest=0) then 
	   agegroup=1; /* Under 1 Year */
    if (1 <= age_invest <= 4) then
	   agegroup=2; /* 1-4 Years */
    if (5 <= age_invest <= 9) then
	   agegroup=3; /* 5-9 Years */
    if (10 <= age_invest <= 14) then 
	   agegroup=4; /* 10-14 Years */
    if (15 <= age_invest <= 19) then 
	   agegroup=5; /* 15-19 Years */
    if (20 <= age_invest <= 24) then
	   agegroup=6; /* 20-24 Years */
    if (25 <= age_invest <= 29) then
	   agegroup=7; /* 25-29 Years */
    if (30 <= age_invest <= 39) then
	   agegroup=8; /* 30-39 Years */
    if (40 <= age_invest <= 49) then 
	   agegroup=9; /* 40-49 Years */
    if (50 <= age_invest <= 59) then 
	   agegroup=10; /* 50-59 Years */
    if (60 <= age_invest <= 998) then 
	   agegroup=11; /* 60 + */
end;
															   
if (not missing(illness_onset_dt)) then do;
  evntdate=put(datepart(illness_onset_dt),mmddyy9.);
  evntmo=substr(evntdate,1,2);
  evntyr=Substr(evntdate,5,2);
end;

agemo=(illness_onset_dt-birth_dt)/30.25;
if (agemo>=0 and agemo<2) then 
   agemnths=1;
if (agemo>=2 and agemo<6) then 
   agemnths=2;
if (agemo>=6 and agemo<12) then
   agemnths=3;
if (agemo>=12 and agemo<60) then 
   agemnths=4;

mening=2;
if (meningitis='Y') then 
   mening=1; 

if agegroup in (1,2) then 
   agegrp=1;
if agegroup in (3,4) then 
   agegrp=2;
if agegroup in (5,6,7,8,9) then 
   agegrp=3;
if agegroup in (10,11) then 
   agegrp=4;
if agegroup in (12,13) then 
   agegrp=9;
if (missing(agegroup)) then 
   agegrp=9;


*************** Create the SEROGROUPING portions of the SCORE ************;
seroall=0;
if n_serogrp in ('103479006','103480009','103481008','103482001','103483006',
   'PHC1120','OTH') then 
   seroall=1;

******************* Create the EVENTD portions of the SCORE ************;
/* Previously checked EVENTD and DATET. New version checks all variables that EVENTD
maps into */
escore=0;
if (not missing(illness_onset_dt) or not missing(dx_dt) or not missing(n_labtestdate) or
   not missing(first_report_county_dt) or not missing(first_report_state_dt) or 
   not missing(n_unkeventd)) then 
   escore=1;

******************* Create the BIRTHD portions of the SCORE ************;
bscore=0;
if (not missing(birth_dt) or not missing(age_invest)) then 
   bscore=1;   

tscore=EScore + BScore;
complete=int((tscore/2)*100);

******************* Create DOSE VARIABLE and Look at VACCINE HISTORY *****************;

meningvacd1=datepart(vaxdate1);
meningvacd2=datepart(vaxdate2);
meningvacd3=datepart(vaxdate3);
meningvacd4=datepart(vaxdate4);
*fculture=input(frstcult,mmddyy9.);
format meningvacd1 mmddyy9. meningvacd2 mmddyy9. meningvacd3 mmddyy9.
   meningvacd4 mmddyy9. n_cdcdate mmddyy9.;
 
/* Dose does not exist for mening */
dose=. ; /* this avoids the 'variable DOSE is not initialized' warning */

if (not missing(meningvacd4)) then 
   dose=4; 
else if (not missing(meningvacd3)) then
   dose=3; 
else if (not missing(meningvacd2)) then 
   dose=2; 
else if (not missing(meningvacd1)) then 
   dose=1; 
else if (missing(meningvacd1)) and (missing(meningvacd2)) and (missing(meningvacd3))
   and (missing(meningvacd4)) then 
   dose=0;
else dose=9;


**************** CREATING CATEGORICAL VARIABLE FOR VACCINE HISTORY ******************;

/*-----------------------------------------------------------------------------
This is the standard way of defining a complete vaccine.
------------------------------------------------------------------------------*/
vaccin1=0;
vaccin2=0;
vaccin3=0;
vaccin4=0;
if (not missing(meningvacd1)) and (vaxtype1 in ('114','136','148','32','147','163','162','OTH','999')) then
   vaccin1=1;
if (not missing(meningvacd2)) and (vaxtype2 in ('114','136','148','32','147','163','162','OTH','999')) then
   vaccin2=1;
if (not missing(meningvacd3)) and (vaxtype3 in ('114','136','148','32','147','163','162','OTH','999')) then
   vaccin3=1;
if (not missing(meningvacd4)) and (vaxtype4 in ('114','136','148','32','147','163','162','OTH','999')) then
   vaccin4=1;

if (received_vax='Y') then do;
   if (dose=1) then
      complvac=vaccin1;
   if (dose=2) then 
      complvac=vaccin1*vaccin2;
   if (dose=3) then
      complvac=vaccin1*vaccin2*vaccin3;
   if (dose=4) then
      complvac=vaccin1*vaccin2*vaccin3*vaccin4;
   if (dose in (9,0,.)) then
      complvac=0;
end;
else if (received_vax='N') then 
   complvac=1;
else if (received_vax in (' ','UNK','#M')) then
   complvac=0;

/*-----------------------------------------------------------------------------
Define a completed VACCINE HISTORY similarly but ignore the presence of vaccine name.
NVN = No Vaccine Name.  This is a new requirement from the MeningIND program. 
------------------------------------------------------------------------------*/
vaccin1NVN=0;
vaccin2NVN=0;
vaccin3NVN=0;
vaccin4NVN=0;
if (not missing(meningvacd1)) then
   vaccin1NVN=1;
if (not missing(meningvacd2)) then 
   vaccin2NVN=1;
if (not missing(meningvacd3)) then
   vaccin3NVN=1;
if (not missing(meningvacd4)) then
   vaccin4NVN=1;

if (received_vax='Y') then do;
   if (dose=1) then 
      complvacNVN=vaccin1NVN;
   if (dose=2) then 
      complvacNVN=vaccin1NVN*vaccin2NVN;
   if (dose=3) then 
      complvacNVN=vaccin1NVN*vaccin2NVN*vaccin3NVN;
   if (dose=4) then 
      complvacNVN=vaccin1NVN*vaccin2NVN*vaccin3NVN*vaccin4NVN;
   if (dose in (9,0,.)) then
      complvacNVN=0;
end;
else if (received_vax='N') then 
   complvacNVN=1;
else if (received_vax in (' ','UNK','#M')) then
   complvacNVN=0;

/*-----------------------------------------------------------------------------
COUNT is a variable that identifies how many cases the particular record reflects.
Duplicate the record so that you can process the data as if it's one record per
case. But you need a variable for Proc Summary to sum on, so create MeningCases.
-------------------------------------------------------------------------------*/
Meningcases=1;
   do i=1 to input(n_count, BEST.);
      output;
   end;
   drop i;	
run ;

proc sort data=USMening; by state; run;
proc freq data=USMening noprint;
table state*year/out=MeningCases(drop=percent rename=count=MeningCases) sparse; 
run;

Proc Sort data=USMening ;
	by Year State ;
	run ;


/*-----------------------------------------------------------------------------
Calculate the TOTAL number of CASES by Year State.
-------------------------------------------------------------------------------*/

Proc Freq Data=USMening noprint ;
	Table State / out=StateCounts(rename=Count=Numcases drop=percent) ;
				  
	Title 'Mening Cases by Year State';
	by Year ;
	Run ;
	
/*-----------------------------------------------------------------------------
Calculate the MEAN of how COMPLETE the information is.
-------------------------------------------------------------------------------*/
Proc Means Data=USMening noprint nway ;
																				
	var Complete ;
	Class Year State;
	output out=StateComplete (drop=_type_ _Freq_ ) Mean=MeanComplete;
	run ;

Proc Sort data=USMening ;
	by Year State ;
	Run ;

/*----------------------------------------------------------------------------
Calculate the number of CONFIRMED cases.
----------------------------------------------------------------------------*/
Proc Freq Data=USMening noprint ;
     Table State / out=StateConfCounts(Rename=Count=NumConfirmed drop=Percent) ;
     By Year;
     where case_status='410605003';
     run;

/*----------------------------------------------------------------------------
Calculate the percentage of cases with KNOWN OUTCOME.
----------------------------------------------------------------------------*/
Proc Freq Data=USMening noprint ;
     Table died/ Out=StateOutcome(Rename=Percent=Pct_Unknown drop=count) missing ;
     By Year State ;
     run ;

/*----------------------------------------------------------------------------
Compute the percentage of CONFIRMED cases with SEROGROUP TESTING.
----------------------------------------------------------------------------*/
Proc Freq data=USMening ;
     tables SeroAll / noprint out=StateSeroAll(Rename=Percent=PCT_SERO Drop=Count) ;
     by Year State ;
     where case_status='410605003';
     run ;
	 
/*-----------------------------------------------------------------------------
Compute the percentage of COMPLETE VACCINE HISTORY, where vaccine name
is and is not required.
/*----------------------------------------------------------------------------

----------------------------------------------------------------------------*/
%macro PctComplete (indata=, outdata=,var=,pctvar=) ;

proc freq data=&Indata ;
     tables &Var / noprint out=Complete (drop=count rename=Percent=&PctVar) ;
     by year state ;
     tables year / noprint out=Years (drop=count rename=Percent=&PctVar) ;
     run ;

/*-------------------------------------------------------------------------------
Create a skeleton dataset that will have an entry for completed records for each
year/state but with a percent value of 0.  
-------------------------------------------------------------------------------*/
data Years ;
     set Years ;
     &Var = 1 ; 
     &PctVar = 0 ;
     run ;

Proc Sort data = Years ;
     by Year State &Var ;
     run ;

/*-------------------------------------------------------------------------------
Update the skeleton data with the actual data, allowing existing values to 
overwrite what's in the skeleton but retaining the 0 percent value you want for
combinations that have no completed records.  
-------------------------------------------------------------------------------*/

Data &Outdata  ;
     Update Years (in=y) Complete(in=p) ;
     by Year State &Var  ;
     run ;     

%mend PctComplete ;


%PctComplete(indata=USMening,Outdata=StateComplvac, Var=Complvac, PctVar=Pct_Complete) ;
%PctComplete(indata=USMening,Outdata=StateComplvacNVN, Var=ComplvacNVN, PctVar=Pct_ComplNVN) ;


	
/*-----------------------------------------------------------------------------
Create a dataset with all the state values so that if one state has no cases
we'll still have an entry for them.
-------------------------------------------------------------------------------*/
Data States ;
do year = &StartYear to &EndYear ;
	do state = 0 to 975772 ;
     	if state in (3,7,14,43,52,71-975771) then continue ; * these state codes are not defined ;
        if state le 56 or state = 975772 then output ;
	end ;
end ;
Run ;

Proc Sort Data=States ;
     by Year State ;
     run ;


Data indrpts.Mening ;
merge States (in=s)
	  StateCounts (in=c)
	  StateConfCounts(in=l)
	  StateComplete(in=cp )
       StateOutcome (in=out where=(missing(died)))
	  StateComplVac(in=cv where=(ComplVac=1))
	  StateComplVacNVN(in=cvNVN where=(ComplVacNVN=1))
       StateSeroAll(in=ss where=(SeroAll=1))
	  ;
by Year State ;
if s ;
if Pct_unknown = . then Pct_unknown=0; 
Pct_Known = 100 - Pct_Unknown ; 
if Numcases = .
     then do ;
          Numcases = 0 ;
          MeanComplete = . ;
          Pct_Known = . ;
          Pct_Complete = . ;
          Pct_ComplNVN = . ;
          Pct_Sero = . ;
          end ;
else do ;

          if Pct_Sero = . then Pct_Sero = 0 ;     
          End ; 
run ;


*validation;
*%include '\\cdc\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\Surveillance Indicators_NNAD\SAS Code\Validation\Mening validation.sas';

