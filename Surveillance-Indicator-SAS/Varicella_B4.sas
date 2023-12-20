 /********************************************************************/
 /* PROGRAM NAME: Varicella Surv Indi                                */
 /* VERSION: 4.0                                                     */
 /* CREATED: 2021/04/13                                              */
 /*                                                                  */
 /* BY:  Hannah Fast                                                 */
 /*                                                                  */
 /* PURPOSE:  This program is to read data from NNAD to be used in   */
 /*           creating the Surveillance Indicator Reports            */
 /*                                                                  */ 
 /* INPUT:                                                           */                                                              
 /* OUTPUT: 		                                                   */
 /*  	     			                                                   */
 /* Date Modified: 2021Apr19                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: undrop the birthD in data both; set both step           */
 /*                                                                  */ 
 /* Date Modified: 2021Dec30                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Commented out NNAD libname because it is in the         */
 /*           main program                                           */
 /*                                                                  */ 
 /* Date Modified: 2022Mar15                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: - remove year =2021 as we can use the &EndYear in the   */
 /*            create program                                        */
 /*          - re-define this program by adding legacy and nmi       */
 /*          - create 7 indicators for nmi                           */
 /*                                                                  */
 /* Date Modified: 2022/Mar/18                                       */
 /* Modified by: Ying Shen                                           */
 /* Changes: Updated the code of 'New York City' from 975771 to 975772*/
 /*                                                                  */
 /* Date Modified: 2023/Feb/23                                       */
 /* Modified by: Ying Shen                                           */
 /* Changes: Change year=mmwr_year because mmwr_year is a numerical  */
 /*          value, input() can only convert characters              */
 /*                                                                  */
 /* Date Modified: 2023/DEC/04                                       */
 /* Modified by: Ying Shen                                           */
 /* Changes: Change MVPSdata\qsrv1 to MVPSdata,1201\qsrv1            */
 /********************************************************************/




/*Below codes are for Legacy data from MVPS Data Mart*/
libname CDS OLEDB
        provider="sqloledb"
        properties = ( "data source"="MVPSdata,1201\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="CDSR_DM_VARICELLA" ) 
        schema=DBO access=readonly;

/*Bring in CDS data mart data*/
proc sql;
create table var_case_data_dm as
select source_system_name, Case_Local_ID, Legacy_Case_ID, Jurisdiction_Cd, Condition_Cd, Condition_Cd_Desc ,MMWR_YEAR ,MMWR_WEEK  
	,Case_Status_Cd ,Case_Status_Cd_Desc ,Birth_Dt ,Age_at_Investigation ,AGE_AT_INV_UOM_CD ,AGE_AT_INV_UOM_CD_DESC  
	,RECEIVE_VAR_CONTAIN_VACCINE_IND ,NBR_LESIONS_CD ,NBR_LESIONS_CD_DESC ,HOSPITALIZED_IND  
	,OUTBREAK_IND ,Lab_Test_For_VAR_Ind ,CULT_RESULT_CD_DESC ,DFA_TEST_RESULT_CD_DESC ,IGM_TEST_RESULT_CD_DESC ,PCR_RESULT_CD_DESC 
   ,Current_Global_Rec_Flag ,Natl_Rptg_Jurisdiction_Cd ,Natl_Rptg_Jurisdiction_Cd_Desc ,nnd_reporting_state_cd_fips ,update_notification_dt 
   ,current_case_data_uid ,cds_dm_create_dt
   from CDS.var_case_data
   where current_global_rec_flag='Y';
   quit;

   Data var_case_data_dm
    (keep= source_system_name Case_Local_ID Legacy_Case_ID Jurisdiction_Cd Condition_Cd Condition_Cd_Desc MMWR_YEAR MMWR_WEEK  
	Case_Status_Cd Case_Status_Cd_Desc Birth_Dt Age_at_Investigation AGE_AT_INV_UOM_CD AGE_AT_INV_UOM_CD_DESC  
	RECEIVE_VAR_CONTAIN_VACCINE_IND NBR_LESIONS_CD NBR_LESIONS_CD_DESC HOSPITALIZED_IND  
	OUTBREAK_IND Lab_Test_For_VAR_Ind CULT_RESULT_CD_DESC DFA_TEST_RESULT_CD_DESC IGM_TEST_RESULT_CD_DESC PCR_RESULT_CD_DESC 
    Current_Global_Rec_Flag Natl_Rptg_Jurisdiction_Cd Natl_Rptg_Jurisdiction_Cd_Desc nnd_reporting_state_cd_fips update_notification_dt current_case_data_uid cds_dm_create_dt);
  set CDS.var_case_data;
  where current_global_rec_flag='Y';
  RUN;


/*Convert MMWR_year from character to numeric*/
  data var_case_data_dm2;
	set var_case_data_dm;
	temp_column = input (mmwr_year, 4.);
	attrib temp_column format= 4. informat=4.;
	drop mmwr_year;
	rename temp_column=mmwr_year;
  RUN;

/* Filter CDS datamart data by year and case status*/
Data varmart;
	set var_case_data_dm2;
	where mmwr_year >= &StartYear and mmwr_year <= &EndYear
   and case_status_CD not in ('PHC178', '415684004', 'unk', 'Unk', 'UNK');
  RUN;

/*Save out dataset for re-use, if needed*/
  data IndRpts.Datamartcases_&EndYear;
	set varmart;
  RUN;

proc freq data=varmart;
  table natl_rptg_jurisdiction_cd_desc/nocol norow nopercent list missing;
  table Case_Status_Cd;
  title "TOTAL NUMBER OF VARICELLA CASES &year - Datamart (HL7)";
  run;


PROC FORMAT; VALUE AGE .,9999='UNK' 0='<1' 1-4='1-4' 5-9='5-9' 10-14='10-14' 15-19='15-19' 20-999='20+'; RUN;

/* Create matching variables, remove territories from data mart, create variable for length of local case id */
Data marttemp;
set IndRpts.Datamartcases_&EndYear;
/*	set varicella_2021;*/

	if natl_rptg_jurisdiction_cd = " " then natl_rptg_jurisdiction_cd = nnd_reporting_state_cd_fips;
	state=input(natl_rptg_jurisdiction_cd, 6.);
/*	year=input(mmwr_year, 4.);*/
	year=mmwr_year;
	event=input(condition_cd, 5.);
	birthd=datepart(birth_dt);
	format birthd mmddyy10.;  

/*	IF (STATE NE 70 ) AND STATE > 59 THEN DELETE;*/

	id_length=length(case_local_id);

RUN;

/* Prepare data mart for merge */
Data varmart_merge;
  set marttemp;
  
  IF state in (1, 5, 11, 18, 21, 22, 23, 24, 30, 31, 35, 44, 45, 47, 50, 51, 54, 56) and id_length = 15
        then id=input(substr(case_local_id,6,6),6.);
        
		else if state in (2, 10, 15, 27, 45) and id_length = 9 then id=input(substr(case_local_id,4,6),6.);
		else if state = 2 and id_length = 15 then id=input(substr(case_local_id,6,6),6.);
		else if state in (20, 26, 29) and id_length = 10 then id=input(substr(case_local_id,5,6),6.);	
		else if state = 26 and id_length = 11 then id=input(substr(case_local_id,6,6),6.); *new;	
/*		else if state = 18 and id_length = 13 then id=input(substr(case_local_id,1,6),6.); retained for historical documentation	*/
		else if mmwr_year le 2018 and state = 18 and id_length = 13 then id=input(substr(case_local_id,1,6),6.);		
		else if mmwr_year = 2016 and state = 33 then id=input(substr(legacy_case_id,1,5),6.); *new;
		else if mmwr_year ge 2019 and state = 32 and id_length =15 then id=input(substr(case_local_id,6,6),6.);
		else if state = 33 and id_length = 8  then id=input(substr(case_local_id,3,6),6.);	
		else if state = 33 and id_length = 9  then id=input(substr(case_local_id,4,6),6.); *new;
		else if state = 48 and id_length = 16 then id=input(substr(case_local_id,7,6),6.);		
		else if state = 55 and id_length = 7  then id=input(substr(case_local_id,2,6),6.);	
	    else if mmwr_year le 2016 and state = 17 and id_length = 25 and legacy_case_id NE ' ' then id=input(substr(legacy_case_id,1,6),6.);
		else if state = 17 and id_length = 25 then id=input(substr(case_local_id,20,6),6.); *new;
		else id=input(substr(case_local_id,1,6),6.);
RUN;


/* Code to look at the DataMart cases with any of the 5 merge variables missing */
Data varmart_merge_nomiss varmart_merge_miss;
  set varmart_merge;
  if state NE . 
  and year NE .
  and id NE .
  and birthd NE . 
  and event NE .
  then output varmart_merge_nomiss;
  else output varmart_merge_miss;
RUN;

** This will show you which of the 5 variables is missing for varmart;
proc summary Data=varmart_merge_miss;
	VAR state year id event;
	title 'proc summary of varmart with any of the 5 variables missing';
	Output NMiss= Out=charset;
RUN;


/*Prepare the dataset from legacy*/
data Raw_Varicella_HL7_legacy(drop = Update_Notification_Dt Legacy_Case_ID Jurisdiction_Cd CULT_RESULT_CD_DESC DFA_TEST_RESULT_CD_DESC 
						IGM_TEST_RESULT_CD_DESC PCR_RESULT_CD_DESC birth_dt nnd_reporting_state_cd_fips);
	set varmart_merge_nomiss;
	mmwr_yearn=input(mmwr_year, 4.);
	condition_cdn=input(condition_cd, 5.);
	natl_rptg_jurisdiction_cdn=input(natl_rptg_jurisdiction_cd, 10.);
	expanded_caseidn=input(expanded_caseid, $50.);
	drop mmwr_year condition_cd natl_rptg_jurisdiction_cd expanded_caseid ;
	rename mmwr_yearn=mmwr_year;
	rename condition_cdn=condition_cd;
	rename natl_rptg_jurisdiction_cdn=natl_rptg_jurisdiction_cd;
	rename expanded_caseidn=expanded_caseid;
run;

/*Reformat*/
PROC FORMAT;

VALUE STATE      
0='Total' 
1='Alabama'                                                    
2='Alaska'                                                     
4='Arizona'                                                    
5='Arkansas'                                                   
6='California'                                                 
8='Colorado'                                                   
9='Connecticut'                                                
10='Delaware'                                                   
11='Dist of Columbia'                                           
12='Florida'                                                    
13='Georgia'                                                    
15='Hawaii'                                                     
16='Idaho'                                                      
17='Illinois'                                                   
18='Indiana'                                                    
19='Iowa'                                                       
20='Kansas'                                                     
21='Kentucky'                                                   
22='Louisiana'                                                  
23='Maine'                                                      
24='Maryland'                                                   
25='Massachusetts'                                              
26='Michigan'                                                   
27='Minnesota'                                                  
28='Mississippi'                                                
29='Missouri'                                                   
30='Montana'                                                    
31='Nebraska'                                                   
32='Nevada'                                                     
33='New Hampshire'                                              
34='New Jersey'                                                 
35='New Mexico'                                                 
36='New York'                                                   
37='North Carolina'                                                 
38='North Dakota'                                                   
39='Ohio'                                                       
40='Oklahoma'                                                   
41='Oregon'                                                     
42='Pennsylvania'                                               
44='Rhode Island'                                               
45='South Carolina'                                                 
46='South Dakota'                                                   
47='Tennessee'                                                  
48='Texas'                                                      
49='Utah'                                                       
50='Vermont'                                                    
51='Virginia'                                                   
53='Washington'                                                 
54='West Virginia'                                                 
55='Wisconsin'                                                  
56='Wyoming'                                                    

60='American Samoa'                                                   				
66='Guam'                                                       
69='Northern Marianna Islands'                                          
975772='New York City'                                              
72='Puerto Rico'                                                                
75='Chicago'                                                                    
78='Virgin Islands'      
                ;

value pctcomp 
low-<0 = 'NA'  /* negative numbers get a NA */
0='0' 
0<-<1 = '0'
1-high=[3.]
;
run ;



/*data mart legacy starts*/
/*-------------------------------------------------------------------------------
Identify the total number of varicella cases.  This will become the denominator
for all the frequency percentages that are computed later.  
-------------------------------------------------------------------------------*/
Data Varicella_legacy ;
	set Raw_Varicella_HL7_legacy (rename=Natl_Rptg_Jurisdiction_Cd_Desc=StateName);
     If Case_Status_CD in ("2931005" "410605003") ; 
	Numcases = 1 ;
	
	/*----------------------------------------------------------------------------
	Compute Age in Years.
	----------------------------------------------------------------------------*/
	IF AGE_AT_INVESTIGATION=999 THEN AGE=.;
     ELSE IF AGE_AT_INV_UOM_CD IN ('a' 'y') THEN AGE=AGE_AT_INVESTIGATION;
     ELSE IF AGE_AT_INV_UOM_CD = 'd' AND AGE_AT_INVESTIGATION < 365 THEN AGE=0;
     ELSE IF AGE_AT_INV_UOM_CD = 'd' AND AGE_AT_INVESTIGATION GE 365 THEN AGE= INT(AGE_AT_INVESTIGATION/365) ;
     ELSE IF AGE_AT_INV_UOM_CD = 'wk' AND AGE_AT_INVESTIGATION < 53 THEN AGE=0;
     ELSE IF AGE_AT_INV_UOM_CD ='wk' AND AGE_AT_INVESTIGATION GE 53 THEN AGE=INT(AGE_AT_INVESTIGATION/53);
     ELSE IF AGE_AT_INV_UOM_CD IN ('m' 'mo') AND AGE_AT_INVESTIGATION < 12 THEN AGE=0; 
     ELSE IF AGE_AT_INV_UOM_CD IN ('m' 'mo') AND AGE_AT_INVESTIGATION GE 12 THEN AGE=INT(AGE_AT_INVESTIGATION/12);
     Else Age = . ;
     
     /*----------------------------------------------------------------------------
     Calculate the value of state based on its state name so that it matches how 
     the other pathogens define STATE.
     ----------------------------------------------------------------------------*/
     Do i = 1 to 78  ;  
          if StateName = put(i,state.) then do ; State = i ; leave ; end ;
     end ;
	output ;
	/*----------------------------------------------------------------------------
	
	----------------------------------------------------------------------------*/
	State = 0 ; *'Total' ;
	output ;
     drop i ;
	run ;

Proc Sort Data=Varicella_legacy ;
	by Year State ;
	run ;

Proc Summary Data=Varicella_legacy NWAY ;
     Var NumCases ;
     Class Year State ;
     Output out=Numcases_HL7 (drop=_:) Sum=NumCases_HL7 ;
     run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that have a value of age that is not missing
by year and state.  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_legacy noprint ;
	by Year State ;
	tables Age / missing out=Age_HL7 ;
	run ;

/*-------------------------------------------------------------------------------
Since the percentage you want is the aggregation of records with a non-missing   
value for age, sum up the percentages. 
-------------------------------------------------------------------------------*/
Proc Summary data = Age_HL7 nway ;
	var Percent ;
	Class Year State ;
     output out=AgePct_HL7(drop=_type_ _freq_ ) sum=AgePct_HL7 ;
	Where Age ne . ;  
	run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that have complete information on the number 
of lesions (no blanks or unknowns).  Denominator is the total number of cases.
Since there's more than 1 value for Nbr_Lesions_CD we have to add the percentages
of each value that we care about.  
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_legacy noprint ;
	by Year State;
	tables Nbr_Lesions_CD / missing out=Lesions_HL7 ;
	run ;

Proc Summary data =Lesions_HL7 nway ;
	var Percent ;
	Class Year State ;
     output out=LesionsPct_HL7(drop=_type_ _freq_ ) sum=LesionsPct_HL7 ;
	Where Nbr_Lesions_CD not in (' ');
	run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that have complete information on  
hospitalization (no blanks or unknowns).  Denominator is the total number of
cases.
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_legacy noprint ;
	by Year State ;
	tables Hospitalized_Ind / missing out=Hospitalized_HL7 ;
	run ;

Proc Summary data = Hospitalized_HL7 nway ;
	var Percent ;
	Class Year State ;
	output out=HospPct_HL7(drop=_type_ _freq_ ) sum=HospPct_HL7 ;
	Where Hospitalized_Ind not in (' ') ;
	run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that are confirmed (e.g.
where=(Case_Status_Cd = '410605003').  This code calculates the percentages for 
all values of Case_Status_CD but outputs only the one we want.  Denominator is 
the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_legacy noprint ;
	by Year State;
	tables Case_Status_CD / missing out=CaseConfirmedPct_HL7 
	(rename=Percent=CaseConfirmedPCt_HL7 where=(Case_Status_Cd = '410605003')) ;
	run ;


/*-------------------------------------------------------------------------------
Calculate the percentage of entries that had laboratory testing performed
(Lab_Test_Ind = 'Y' only).  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_legacy noprint ;
	by Year State;
	tables Lab_Test_for_VAR_Ind  / missing out=LabTestsPct_HL7 
            (rename=Percent=LabTestsPct_HL7 where=(Lab_Test_for_Var_Ind = 'Y')) ;
	run ;
/*-------------------------------------------------------------------------------
Calculate the percentage of entries that related to outbreaks 
(Outbreak_Ind = 'Y' only).  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq Data = Varicella_legacy noprint ;
	by Year State;
	tables Outbreak_Ind  / missing out=OutbreakPct_HL7 
	(rename=Percent=OutbreakPct_HL7 where=(Outbreak_Ind = 'Y'));
	run ;


/*-------------------------------------------------------------------------------
Calculate the percentage of entries with complete information on vaccine history
(no blanks or unknowns).  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq Data = Varicella_legacy noprint ;
	by Year State;
	tables Receive_VAR_Contain_Vaccine_IND  / missing out=VacHistory_HL7;
run ;

Proc Summary data = VacHistory_HL7 nway ;
	var Percent ;
	Class Year State;
	output out=VacHistoryPct_HL7(drop=_type_ _freq_ ) sum=VacHistoryPct_HL7 ;
	Where Receive_VAR_Contain_Vaccine_IND not in (' ','UNK');
	run ;

/*-------------------------------------------------------------------------------
Create a dataset with all the state values so that if one state has no cases 
we'll still have an entry for them.  
-------------------------------------------------------------------------------*/

data States ;
	length State 8 ;
     do Year = &StartYear to &EndYear ;
	do state = 0 to 975772 ;
      StateName = put(state,state.) ;  * Not sure if we use this, but it is here nonetheless ;
     	if state in (3,7,14,43,52,79-975771) then continue ; * these state codes are not defined ;	
      if state le 79 or state = 975772 then output ;     
	end ;
     End ;
Run ;

Proc Sort data=States ;
     by Year State ;
     run ;


/*-------------------------------------------------------------------------------
Now combine all the information together 
-------------------------------------------------------------------------------*/

data indrpts.Varicella_legacy ;
     merge
     States (in=s)
     NumCases_HL7 (in=n)  
     AgePct_HL7 (in=a) 
     LesionsPct_HL7 (in=l)
     HospPct_HL7(in=hosp)
     CaseConfirmedPct_HL7(in=case drop=count)
     LabTestsPct_HL7(in=lab drop=count)
     OutbreakPct_HL7 (in=out drop=count)
     VacHistoryPct_HL7(in=vac)
     ;
     by Year State;
     if s ;

 if numcases_HL7 = .
 	then do;
		numcases_HL7 = 0;
		AgePct_HL7 = .;
		LesionsPct_HL7= .;
		HospPct_HL7= .;
		CaseConfirmedPct_HL7= .;
		LabTestsPct_HL7= .;
		OutbreakPct_HL7= .;
		VacHistoryPct_HL7= .;
		end;
	else do;
		if AgePct_HL7 = . then AgePct_HL7 = 0;
		if LesionsPct_HL7= . then LesionsPct_HL7= 0;
		if HospPct_HL7= . then HospPct_HL7= 0;
		if CaseConfirmedPct_HL7= . then CaseConfirmedPct_HL7= 0;
		if LabTestsPct_HL7= . then LabTestsPct_HL7= 0;
		if OutbreakPct_HL7= . then OutbreakPct_HL7= 0;
		if VacHistoryPct_HL7= . then VacHistoryPct_HL7= 0;
		end;
     run ;
/*Data mart legacy ends*/


/*----------------------------------------------------------------------------*/
/*Get the NMI data from NNAD stage4 starts*/
/*----------------------------------------------------------------------------*/


DATA stVaricella;
	set IndRpts.HL7_varicella; 
	* only confirmed and probable cases;
	If case_status in ('410605003','2931005') ;
	Numcases = 1 ;
	* only US states, DC, and NYC ;
	if state le 56 or state = 975772;
	
run;

/*------------------------------------------------------------------------------
Now create a "state" that represents the entire US so you can get totals without
extra coding.                                                                   
-------------------------------------------------------------------------------*/
Data USVaricella;
	set StVaricella;
	output;
	state = 0;
	output;
	Run;

/*---------------
Prepare 7 key variables
-----------------*/

data Varicella_nmi;
set USVaricella;

*1. Cases with Complete Information on Age;
ageok = 0;
if birth_dt ne . or (age_invest ne . and age_invest_units in ('a','d','mo','wk')) then ageok = 1;

*2. Cases with Complete Information on Number of Lesions;
lesion = 0;
if num_lesions in ('PHC223','PHC224','PHC225','PHC1437','UNK') then lesion = 1;
else if num_lesions = 'PHC222' and num_lesions_specify ne . then lesion = 1;

*3. hospitalizaiton/complications inforamtion;
hosp = 0;
if hospitalized in ('N','UNK') then hosp = 1; *include other varicella hospitalization variables (from reason for hospitalization)?;
if hospitalized = 'Y' and (0 < days_in_hosp < 999 or days_in_hosp =.Y) then hosp = 1; 


*4. case_status;
case_conf = 0;
if case_status in ('410605003') then case_conf = 1; 

*5. case with lab testing;
lab = 0;
if lab_test_done in ('Y') then lab = 1;
if lab_confirmed in ('Y') then lab = 1;
if im_ts_1 not in (' ') then lab =1;
if im_unk_1 not in (' ') then lab =1;
if im_urine_1 not in (' ') then lab =1;
if im_vescswab_1 not in (' ') then lab =1;
if im_vesfluid_1 not in (' ') then lab =1;
if pcr_blood_1 not in (' ') then lab =1;
if pcr_crust_1 not in (' ') then lab =1;
if pcr_csf_1 not in (' ') then lab =1;
if pcr_im_1 not in (' ') then lab =1;
if pcr_lavage_1 not in (' ') then lab =1;
if pcr_lesion_1 not in (' ') then lab =1;
if pcr_lsn_swab_1 not in (' ') then lab =1;
if pcr_nsl_swab_1 not in (' ') then lab =1;
if pcr_scab_1 not in (' ') then lab =1;
if pcr_serum_1 not in (' ') then lab =1;
if pcr_swab_1 not in (' ') then lab =1;
if pcr_tissue_1 not in (' ') then lab =1;
if pcr_ts_1 not in (' ') then lab =1;
if pcr_urine_1 not in (' ') then lab =1;
if pcr_vesfluid_1 not in (' ') then lab =1;
if typing_blood_1 not in (' ') then lab =1;
if typing_crust_1 not in (' ') then lab =1;
if typing_csf_1 not in (' ') then lab =1;
if typing_im_1 not in (' ') then lab =1;
if typing_lesion_1 not in (' ') then lab =1;
if typing_lsn_swab_1 not in (' ') then lab =1;
if typing_saliva_1 not in (' ') then lab =1;
if typing_scab_1 not in (' ') then lab =1;
if typing_serum_1 not in (' ') then lab =1;
if typing_tissue_1 not in (' ') then lab =1;
if typing_vescswab_1 not in (' ') then lab =1;
if typing_vesfluid_1 not in (' ') then lab =1;



*6. case related to outbreak;
outbreak=0;
/*if outbreak_assoc in ('N','UNK') then outbreak = 1; */
if outbreak_assoc = 'Y' then outbreak = 1;
/*if outbreak_assoc = 'Y' and outbreak_name ne ' ' then outbreak = 1;*/

*7. Cases with Complete Information on Vaccine History;
vac = 0;
if received_vax in ('Y') then vac = 1;
if vaxdate1 not in (' ') then vac = 1;
if vaxtype1 not in (' ') then vac = 1;
if vaxmfr1 not in (' ') then vac = 1;

run;



/*-----------------------------------------------------------------------------
Calculate the Percentage of completed records based on the score from the 
7 indicator variables.  
-------------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*/
/*calculate the total number of cases*/
/*----------------------------------------------------------------------------*/
Proc Sort Data=Varicella_nmi;
	by Year State ;
	run ;

Proc Summary Data=Varicella_nmi NWAY ;
     Var NumCases ;
     Class Year State ;
     Output out=Numcases_nmi (drop=_:) Sum=NumCases_nmi ;
     run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that have a value of age that is not missing
by year and state.  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_nmi noprint ;
	by Year State ;
	tables AgeOK / missing out=Age_nmi ;
	run ;

Proc Summary data = Age_nmi nway ;
	var Percent ;
	Class Year State ;
     output out=AgePct_nmi(drop=_type_ _freq_ ) sum=AgePct_nmi ;
	Where AgeOK=1 ;  
	run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that have complete information on the number 
of lesions (no blanks or unknowns).  Denominator is the total number of cases.
Since there's more than 1 value for Nbr_Lesions_CD we have to add the percentages
of each value that we care about.  
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_nmi noprint ;
	by Year State;
	tables lesion / missing out=Lesions_nmi ;
	run ;

Proc Summary data =Lesions_nmi nway ;
	var Percent ;
	Class Year State ;
     output out=LesionsPct_nmi(drop=_type_ _freq_ ) sum=LesionsPct_nmi ;
	Where lesion=1;
	run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that have complete information on  
hospitalization (no blanks or unknowns).  Denominator is the total number of
cases.
-------------------------------------------------------------------------------*/
Proc freq data = Varicella_nmi  noprint ;
	by Year State ;
	tables hosp / missing out=Hospitalized_nmi ;
	run ;

Proc Summary data = Hospitalized_nmi nway ;
	var Percent ;
	Class Year State ;
	output out=HospPct_nmi(drop=_type_ _freq_ ) sum=HospPct_nmi ;
	Where hosp=1;
	run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that are confirmed (e.g.
where=(Case_Status_Cd = '410605003').  This code calculates the percentages for 
all values of Case_Status_CD but outputs only the one we want.  Denominator is 
the total number of cases.
-------------------------------------------------------------------------------*/

Proc freq data = Varicella_nmi  noprint ;
	by Year State ;
	tables case_conf / missing out=CaseConfirmed_nmi ;
	run ;

Proc Summary data = CaseConfirmed_nmi nway ;
	var Percent ;
	Class Year State ;
	output out=CaseConfirmedPct_nmi(drop=_type_ _freq_ ) sum=CaseConfirmedPct_nmi ;
	Where case_conf=1;
	run ;


/*-------------------------------------------------------------------------------
Calculate the percentage of entries that related to outbreaks 
(Outbreak_Ind = 'Y' only).  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq Data = Varicella_nmi noprint ;
	by Year State;
	tables outbreak  / missing out=Outbreak_nmi;
	run ;

Proc Summary data = Outbreak_nmi nway ;
	var Percent ;
	Class Year State ;
	output out=OutbreakPct_nmi(drop=_type_ _freq_ ) sum=OutbreakPct_nmi ;
	Where outbreak=1;
	run ;


/*-------------------------------------------------------------------------------
Calculate the percentage of entries with complete information on vaccine history
(no blanks or unknowns).  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq Data = Varicella_nmi noprint ;
	by Year State;
	tables vac  / missing out=VacHistory_nmi;
run ;

Proc Summary data = VacHistory_nmi nway ;
	var Percent ;
	Class Year State;
	output out=VacHistoryPct_nmi(drop=_type_ _freq_ ) sum=VacHistoryPct_nmi ;
	Where vac=1;
	run ;

/*-------------------------------------------------------------------------------
Calculate the percentage of entries that had laboratory testing performed.  Denominator is the total number of cases.
-------------------------------------------------------------------------------*/
Proc freq Data = Varicella_nmi noprint ;
	by Year State;
	tables lab  / missing out=LabTests_nmi;
run ;

Proc Summary data = LabTests_nmi nway ;
	var Percent ;
	Class Year State;
	output out=LabTestsPct_nmi(drop=_type_ _freq_ ) sum=LabTestsPct_nmi ;
	Where lab=1;
	run ;

/*----------------------------------------------------------------------------*/
/*End of NNAD stage4 NMI*/
/*----------------------------------------------------------------------------*/


/*-------------------------------------------------------------------------------
Now combine all the information together 
-------------------------------------------------------------------------------*/

data indrpts.Varicella_nmi ;
     merge
     States (in=s)
     NumCases_nmi (in=n)  
     AgePct_nmi (in=a) 
     LesionsPct_nmi (in=l)
     HospPct_nmi(in=hosp)
     CaseConfirmedPct_nmi(in=case )
     LabTestsPct_nmi(in=lab)
     OutbreakPct_nmi (in=out)
     VacHistoryPct_nmi(in=vac)
     ;
     by Year State;
     if s ;

 if numcases_nmi = .
 	then do;
		numcases_nmi = 0;
		AgePct_nmi = .;
		LesionsPct_nmi= .;
		HospPct_nmi= .;
		CaseConfirmedPct_nmi= .;
		LabTestsPct_nmi= .;
		OutbreakPct_nmi= .;
		VacHistoryPct_nmi= .;
		end;
	else do;
		if AgePct_nmi = . then AgePct_nmi = 0;
		if LesionsPct_nmi= . then LesionsPct_nmi= 0;
		if HospPct_nmi= . then HospPct_nmi= 0;
		if CaseConfirmedPct_nmi= . then CaseConfirmedPct_nmi= 0;
		if LabTestsPct_nmi= . then LabTestsPct_nmi= 0;
		if OutbreakPct_nmi= . then OutbreakPct_nmi= 0;
		if VacHistoryPct_nmi= . then VacHistoryPct_nmi= 0;
		end;
     run ;


/*End of Varicella include program*/
