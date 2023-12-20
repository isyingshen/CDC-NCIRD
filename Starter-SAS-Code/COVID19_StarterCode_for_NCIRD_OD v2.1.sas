/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COVID-19 Starter Code

This code is used to pull COVID-19 cases from the Stage 4 NCIRD NNDSS Analytic Database (NNAD).  

Changes on 9/28/2020:  Addition of macro to pull formats automatically.  Also, addition of ODS statements to write output to files.
Changes on 11/25/2020: Column L brings in the corresponding Format label.
Changes on 05/11/2021: Converted the extract column to character; added compress function before extract filter
Changes on 08/31/2021: Added three database environments to this one code: Prod, staging and test
 	                    Converted '=num' to 'num'. For example, '=25' to '25' for age_invest, mmwr_week and days_in_hosp
                       Added proc sql to look at frequency instead of proc freq, because proc sql is able to output '.Y'. Proc freq read .Y as missing.
Changes on 1/13/2022:  convert mmwr_week from char to num so that 0x(e.g.,07) will be converted to x(e.g.,7)    
Changes on 5/11/2022:  Include snippet for users to import a list of trans_id or local_record_id as a filter   
Changes on 12/7/2023:  Remove the code to convert .E, .Y and variable age        
Changes on 12/8/2023:  Add back variable age    

Analysts will need to modify the folder directory to their location of the Macro code, Format code, Excel Data Dictionary 
and the stage4dictionary dataset.  

Please read ALL comments in the code,and only edit code where indicated (e.g., at locations noted with *!!!!!).


Brief descriptions for each step are listed below. The variable list can be managed using the Excel Data Dictionary and specifying
1 in column K Extract column for any variables analyst wishes to include in analysis.  Column L brings in the corresponding Format label.
 
This version works with all cases with de-dup all variables created from the epi lab repeating group.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/* Analysts will need to modify location of root directory */

%let rootdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NCIRD NNDSS Analytic Database (NNAD) for programs\Code;

/*!!!!!Analysts will need to modify directory to location of Macro code!!!*/

*Sasautos specifies folders to search in the order to locate the macro;
options mprint mlogic noxwait symbolgen
        sasautos =  (sasautos,
                     "&rootdir\NNAD Macros"
                    );

/* Analyst will need to assign location of output */
%let output=&rootdir\Pathogen Specific Code\COVID-19\Outputs;

*The libname below refers to the location of the SAS Data Dictionary. All variables in the COVID19_NNAD views are listed
in the SAS Data Dictionary;

/*!!!!!Analysts will need to modify directory to location of Data Dictionary!!!*/
*libname sasfmt "&rootdir\NNAD Formats";
libname sasfmt "&rootdir\Pathogen Specific Code\COVID-19\Formats";

*%let fmtdir = &rootdir\NNAD Formats;
%let fmtdir = &rootdir\Pathogen Specific Code\COVID-19\Formats;

/* Bring in formats */
libname qcfmt XLSX "&fmtdir\QCNNADFormats.xlsx" access=readonly;


/* excel dictionary with user extract flag */
libname usrD XLSX "&rootdir\Pathogen Specific Code\COVID-19\Formats\DataDictionary_tf_11065.xlsx";

*This line connects to the NNAD Production database;
/*libname NNAD OLEDB*/
/*        provider="sqloledb"*/
/*        properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1"*/
/*                       "Integrated Security"="SSPI"*/
/*                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;*/

*This line connects to the NNAD Staging database;
/*Analysts will need to uncomment it to use!!!*/
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSSV-INFC-1601\QSRV1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;

*This line connects to the NNAD Test database;
/*Analysts will need to uncomment it to use!!!*/
/*libname NNAD OLEDB*/
/*        provider="sqloledb"*/
/*        properties = ( "data source"="DSTV-INFC-1601\QSRV1"*/
/*                       "Integrated Security"="SSPI"*/
/*                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;*/

/* extract Stage4 variable list from excel dictionary and assign to macro */

/*  Analyst note: The variable list can be managed using the Excel Data Dictionary,and specifying
1 in column K Extract column for any variables analyst wishes to include in analysis.
Due to the SAS field vlist constraint of 6000 character limit, recommendation is to limit extract column to 150 to 180 variables.
For deduplication below, analyst must select the source_system, n_expandedcaseid columns from the Excel Data Dictionary.*/


/*convert the extract column to text*/
data stage4dict_tf_11065;
	set usrD.stage4dict_tf_11065;
	newvar=vvalue(Extract);
	drop Extract;
	rename newvar=Extract;
run;

proc sql noprint;
   select Var_Name
   into :vlist separated by ' '
   from stage4dict_tf_11065
   where compress(Extract) = "1"
   ;

%put List of variables to extract: &vlist;

 /* for useage where list is needed.  Full list of variable with format */
   select trim(left(Var_Name)) || ' ' || trim(left(format))
   into  :varfmtlist separated by ' '
   from  stage4dict_tf_11065
   where compress(Extract) = "1" and format ^= ''
   ;   
   /* remove dollar and period from format to obtain distinct worksheet name. */
   select distinct compress(format,'$.')
   into :fmtsheetlist  separated by ' '
   from  stage4dict_tf_11065
   where compress(Extract) = "1" and format ^= ''
   ;
   /* remove dollar and period from format name.  That name will match worksheet name */
   select Var_Name, format, compress(format,'$.')
   into :vname1- , :fmtname1-, :fmtsheet1-
   from  stage4dict_tf_11065
   where compress(Extract) = "1" and format ^= ''
   ;
   %let Vtotal = &sqlobs; /* total number of variables extracted using flag Extract = 1 */
quit;

data stage4dict;
   set stage4dict_tf_11065;
run;

/* Read in worksheets containing formats referenced in the dictionary */
%ExlFmt(LibN=qcfmt, SheetN=&fmtsheetlist);

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Using the Macro provided will cut down on the processing time and create a ready-to-go analytic database.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

%extractstg4(outdatasetname=stg4_Exl,
             SQLlibname=NNAD,
             Stg4DictName=stage4dict,
             filter=%nrstr(condition in ("11065") ),
/*				 & report_jurisdiction in ("08")*/
             /*only edit below this comment line*/
             varlist= &vlist
            ); /* end of macro call */

%extractstg4(outdatasetname=stg4_manual,
             SQLlibname=NNAD,
             Stg4DictName=stage4dict,
             filter=%nrstr(condition in ("11065") ),
/*				 & report_jurisdiction in ("08")*/
             /*only edit below this comment line*/
             varlist= source_system case_status n_expandedcaseid n_cdcdate result_status
				 
			);

;*/;*;*;*;*/;*';*";quit;run; /* this line exits from unbalanced quotation problem and others */
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


/* DEDUPLICATION AND DATA CLEANING FOR NNAD STAGE4 DATA*/
/*Note: If CASEID=0 for multiple cases in NETSS(with the same mmwr_year, report_jurisdiction and site),the code below that states "((source_system=1) and (WSYSTEM NE 5))" may dedup in a non-preferred way. */
/*For such situations, you may see unexpected drops in case numbers before and after deduplications. */
/*For such situations, it is recommended that you refer to the dataset before the dedup steps to review the detailed messages. That review will inform your determination about any coding changes needed for the missing NETSS identifier. */

data stage4_11065 error_nokey;
   set stg4;
  

   if (source_system in (5,15)) then 
      firstkey=cats(report_jurisdiction,compress(local_record_id)); /* For HL7 records, look at local_record_id */
   else if ((source_system=1) and (WSYSTEM=5)) then
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* For NETSS records created from MVPS, look at n_expandedcaseid */  
   else if ((source_system=1) and (WSYSTEM NE 5)) then
      firstkey=cats(report_jurisdiction,compress(local_record_id),site,mmwr_year); /* For other NETSS records, look at local_record_id (CASEID), site, mmwr_year */

   output stage4_11065;

   if (firstkey = '') then
      output error_nokey;
run;
proc sort tagsort data=stage4_11065;
   by firstkey descending source_system descending n_cdcdate; /* Prefer HL7 record over NETSS duplicate, newer NETSS record over older */
run;

/* Duplicates by match of local_record_id/n_expandedcaseid are removed */
data stage4_clean stage4_remove;
   set stage4_11065;
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
/**/
/*      if (remove{i} = 1) then*/
/*         new{i} = .E; *vaules with characters/special characters;*/
/*      else if (remove{i} = 2) then*/
/*         new{i} = .Y; *values with mathematical characters;*/
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



**********************************************************************************************************
Include this code snippet if you would like to import a list of trans_id or local_record_id as a filter
Import starts here
**********************************************************************************************************;

/* Import a list of trans_id or local_record_id which are used as a filter */
/* Analysts will need to modify location and name of datafile */
/*proc import datafile="C:\Temp\Trans_id list.xlsx"*/
/*      DBMS=EXCEL out=imptxlsx replace;*/
/*      range = "Sheet1$";*/
/*      getnames=yes;*/
/*      mixed = yes;*/
/*      scantext = yes;*/
/*      usedate=yes;*/
/*run;*/
/**/
/*/*Let the program know of the imported column. It can be trans_id, local_record_id...*/*/
/*/* Analysts will need to modify the column name of the datafile */*/
/*%let imptColumn = trans_id;*/
/**/
/*/*Create a table nnad_impt_filtered. This table uses the imported list as a filter. The analysis afterwards should use this table.*/*/
/*proc sql;*/
/*create table nnad_impt_filtered as*/
/*select **/
/*from nnad*/
/*where &imptColumn in*/
/*(select &imptColumn from imptxlsx);*/
/*quit;*/

**********************************************************************************************************
Include this code snippet if you would like to import a list of trans_id or local_record_id as a filter
Import ends here
**********************************************************************************************************;

/*Output*/
/*COVID Starter Code Report*/
ods _all_ close; 
ods listing;
ods noproctitle;
ods word file="&output\COVID19_STG_StarterCodeReport &SYSDATE9..docx";

proc freq data = nnad; 
	tables case_status jurisdiction condition sex	ak_n_ai	asian	black	hi_n_pi	white	race_unk	race_oth	race_oth_txt ethnicity hospitalized hosp_icu;
	tables age_invest*age_invest_units/list missing;
	title "Quick look at COVID data in NNAD Production";
run; 


proc freq data=nnad;
  table ethnicity;
  format _all_;
  title "Example of non-formatted COVID data frequency";
run;

proc print data = nnad;
	where local_record_id in ("20201154088","20201197922", "20201342523"); 
	title "Example of a proc print for a sample of cases";
	run; 

proc contents;
run;

ods word close;

/*If you would like to output .Y, then use proc sql instead of proc freq*/
/*numeric values with '=','>'and '<'are converted to .Y*/
/*proc sql;*/
/*select age_invest*/
/*,count(*) as num*/
/*from nnad*/
/*group by age_invest;*/
/*quit;*/

/* Added this snippet to output all obs.  Please remove comments to run. */
/* This code will export an Excel spreadsheet for every toggled variable for every case.  Please be aware this will take a long time to run and be a  very large file. */
/*PROC EXPORT DATA= NNAD
             OUTFILE= "&output\nnad_prod_ks.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="nnad_prod_ks";
RUN;
*/
