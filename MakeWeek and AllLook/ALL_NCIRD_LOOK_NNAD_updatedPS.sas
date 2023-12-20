/*****************************************************************************/
/*PROGRAM NAME:  ALL_NCIRD_LOOK_NNAD                                         */
/*VERSION: 1.0                                                               */
/*CREATED: 2021/8/6                                                          */
/*                                                                           */
/*BY: Ying Shen based on ALL_NCIRD_LOOK netss program SANDY ROUSH (8/2005)   */
/*PURPOSE:  PRODUCES TABLES OF THE CASE COUNTS BY DISEASE                    */
/*                      FOR THE ENTIRE U.S. FROM HISTORICAL, CURRENT,        */
/*                      OR WEEK 52                                           */
/*                                                                           */
/* INPUT:  NNAD DATABASE - ALLVPD                                            */
/*                                                                           */
/* OUTPUT: different spreadsheets by pathogens   		                       */
/*                                                                           */
/* Date Modified: 2022/1/3                                                   */
/* Modified by: Ying Shen                                                    */
/* Changes: Added the deduplication and removed "not a case"                 */
/*                                                                           */
/*****************************************************************************/


*Enter year of interest and type of data (e.g., WK52, FINAL, CURRENT) in macro statements below;
%Let year=2021;
%Let libname = NNAD;

/*Update the output location for excel spreadsheets*/
%Let output = \\cdc\project\NIP_Project_Store1\Surveillance\SAS_output\2020-2021 NNAD;

*make sure that you have created a folder within: \\cdc\project\NIP_Project_Store1\Surveillance\SAS_output 
named with the following convention: &year-&libname nndss look output
so that the output goes to the correct folder on the sharedrive ;

*do not edit these macro statements;
%Let Yr = %substr(&Year,3,2) ;
%put Year=&Year Yr=&YR ;


*This line connects to the NNAD database; 
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;

/*libname WK53 "\\cdc\csp_project\NCIRD_MB00\swr1\NETSS\WK5221" access=readonly ;*/
/*libname FINAL "\\cdc\csp_project\NCPHI_DISSS_NNDSS_NCIRD\History" access=readonly ;*/
/**/
/**/
PROC FORMAT;

VALUE AGE 1 = 'UNDER 1'
          2 = '1-4'
          3 = '5-9'
          4 = '10-14 '
          5 = '15-19 '
          6 = '20-25 '
          7 = '26-29 '
          8 = '30-39 '
          9 = '40-49 '
          10 = '50-59 '
          11 = '60-69 '
          12 = '70 + '
          13 = 'UNKNOWN'
          14 = 'AGE NOT REPORTED'
		  99 = 'INVALID AGE CALCULATION';

VALUE AGEPERT 1 = 'UNDER 1'
              2 = '1-4'
              3 = '5-6'
              4 = '7-14 '
              5 = '15-19 '
              6 = '20-25 '
              7 = '26-29 '
              8 = '30-39 '
              9 = '40-49 '
              10 = '50-59 '
              11 = '60-69 '
              12 = '70 + '
              13 = 'UNKNOWN'
              14 = 'AGE NOT REPORTED'
			  99 = 'INVALID AGE CALCULATION';

VALUE $ EVENT '10040'='DIPHTHERIA'
			'10590'='HAEMOPHILUS INFLUENZAE'
			'11061'='INFLUENZA ASSOC PED MORT'
			'11723'='IPD-ALL AGES'
			'11720'='S PNEUMO, DRUG RESIST'
			'11717'='S PNEUMO, AGE < 5'
			'10490'='LEGIONELLOSIS'
			'10140'='MEASLES'
			'10150'='MENINGOCOCCAL DISEASE'
			'10180'='MUMPS'
			'11062'='NOVEL INFLUENZA A'
            '10190'='PERTUSSIS'
            '10410'='POLIO, PARALYTIC'
            '10405'='POLIO, NON-PARALYTIC'
			'10450'='PSITTACOSIS'
            '10200'='RUBELLA'
			'10370'='CRS'
            '10575'='SARS-COV'
			'11700'='STSS'           
            '10210'='TETANUS'
            '10030'='VARICELLA'

			'10110'='HEPATITIS A'             
            '10100'='HEPATITIS B'
			'10104'='HEP B, PERINATAL'
			'10380'='HANSEN DISEASE'
			'10390'='LEPTOSPIROSIS'
            '10650'='OTHER BACTERIAL MENINGITIS'
			'10520'='TSS OTHER THAN STREP'
			'10640'='LISTERIOSIS'
			'11563'='STEC'
			'10010'='ASEPTIC MENINGITIS'
			'11060'='INFLUENZA, HUMAN ISOLATES'
			'11070'='INFLUENZA, ANIMAL ISOLATES'
			'11661'='MRSA aka ORSA'
			'11710'='STREP, INV, GRP A'
			'11715'='STREP, INV, GRP B'
			'11716'='STREP, INV, OTHER';

VALUE $ SEX "M" = 'MALE'
          "F" = 'FEMALE'
          "U" = 'UNKNOWN'
          other = 'OTHER RESPONSES';
			

VALUE $ STAT '410605003' = 'CONFIRMED'
           '2931005' = 'PROBABLE'
           '415684004' = 'SUSPECT'
           'UNK' = 'UNK STATUS';
run;

/**set 'WK52' dataset for year of interest;*/
/*data wk52;*/
/*set nnad.Stage4_NNDSScasesT1;*/
/*if condition = 11065 then delete;*/
/*if mmwr_year=&year;*/
/*run;*/
/**/
/**set 'final' dataset for year of interest;*/
/*data final;*/
/*set final.Stage4_NNDSScasesT1;*/
/*if mmwr_year=&year;*/
/*run;*/

*set 'current' dataset for year of interest;
/*data current;*/
/*set current.Stage4_NNDSScasesT1;*/
/*if mmwr_year=&year;*/
/*run;*/

/*Retrieve the dataset from NNAD*/
proc sql;
create table nnad_org as
select * 
,mmwr_year as year
,mmwr_week as week
,age_invest as age
,age_invest_units as agetype
,condition as event
,sex
,case_status as CASSTAT
,report_jurisdiction as state
,N_rectype as rectype
,n_count as count
,disease_acquired as import

from nnad.Stage4_NNDSScasesT1
where mmwr_year = "&year"
and condition not in ("11065");
quit;


/* DEDUPLICATION AND DATA CLEANING FOR NNAD STAGE4 DATA*/
/*Note: If CASEID=0 for multiple cases in NETSS(with the same mmwr_year, report_jurisdiction and site),the code below that states "((source_system=1) and (WSYSTEM NE 5))" may dedup in a non-preferred way. */
/*For such situations, you may see unexpected drops in case numbers before and after deduplications. */
/*For such situations, it is recommended that you refer to the dataset before the dedup steps to review the detailed messages. That review will inform your determination about any coding changes needed for the missing NETSS identifier. */

data stage4_nonerror error_nokey;
   set nnad_org;
  
   if (source_system in (5,15)) then 
      firstkey=cats(report_jurisdiction,compress(local_record_id)); /* For HL7 records, look at local_record_id */
   else if ((source_system=1) and (WSYSTEM=5)) then
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* For NETSS records created from MVPS, look at n_expandedcaseid */  
   else if ((source_system=1) and (WSYSTEM NE 5)) then
      firstkey=cats(report_jurisdiction,compress(local_record_id),site,mmwr_year); /* For other NETSS records, look at local_record_id (CASEID), site, mmwr_year */

   output stage4_nonerror;

   if (firstkey = '') then
      output error_nokey;
run;
proc sort tagsort data=stage4_nonerror;
   by firstkey descending source_system descending n_cdcdate; /* Prefer HL7 record over NETSS duplicate, newer NETSS record over older */
run;

/* Duplicates by match of local_record_id/n_expandedcaseid are removed, and remove "Not a cases"*/
data nnad stage4_remove;
   set stage4_nonerror;
   by firstkey;

   if ((first.firstkey) and (result_status NE 'X') and (case_status NE 'PHC178')) then
      output nnad;
   else 
      output stage4_remove;
run;


/*Change data format. Convert count from character to numeric*/
%macro char2num(formn,charclm);
data &formn;
	set &formn;
	temp_column = input (&charclm, 8.);
	attrib temp_column format= 8. informat=8.;
	drop &charclm;
	rename temp_column=&charclm;
run;
%mend char2num;

%char2num(nnad,count);
/*%char2num(nnad,casstat);*/
/*%char2num(nnad,sex);*/
%char2num(nnad,age);

*set dataset for type of data (e.g., WK52, current, final);
data &libname;
set &libname;

FORMAT EVENT $Event.; *FORMAT EVENT Event.;
LENGTH  DIS $20;
IF STATE NE 975772 AND STATE NE 70 AND STATE > 59 THEN DELETE;
DIS = PUT(EVENT, $Event.); *DIS = PUT(EVENT, Event.);

IF AGETYPE = "mo" THEN DO;
    AGETYPE = "a";
    AGE = INT(AGE/12);
END;
ELSE
    IF AGETYPE = "wk" THEN DO;
       AGETYPE = "a";
       AGE = INT(AGE/52);
     END;
     ELSE
        IF AGETYPE = "d" THEN DO;
           AGETYPE = "a";
           AGE = INT(AGE/365);
        END;
IF AGE = . THEN AGEGROUP = 14; *** AGE NOT REPORTED ***;
ELSE IF RECTYPE = 'S' THEN AGEGROUP = 14;
ELSE IF (AGE >998 OR AGETYPE = "UNK") THEN AGEGROUP =13;** AGE UNKNOWN **;

ELSE IF AGETYPE = "a" OR AGETYPE = "OTH" THEN DO;
	 IF AGE <0 THEN AGEGROUP =99;
     IF AGE = 0 THEN AGEGROUP = 1; *** UNDER 1 YEAR ***;
     IF 1 <= AGE <= 4 THEN AGEGROUP = 2; *** 1-4 YEARS ***;
     IF 5 <= AGE <= 9 THEN AGEGROUP = 3; *** 5-9 YEARS ***;
     IF 10 <= AGE <= 14 THEN AGEGROUP = 4; *** 1O-14 YEARS ***;
     IF 15 <= AGE <= 19 THEN AGEGROUP = 5; *** 15-19 YEARS ***;
     IF 20 <= AGE <= 25 THEN AGEGROUP = 6; *** 20-25 YEARS ***;
     IF 26 <= AGE <= 29 THEN AGEGROUP = 7; *** 26-29 YEARS ***;
     IF 30 <= AGE <= 39 THEN AGEGROUP = 8; *** 30-39 YEARS ***;
     IF 40 <= AGE <= 49 THEN AGEGROUP = 9; *** 40-49 YEARS ***;
     IF 50 <= AGE <= 59 THEN AGEGROUP = 10; *** 50-59 YEARS ***;
     IF 60 <= AGE <= 69 THEN AGEGROUP = 11; *** 60-69 YEARS***;
     IF 70 <= AGE <= 998 THEN AGEGROUP = 12; *** 70 + ***;
	 IF AGE >998 THEN AGEGROUP =99;
	 
END;

IF AGE = . THEN AGEPERT = 14; *** AGE NOT REPORTED ***;
ELSE IF RECTYPE = 'S' THEN AGEPERT = 14;
ELSE IF (AGE > 999 OR AGETYPE = "UNK") THEN AGEPERT=13;** AGE UNKNOWN **;

ELSE IF AGETYPE = "a" OR AGETYPE = "OTH" THEN DO;
	 IF AGE <0 THEN AGEGROUP =99;
     IF AGE = 0 THEN AGEPERT = 1; *** UNDER 1 YEAR ***;
     IF 1 <= AGE <= 4 THEN AGEPERT = 2; *** 1-4 YEARS ***;
     IF 5 <= AGE <= 6 THEN AGEPERT = 3; *** 5-6 YEARS ***;
     IF 7 <= AGE <= 14 THEN AGEPERT = 4; *** 7-14 YEARS ***;
     IF 15 <= AGE <= 19 THEN AGEPERT = 5; *** 15-19 YEARS ***;
     IF 20 <= AGE <= 25 THEN AGEPERT = 6; *** 20-25 YEARS ***;
     IF 26 <= AGE <= 29 THEN AGEPERT = 7; *** 26-29 YEARS ***;
     IF 30 <= AGE <= 39 THEN AGEPERT = 8; *** 30-39 YEARS ***;
     IF 40 <= AGE <= 49 THEN AGEPERT = 9; *** 40-49 YEARS ***;
     IF 50 <= AGE <= 59 THEN AGEPERT = 10; *** 50-59 YEARS ***;
     IF 60 <= AGE <= 69 THEN AGEPERT = 11; *** 60-69 YEARS***;
     IF 70 <= AGE <= 998 THEN AGEPERT = 12; *** 70 + ***;
	 IF AGE >998 THEN AGEGROUP =99;
END;

ST=FIPNAMEL(STATE);
IF STATE = 975772 THEN ST = 'NYC';
run; 



*********************************************
|ALL EVENTS AND CASE CLASSIFICATIONS BY WEEK|
*********************************************;

data &libname;
set &libname;

proc sort data=&libname; by YEAR;

/*ods tagsets.ExcelXP file="\\cdc\project\NIP_Project_Store1\Surveillance\SAS_output\&year-&libname nndss look output\&year-&libname-freq-all-events.xls" Style=sasweb*/
ods tagsets.ExcelXP file="&output\&year-&libname-freq-all-events.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
  BY year;
  Title1 j=l bold h=10pt color=red "ALL EVENTS AND CASE CLASSIFICATIONS BY WEEK- &libname &year"; 
  TABLES WEEK*EVENT/MISSING NOROW NOCOL NOPERCENT; 
  run; 

ods tagsets.ExcelXP close ; 

**********************************************
|ALL EVENTS AND CASE CLASSIFICATIONS BY STATE|
**********************************************;

data &libname;
set &libname;

PROC SORT data=&libname; BY ST;

ods tagsets.ExcelXP file="&output\&year-&libname-allrptbystate.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
  BY st;
  WEIGHT COUNT;
  FORMAT CASSTAT $STAT.;
  LABEL DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "COUNT OF REPORTS-CASES, ALL REPORTS AND CASE STATUS BY STATE - &libname &year";
  TABLES DIS*CASSTAT/ MISSING NOROW NOCOL NOPERCENT;
  *TABLES DIS*IMPORT/ MISSING NOROW NOCOL NOPERCENT;
  *TABLES DIS*COUNT/ MISSING NOROW NOCOL NOPERCENT;
run;

ods tagsets.ExcelXP close ; 


**********************************************************
|DIPHTHERIA - confirmed, probable and unknown case status|
**********************************************************;

DATA DIP;
  SET &libname;
  if event = 10040;
  
proc sort; by year;

ods tagsets.ExcelXP file="&output\&year-&libname-diphtheria.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DIPHTHERIA BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data DIPprint;
set DIP;
IF EVENT=10040 AND (CASSTAT='410605003' OR CASSTAT='2931005' OR CASSTAT='UNK');

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN DIPHTHERIA BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN DIPHTHERIA BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN DIPHTHERIA BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 


**********************************************************************
|HAEMOPHILUS INFLUENZAE - confirmed, probable and unknown case status|
**********************************************************************;

DATA HI;
  SET &libname;
  IF EVENT=10590;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-hi.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF H. INFLUENZAE BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data HIprint;
set HI;
IF EVENT=10590 AND (CASSTAT='410605003' OR CASSTAT='2931005' OR CASSTAT='UNK');

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN H. INFLUENZAE BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN H. INFLUENZAE BY STATE AND AGE GROUP - &libname &year";
  TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN H. INFLUENZAE BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN H. INFLUENZAE BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 


*************************************************************
|INFLUENZA ASSOC PEDIATRIC MORTALITY - confirmed case status|
*************************************************************;

DATA IAPM;
  SET &libname;
  if event = 11061;
  
proc sort; by year;

ods tagsets.ExcelXP file="&output\&year-&libname-infassocpedmort.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INFLUENZA ASSOC PEDIATRIC MORTALITY BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data IAPMprint;
set IAPM;
IF EVENT=11061 AND (CASSTAT='410605003');

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED INFLUENZA ASSOC PEDIATRIC MORTALITY BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED INFLUENZA ASSOC PEDIATRIC MORTALITY BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED INFLUENZA ASSOC PEDIATRIC MORTALITY BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 


*****************************************************
|INVASIVE PNEUMOCOCCAL DISEASE - 11717, 11720, 11723|
*****************************************************;

*IPD - <5 YEARS OF AGE;

DATA IPDless5;
  SET &libname;
  IF EVENT=11717;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-spneumo11717.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
by year;
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INV S PNEUMO (<5) 11717 (ALL CASE STATUS)- &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INV S PNEUMO (<5) 11717 BY AGE GROUP (ALL CASE STATUS)- &libname &year";
TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
where (CASSTAT='410605003' OR CASSTAT='2931005');
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INV S PNEUMO (<5) 11717 BY STATE & AGE GROUP (CONF & PROB)- &libname &year";
TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INV S PNEUMO (<5) 11717 BY WEEK (ALL CASE STATUS)- &libname &year";
TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
run;

ods tagsets.ExcelXP close ; 

*IPD - DRUG RESISTANT;

DATA IPDdr;
  SET &libname;
  IF EVENT=11720;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-spdrgresist11720.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
by year;
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DRUG RESISTANT S PNEUMO 11720 (ALL CASE STATUS)- &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DRUG RESISTANT S PNEUMO 11720 BY AGE GROUP (ALL CASE STATUS)- &libname &year";
TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
where (CASSTAT='410605003' OR CASSTAT='2931005');
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DRUG RESISTANT S PNEUMO 11720 BY STATE & AGE GROUP (CONF & PROB)- &libname &year";
TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX $SEX. AGEGROUP AGE. casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DRUG RESISTANT S PNEUMO 11720 BY WEEK (ALL CASE STATUS)- &libname &year";
TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
run;

ods tagsets.ExcelXP close ; 

*IPD - ALL AGES - confirmed and probable case status; 

DATA IPDallage;
SET &libname;
if event = 11723;

proc sort; by year;

ods tagsets.ExcelXP file="&output\&year-&libname-ipdallage11723.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF IPD BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
where agegroup <3;
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF IPD (<5) BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data IPDallageprint;
set IPDallage;
IF (EVENT=11723 AND (CASSTAT='410605003' OR CASSTAT='2931005')) OR (st=06 and EVENT = 11723 and CASSTAT='UNK');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY CASE STATUS AND AGE GROUP - &libname &year";
  TABLES AGEGROUP*CASSTAT / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY STATE AND AGE GROUP - &libname &year";
  TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
  run;

ods tagsets.ExcelXP close ; 


***************************************
|LEGIONELLOSIS - confirmed case status|
***************************************;

DATA LEG;
SET &libname;
if event = 10490;

proc sort; by year;

ods tagsets.ExcelXP file="&output\&year-&libname-legionella.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF LEGIONELLOSIS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data LEGprint;
set LEG;
IF EVENT = 10490 and CASSTAT='410605003';

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED LEGIONELLOSIS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED LEGIONELLOSIS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED LEGIONELLOSIS BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
  run;

ods tagsets.ExcelXP close ; 


*********************************************
|MEASLES - confirmed and unknown case status|
*********************************************;

DATA MEAS;
SET &libname;
IF EVENT=10140;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-measles.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF MEASLES BY ALL CASE STATUS - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN;

*subset by print criteria;
data MEASprint;
set MEAS;
IF EVENT=10140 AND (CASSTAT='410605003' OR CASSTAT='UNK');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED OR UNKNOWN MEASLES BY AGE GROUP - &libname &year";
  TABLES AGEGROUP/ MISSING NOROW NOCOL NOPERCENT;
RUN;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED OR UNKNOWN MEASLES BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED OR UNKNOWN MEASLES BY IMPORTATION STATUS - &libname &year";
  TABLES IMPORT/MISSing NOROW NOCOL NOPERCENT;
RUN;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED OR UNKNOWN MEASLES BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN;

*look at importation status of measles cases;

DATA MEASIMP;
  SET MEASprint;
    IF IMPORT ne 2;

PROC PRINT; 
 TITLE1 j=l bold h=10pt color=red "THESE MEASLES (CONF, UNK) WERE LISTED AS INDIGENOUS or UNKNOWN - &libname &year";

PROC FREQ; 
  TABLES ST/MISSING NOROW NOCOL NOPERCENT;
  TITLE1 j=l bold h=10pt color=red "THESE MEASLES (CONF, UNK) WERE LISTED AS INDIGENOUS or UNKNOWN - &libname &year";
  RUN;

DATA MEASIMP2;
  SET MEASprint;
    IF IMPORT=2;

PROC PRINT; 
 TITLE1 j=l bold h=10pt color=red "THESE MEASLES (CONF, UNK) WERE LISTED AS IMPORTATIONS - &libname &year";

PROC FREQ; BY YEAR;
  TABLES ST/MISSing NOROW NOCOL NOPERCENT;
  TITLE1 j=l bold h=10pt color=red "THESE MEASLES (CONF, UNK) WERE LISTED AS IMPORTATIONS - &libname &year";
  RUN;

ods tagsets.ExcelXP close ; 


************************************************************
|MENINGOCOCCAL DISEASE - confirmed and probable case status|
************************************************************;

DATA MENING;
  SET &libname;
  If event=10150;

proc sort; by year;

ods tagsets.ExcelXP file="&output\&year-&libname-mening.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
  by year;
  WEIGHT COUNT;
  FORMAT CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF MENING BY ALL CASE STATUS - &libname &year";
  tables st*casstat/ MISSING NOROW NOCOL NOPERCENT;
  run;

*subset by print criteria;
Data MENINGprint;
set mening;
IF (EVENT = 10150 AND (CASSTAT='410605003' OR CASSTAT='2931005')) OR (st=06 and EVENT = 10150 and CASSTAT='UNK'); 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) MENING BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) MENING BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) MENING BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
  run;

ods tagsets.ExcelXP close ; 


*****************************************************
|MUMPS - confirmed, probable and unknown case status|
*****************************************************;

DATA MUMPS;
  SET &libname;
  if event = 10180;
  
PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-mumps.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF MUMPS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data MUMPSprint;
set mumps;
IF EVENT=10180 AND (CASSTAT='410605003' OR CASSTAT='2931005' OR CASSTAT='UNK');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN MUMPS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN MUMPS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN MUMPS BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

ods tagsets.ExcelXP close ; 


*******************************************
|NOVEL INFLUENZA A - confirmed case status|
*******************************************;

DATA NOVINFA;
  SET &libname;
  IF EVENT=11062;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-novelinfA.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF NOVEL INFLUENZA A BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data NOVINFAprint;
set NOVINFA;
IF EVENT=11062 AND (CASSTAT='410605003');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED NOVEL INFLUENZA A BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED NOVEL INFLUENZA A BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED NOVEL INFLUENZA A BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 

*********************************************************
|PERTUSSIS - confirmed, probable and unknown case status|
*********************************************************;

DATA PERT;
  SET &libname;
  IF EVENT=10190;

PROC SORT; by year;

ods tagsets.ExcelXP file="&output\&year-&libname-pertussis.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PERTUSSIS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data PERTprint;
set pert;
IF EVENT=10190 AND (CASSTAT='410605003' OR CASSTAT='2931005' OR CASSTAT='UNK');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. AGEPERT AGEPERT. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY AGE GROUP (AGEPERT) - &libname &year";
  TABLES AGEGPERT / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. AGEPERT AGEPERT. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY AGE GROUP (AGEGROUP)- &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. AGEPERT AGEPERT. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY STATE AND AGE GROUP (AGEGROUP)- &libname &year";
  TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. AGEPERT AGEPERT. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $sex. AGEGROUP AGE. AGEPERT AGEPERT. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 

*look at pertussis prog_dat;

DATA PERTLK1;
  SET PERT;
    IF PROG_DAT NE .;

DATA PERTLK2;
  SET PERT;
    IF PROG_DT2 NE .;

******************************************
|POLIO, PARALYTIC - confirmed case status|
******************************************;

DATA POLIOpar;
  SET &libname;
  IF EVENT=10410;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-paralyticpolio.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PARALYTIC POLIO (ALL CASE STATUS) - &libname &year";
  TABLES ST*CASSTAT/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PARALYTIC POLIO BY AGE GROUP (ALL CASE STATUS)- &libname &year";
  TABLES AGEGROUP/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PARALYTIC POLIO BY WEEK (ALL CASE STATUS)- &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

PROC PRINT;
   BY YEAR;
   TITLE1 j=l bold h=10pt color=red "PROC PRINT OF PARALYTIC POLIO (ALL CASE STATUS) - &libname &year";
RUN; 

ods tagsets.ExcelXP close ; 


**********************************************
*POLIO, NON-PARALYTIC - confirmed case status|
**********************************************;

DATA POLIOnonpar;
  SET &libname;
  IF EVENT=10405;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-poliovirusinf.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF NON-PARALYTIC POLIO BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data POLIOnonparprint;
set poliononpar;
IF (EVENT = 10405 AND CASSTAT='410605003') OR (st=06 and EVENT = 10405 and CASSTAT='UNK'); 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED (and UNKNOWN for CA) NON-PARALYTIC POLIO BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED (and UNKNOWN for CA) NON-PARALYTIC POLIO BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED (and UNKNOWN for CA) NON-PARALYTIC POLIO BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC PRINT;
   BY YEAR;
   TITLE1 j=l bold h=10pt color=red "PROC PRINT OF CONFIRMED (and UNKNOWN for CA) NON-PARALYTIC POLIO - &libname &year";
RUN; 

ods tagsets.ExcelXP close ; 

**************************************************
|PSITTACOSIS - confirmed and probable case status|
**************************************************;

DATA PSITT;
  SET &libname;
  IF EVENT=10450;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-psittacosis.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PSITTACOSIS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data PSITTprint;
set PSITT;
IF EVENT=10450 AND (CASSTAT='410605003' OR CASSTAT='2931005');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE PSITTACOSIS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE PSITTACOSIS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE PSITTACOSIS BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 

*********************************************
|RUBELLA - confirmed and unknown case status|
*********************************************;

DATA RUBELLA;
  SET &libname;
  IF EVENT=10200;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-rubella.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF RUBELLA BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data RUBELLAprint;
set rubella;
IF EVENT=10200 AND (CASSTAT='410605003' OR CASSTAT='UNK');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND UNKNOWN RUBELLA BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND UNKNOWN RUBELLA BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND UNKNOWN RUBELLA BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC PRINT;
BY YEAR;
TITLE1 j=l bold h=10pt color=red "PROC PRINT OF CONFIRMED AND UNKOWN RUBELLA - &libname &year";
RUN; 

ods tagsets.ExcelXP close ; 

***************************************************************************
|CONGENITAL RUBELLA SYNDROME - confirmed, probable and unknown case status|
***************************************************************************;

DATA CRS;
  SET &libname;
  IF EVENT=10370;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-crs.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF CRS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data CRSprint;
set crs;
IF EVENT=10370 AND (CASSTAT='410605003' OR CASSTAT='2931005' OR CASSTAT='UNK');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN CRS  BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN CRS  BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN CRS  BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
  run;

PROC PRINT;
BY year;
TITLE1 j=l bold h=10pt color=red "PROC PRINT OF CONFIRMED, PROBABLE, UNKNOWN CRS - &libname &year";
RUN; 

ods tagsets.ExcelXP close ; 


*******************************************
|SARS - confirmed and probable case status|
*******************************************;

DATA SARS;
SET &libname;
if event = 10575;
  
PROC SORT; BY YEAR;   

ods tagsets.ExcelXP file="&output\&year-&libname-SARS.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF SARS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data SARSprint;
set SARS;
IF EVENT = 10575 AND (CASSTAT='410605003' OR CASSTAT='2931005');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE SARS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE SARS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE SARS BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 


*******************************************
|STSS - confirmed and probable case status|
*******************************************;

DATA STSS;
SET &libname;
if event = 11700;
  
PROC SORT; BY YEAR;   

ods tagsets.ExcelXP file="&output\&year-&libname-STSS.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF STSS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data STSSprint;
set STSS;
IF EVENT = 11700 AND (CASSTAT='410605003' OR CASSTAT='2931005');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE STSS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE STSS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE STSS BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 


***********************
|TETANUS - all reports|
***********************;

DATA TETANUS;
  SET &libname;
  IF EVENT=10210;

PROC SORT; BY YEAR;

ods tagsets.ExcelXP file="&output\&year-&libname-tetanus.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF TETANUS (ALL CASE STATUS) - &libname &year";
  TABLES ST*CASSTAT/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF TETANUS BY AGE GROUP (ALL CASE STATUS) - &libname &year";
  TABLES AGEGROUP/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF TETANUS BY STATE AND AGE (ALL CASE STATUS) - &libname &year";
  TABLES ST*AGE/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. casstat $stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF TETANUS BY WEEK (ALL CASE STATUS) - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

ods tagsets.ExcelXP close ; 


************************************************
|VARICELLA - confirmed and probable case status|
************************************************;

DATA VAR;
SET &libname;
if event = 10030;
  
PROC SORT; BY YEAR;   

ods tagsets.ExcelXP file="&output\&year-&libname-varicella.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF VARICELLA BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data VARprint;
set VAR;
IF (EVENT = 10030 AND (CASSTAT='410605003' OR CASSTAT='2931005' )) OR (st=06 and EVENT = 10030 and CASSTAT='UNK');

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) VARICELLA BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) VARICELLA BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) VARICELLA BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 













**************************************************************************
|AD HOC ANALYSES - use statements below as guide to run ad hoc analyses. |
|Be sure to specify EVENT CODE in data step,                             |
|FILE NAME in ods statement,                                             |
|and TABLE TITLE in title statment as appropriate                        |
**************************************************************************;

*proc contents on dataset;
DATA LOOK1;
SET &libname;

ods tagsets.ExcelXP file="&output\&year-&libname-proc contents.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc contents;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "proc contents - &libname &year";
run;
 
ods tagsets.ExcelXP close ; 

*look at specific disease;
DATA LOOK1;
SET &libname;
if event = XXXXX;

PROC SORT; BY YEAR;   

ods tagsets.ExcelXP file="&output\&year-&libname-LOOK2021.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="no");

proc freq;
by year;
weight count;
format casstat $stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DISEASE BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data LOOK1print;
set LOOK1;
IF (EVENT = XXXXX AND (CASSTAT=1 OR CASSTAT=2)) OR (st=06 and EVENT = XXXXX and CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX $SEX. AGEGROUP AGE. CASSTAT $STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) DISEASE BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ;
