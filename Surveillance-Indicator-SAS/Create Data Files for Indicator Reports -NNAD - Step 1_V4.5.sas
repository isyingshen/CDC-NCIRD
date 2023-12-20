 /**********************************************************************************/
 /*This program creates the data for populating the Surveillance Indicator         */
 /*Reports on Stage 4 HL7 data (NNAD).  The programs are such that they can be run */
 /*all together just by editing the Start and End Year & Output folder.            */
 /**********************************************************************************/

 /***************************************************************************************/
 /* Date Modified: 2021/Mar/24                                                          */
 /* Modified by: Ying Shen                                                              */
 /* Changes: updated the program based on the newest version of Starter Code            */
 /*(\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\             */
 /*NCIRD NNDSS Analytic Database (NNAD) for programs\Code\Pathogen Specific Code        */
 /*\COVID-19\Production\Starter Code)                                                   */
 /*    Added the dedup part in code                                                     */
 /*    Updated to the newest QCNNAD Formats                                             */
 /*    Updated to the newest Macro folder                                               */
 /*    Created a macro to pull data and process data for each condition                 */
 /*                                                                                     */
 /* Date Modified: 2021/Mar/29                                                          */
 /* Modified by: Ying Shen                                                              */
 /*    Created a new data dictionary at &FilePath\Data to extract vars                  */
 /*    Added a snippet to convert extract column to character if it's numeric           */
 /*    Updated compress(Extract_&condtx) = "1"; Used compress function to remove spaces */
 /*                                                                                     */
 /* Date Modified: 2021/Mar/31                                                          */
 /* Modified by: Ying Shen                                                              */
 /*    Changed the location of IndRpts to 2021Currentdata.file                          */
 /*    Changed the output dataset to indrpts.HL7_&condtx instead of indrpts.HL7         */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/07                                                          */
 /* Modified by: Ying Shen                                                              */
 /*    Added a macro to convert data type from character to numeric                     */
 /*    Updated the data type conversion for age_invest, mmwr_week,                      */ 
 /*             illness_duration, mmwr_year,days_in_hosp n_count                        */
 /*    Removed special missing (E)                                                      */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/09                                                          */
 /* Modified by: Ying Shen                                                              */
 /*    Updated Calculate age in year part: changed iage_invest to age_invest because    */
 /*       iage_invest is blank                                                          */
 /*                                                                                     */
 /* Date Modified: 2021/Apr/22                                                          */
 /* Modified by: Ying Shen                                                              */
 /*    Added Varicella_C.sas                                                            */
 /*                                                                                     */
 /* Date Modified: 2021/May/06                                                          */
 /* Modified by: Ying Shen                                                              */
 /*    Added Rubella_B.sas                                                              */
 /*                                                                                     */
 /* Date Modified: 2021/DEC/30                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Updated the nnad server name to DSPV-VPDN-1601,59308\qsrv1                 */
 /*                                                                                     */
 /* Date Modified: 2022/Feb/09                                                          */
 /* Modified by: Sang Kang                                                              */
 /*          Updated the stage4 extraction to include week5253_flag.                    */ 
 /*                                                                                     */
 /* Date Modified: 2022/Mar/02                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          Added a macro NNADData to control data source                              */
 /*          Added a if-else to switch back and forth between NNAD st4 and week5253     */ 
 /*          Added a filter of week5253_flag not null                                   */ 
 /*             where coalescec(c.week5253_flag,d.week5253_flag,'') in ('&EndYear');    */
 /*                                                                                     */
 /* Date Modified: 2022/Mar/04                                                          */
 /* Modified by: Sang Kang /Ying Shen                                                   */
 /*          Added two more columns for the Not Found table:                            */ 
 /*          Found_nnad_stg4 and Found_mvps_spinoffvw                                   */
 /*                                                                                     */
 /* Date Modified: 2022/Mar/04                                                          */
 /* Modified by: Sang Kang /Ying Shen                                                   */
 /*          Added two more columns for the Not Found table:                            */ 
 /*          Found_nnad_stg4 and Found_mvps_spinoffvw                                   */
 /*                                                                                     */
 /* Date Modified: 2022/Mar/07                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          change the filter for week5253 and add historic data into week5253 report  */
 /*          added message_received in mvpsspinoffvw                                    */
 /*                                                                                     */
 /* Date Modified: 2022/Mar/16                                                          */
 /* Modified by: Ying Shen                                                              */
 /*          updated the include program: varicella_b3                                  */
 /*                                                                                     */
 /* Date Modified: 2023/SEP/18                                                          */
 /* Updated by: Jodi Baldy                                                              */
 /*   ?|       updated data dictionary                                                    */

 /***************************************************************************************/

%Let StartYear = 2016 ;
%Let EndYear = 2022 ;
/*%Let EndYr = %substr(&EndYear,3,2) ;*/
%Let NNADData = current; /*| wk5253  NNAD data to control the data source*/ 

/*Identify the name of the folder in "&FilePath\Data"  and "&FilePath\Output" where the data and output will be stored.  */
/*The folders must be created manually before running the program. ;*/
/*use naming convention, e.g., 2017Wk52data.files; */
%Let Folder = 2022Currentdatatest.files(JB) ; 

/*Select the production or development environment. */
%Let FilePath = \\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_Indicators_NNAD; 
* Development Folder for Stage 4 NNAD data;

options nofmterr;

/*Define Indrpts libref;*/
libname IndRpts "&FilePath\Data\&Folder" ;

%let rootdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NMI\Dev\Sang\StarterCode;
%let fmtdir = &rootdir\Formats;

/* Analysts will need to modify directory to location of Macro code            */
/* Note: Sasautos specifies folders to search in the order to locate the macro */
options mprint mlogic noxwait symbolgen compress=yes
        sasautos =  (sasautos,
                     "&rootdir\NNAD Macros"
                     );

/* Analysts will need to assign location of Data Dictionary */
libname sasfmt "&fmtdir";

/* Excel file containing formats referenced in data dictionary */
libname qcfmt XLSX "\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NCIRD NNDSS Analytic Database (NNAD) for programs\Code\Pathogen Specific Code\NON_COVID\Formats\QCNNADFormats.xlsx" access=readonly;


libname comfmt XLSX "&fmtdir\NETSStoHL7Formats.xlsx" access=readonly;

/* excel dictionary with user extract flag */
libname usrD XLSX "\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_Indicators_NNAD\DataDictionary_eachcond_surv_indi.xlsx" access=readonly;

*This line connects to the NNAD staging database;
/*libname NNAD OLEDB*/
/*        provider="sqloledb"*/
/*        properties = ( "data source"="DSSV-INFC-1601,53831\QSRV1"*/
/*                       "Integrated Security"="SSPI"*/
/*                       "Initial Catalog"="NCIRD_DVD_VPD_COVIDTF" ) schema=NNDSS access=readonly;*/

*This line connects to the NNAD production database;
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;
                       
libname MVPS OLEDB
        provider="sqloledb"
        properties = ( "data source"="mvpsdata,1201\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="MVPS_Prod" ) schema=NETSS access=readonly;                       

/* state FIPS format */
proc format cntlin = comfmt.'statefips'n;run;  
libname comfmt clear;

/*Macro to convert numeric var to character*/
%macro toChar(dbname, varname);
data &dbname;
	set &dbname;
	newvar=vvalue(&varname);
	drop &varname;
	rename newvar=&varname;
run;
%mend toChar;


/* extract Stage4 variable list from excel dictionary and assign to macro */

%macro pullData(condtx=,condcd=);

proc sql noprint;
   /* create SAS dataset of the condition specific dictionary */
   create table stage4dict as
   select *
   from usrD.stage4MasterVars
   where &condtx = "1";
 quit;
 
/*convert the extract column to text*/
data stage4dict;
	set stage4dict;
/*	length newvar $1;*/
	newvar=vvalue(Extract_&condtx);
	drop Extract_&condtx;
	rename newvar=Extract_&condtx;
run;


proc sql noprint;
   /* create SAS dataset of the variable tagged for extraction */
   create table extraction_variables as
   select Var_Name, Formats_AllCond_NCIRD
   from stage4dict
   where compress(Extract_&condtx) = "1";
   
   /* macro vlist is used in data extraction */
   select Var_Name
   into :vlist separated by " "
   from extraction_variables;

   %put List of variables to extract: &vlist;

   /* Full list of variable and format */
   select trim(left(Var_Name)) || " " || trim(left(Formats_AllCond_NCIRD))
   into :varfmtlist separated by " "
   from extraction_variables
   where Formats_AllCond_NCIRD ^= ""; 
   
   /* remove dollar and period from format to obtain distinct worksheet name.   */
   /* macro fmtsheetlist is used in macro ExlFmt to read in excel format sheets */
   /* format_common column is the default format but it can be overwritten by   */
   /* format name from the column specific to the condition                     */
   select distinct compress(Formats_AllCond_NCIRD,"$.")
   into :fmtsheetlist  separated by " "
   from  extraction_variables
   where Formats_AllCond_NCIRD ^= "";
   
   /* remove dollar and period from format name.  That name will match worksheet name */
   select Var_Name, Formats_AllCond_NCIRD, compress(Formats_AllCond_NCIRD,'$.')
   into :vname1- , :fmtname1-, :fmtsheet1-
   from extraction_variables
   where Formats_AllCond_NCIRD ^= "";
   
   %let Vtotal = &sqlobs; /* total number of variables extracted using flag Extract = 1 */
quit;


/* Read in worksheets containing formats referenced in the dictionary */
%ExlFmt(LibN=qcfmt, SheetN=&fmtsheetlist);


%If (&NNADData=wk5253) %then %do;

/***************************************************/
/* Prepare frozen week52 cases for the match merge */
proc sql noprint;
   create table mvpspinoff as
   select distinct trim(left(put(year,8.))) as mmwr_year, left(put(state,stfips.)) as report_jurisdiction,
                   expanded_caseid, site,message_received
   from MVPS.NetssCaseSASSpinOff_vw
   where event in (&condcd) and year >= &StartYear and year <= &EndYear  
   order by mmwr_year, report_jurisdiction, expanded_caseid, site   
   ;
   create table frozenweek5253_Loc as
   select distinct mmwr_year, report_jurisdiction, local_record_id, expanded_caseid, site, week5253_flag
   from NNAD.NetssCaseSASSpinOffWeek52_Keys
   where condition in ("&condcd") and mmwr_year >= "&StartYear" and mmwr_year <="&EndYear"
   order by mmwr_year, report_jurisdiction, local_record_id, site
   ;
   /* to be used as secondary match where local record id is expanded caseid */
   create table frozenweek5253_Exp as
   select distinct mmwr_year, report_jurisdiction, expanded_caseid as local_record_id, site, week5253_flag
   from NNAD.NetssCaseSASSpinOffWeek52_Keys
   where condition in ("&condcd") and mmwr_year >= "&StartYear" and mmwr_year <="&EndYear"
   order by mmwr_year, report_jurisdiction, local_record_id, site
   ;   
   /* by default UNION keeps distinct records */
   create table frozenweek5253 as
   select mmwr_year, report_jurisdiction, local_record_id, site, week5253_flag
   from frozenweek5253_Loc
   union
   select *
   from frozenweek5253_Exp
   order by mmwr_year, report_jurisdiction, local_record_id, site
   ;
quit; 
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*Using the Macro provided will cut down on the processing time and create a ready-to-go analytic database.*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

%extractstg4(outdatasetname=stg4_Exl,
             SQLlibname=NNAD,
             Stg4DictName=stage4dict,
             filter=%nrstr(condition in ("&condcd") and 
                           mmwr_year >= "&StartYear" and mmwr_year <="&EndYear"),
             /*only edit below this comment line*/
             varlist= &vlist
            ); /* end of macro call */

%extractstg4(outdatasetname=stg4_manual,
             SQLlibname=NNAD,
             Stg4DictName=stage4dict,
             filter=%nrstr(condition in ("&condcd") and 
                           mmwr_year >= "&StartYear" and mmwr_year <="&EndYear"),
             /*only edit below this comment line*/
             varlist= source_system case_status n_expandedcaseid n_cdcdate result_status
             
         );
;*/;*;*;*;*/;*;*;quit;run; /* this line exits from unbalanced quotation problem and others */;
         
/* merge multiple extractions into one dataset */
proc sql noprint;
   create table stg4_year as
   select a.*, b.*, coalescec(c.week5253_flag,d.week5253_flag,'') as week5253_flag length=200
   from stg4_Exl as a left join stg4_manual as b 
   on a.condition = b.condition and a.report_jurisdiction = b.report_jurisdiction and
      a.local_record_id = b.local_record_id and a.mmwr_year = b.mmwr_year and a.site = b.site and
      a.wsystem = b.wsystem and a.dup_sequenceID = b.dup_sequenceID
   left join frozenweek5253 as c on a.mmwr_year = c.mmwr_year and a.report_jurisdiction = c.report_jurisdiction
             and a.local_record_id = c.local_record_id and a.site = c.site
   left join frozenweek5253_Exp as d on b.mmwr_year = d.mmwr_year and b.report_jurisdiction = d.report_jurisdiction
             and b.n_expandedcaseid = d.local_record_id and b.site = d.site                

	where (coalescec(c.week5253_flag,d.week5253_flag,'') in ("&EndYear") and c.mmwr_year in ("&EndYear"))
	or (a.mmwr_year not in ("&EndYear"));
quit;

/*=================Report unfound frozen cases===============================*/
/* This section identifies cases in Frozen Week52 that are not found in NNAD */
proc sort data=stg4_manual(keep=mmwr_year report_jurisdiction local_record_id site n_expandedcaseid) 
          out=stg4keys;
   by mmwr_year report_jurisdiction local_record_id site;
run;
data notfoundinStg4;
   merge frozenweek5253_loc(in=left) stg4keys(in=right);
   by mmwr_year report_jurisdiction local_record_id site;
   if (left and not right);
run;

/* second match based on expanded_caseid. */
proc sort data=notfoundinStg4;
   by mmwr_year report_jurisdiction expanded_caseid site;
run;
proc sort data=stg4keys(drop=local_record_id where=(n_expandedcaseid ne '')) 
          out=stg4keys_exp(rename=(n_expandedcaseid = expanded_caseid));
   by mmwr_year report_jurisdiction n_expandedcaseid site;
run;
/* report records in week52 not found after second match based on expanded_caseid. */
data notfoundstg4_after_2ndmatch(drop=n_expandedcaseid);
   merge notfoundinStg4(in=left) stg4keys_exp(in=right) mvpspinoff(in=mvps);
   by mmwr_year report_jurisdiction expanded_caseid site;
   length Found_nnad_stg4 $2 Found_mvps_spinoffvw $3;
   
   if (left and not right) then do;  /* only then not in NNAD the output is triggered */
      Found_nnad_stg4 = "no";
      if (mvps) then /* found in MVPS spinoff */
         Found_mvps_spinoffvw = "yes";
      else
         Found_mvps_spinoffvw = "no";      
      output;  /* only the not found in stg4 but in frozen are outputted */
   end;
run;
Proc print data=notfoundstg4_after_2ndmatch;
   title "Following frozen week52 cases are not found in the extraction for condition = &condcd and &StartYear <= mmwr_year <=&EndYear";
run;
/*===========================================================================*/

%end;

%else %do;

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*Using the Macro provided will cut down on the processing time and create a ready-to-go analytic database.*/
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

%extractstg4(outdatasetname=stg4_Exl,
             SQLlibname=NNAD,
             Stg4DictName=stage4dict,
             filter=%nrstr(condition in ("&condcd")),
             /*only edit below this comment line*/
             varlist= &vlist
            ); /* end of macro call */

%extractstg4(outdatasetname=stg4_manual,
             SQLlibname=NNAD,
             Stg4DictName=stage4dict,
             filter=%nrstr(condition in ("&condcd")),
             /*only edit below this comment line*/
             varlist= source_system case_status n_expandedcaseid n_cdcdate result_status
             
         );

/* merge multiple extractions into one dataset */
/* merge multiple extractions into one dataset */
proc sql noprint;
   create table stg4 as
   select *
   from stg4_Exl as a left join stg4_manual as b 
   on a.condition = b.condition and a.report_jurisdiction = b.report_jurisdiction and
      a.local_record_id = b.local_record_id and a.mmwr_year = b.mmwr_year and a.site = b.site and
      a.wsystem = b.wsystem and a.dup_sequenceID = b.dup_sequenceID           
   ;
quit;

/*Add the year filter*/
proc sql noprint;
create table stg4_year as
select *
from stg4
where mmwr_year >= "&StartYear" and mmwr_year <="&EndYear";
quit;


%end;



/* DEDUPLICATION AND DATA CLEANING FOR NNAD STAGE4 DATA*/
data stage4_&condcd error_nokey;
   set stg4_year;

   if (source_system in (5,15)) then 
      firstkey=cats(report_jurisdiction,compress(local_record_id)); /* For HL7 records, look at local_record_id */
   else if ((source_system=1) and (WSYSTEM=5)) then
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* For NETSS records created from MVPS, look at n_expandedcaseid */  
   else if ((source_system=1) and (WSYSTEM NE 5)) then
      firstkey=cats(report_jurisdiction,compress(local_record_id),site,mmwr_year); /* For other NETSS records, look at local_record_id (CASEID), site, mmwr_year */

   output stage4_&condcd;

   if (firstkey = '') then
      output error_nokey;
run;
proc sort tagsort data=stage4_&condcd;
   by firstkey descending source_system descending n_cdcdate; /* Prefer HL7 record over NETSS duplicate, newer NETSS record over older */
run;


/* Duplicates by match of local_record_id/n_expandedcaseid are removed */
data stage4_clean stage4_remove;
   set stage4_&condcd;
   by firstkey;

   if ((first.firstkey) and (result_status NE "X") and (case_status NE "PHC178")) then
      output stage4_clean;
   else 
      output stage4_remove;
run;

/* This macro is to convert character to numeric;*/
data stage4_clean(drop= T_mmwr_year T_mmwr_week T_illness_duration T_age_invest T_days_in_hosp T_n_count);
	set stage4_clean(rename=(mmwr_year=T_mmwr_year mmwr_week=T_mmwr_week illness_duration=T_illness_duration
                            age_invest=T_age_invest days_in_hosp=T_days_in_hosp n_count=T_n_count));
                            
   length mmwr_year mmwr_week illness_duration age_invest days_in_hosp n_count 8.;
   
	mmwr_year=input(T_mmwr_year,4.);
	mmwr_week=input(T_mmwr_week,4.);
   illness_duration=input(T_illness_duration,4.);
	age_invest=input(T_age_invest,4.);   
	days_in_hosp=input(T_days_in_hosp,4.);  
	n_count=input(T_n_count,4.);     
run;

data nnad;
   set stage4_clean;
   options fmtsearch=(library.nnadformats);
   format &varfmtlist;

/*   Calculating age in years;*/

  if (age_invest_units = 'a') then
      age = age_invest;
   else if (age_invest_units = 'mo') then
      age = int(age_invest/12);
   else if (age_invest_units = 'wk') then
      age = int(age_invest/52);
   else if (age_invest_units = 'd') then
      age = int(age_invest/365.25);
   else if (age_invest_units = 'h') then
      age = int(age_invest/8760);
   else if (age_invest_units = 'min') then
      age = int(age_invest/525600);
   else if (age_invest_units='s') then
      age = int(age_invest/32000000);
   else if (age_invest_units='UNK' or age_invest=9999) then
      age=999;
   else
      age=.; /*leaves other values as missing;*/

/*   parsing out local_subject_id;*/

   local_subject_id = scan(local_subject_id, 1, '^');
run;



/*Reformatting date variables to SAS date;*/

/*Creating macro variables;*/
proc sql noprint;
   select compress(NAME)
   into :dtlist separated by " "
   from dictionary.columns
   where libname='WORK' and format='DATETIME22.3' and memname='NNAD';

   /*creates idummy variable names*/
   select catt(compress(NAME, "_"), "_i")
   into :idtlist separated by ' '
   from dictionary.columns
   where libname='WORK' and format='DATETIME22.3' and memname='NNAD';

   select count(NAME)
   into :num separated by " " /*enumerates number of variables*/
   from dictionary.columns
   where libname='WORK' and format='DATETIME22.3' and memname='NNAD';

   /*create list of variables to rename*/
   select catt(catt(compress(NAME, "_"), "_i"), '= ', NAME)
   into :relist separated by ' '
   from dictionary.columns
   where libname='WORK' and format='DATETIME22.3' and memname='NNAD';
quit;


/*Array to convert data;*/
data nnad;
   set nnad;

   format &idtlist mmddyy10.;
   array dtchng{&num} &dtlist;
   array idtchng{&num} &idtlist;
   do i=1 to &num;
      idtchng{i}=datepart(dtchng{i});
   end;

   drop &dtlist i;
run;

/*Renaming converted data variables to original variable names;*/
proc datasets lib=work nolist;
   modify nnad;
   rename &relist;
run;
quit;

/********************************************************************/
/*Include this code snippet if you would like to explode out NETSS cases with a count>1.*/
/*Note, that these cases will be EXACT duplicates, so do not run a deduplication code*/
/*without differentiating these records.*/
/*If you don not choose to use the code below, the count variable will need to be included in*/
/*any summary analyses to get correct case counts;*/
/*******************************************************************;*/
data nnad;
   set nnad;

   if n_count<1 then
      n_count=1;

   do i=1 to n_count; /* explode NETSS cases with a count > 1 */
      output;
   end;
   drop i;
run;

data temp;
   set nnad;
   pk = compress(local_record_id||mmwr_year||condition||wsystem);
run;

proc sql noprint;
   create table temp2 as
   select *, count(pk) as freq
   from temp
   group by pk;
quit;
run;

/*Removing duplicate HL7 records where site is NULL/S01;*/

data nnad;
   set temp2;
   if (freq > 1 and site = 'S01' and source_system ne 1) then
      delete;
run;

/*convert character variables;*/
data indrpts.HL7_&condtx;
set nnad;
	year = mmwr_year;
	state = input(report_jurisdiction, 6.);
	event = input(condition, 5.);
run;

%mend pullData;


*Create data files;
/* column name   : generic  pertussis   mumps    varicella   H_influenzae   N_meningitidis IPD   Psittacosis Legionellosis  Measles  Rubella  CRS    */
/* condition code: 00000    10190       10180    10030       10590          10150          11723 10450       10490          10140    10200    10370  */


%pullData(condtx=mumps,condcd=10180);
%include "&FilePath\SAS Code\Mumps_B.sas" / source2 ;
%pullData(condtx=pertussis,condcd=10190);
%include "&FilePath\SAS Code\Pertussis_B.sas" / source2 ;
%pullData(condtx=varicella,condcd=10030);
%include "&FilePath\SAS Code\Varicella_B4.sas" / source2 ;
%pullData(condtx=measles,condcd=10140);
%include "&FilePath\SAS Code\Measles_B.sas" / source2 ;
%pullData(condtx=Rubella,condcd=10200); 
%include "&FilePath\SAS Code\Rubella_B5.sas" / source2 ; 
%pullData(condtx=H_influenzae,condcd=10590); 
%include "&FilePath\SAS Code\Hflu_B.sas" / source2 ;
%pullData(condtx=N_meningitidis,condcd=10150); 
%include "&FilePath\SAS Code\Mening_B.sas" / source2 ; 
%pullData(condtx=IPD,condcd=11723); 
%include "&FilePath\SAS Code\IPD_B.sas" / source2 ;


