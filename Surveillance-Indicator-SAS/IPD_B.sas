 /* IPD B */
 /*********************************************************************************************/
 /* Date Modified: 2021/May/11                                                                */
 /* Modified by: Hannah Fast                                                                  */
 /* Changes:    Transformed Mening into IPD                                           */
 /*********************************************************************************************/

/*libname indrpts "\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_Indicators_NNAD\Data\2021Currentdata.file";*/


/*-------------------------
Read the IPD File.
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
data StIPD;
	set IndRpts.hl7_IPD; 
	   /* confirmed and probable starting in 2017*/
	   if (mmwr_year < 2017 and case_status='410605003') or 
	   (mmwr_year >= 2017 and case_status in ('410605003','2931005'));
	      /* only US states, DC, and NYC */
          if state le 56 or state=975772;   
run; 

/*------------------------------------------------------------------------------
Now create a "state" that represents the entire US so you can get totals without
extra coding.                                                                   
-------------------------------------------------------------------------------*/
Data USIPD;
	set StIPD;
	output;
	state=0;
	output;
run;

data USIPD;
   set USIPD;

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

infall=0;
if ((n_primary_bacteremia='Y') or (meningitis='Y') or (otitis_media='Y') or (pneumonia='Y') or 
   (cellulitis='Y') or (epiglottitis='Y') or (peritonitis='Y') or (pericarditis='Y') or 
   (sepsis_abortion='Y') or (n_infection_amniotic='Y') or (arthritis='Y') or 
   (bacterialinfection_oth_ynu='Y')) then
   infall=1;

specall=0;
if ((n_specimen1 in ('119297000','258450006','418564007','168139001','122571007','110522009',
   '119403008','119373006','OTH')) or (n_specimen1 in ('119297000','258450006','418564007',
   '168139001','122571007','110522009','119403008','119373006','OTH')) or (n_specimen3 in 
   ('119297000','258450006','418564007','168139001','122571007','110522009','119403008',
   '119373006','OTH'))) then
   specall=1;

clinall=0;
if (specall=1 or infall=1) and (n_species='9861002') then 
   clinall=1;     

**************** Create The SEROTYPING And VACCINE Portions Of Score *****************;

seroall=0;
if (n_serotype in ('PCV7_13','PPSV23','OTH')) then 
   seroall=1;
   
vacall=0;
if received_vax in ('Y','N','UNK') then 
   vacall=1;
   
************************** Create COMPLETENESS Variable ******************************;

score=clinall+seroall+vacall;
Complete=Int((Score/3)*100);

******************* Create DOSE VARIABLE and Look at VACCINE HISTORY *****************;

IPDvacd1=datepart(vaxdate1);
IPDvacd2=datepart(vaxdate2);
IPDvacd3=datepart(vaxdate3);
IPDvacd4=datepart(vaxdate4);
*fculture=input(frstcult,mmddyy9.);
format IPDvacd1 mmddyy9. IPDvacd2 mmddyy9. IPDvacd3 mmddyy9.
   IPDvacd4 mmddyy9. n_cdcdate mmddyy9.;
 
/* Dose does not exist for IPD */
dose=. ; /* this avoids the 'variable DOSE is not initialized' warning */

if (not missing(IPDvacd4)) then 
   dose=4; 
else if (not missing(IPDvacd3)) then
   dose=3; 
else if (not missing(IPDvacd2)) then 
   dose=2; 
else if (not missing(IPDvacd1)) then 
   dose=1; 
else if (missing(IPDvacd1)) and (missing(IPDvacd2)) and (missing(IPDvacd3))
   and (missing(IPDvacd4)) then 
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
if (not missing(IPDvacd1)) and (vaxtype1 in ('133','33','100','OTH','999')) then
   vaccin1=1;
if (not missing(IPDvacd2)) and (vaxtype2 in ('133','33','100','OTH','999')) then
   vaccin2=1;
if (not missing(IPDvacd3)) and (vaxtype3 in ('133','33','100','OTH','999')) then
   vaccin3=1;
if (not missing(IPDvacd4)) and (vaxtype4 in ('133','33','100','OTH','999')) then
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
if (not missing(IPDvacd1)) then
   vaccin1NVN=1;
if (not missing(IPDvacd2)) then 
   vaccin2NVN=1;
if (not missing(IPDvacd3)) then
   vaccin3NVN=1;
if (not missing(IPDvacd4)) then
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
case. But you need a variable for Proc Summary to sum on, so create IPDCases.
-------------------------------------------------------------------------------*/
IPDcases=1;
   do i=1 to input(n_count, BEST.);
      output;
   end;
   drop i;	
run ;

proc sort data=USIPD; by state; run;
proc freq data=USIPD noprint;
table state*year/out=IPDCases(drop=percent rename=count=IPDCases) sparse; 
run;

Proc Sort data=USIPD ;
	by Year State ;
	run ;


/*-----------------------------------------------------------------------------
Calculate the TOTAL number of CASES by Year State.
-------------------------------------------------------------------------------*/

Proc Freq Data=USIPD noprint ;
	Table State / out=StateCounts(rename=Count=Numcases drop=percent) ;
				  
	Title 'IPD Cases by Year State';
	by Year ;
	Run ;
	
/*-----------------------------------------------------------------------------
Calculate the MEAN of how COMPLETE the information is.
-------------------------------------------------------------------------------*/
Proc Means Data=USIPD noprint nway ;
																				
	var Complete ;
	Class Year State;
	output out=StateComplete (drop=_type_ _Freq_ ) Mean=MeanComplete;
	run ;

Proc Sort data=USIPD ;
	by Year State ;
	Run ;

/*----------------------------------------------------------------------------
Calculate the number of CONFIRMED cases.
----------------------------------------------------------------------------*/
Proc Freq Data=USIPD noprint ;
     Table State / out=StateConfCounts(Rename=Count=NumConfirmed drop=Percent) ;
     By Year;
     where case_status='410605003';
     run;

/*----------------------------------------------------------------------------
Compute the percentage of CONFIRMED cases with SEROGROUP TESTING.
----------------------------------------------------------------------------*/
Proc Freq data=USIPD ;
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

/*----------------------------------------------------------------------------
Note: because you're doing a frequency on the variable YEAR that's also being
done BY year and state, you'll get a warning that YEAR is already on the data
set WORK.YEARS.  You can ignore this warning.
----------------------------------------------------------------------------*/

%PctComplete(indata=USIPD,Outdata=StateComplvac, Var=Complvac, PctVar=Pct_Complete) ;
%PctComplete(indata=USIPD,Outdata=StateComplvacNVN, Var=ComplvacNVN, PctVar=Pct_ComplNVN) ;

/* Subset for cases <5 */
data usipd5;
   set usipd;
   if agegroup <3;
run;

/*-----------------------------------------------------------------------------
Calculate the TOTAL number of CASES by Year State.
-------------------------------------------------------------------------------*/

Proc Freq Data=USIPD5 noprint ;
	Table State / out=StateCounts5(rename=Count=Numcases5 drop=percent) ;
	Title 'IPD Cases <5 by Year State';
	by Year ;
	Run ;

/*-----------------------------------------------------------------------------
Calculate the MEAN of how COMPLETE the information is.
-------------------------------------------------------------------------------*/
Proc Means Data=USIPD5 noprint nway ;
	var Complete ;
	Class Year State;
	output out=StateComplete5(drop=_type_ _Freq_ ) Mean=MeanComplete5;
	run ;


/*----------------------------------------------------------------------------
Calculate the number of CONFIRMED cases.
----------------------------------------------------------------------------*/
Proc Freq Data=USIPD5 noprint ;
     Table State / out=StateConfCounts5(Rename=Count=NumConfirmed5 drop=Percent) ;
     By Year ;
     where case_status='410605003' ;
     run ;

/*----------------------------------------------------------------------------
Compute the percentage of CONFIRMED cases with SEROGROUP TESTING.
----------------------------------------------------------------------------*/
Proc Freq data=USIPD5 ;
     tables SeroAll / noprint out=StateSeroAll5(Rename=Percent=PCT_SERO5 Drop=Count) ;
     by Year State ;
     where case_status='410605003' ;
     run ;

/*-----------------------------------------------------------------------------
Compute the percentage of COMPLETE VACCINE HISTORY, where vaccine name
is and is not required.
----------------------------------------------------------------------------*/
%macro PctComplete5 (indata=, outdata=,var=,pctvar=) ;

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

%mend PctComplete5 ;

/*----------------------------------------------------------------------------
Note: because you're doing a frequency on the variable YEAR that's also being
done BY year and state, you'll get a warning that YEAR is already on the data
set WORK.YEARS.  You can ignore this warning.
----------------------------------------------------------------------------*/
%PctComplete5(indata=USIPD5,Outdata=StateComplvac5, Var=Complvac, PctVar=Pct_Complete5) ;
%PctComplete5(indata=USIPD5,Outdata=StateComplvacNVN5, Var=ComplvacNVN, PctVar=Pct_ComplNVN5) ;

	
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

Data indrpts.IPD ;
merge States (in=s)
	  StateCounts (in=c)
	  StateConfCounts(in=l)
	  StateComplete(in=cp )
	  StateComplVac(in=cv where=(ComplVac=1))
	  StateComplVacNVN(in=cvNVN where=(ComplVacNVN=1))
      StateSeroAll(in=ss where=(SeroAll=1))

	  statecounts5 (in=c5)
	  stateconfcounts5 (in=l5)
	  StateComplete5(in=cp5 )
	  StateComplVac5(in=cv5 where=(ComplVac=1))
	  StateComplVacNVN5(in=cvNVN5 where=(ComplVacNVN=1))
      StateSeroAll5(in=ss5 where=(SeroAll=1))

	  ;
by Year State ;
if s ;

if Numcases = .
     then do ;
          Numcases = 0 ;
          MeanComplete = . ;
          NumConfirmed = . ;
          Pct_Complete = . ;
          Pct_ComplNVN = . ;
          Pct_Sero = . ;

		  Numcases5 = 0 ;
          MeanComplete5 = . ;
          NumConfirmed5 = . ;
          Pct_Complete5 = . ;
          Pct_ComplNVN5 = . ;
          Pct_Sero5 = . ;
          end ;
else do ;

          if Pct_Sero = . then Pct_Sero = 0 ;     
		  if Pct_Sero5 = . then Pct_Sero5 = 0 ;  
          End ;
run ;


*validation;
*%include '\\cdc\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\Surveillance Indicators_NNAD\SAS Code\Validation\IPD validation.sas';

