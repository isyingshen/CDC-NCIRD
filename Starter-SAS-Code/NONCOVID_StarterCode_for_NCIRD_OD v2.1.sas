/*******************************************************************************************************************/
/* Starter Code                                                                                                    */
/*                                                                                                                 */
/* This code is used to pull condition cases from the Stage 4 NCIRD NNDSS Analytic Database (NNAD).                */
/*                                                                                                                 */
/* Changes on 9/28/2020:  Addition of macro to pull formats automatically.                                         */
/*                        Also, addition of ODS statements to write output to files.                               */
/* Changes on 11/25/2020: Column L brings in the corresponding Format label.                                       */
/* Changes on 9/9/2021:   Added three database environments to this one code: Prod, staging and test               */
/* Changes on 9/9/2021:   Converted '=num' to 'num'. For example, '=25' to '25' for age_invest, mmwr_week and      */
/*                        days_in_hosp                                                                             */
/* Changes on 9/9/2021:   Added proc sql to look at frequency instead of proc freq, because proc sql is able to    */
/*                        output '.Y'. Proc freq read .Y as missing.                                               */
/* Changes on 12/20/2021: updated the unique key from local_record_id to expended_caseID in the dedup code         */
/* Changes on 1/13/2022:  convert mmwr_week from char to num so that 0x(e.g.,07) will be converted to x(e.g.,7)    */
/* Changes on 3/21/2022:  Updated the stage4 extraction to include week5253_flag.                                  */
/* Changes on 3/21/2022:  Add a control macro to switch week5253 back to nnad stage4                               */
/* Changes on 12/7/2023:  By Ying Shen Remove the code to convert .E, .Y and variable age                          */
/* Changes on 12/8/2023:  By Ying Shen Add back variable age                                                       */
/*                                                                                                                 */
/* Analysts will need to modify the folder directory to their location of the Macro code, Format code,             */
/*    Excel Data Dictionary and the stage4dictionary dataset.                                                      */
/*                                                                                                                 */
/* Please read ALL comments in the code,and only edit code where indicated (e.g., at locations noted with *!!!!!). */
/*                                                                                                                 */
/*                                                                                                                 */
/* Brief descriptions for each step are listed below. The variable list can be managed using the Excel             */
/*    Data Dictionary and specifying 1 in column K Extract column for any variables analyst wishes to              */
/*    include in analysis.  Column L brings in the corresponding Format label.                                     */
/*                                                                                                                 */
/* This version works with all cases with de-dup all variables created from the epi lab repeating group.           */
/* Changes on 4/23/2021 removed "& report_jurisdiction in ("20") & mmwr_year in ("2020")" in both %extractstg4 macros*/
/*******************************************************************************************************************/
/* column name   : generic  pertussis   mumps    varicella   H_influenzae   N_meningitidis IPD   Psittacosis Legionellosis  Measles  Rubella  CRS    Tetanus */
/* condition code: 00000    10190       10180    10030       10590          10150          11723 10450       10490          10140    10200    10370  10210   */

%let condtx = Pertussis;
%let condcd = 10190;

/* Analysts will need to modify location of root directory */
%let rootdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NCIRD NNDSS Analytic Database (NNAD) for programs\Code\Pathogen Specific Code\NON_COVID;
%let macdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NCIRD NNDSS Analytic Database (NNAD) for programs\Code;
%let fmtdir = &rootdir\Formats;


/* Analysts will need to modify directory to location of Macro code            */
/* Note: Sasautos specifies folders to search in the order to locate the macro */
options noxwait NOQUOTELENMAX
        sasautos =  (sasautos,
                     "&macdir\NNAD Macros"
                     );
                     
/* Analyst will need to assign location of output */
%let output = &rootdir\Outputs;

/* Analysts will need to assign location of Data Dictionary */
libname sasfmt "&fmtdir";

/* Excel file containing formats referenced in data dictionary */
libname qcfmt XLSX "&fmtdir\QCNNADFormats.xlsx" access=readonly;

/* excel dictionary with user extract flag */
libname usrD XLSX "&fmtdir\DataDictionary_eachcond.xlsx";


*This line connects to the NNAD Production database;
*libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;

libname NNAD OLEDB
        provider="sqlncli11"
        properties = ( "data source"="DSPV-INFC-1601\QSRV1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;


*This line connects to the NNAD Staging database;
/*Analysts will need to uncomment it to use!!!*/
/*libname NNAD OLEDB*/
/*        provider="sqloledb"*/
/*        properties = ( "data source"="DSSV-INFC-1601\QSRV1"*/
/*                       "Integrated Security"="SSPI"*/
/*                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;*/

*This line connects to the NNAD Test database;
/*Analysts will need to uncomment it to use!!!*/
/*libname NNAD OLEDB*/
/*        provider="sqloledb"*/
/*        properties = ( "data source"="DSTV-INFC-1601\QSRV1"*/
/*                       "Integrated Security"="SSPI"*/
/*                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;*/


/* extract Stage4 variable list from excel dictionary and assign to macro */

/*  Analyst note: The variable list can be managed using the Excel Data Dictionary,and specifying
                  1 in column Extract_<condition name> column for any variables analyst wishes to 
                  include in analysis.
                  Due to the SAS field vlist constraint of 6000 character limit, recommendation is
                  to limit extract column to 150 to 180 variables.
                  For deduplication below, analyst must select the source_system, n_expandedcaseid
                  columns from the Excel Data Dictionary. */

/*convert the extract column to text*/
/*data usrD.stage4MasterVars;*/
/*	set usrD.stage4MasterVars;*/
/*	newvar=vvalue(Extract_&condtx);*/
/*	drop Extract_&condtx;*/
/*	rename newvar=Extract_&condtx;*/
/*run;*/


proc sql noprint;
   /* create SAS dataset of the condition specific dictionary */
   create table stage4dict as
   select *
   from usrD.stage4MasterVars
   where  &condtx = '1'
   ;
   
   /* create SAS dataset of the variable tagged for extraction */
   create table extraction_variables as
   select Var_Name, Formats_AllCond_NCIRD
   from stage4dict
   where  Extract_&condtx = '1'
   ;
   
   /* macro vlist is used in data extraction */
   select Var_Name
   into :vlist separated by ' '
   from extraction_variables
   ;

   %put List of variables to extract: &vlist;

   /* Full list of variable and format */
   select trim(left(Var_Name)) || ' ' || trim(left(Formats_AllCond_NCIRD))
   into  :varfmtlist separated by ' '
   from  extraction_variables
   where Formats_AllCond_NCIRD ^= ''
   ; 
   
   /* remove dollar and period from format to obtain distinct worksheet name.   */
   /* macro fmtsheetlist is used in macro ExlFmt to read in excel format sheets */
   /* format_common column is the default format but it can be overwritten by   */
   /* format name from the column specific to the condition                     */
   select distinct compress(Formats_AllCond_NCIRD,'$.')
   into :fmtsheetlist  separated by ' '
   from  extraction_variables
   where Formats_AllCond_NCIRD ^= ''
   ;
   
   /* remove dollar and period from format name.  That name will match worksheet name */
   select Var_Name, Formats_AllCond_NCIRD, compress(Formats_AllCond_NCIRD,'$.')
   into :vname1- , :fmtname1-, :fmtsheet1-
   from  extraction_variables
   where Formats_AllCond_NCIRD ^= ''
   ;
   
   %let Vtotal = &sqlobs; /* total number of variables extracted using flag Extract = 1 */
quit;


/* Read in worksheets containing formats referenced in the dictionary */
%ExlFmt(LibN=qcfmt, SheetN=&fmtsheetlist);

/***************************************************/
/* Prepare frozen week52 cases for the match merge */
proc sql noprint;
   create table frozenweek5253_Loc as
   select distinct mmwr_year, report_jurisdiction, local_record_id, expanded_caseid, site, week5253_flag
   from NNAD.NetssCaseSASSpinOffWeek52_Keys
   where condition in ("&condcd")
   order by mmwr_year, report_jurisdiction, local_record_id, site
   ;
   /* to be used as secondary match where local record id is expanded caseid */
   create table frozenweek5253_Exp as
   select distinct mmwr_year, report_jurisdiction, expanded_caseid as local_record_id, site, week5253_flag
   from NNAD.NetssCaseSASSpinOffWeek52_Keys
   where condition in ("&condcd")
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

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Using the Macro provided will cut down on the processing time and create a ready-to-go analytic database.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

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
;*/;*;*;*;*/;*';*";quit;run; /* this line exits from unbalanced quotation problem and others */

/* merge multiple extractions into one dataset */
proc sql noprint;
   create table stg4 as
   select a.*, b.*, coalescec(c.week5253_flag,d.week5253_flag,'') as week5253_flag length=200
   from stg4_Exl as a left join stg4_manual as b 
   on a.condition = b.condition and a.report_jurisdiction = b.report_jurisdiction and
      a.local_record_id = b.local_record_id and a.mmwr_year = b.mmwr_year and a.site = b.site and
      a.wsystem = b.wsystem and a.dup_sequenceID = b.dup_sequenceID   
   left join frozenweek5253 as c on a.mmwr_year = c.mmwr_year and a.report_jurisdiction = c.report_jurisdiction
             and a.local_record_id = c.local_record_id and a.site = c.site 
   left join frozenweek5253_Exp as d on b.mmwr_year = d.mmwr_year and b.report_jurisdiction = d.report_jurisdiction
             and b.n_expandedcaseid = d.local_record_id and b.site = d.site              
   ;
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
   merge notfoundinStg4(in=left) stg4keys_exp(in=right);
   by mmwr_year report_jurisdiction expanded_caseid site;
   if (left and not right);
run;
Proc print data=notfoundstg4_after_2ndmatch;
   title "Following frozen week52 cases are not found in the extraction for condition = &condcd";
run;
/*===========================================================================*/

/* DEDUPLICATION AND DATA CLEANING FOR NNAD STAGE4 DATA*/
/*Note: If CASEID=0 for multiple cases in NETSS(with the same mmwr_year, report_jurisdiction and site),the code below that states "((source_system=1) and (WSYSTEM NE 5))" may dedup in a non-preferred way. */
/*For such situations, you may see unexpected drops in case numbers before and after deduplications. */
/*For such situations, it is recommended that you refer to the dataset before the dedup steps to review the detailed messages. That review will inform your determination about any coding changes needed for the missing NETSS identifier. */

data stage4_&condcd error_nokey;
   set stg4;
  
   if (source_system in (5,15)) then 
      firstkey=cats(report_jurisdiction,compress(local_record_id)); /* For HL7 records, look at local_record_id */
   else if ((source_system=1) and (WSYSTEM=5)) then
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* For NETSS records created from MVPS, look at n_expandedcaseid */  
   else if ((source_system=1) and (WSYSTEM NE 5)) then
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid),site,mmwr_year); /* For other NETSS records, look at local_record_id (CASEID), site, mmwr_year */

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

   if ((first.firstkey) and (result_status NE 'X') and (case_status NE 'PHC178')) then
      output stage4_clean;
   else 
      output stage4_remove;
run;


data nnad;
   set stage4_clean;

   options fmtsearch=(library.nnadformats);
   format &varfmtlist;
   
	/*	Convert '=num' to 'num'. For example, '=25' to '25'*/
	age_invest_c=compress(age_invest, '=');
	drop age_invest;
	rename age_invest_c=age_invest;

	mmwr_week_c=compress(mmwr_week, '=');
	drop mmwr_week;
	rename mmwr_week_c=mmwr_week;

/*	illness_duration_c=compress(illness_duration, '=');*/
/*	drop illness_duration;*/
/*	rename illness_duration_c=illness_duration;*/

	days_in_hosp_c=compress(days_in_hosp, '=');
	drop days_in_hosp;
	rename days_in_hosp_c=days_in_hosp;

   *Converting character to numeric and adding special missing (E);

   array old {6} age_invest mmwr_week  illness_duration mmwr_year
                  days_in_hosp n_count;
   array new{6} iage_invest immwr_week iillness_duration
                 immwr_year idays_in_hosp in_count;
   array remove{6} rage_invest rmmwr_week  rillness_duration
                    rmmwr_year rdays_in_hosp rn_count;

   do i=1 to 6;
      remove{i}=ifn(lengthn(compress(old{i}, "`~!@#$%^&*()-_=+\|[]{};:',?/", 'ak'))>=1,1,0);
      if (anyalpha(old{i})<1 and (index(old{i}, ">")>0 or index(old{i}, "+")) or
          index(old{i}, "<")>0 or index(old{i}, "=")>0) then
         remove{i}=2; /*indicating <, >, = + values and turning into number for .Y*/

/*      if (remove{i} = 1) then*/
/*         new{i} =.E ; *vaules with characters/special characters;*/
    
/**/
/*	else if (remove{i} = 2) then*/
/*         new{i} = compress(old{i},'<>+='); *values with mathematical characters;*/
      else if (remove{i} = 0) then
         new{i} = input(old{i}, 4.); *converts to numeric;
   end;

   drop age_invest mmwr_week  illness_duration mmwr_year rage_invest
        rmmwr_week  rillness_duration rmmwr_year days_in_hosp
        rdays_in_hosp n_count rn_count;

   rename iage_invest=age_invest immwr_week=mmwr_week iillness_duration=illness_duration 
          immwr_year=mmwr_year idays_in_hosp=days_in_hosp in_count=n_count;

   *Calculating age in years;

/*   if (iage_invest = .E) then*/
/*      age = .E;*/
/*   else */
if (age_invest_units = 'a') then
      age = iage_invest;
   else if (age_invest_units = 'mo') then
      age = int(iage_invest/12);
   else if (age_invest_units = 'wk') then
      age = int(iage_invest/52);
   else if (age_invest_units = 'd') then
      age = int(iage_invest/365.25);
   else if (age_invest_units = 'h') then
      age = int(iage_invest/8760);
   else if (age_invest_units = 'min') then
      age = int(iage_invest/525600);
   else if (age_invest_units='s') then
      age = int(iage_invest/32000000);
   else if (age_invest_units='UNK' or iage_invest=9999) then
      age=999;
   else
      age=.; *leaves other values as missing;

   *parsing out local_subject_id;

   local_subject_id = scan(local_subject_id, 1, '^');
run;

*Reformatting date variables to SAS date;

*Creating macro variables;
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


*Array to convert data;
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

*Renaming converted data variables to original variable names;
proc datasets lib=work nolist;
   modify nnad;
   rename &relist;
run;
quit;

******************************************************************
Include this code snippet if you would like to explode out NETSS cases with a count>1.
Note, that these cases will be EXACT duplicates, so do not run a deduplication code
without differentiating these records.
If you don't choose to use the code below, the count variable will need to be included in
any summary analyses to get correct case counts;
******************************************************************;
data nnad;
   set nnad;

   if n_count<1 then
      n_count=1;

   do i=1 to n_count; /* explode NETSS cases with a count > 1 */
      output;
   end;
   drop i;
run;

/*******************************************************************************************************
 In NETSS, the variable “SITE” has historically been used as one of the data elements that identify
 a unique case.  For case notifications received from jurisdictions via HL7 messages, but subsequently
 “NETSS-ified” by CSELS into the MMWR/NNDSS database, the first three characters in “Jurisdiction Code”
 (77969-4) are used to create “SITE” in NETSS. Thus, “SITE” is included as one of the data elements in
 the composite primary key (mmwr year, report jurisdiction, condition, wsystem) that identifies a
 unique case.  If a jurisdiction submits a “null” value for “SITE,” NNAD ETL assigns a value of “S01”
 (“state/jurisdiction”), because
 of the requirement for “SITE” to identify a unique case.

 For HL7 records that differ only by site in the composite primary key, an HL7 record will be kept for
 each occurrence of “SITE.” However, because MVPS does not include “SITE” in the case determination
 algorithm, there could be differences between case counts in MVPS and NNAD.

Note that not all differences in “SITE” definitively represent separate cases. For example,
a jurisdiction could submit a “NULL” value for “Jurisdiction Code” (HL7 data element that is
used by jurisdiction to indicate “SITE”), but then could submit the same case with the
“Jurisdiction Code” value populated, as updated information. Using the NNAD algorithm, this
would create two separate cases in the database. The programs must determine which of these
cases to include and/or exclude when performing analyses.

Below, sample code has been written to remove potentially duplicate cases where the composite
primary key differs only by “SITE” and where one of the values of site is “S01.” This code is
written as just one of multiple options for addressing potentially duplicated cases due to
differences in the “SITE” value. Each program will need to apply their own business rules and
methods to determine whether duplicates actually exist and how to manage that data:
********************************************************************************************************/

data temp;
   set nnad;
   pk = compress(local_record_id||mmwr_year||condition||wsystem);
run;

proc sql;
   create table temp2 as
   select *, count(pk) as freq
   from temp
   group by pk;
quit;
run;

*Removing duplicate HL7 records where site is NULL/S01;

data nnad;
   set temp2;
   if (freq > 1 and site = 'S01' and source_system ne 1) then
      delete;
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

%char2num(nnad,mmwr_week);


/*Output*/
/* Starter Code Report*/
ods _all_ close; 
ods listing;
ods noproctitle;
ods word file="&output\&condtx._STG_StarterCodeReport &SYSDATE9..docx";


PROC FORMAT;
         VALUE groupage 1 = 'UNDER 1'
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
Run;

DATA NEW;
  SET NNAD;


DATA TEMP;  SET NEW;

     IF age = 0 THEN groupage = 1; *** UNDER 1 YEAR ***;
     IF 1 <= age <= 4 THEN groupage = 2; *** 1-4 YEARS ***;
     IF 5 <= age <= 6 THEN groupage = 3; *** 5-6 YEARS ***;
     IF 7 <= age <= 14 THEN groupage = 4; *** 7-14 YEARS ***;
     IF 15 <= age <= 19 THEN groupage = 5; *** 15-19 YEARS ***;
     IF 20 <= age <= 25 THEN groupage = 6; *** 20-25 YEARS ***;
     IF 26 <= age <= 29 THEN groupage = 7; *** 26-29 YEARS ***;
     IF 30 <= age <= 39 THEN groupage = 8; *** 30-39 YEARS ***;
     IF 40 <= age <= 49 THEN groupage = 9; *** 40-49 YEARS ***;
     IF 50 <= age <= 59 THEN groupage = 10; *** 50-59 YEARS ***;
     IF 60 <= age <= 69 THEN groupage = 11; *** 60-69 YEARS***;
     IF 70 <= age <= 998 THEN groupage = 12; *** 70 + ***;


	 format groupage $groupage.;
Run;

proc contents data=temp;
run;

proc freq data = temp; 
   tables age case_status report_jurisdiction condition age sex  ak_n_ai  asian black hi_n_pi
          white race_unk race_oth race_oth_txt ethnicity ;
   tables age_invest*age_invest_units/list missing;
   tables groupage*(mmwr_year)/missing;
   title "Quick look at &condtx data in NNAD Production";
run; 


proc freq data=temp;
  table ethnicity;
  format _all_;
  title "Example of non-formatted &condtx data frequency";
run;

/*proc print data=temp;*/
/*  var age age_invest age_invest_units groupage;*/
/*run;*/

/*  
proc print data = nnad;
   where local_record_id in ("20201154088","20201197922", "20201342523"); 
   title "Example of a proc print for a sample of cases";
   run; 
*/

ods word close;

/*If you would like to output .Y, then use proc sql instead of proc freq*/
/*numeric values with '=','>'and '<'are converted to .Y*/
/*proc sql;*/
/*select age_invest*/
/*,count(*) as num*/
/*from nnad*/
/*group by age_invest;*/
/*quit;*/

/*  Added this snippet to output all obs.  Please remove comments to run. */
/* NOTE NOTE This code will export an Excel spreadsheet for every toggled variable for every case.  Please be aware this will take a very long time to run and be a  very large file. */
/*PROC EXPORT DATA= NNAD
             OUTFILE= "&output\nnad_prod_ks.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="nnad_prod_ks";
RUN;
*/
