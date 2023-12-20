 /* Hflu B */
 /*********************************************************************************************/
 /* Date Modified: 2021/May/07                                                                */
 /* Modified by: Hannah Fast                                                                  */
 /* Changes:    Transformed Rubella B into Hflu                                               */
 /*                                                                                           */
 /* Date Modified: 2021/May/12                                                                */
 /* Modified by: Ying Shen                                                                    */
 /* Changes: added 'OTHNOTB' in serotype                                                      */
 /*                                                                                           */
 /* Date Modified: 2022/Jan/27                                                                */
 /* Modified by: Ying Shen                                                                    */
 /* Changes: remove libname indrpts because it's defined in the create program                */
 /*********************************************************************************************/

/*libname indrpts "\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_Indicators_NNAD\Data\2021Currentdata.file";*/


/*-------------------------
Read the Hflu File.
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
data StHflu;
	set IndRpts.hl7_H_influenzae; 
	   /* only confirmed, probable, and unknown cases */
       if case_status in ('410605003','2931005','UNK');
	      /* only US states, DC, and NYC */
          if state le 56 or state=975772;   
run; 

/*------------------------------------------------------------------------------
Now create a "state" that represents the entire US so you can get totals without
extra coding.                                                                   
-------------------------------------------------------------------------------*/
Data USHflu;
	set StHflu;
	output;
	state=0;
	output;
run;

data USHflu;
   set USHflu;

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

   
********************* Create the CLINICAL CASE DEFINITION protion of Score ***********************;

*The following NETSS options are considered 'valid' for infection type, 
according to e-mail received from Amanda Faulkner on 10/5/16: 
										 

1. Primary bacteremia
2. Meningitis
3. Otitis media
4. Pneumonia
5. Cellulitis
6. Epiglottitis
7. Peritonitis
8. Pericarditis
9. Septic Abortion
10. Amnionitis
11. Septic Arthritis
13. Other
;

infall=0;
if (n_primary_bacteremia='Y') or (meningitis='Y') or (otitis_media='Y') or (pneumonia='Y') or 
   (cellulitis='Y') or (epiglottitis='Y') or (peritonitis='Y') or (pericarditis='Y') or 
   (sepsis_abortion='Y') or (n_infection_amniotic='Y') or (arthritis='Y') or 
   (bacterialinfection_oth_ynu='Y') then
   infall=1;

specall=0;
if (n_specimen1 in ('119297000','258450006','418564007','168139001','122571007','110522009',
   '119403008','119373006','OTH')) or (n_specimen1 in ('119297000','258450006','418564007',
   '168139001','122571007','110522009','119403008','119373006','OTH')) or (n_specimen3 in 
   ('119297000','258450006','418564007','168139001','122571007','110522009','119403008',
   '119373006','OTH')) then
   specall=1;

clinall=0;
if (specall=1 or infall=1) and (n_species='44470000') then 
   clinall=1;  
   
**************** Create The SEROTYPING And VACCINE Portions Of Score *****************;

seroall=0;
if (n_serotype in ('277452004','PHC1610','OTH','OTHNOTB')) then 
   seroall=1;
   
vacall=0;
if received_vax in ('Y','N','UNK') then 
   vacall=1;

************************** Create COMPLETENESS Variable ******************************;

score=clinall+seroall+vacall;
Complete=Int((Score/3)*100);


******************* Create DOSE VARIABLE and Look at VACCINE HISTORY *****************;

hibvacd1=datepart(vaxdate1);
hibvacd2=datepart(vaxdate2);
hibvacd3=datepart(vaxdate3);
hibvacd4=datepart(vaxdate4);
*fculture=input(frstcult,mmddyy9.);
format hibvacd1 mmddyy9. hibvacd2 mmddyy9. hibvacd3 mmddyy9.
   hibvacd4 mmddyy9. n_cdcdate mmddyy9.;
if (not missing(hibvacd4)) then 
   dose=4; 
else if (not missing(hibvacd3)) then
   dose=3; 
else if (not missing(hibvacd2)) then 
   dose=2; 
else if (not missing(hibvacd1)) then 
   dose=1; 
else if (missing(hibvacd1)) and (missing(hibvacd2)) and (missing(hibvacd3))
   and (missing(hibvacd4)) then 
   dose=0;
else dose=9;


**************** CREATING CATEGORICAL VARIABLE FOR VACCINE HISTORY ******************;

/*-----------------------------------------------------------------------------
This is the standard way of defining a complete vaccine.

	For vaccine name:
		1=HbOC
		2=PRP-OMP
		3=PRP-D
		4=PRP-T
		5=other*
		6=MenHibrix
		8=other
		9=unknown
	*5=other is kept as valid mapping for historical data. 8 was added in 2017 as a valid value for "other" going forward
	------------------------------------------------------------------------------*/
vaccin1=0;
vaccin2=0;
vaccin3=0;
vaccin4=0;
if (not missing(hibvacd1)) and (vaxtype1 in ('46','47','48','49','148','OTH','999')) then
   vaccin1=1;
if (not missing(hibvacd2)) and (vaxtype2 in ('46','47','48','49','148','OTH','999')) then
   vaccin2=1;
if (not missing(hibvacd3)) and (vaxtype3 in ('46','47','48','49','148','OTH','999')) then
   vaccin3=1;
if (not missing(hibvacd4)) and (vaxtype4 in ('46','47','48','49','148','OTH','999')) then
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
Define a completed VACCINE HISTORY similarly but do not include vaccine name.
NVM = No Vaccine Name.  
------------------------------------------------------------------------------*/
vaccin1NVN=0;
vaccin2NVN=0;
vaccin3NVN=0;
vaccin4NVN=0;
if (not missing(hibvacd1)) then
   vaccin1NVN=1;
if (not missing(hibvacd2)) then 
   vaccin2NVN=1;
if (not missing(hibvacd3)) then
   vaccin3NVN=1;
if (not missing(hibvacd4)) then
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
	case. But you need a variable for Proc Summary to sum on, so create HfluCases.
	-------------------------------------------------------------------------------*/
   Hflucases=1;
   do i=1 to input(n_count, BEST.);
		output;
   end;
   drop i;	
run ;

proc sort data=USHflu; by state; run;
proc freq data=USHflu noprint;
table state*year/out=HfluCases(drop=percent rename=count=HfluCases) sparse; 
run;

/*------------------------------------------------------------------------
Calculate the TOTAL number of CASES by State.  
---------------------------------------------------------------------------*/

Proc Freq Data=USHFlu noprint ;
	Table Year * State / out=StatesCounts(rename=Count=Numcases drop=percent) ;
	Run;
/*-----------------------------------------------------------------------------
Calculate the TOTAL number of CASES by State for those < 5 YEARS old.
---------------------------------------------------------------------------*/

Proc Freq Data=USHFlu ;
	Table Year * State / noprint out=StatesCountsLT5(Rename=Count=NumcasesLT5 drop=percent) ;
	Where agegroup<3;
	Title '# Cases By State for Age < 5 Year Old';
	Run;

Proc Sort data=USHflu ;
	by Year State ;
	Run ;
/*---------------------------------------------------------------------------
Calculate the MEAN of how COMPLETE the information is.
---------------------------------------------------------------------------*/
Proc Means Data=USHFlu noprint ;
	Types Year * State ; * does not compute totals but just Year * State*Complete ;
	var Complete ;
	Class Year State;
	output out=StatesComplete(drop=_type_ _Freq_ ) Mean=MeanComplete;
	run ;


/*-----------------------------------------------------------------------------
Compute the percentage of ComplVac - VACCINE COMPLETENESS
-------------------------------------------------------------------------------*/
Proc Freq data=USHFlu ;
	tables Complvac / missing list noprint out=StatesComplvac
		(rename=percent=ComplvacPct drop=count) ;
	tables ComplvacNVN / missing list noprint out=StatesComplvacNVN
		(rename=percent=ComplvacNVNPct drop=count) ;
	where agegroup < 3 ;
	By Year State ;
	run ;

Proc Freq data=USHFlu ;
     tables SeroAll / noprint out=StatesSeroAllLT5(Rename=Percent=SeroAllLT5Pct Drop=Count) ;
     By Year State ;
     where agegroup < 3 ;
     run ;
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

Data IndRpts.HFlu ;
merge States (in=s)
	  StatesCounts (in=c)
	  StatesCountsLT5(in=l)
	  StatesComplete(in=cp )
	  StatesComplVac(in=cv where=(ComplVac=1))
	  StatesComplVacNVN(in=cvNVN where=(ComplVacNVN=1))
	  StatesSeroAllLT5(in=sa where=(SeroAll=1))
	  ;
by Year State ;
if s ;

if Numcases = .
     then do ;
          Numcases = 0 ;
          NumcasesLT5 = . ;
          MeanComplete = . ;
          ComplVacPCT = . ;
          ComplVacNVNPct = . ;
          SeroAllLT5Pct = . ;
          end ;
     else do ;
          if NumcasesLT5 = . then do ;
                NumcasesLT5 = 0 ;
                *MeanComplete = . ;
                ComplVacPct = . ;
                ComplVacNVNPct = . ;
                SeroAllLT5Pct = . ;
                End ;
          Else do ;
               if MeanComplete = . then MeanComplete = 0 ;
               if ComplVacPct = . then ComplVacPct = 0 ;
               if ComplVacNVNPct = . then ComplVacNVNPct = 0 ;
               If SeroAllLT5Pct = . then SeroAllLT5Pct = 0 ;
               End ; /* if NumcasesLT5 = . else block */
          end ;
run ;

*validation;
*%include '\\cdc\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\Surveillance Indicators_NNAD\SAS Code\Validation\Hflu validation.sas';

