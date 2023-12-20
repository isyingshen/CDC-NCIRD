
*---------------------------------------------------------------------*
|PROGRAM NAME:  ALL_NCIRD_LOOK                                        |
|FUNCTION OF PROGRAM:  PRODUCES TABLES OF THE CASE COUNTS BY DISEASE  |
|                      FOR THE ENTIRE U.S. FROM HISTORICAL, CURRENT,  |
|                      OR WEEK 52 NETSS DATA (SELECT IN MACRO)        |
|                                                                     |
|PROGRAMMER:  SANDY ROUSH (MODIFIED 8/2005),                          |
|             HOLLY VINS (MODIFIED 1/2019)                            |
|                                                                     |
|DATA SOURCES:  NETSS DATABASE - ALLVPD                               ¦
*---------------------------------------------------------------------*;


*Enter year of interest and type of data (e.g., WK52, FINAL, CURRENT) in macro statements below;
%Let year= 2021;
%Let libname = current;

*make sure that you have created a folder within: \\cdc\project\NIP_Project_Store1\Surveillance\SAS_output 
named with the following convention: &year-&libname nndss look output
so that the output goes to the correct folder on the sharedrive ;

%let output =\\cdc\project\NIP_Project_Store1\Surveillance\SAS_output\2021-NetssCaseSASSpinOffWeek52_vw;

*do not edit these macro statements;
%Let Yr = %substr(&Year,3,2) ;
%put Year=&Year Yr=&YR ;

libname MVPS OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-INFC-1604\QSRV1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="MVPS_PROD" ) schema=netss access=readonly;


/*libname CURRENT "\\cdc\csp_project\NCPHI_DISSS_NNDSS_NCIRD\Current" access=readonly ;*/
*libname WK53 "\\cdc\csp_project\NCIRD_MB00\swr1\NETSS\WK5320" access=readonly ;
*libname FINAL "\\cdc\csp_project\NCPHI_DISSS_NNDSS_NCIRD\History" access=readonly ;


*libname library "\\cdc\csp_project\ncird_nndss\Formats" access=readonly ;

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
          14 = 'AGE NOT REPORTED';

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
              14 = 'AGE NOT REPORTED';

VALUE EVENT 10040='DIPHTHERIA'
			10590='HAEMOPHILUS INFLUENZAE'
			11061='INFLUENZA ASSOC PED MORT'
			11723='IPD-ALL AGES'
			11720='S PNEUMO, DRUG RESIST'
			11717='S PNEUMO, AGE < 5'
			10490='LEGIONELLOSIS'
			10140='MEASLES'
			10150='MENINGOCOCCAL DISEASE'
			10180='MUMPS'
			11062='NOVEL INFLUENZA A'
            10190='PERTUSSIS'
            10410='POLIO, PARALYTIC'
            10405='POLIO, NON-PARALYTIC'
			10450='PSITTACOSIS'
            10200='RUBELLA'
			10370='CRS'
            10575='SARS-COV'
			11700='STSS'           
            10210='TETANUS'
            10030='VARICELLA'

			10110='HEPATITIS A'             
            10100='HEPATITIS B'
			10104='HEP B, PERINATAL'
			10380='HANSEN DISEASE'
			10390='LEPTOSPIROSIS'
            10650='OTHER BACTERIAL MENINGITIS'
			10520='TSS OTHER THAN STREP'
			10640='LISTERIOSIS'
			11563='STEC'
			10010='ASEPTIC MENINGITIS'
			11060='INFLUENZA, HUMAN ISOLATES'
			11070='INFLUENZA, ANIMAL ISOLATES'
			11661='MRSA aka ORSA'
			11710='STREP, INV, GRP A'
			11715='STREP, INV, GRP B'
			11716='STREP, INV, OTHER';

VALUE SEX 1 = 'MALE'
          2 = 'FEMALE'
          9 = 'UNKNOWN'
          . = 'SEX NOT REPORTED';

 VALUE SEROFF                                                          
      1='TYPE B'                                                       
      2='NOT TYPABLE'                                                   
      8='OTHER TYPE'                                                   
      9='NOT TESTED/ UNKNOWN'                                                
      3-7='NOT TESTED/ UNKNOWN';   

VALUE STAT 1 = 'CONFIRMED'
           2 = 'PROBABLE'
           3 = 'SUSPECT'
           9 = 'UNK STATUS';

*set 'WK52' dataset for year of interest;
data yr2021;
set MVPS.NetssCaseSASSpinOffWeek52_vw;
if event ne 11065;
if year=&year;
run;

proc contents data=yr2021;
run;


*set 'final' dataset for year of interest;
/*data final;*/
/*set final.ncird;*/
/*if year=&year;*/
/*run;*/

*set 'current' dataset for year of interest;
data current;
set yr2021;
run;

*set dataset for type of data (e.g., WK52, current, final);
data &libname;
set &libname;

FORMAT EVENT EVENT.;
LENGTH  DIS $20;
IF STATE NE 70 AND STATE > 59 THEN DELETE;
DIS = PUT(EVENT,EVENT.);

IF AGETYPE = 1 THEN DO;
    AGETYPE = 0;
    AGE = INT(AGE/12);
END;
ELSE
    IF AGETYPE = 2 THEN DO;
       AGETYPE = 0;
       AGE = INT(AGE/52);
     END;
     ELSE
        IF AGETYPE = 3 THEN DO;
           AGETYPE = 0;
           AGE = INT(AGE/365);
        END;
IF AGE = . THEN AGEGROUP = 14; *** AGE NOT REPORTED ***;
ELSE IF RECTYPE = 'S' THEN AGEGROUP = 14;
ELSE IF (AGE >= 999 OR AGE < 0 OR AGETYPE = 9) THEN AGEGROUP =13;** AGE UNKNOWN **;

ELSE IF AGETYPE = 0 OR AGETYPE = 4 THEN DO;
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
END;

IF AGE = . THEN AGEPERT = 14; *** AGE NOT REPORTED ***;
ELSE IF RECTYPE = 'S' THEN AGEPERT = 14;
ELSE IF (AGE >= 999 OR AGE < 0 OR AGETYPE = 9) THEN AGEPERT=13;** AGE UNKNOWN **;

ELSE IF AGETYPE = 0 OR AGETYPE = 4 THEN DO;
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
END;

ST=FIPNAMEL(STATE);
IF STATE = 70 THEN ST = 'NYC';
run; 


*********************************************
|ALL EVENTS AND CASE CLASSIFICATIONS BY WEEK|
*********************************************;

data &libname;
set &libname;

proc sort data=&libname; by YEAR;

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
  FORMAT CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DIPHTHERIA BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data DIPprint;
set DIP;
IF EVENT=10040 AND (CASSTAT=1 OR CASSTAT=2 OR CASSTAT=9);

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN DIPHTHERIA BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN DIPHTHERIA BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF H. INFLUENZAE BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data HIprint;
set HI;
IF EVENT=10590 AND (CASSTAT=1 OR CASSTAT=2 OR CASSTAT=9);

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN H. INFLUENZAE BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN H. INFLUENZAE BY STATE AND AGE GROUP - &libname &year";
  TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN H. INFLUENZAE BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INFLUENZA ASSOC PEDIATRIC MORTALITY BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data IAPMprint;
set IAPM;
IF EVENT=11061 AND CASSTAT=1;

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED INFLUENZA ASSOC PEDIATRIC MORTALITY BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED INFLUENZA ASSOC PEDIATRIC MORTALITY BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY year;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
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
format SEX SEX. AGEGROUP AGE. casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INV S PNEUMO (<5) 11717 (ALL CASE STATUS)- &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX SEX. AGEGROUP AGE. casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INV S PNEUMO (<5) 11717 BY AGE GROUP (ALL CASE STATUS)- &libname &year";
TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
where CASSTAT=1 OR CASSTAT=2;
weight count;
format SEX SEX. AGEGROUP AGE. casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF INV S PNEUMO (<5) 11717 BY STATE & AGE GROUP (CONF & PROB)- &libname &year";
TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX SEX. AGEGROUP AGE. casstat stat.;
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
format SEX SEX. AGEGROUP AGE. casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DRUG RESISTANT S PNEUMO 11720 (ALL CASE STATUS)- &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX SEX. AGEGROUP AGE. casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DRUG RESISTANT S PNEUMO 11720 BY AGE GROUP (ALL CASE STATUS)- &libname &year";
TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
where CASSTAT=1 OR CASSTAT=2;
weight count;
format SEX SEX. AGEGROUP AGE. casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF DRUG RESISTANT S PNEUMO 11720 BY STATE & AGE GROUP (CONF & PROB)- &libname &year";
TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
by year;
weight count;
format SEX SEX. AGEGROUP AGE. casstat stat.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF IPD BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

proc freq;
by year;
weight count;
format casstat stat.;
label dis = 'EVENT';
where agegroup <3;
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF IPD (<5) BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data IPDallageprint;
set IPDallage;
IF (EVENT=11723 AND (CASSTAT=1 OR CASSTAT=2)) OR (st=06 and EVENT = 11723 and CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY CASE STATUS AND AGE GROUP - &libname &year";
  TABLES AGEGROUP*CASSTAT / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY STATE AND AGE GROUP - &libname &year";
  TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) IPD BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF LEGIONELLOSIS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data LEGprint;
set LEG;
IF EVENT = 10490 and casstat = 1;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED LEGIONELLOSIS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED LEGIONELLOSIS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
  FORMAT CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF MEASLES BY ALL CASE STATUS - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN;

*subset by print criteria;
data MEASprint;
set MEAS;
IF EVENT=10140 AND (CASSTAT=1 OR CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED OR UNKNOWN MEASLES BY AGE GROUP - &libname &year";
  TABLES AGEGROUP/ MISSING NOROW NOCOL NOPERCENT;
RUN;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED OR UNKNOWN MEASLES BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED OR UNKNOWN MEASLES BY IMPORTATION STATUS - &libname &year";
  TABLES IMPORT/MISSing NOROW NOCOL NOPERCENT;
RUN;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
  FORMAT CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF MENING BY ALL CASE STATUS - &libname &year";
  tables st*casstat/ MISSING NOROW NOCOL NOPERCENT;
  run;

*subset by print criteria;
Data MENINGprint;
set mening;
IF (EVENT = 10150 AND (CASSTAT=1 OR CASSTAT=2)) OR (st=06 and EVENT = 10150 and CASSTAT=9); 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) MENING BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) MENING BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF MUMPS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data MUMPSprint;
set mumps;
IF EVENT=10180 AND (CASSTAT=1 OR CASSTAT=2 OR CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN MUMPS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN MUMPS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
run;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF NOVEL INFLUENZA A BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data NOVINFAprint;
set NOVINFA;
IF EVENT=11062 AND CASSTAT=1;

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED NOVEL INFLUENZA A BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED NOVEL INFLUENZA A BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PERTUSSIS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data PERTprint;
set pert;
IF EVENT=10190 AND (CASSTAT=1 OR CASSTAT=2 OR CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. AGEPERT AGEPERT. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY AGE GROUP (AGEPERT) - &libname &year";
  TABLES AGEPERT / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. AGEPERT AGEPERT. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY AGE GROUP (AGEGROUP)- &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. AGEPERT AGEPERT. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY STATE AND AGE GROUP (AGEGROUP)- &libname &year";
  TABLES ST*AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. AGEPERT AGEPERT. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN PERTUSSIS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. AGEPERT AGEPERT. casstat stat.;
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
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PARALYTIC POLIO (ALL CASE STATUS) - &libname &year";
  TABLES ST*CASSTAT/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PARALYTIC POLIO BY AGE GROUP (ALL CASE STATUS)- &libname &year";
  TABLES AGEGROUP/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF NON-PARALYTIC POLIO BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data POLIOnonparprint;
set poliononpar;
IF (EVENT = 10405 AND CASSTAT=1) OR (st=06 and EVENT = 10405 and CASSTAT=9); 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED (and UNKNOWN for CA) NON-PARALYTIC POLIO BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED (and UNKNOWN for CA) NON-PARALYTIC POLIO BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF PSITTACOSIS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data PSITTprint;
set PSITT;
IF EVENT=10450 AND (CASSTAT=1  OR CASSTAT=2);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE PSITTACOSIS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE PSITTACOSIS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF RUBELLA BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data RUBELLAprint;
set rubella;
IF EVENT=10200 AND (CASSTAT=1  OR CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND UNKNOWN RUBELLA BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND UNKNOWN RUBELLA BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF CRS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data CRSprint;
set crs;
IF EVENT=10370 AND (CASSTAT=1 OR CASSTAT=2 OR CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN CRS  BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE, UNKNOWN CRS  BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF SARS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data SARSprint;
set SARS;
IF EVENT = 10575 AND (CASSTAT=1 OR CASSTAT=2);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE SARS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE SARS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF STSS BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data STSSprint;
set STSS;
IF EVENT = 11700 AND (CASSTAT=1 OR CASSTAT=2);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE STSS BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED AND PROBABLE STSS BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF TETANUS (ALL CASE STATUS) - &libname &year";
  TABLES ST*CASSTAT/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF TETANUS BY AGE GROUP (ALL CASE STATUS) - &libname &year";
  TABLES AGEGROUP/ MISSING NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "FREQUENCY OF TETANUS BY STATE AND AGE (ALL CASE STATUS) - &libname &year";
  TABLES ST*AGE/MISSing NOROW NOCOL NOPERCENT;
  run;

  PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. casstat stat.;
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
format casstat stat.;
label dis = 'EVENT';
TITLE1 j=l bold h=10pt color=red "FREQUENCY OF VARICELLA BY ALL CASE STATUS - &libname &year";
TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
run;

*subset by print criteria;
data VARprint;
set VAR;
IF (EVENT = 10030 AND (CASSTAT=1 OR CASSTAT=2)) OR (st=06 and EVENT = 10030 and CASSTAT=9);

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) VARICELLA BY AGE GROUP - &libname &year";
  TABLES AGEGROUP / MISSING NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) VARICELLA BY WEEK - &libname &year";
  TABLES WEEK/MISSing NOROW NOCOL NOPERCENT;
RUN; 

PROC FREQ;
  BY YEAR;
  WEIGHT COUNT;
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
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
format casstat stat.;
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
  FORMAT  SEX SEX. AGEGROUP AGE. CASSTAT STAT.;
  LABEL  DIS = 'EVENT';
  TITLE1 j=l bold h=10pt color=red "CONFIRMED, PROBABLE (and UNKNOWN for CA) DISEASE BY STATE - &libname &year";
  TABLES ST*CASSTAT/MISSing NOROW NOCOL NOPERCENT;
RUN; 

ods tagsets.ExcelXP close ; 


                                         
 ***LET THE HI FUN BEGIN FOR SEROTYPE;                                                                      
   
 
*subset for HI;
DATA HILOOK;                                                          
SET HIprint;  
run; 

                                                                     

DATA HILOOK;                                                            
  SET HILOOK;                                                           
                                                                        
IF CASSTAT = 1 OR CASSTAT=2 OR CASSTAT=9; *KEEP CONF,PROB, UNK;        
                                                                                                                                                       
LENGTH IVDDAY1 $2 IVDYR1 $2                                            
IDAYCARE $2 IOUTCOME $2 ISPECIES $2 IFRSTCLT $8 IFMON $2 IFDAY $2       
IFYR $2 ISPC1MEN $2 ISPC2MEN $2 ISPC3MEN $2 IIN1FECT $2 IIN2FECT $2    
IIN3FECT $2 ISEROGRP $2 ISULFA $2 IRIFAMPN $2 ISEROTYP $2 IAMPCILL $2  
ICHLORMP $2 IRIFAMP $2 IHIBVAC $2 IVACDAT1 $8 IVDMON1 $2                
IVAC1NAM $2 ILOTNUM1 $10 IVACDAT2 $8 IVDMON2 $2 IVDDAY2 $2 IVDYR2 $2   
IVAC2NAM $2 ILOTNUM2 $10 IVACDAT3 $8 IVDMON3 $2 IVDDAY3 $2 IVDYR3 $2    
IVAC3NAM $2 ILOTNUM3 $10 IVACDAT4 $8 IVDMON4 $2 IVDDAY4 $2 IVDYR4 $2    
IVAC4NAM $2 ILOTNUM4 $10 ITEST1 $5;                                    
                                                                        
IF STATE NE 70 AND STATE > 59 THEN DELETE;                                                                       
   STNAME=FIPNAME(STATE);                                               
   IF STATE = 70 THEN STNAME = 'NYC';                                   
                                                                        
ITEST1=SUBSTR(PROG_DAT,1,5);                                            
IDAYCARE=SUBSTR(PROG_DAT,1,1);                                          
IOUTCOME=SUBSTR(PROG_DAT,2,1);                                          
ISPECIES=SUBSTR(PROG_DAT,3,2);                                         
IFRSTCLT=SUBSTR(PROG_DAT,5,8);                                          
IFMON=SUBSTR(PROG_DAT,5,2);                                             
IFDAY=SUBSTR(PROG_DAT,8,2);                                             
IFYR=SUBSTR(PROG_DAT,11,2);                                             
ISPC1MEN=SUBSTR(PROG_DAT,13,1);                                         
ISPC2MEN=SUBSTR(PROG_DAT,14,1);                                         
ISPC3MEN=SUBSTR(PROG_DAT,15,1);                                        
IIN1FECT=SUBSTR(PROG_DAT,16,2);                                        
IIN2FECT=SUBSTR(PROG_DAT,18,2);                                       
IIN3FECT=SUBSTR(PROG_DAT,20,2);                                        
ISEROGRP=SUBSTR(PROG_DAT,22,1);                                        
ISULFA=SUBSTR(PROG_DAT,23,1);                                          
IRIFAMPN=SUBSTR(PROG_DAT,24,1);                                         
ISEROTYP=SUBSTR(PROG_DAT,25,1);                                         
IAMPCILL=SUBSTR(PROG_DAT,26,1);                                         
ICHLORMP=SUBSTR(PROG_DAT,27,1);                                       
IRIFAMP=SUBSTR(PROG_DAT,28,1);                                          
IHIBVAC=SUBSTR(PROG_DAT,29,1);                                         
IVACDAT1=SUBSTR(PROG_DAT,30,8);                                       
IVDMON1=SUBSTR(PROG_DAT,30,2);                                          
IVDDAY1=SUBSTR(PROG_DAT,33,2);                                       
IVDYR1=SUBSTR(PROG_DAT,36,2);                                           
IVAC1NAM=SUBSTR(PROG_DAT,38,1);                                         
ILOTNUM1=SUBSTR(PROG_DAT,39,10);                                       
IVACDAT2=SUBSTR(PROG_DAT,49,8);                                        
IVDMON2=SUBSTR(PROG_DAT,49,2);                                         
IVDDAY2=SUBSTR(PROG_DAT,52,2);                                         
IVDYR2=SUBSTR(PROG_DAT,55,2);                                          
IVAC2NAM=SUBSTR(PROG_DAT,57,1);                                        
ILOTNUM2=SUBSTR(PROG_DAT,58,10);                                       
IVACDAT3=SUBSTR(PROG_DAT,68,8);                                        
IVDMON3=SUBSTR(PROG_DAT,68,2);                                          
IVDDAY3=SUBSTR(PROG_DAT,71,2);                                        
IVDYR3=SUBSTR(PROG_DAT,74,2);                                           
IVAC3NAM=SUBSTR(PROG_DAT,76,1);                                         
ILOTNUM3=SUBSTR(PROG_DAT,77,10);                                        
IVACDAT4=SUBSTR(PROG_DAT,87,8);                                         
IVDMON4=SUBSTR(PROG_DAT,87,2);                                          
IVDDAY4=SUBSTR(PROG_DAT,90,2);                                          
IVDYR4=SUBSTR(PROG_DAT,93,2);                                           
IVAC4NAM=SUBSTR(PROG_DAT,95,1);                                         
ILOTNUM4=SUBSTR(PROG_DAT,96,10);                                        
                                                                        
                                                                                                                               
***THESE STATES HAD EXT SCRN INSTALLED AS OF EPO RPT 2/12/96***;        
                                                                        
IF (STATE=04 OR STATE=05 OR STATE=06 OR STATE=08 OR STATE=09            
   OR STATE=10 OR STATE=12 OR STATE=13 OR STATE=16 OR STATE=17          
   OR STATE=18 OR STATE=19 OR STATE=20 OR STATE=21 OR STATE=22          
OR STATE=24 OR STATE=25 OR STATE=27 OR STATE=28 OR STATE=29 OR STATE=31 
 OR STATE=32 OR STATE=33 OR STATE=35 OR STATE=36 OR STATE=70 OR STATE=38
   OR STATE=39 OR STATE=40 OR STATE=42 OR STATE=44 OR STATE=45          
   OR STATE=47 OR STATE=48 OR STATE=49 OR STATE=50 OR STATE=54)         
   THEN INSTALL = 1;                                                    
  ELSE INSTALL = 2;                                                     
                                                                                                                                      
DROP IDAYCARE IOUTCOME ISPECIES IFRSTCLT IFMON IFDAY IFYR ISPC1MEN      
ISPC2MEN ISPC3MEN IIN1FECT IIN2FECT IIN3FECT ISEROGRP ISULFA           
IRIFAMPN ISEROTYP IAMPCILL ICHLORMP IRIFAMP IHIBVAC IVACDAT1           
IVDMON1 IVDDAY1 IVDYR1 IVAC1NAM ILOTNUM1 IVACDAT2 IVDMON2 IVDDAY2      
IVDYR2 IVAC2NAM ILOTNUM2 IVACDAT3 IVDMON3 IVDDAY3 IVDYR3 IVAC3NAM       
ILOTNUM3 IVACDAT4 IVDMON4 IVDDAY4 IVDYR4 IVAC4NAM ILOTNUM4 ITEST1;      
                                                                                                                                                                                                  
LENGTH DAYCARE 3 OUTCOME 3 SPECIES 3 FRSTCULT $8 FMON 3 FDAY 3         
FYR 3 SPEC1MEN 3 SPEC2MEN 3 SPEC3MEN 3 IN1FECT 3 IN2FECT 3              
IN3FECT 3 SEROGRP 3 SULFA 3 RIFAMPIN 3 SEROTYPE 3  AMPICILL 3          
CHLORAMP 3 RIFAMP 3 HIBVAC 3 VACDATE1 $8 VDMON1 3 VDDAY1 3 VDYR1 3     
VAC1NAME 3 LOTNUM1 $10 VACDATE2 $8 VDMON2 3 VDDAY2 3 VDYR2 3            
VAC2NAME 3 LOTNUM2 $10 VACDATE3 $8 VDMON3 3 VDDAY3 3 VDYR3 3            
VAC3NAME 3 LOTNUM3 $10 VACDATE4 $8 VDMON4 3 VDDAY4 3 VDYR4 3           
VAC4NAME 3 LOTNUM4 $10 STNAME $20 MESS $50 MESSAGE $50 TEST1 $5;       
                                                                       
TEST1=ITEST1;                                                         
DAYCARE=IDAYCARE;                                                       
OUTCOME=IOUTCOME;                                                      
SPECIES=ISPECIES;                                                 
FRSTCULT=IFRSTCLT;                                                      
FMON=IFMON;                                                          
FDAY=IFDAY;                                                            
FYR=IFYR;                                                               
SPEC1MEN=ISPC1MEN;                                                      
SPEC2MEN=ISPC2MEN;                                                     
SPEC3MEN=ISPC3MEN;                                                      
IN1FECT=IIN1FECT;                                                      
IN2FECT=IIN2FECT;                                                      
IN3FECT=IIN3FECT;                                                       
SEROGRP=ISEROGRP;                                                     
SULFA=ISULFA;                                                          
RIFAMPIN=IRIFAMPN;                                                      
SEROTYPE=ISEROTYP;                                                      
AMPICILL=IAMPCILL;                                                     
CHLORAMP=ICHLORMP;                                                     
RIFAMP=IRIFAMP;                                                        
HIBVAC=IHIBVAC;                                                         
VACDATE1=IVACDAT1;                                                     
VDMON1=IVDMON1;                                                         
VDDAY1=IVDDAY1;                                                        
VDYR1=IVDYR1;                                                          
VAC1NAME=IVAC1NAM;                                                    
LOTNUM1=ILOTNUM1;                                                      
VACDATE2=IVACDAT2;                                                     
VDMON2=IVDMON2;                                                         
VDDAY2=IVDDAY2;                                                       
VDYR2=IVDYR2;                                                          
VAC2NAME=IVAC2NAM;                                                     
LOTNUM2=ILOTNUM2;                                                      
VACDATE3=IVACDAT3;                                                    
VDMON3=IVDMON3;                                                      
VDDAY3=IVDDAY3;                                                         
VDYR3=IVDYR3;                                                         
VAC3NAME=IVAC3NAM;                                                      
LOTNUM3=ILOTNUM3;                                                       
VACDATE4=IVACDAT4;                                                     
VDMON4=IVDMON4;                                                        
VDDAY4=IVDDAY4;                                                        
VDYR4=IVDYR4;                                                           
VAC4NAME=IVAC4NAM;                                                     
LOTNUM4=ILOTNUM4;                                                       
                                                                    
*FORMAT BIRTHD MMDDYY8. EVENTD MMDDYY8.; 

/*IF EVENTD NE . THEN DO;                                                 
  EVNTDATE=PUT(EVENTD,MMDDYY6.);                                        
  EVNTMO=SUBSTR(EVNTDATE,1,2);                                          
  EVNTYR=SUBSTR(EVNTDATE,5,2);                                          
END;     
                                                                                                                                                                                                   
IF STATE NE 70 AND STATE > 59 THEN DELETE;                             
DIS = PUT(EVENT,EVENTN.);                                              
MMWR_WK = (YEAR * 100) + WEEK;                                         
CDATE = PUT(MMWR_WK,MMTOWK.);                                          
RPTDATE = INPUT(CDATE,YYMMDD6.);                                      
ONSETDT = PUT(EVENTD,YYMMDD6.);  */   

*run;  
                                                                                                                          
 IF AGETYPE = 1 THEN DO;                                               
    AGETYPE = 0;                                                        
    AGE = INT(AGE/12);                                                 
 END;                                                                   
 ELSE                                                                   
    IF AGETYPE = 2 THEN DO;                                           
       AGETYPE = 0;                                                     
       AGE = INT(AGE/52);                                              
     END;                                                               
     ELSE                                                              
        IF AGETYPE = 3 THEN DO;                                         
           AGETYPE = 0;                                                 
           AGE = INT(AGE/365);                                          
        END;                                                            
IF AGE = . THEN AGEGROUP = 13;  *** AGE NOT REPORTED ***;               
ELSE IF RECTYPE = 'S' THEN AGEGROUP = 13;                               
ELSE IF (AGE = 999 OR AGETYPE = 9) THEN AGEGROUP =12; ** AGE UNKNOWN **;
                                                                        
ELSE IF AGETYPE = 0 OR AGETYPE = 4 THEN DO;                             
     IF AGE = 0 THEN AGEGROUP = 1; *** UNDER 1 YEAR ***;                
     IF 1 <= AGE <= 4 THEN AGEGROUP = 2; *** 1-4 YEARS ***;             
     IF 5 <= AGE <= 10 THEN AGEGROUP = 3; *** 5-10 YEARS ***;          
     IF 11 <= AGE <= 14 THEN AGEGROUP = 4; *** 11- 14 YEARS ***;        
     IF 15 <= AGE <= 19 THEN AGEGROUP = 5; *** 15-19 YEARS ***;         
     IF 20 <= AGE <= 24 THEN AGEGROUP = 6; *** 20-24 YEARS ***;         
     IF 25 <= AGE <= 29 THEN AGEGROUP = 7; *** 25-29 YEARS ***;         
     IF 30 <= AGE <= 39 THEN AGEGROUP = 8; *** 30-39 YEARS ***;         
     IF 40 <= AGE <= 49 THEN AGEGROUP = 9; *** 40-49 YEARS ***;         
     IF 50 <= AGE <= 59 THEN AGEGROUP = 10; *** 50-59 YEARS ***;        
     IF 60 <= AGE <= 998 THEN AGEGROUP = 11; *** 60 + ***;              
END;                                                                    
                                                                        
                                                                        
ST=FIPNAMEL(STATE);                                                     
IF STATE = 70 THEN ST = 'NYC';                                          
                                                                                                                                                                                                                                                                                                                                                                                                  
AGEMO=(EVENTD-BIRTHD)/30.25;                                            
IF AGEMO>=0 AND AGEMO<2 THEN AGEMNTHS=1;                                
IF AGEMO>=2 AND AGEMO<6 THEN AGEMNTHS=2;                                
IF AGEMO>=6 AND AGEMO<12 THEN AGEMNTHS=3;                               
IF AGEMO>=12 AND AGEMO<60 THEN AGEMNTHS=4;                              
                                                                        
IF IN1FECT=2 OR IN2FECT=2 OR IN3FECT=2 THEN MENING=1; ELSE MENING=2;    
                                                                        
IF AGEGROUP IN (1,2) THEN AGEGRP=1;                                     
IF AGEGROUP IN (3,4) THEN AGEGRP=2;                                     
IF AGEGROUP IN (5,6,7,8,9) THEN AGEGRP=3;                               
IF AGEGROUP IN (10,11) THEN AGEGRP=4;                                   
IF AGEGROUP IN (12,13) THEN AGEGRP=9;                                   
IF AGEGROUP=. THEN AGEGRP=9;                                            

IF SEROTYPE=. THEN SEROTYPE=9; 

run;

 
DATA hisummary;                                                              
  SET hilook;                                                              
  IF COUNT NE 1;  

ods tagsets.ExcelXP file="\\cdc\project\NIP_Project_Store1\Surveillance\SAS_output\2021-NetssCaseSASSpinOffWeek52_vw\&year-&libname-hi summary cases.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="yes");
                                                                   
PROC PRINT; BY YEAR; VAR COUNT ST;                                      
TITLE j=l bold h=10pt color=red "SUMMARY COUNT CASES-THIS SHOULD BE ZERO";                        
FORMAT  SEX SEX. AGEGROUP AGE.;   
run; 

ods tagsets.ExcelXP close ; 
                                                                                                                                                                                             
 
data hicases;
set hilook;

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
          14 = 'AGE NOT REPORTED';

 VALUE SEROFF                                                          
      1='TYPE B'                                                       
      2='NOT TYPABLE'                                                   
      8='OTHER TYPE'                                                   
      9='NOT TESTED/ UNKNOWN'                                                
      3-7='NOT TESTED/ UNKNOWN';   

VALUE STAT 1 = 'CONFIRMED'
           2 = 'PROBABLE'
           3 = 'SUSPECT'
           9 = 'UNK STATUS';


 
PROC SORT;                                                          
BY YEAR STname ;                                                                                                                         
*PROC PRINT;   
 *TITLE 'print of cases';
  *BY STATE;                                                             
  *VAR STNAME BIRTHD AGEGROUP SEROTYPE eventd;     
      *format birthd mmddyy8. eventd mmddyy8.; 
run;

ods tagsets.ExcelXP file="\\cdc\project\NIP_Project_Store1\Surveillance\SAS_output\2021-NetssCaseSASSpinOffWeek52_vw\&year-&libname-hi casestat agegrp serotype.xls" Style=sasweb
options(EMBEDDED_TITLES="yes" WRAPTEXT="yes");

                                                                       
PROC FREQ;                                                             
BY YEAR;                                                             
WEIGHT COUNT;                                                         
TITLE j=l bold h=10pt color=red "HI CASES ALL AGES, CONF-PROB-UNK,&libname &year";
 TABLES CASSTAT*AGEGROUP/MISSING NOROW NOCOL NOPERCENT;                                      
 TABLES STNAME*SEROTYPE/MISSING NOROW NOCOL NOPERCENT;                                       
 TABLES CASSTAT*SEROTYPE/MISSING NOROW NOCOL NOPERCENT;                                     
 TABLES AGEGROUP*SEROTYPE/MISSING NOROW NOCOL NOPERCENT;                                     
FORMAT AGEGROUP AGE. SEROTYPE SEROFF. casstat stat.;
run; 

PROC FREQ;
BY year;
WEIGHT COUNT;       
WHERE AGEGROUP LT 3;                                                  
TITLE j=l bold h=10pt color=red "HI CASES < 5 YRS , CONF-PROB-UNK,&libname &year";                      
 TABLES CASSTAT*AGEGROUP/MISSING NOROW NOCOL NOPERCENT;                                      
 TABLES STNAME*SEROTYPE/MISSING NOROW NOCOL NOPERCENT;                                       
 TABLES CASSTAT*SEROTYPE/MISSING NOROW NOCOL NOPERCENT;                                     
 TABLES AGEGROUP*SEROTYPE/MISSING NOROW NOCOL NOPERCENT; 
FORMAT AGEGROUP AGE. SEROTYPE SEROFF. casstat stat. ;
run; 

ods tagsets.ExcelXP close ; 



