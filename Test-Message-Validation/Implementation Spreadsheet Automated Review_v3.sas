/*************************************************************************************************/
/* Description: Reviews jurisdiction implementation spreadsheet for NCIRD conditions and         */
/*              produces a report with standard responses.                                       */
/*                                                                                               */
/* Created By:   Hannah Fast  4/28/2020                                                          */
/* Modified By:  Hannah Fast  6/11/2020  -Combined all conditions into one program               */
/*               Hannah Fast  6/30/2020  -Added ability to read in priorities from MMG.          */
/*               Hannah Fast  7/08/2020  -Updated output                                         */
/*               Hannah Fast  7/10/2020  -Combined summary and validation report                 */
/*               Hannah Fast  9/21/2020  -Took out removal of 'N/A:' for other report            */
/*               Hannah Fast  5/04/2021  -Split out Generic v2 output into separate document     */
/*               Hannah Fast  5/12/2021  -Added option for running lite MMGs                     */
/*               Hannah Fast  5/12/2021  -Added in RIBD check of ABCs and NNDSS comparison       */
/*               Hannah Fast  5/13/2021  -Adjusted for CRS MMGs                                  */
/*               Pam, Sandy, Ying and Katherine  5/13/2022  -updated the COVID mmg               */
/*               Pam, Sandy, Ying  3/14/2023  -updated the legionellosis mmg to the current mmg instead of the RIBD */
/*               Pam, Sandy, Ying  3/15/2023  -updated the Measles, Rubella and CRS mmg          */
/*                                             to the current mmg instead of the RIBD            */
/*************************************************************************************************/


/* IMPORTANT: Update the following statements before proceeding */
/* Note: To run all 5 RIBD conditions at once, use condition=10590,10150,11723,10490,10450 */

%let condition=10200; /* NNDSS event code */
%let jurisdiction=TEST; /* Jurisdiction abbreviation */
%let ISfilename=Rubella_v1_0_nmi_implementation_spreadsheet_and_instructions_20230224.xlsx;/* Paste Implementation Spreadsheet document name with the postfix of xlsx*/
%let ISsheetname='Rubella'; /* Sheet on IS with single quotes (COPY&PASTE or CHOOSE from: 'MUMPS' / 'PERTUSSIS' / 'VARICELLA' / 'RIBD' / 'MEASLES' / 'RUBELLA' / 'CRS' / 'COVID19') */

/****************************************************************/
/* Directory */
%let rootdir=\\cdc.gov\project\NIP_Project_Store1\Surveillance\NNDSS_Modernization_Initiative;
%let impldir=&rootdir\MMG_Implementation\Implementation Review\Automation;
%let priordir=&rootdir\MMG_Implementation\Data Element Priority Lists;
%let mmgdir=&rootdir\MMG_Development_Communications;
%let outputdir=\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\Implementation Spreadsheet Review\Output;

/* Formats and Macros */
options fullstimer;
options /* mprint mlogic symbolgen NOQUOTELENMAX */
        sasautos = (sasautos,
                    "&impldir\Code\Macros");
%include "&impldir\Metadata\ISReview_Formats.sas";
%let time=%sysfunc(time(),time8.0);
%let weekdate=%sysfunc(date(),weekdate29.);
%let date=%sysfunc(date(),mmddyyd8.);
%let condition_txt=%sysfunc(putn(&condition,CONDITION.));

/* Documents */
libname resp XLSX "&impldir\Metadata\ISAutomatedResponses.xlsx" access=readonly;
libname impl XLSX "&impldir\Spreadsheets\&jurisdiction\&ISfilename" access=readonly;
filename MPV "&priordir\MPV\NCIRD Data Element Priorities_Mumps Pertussis Varicella v04092020.xlsx";
filename RIBD "&priordir\RIBD\NCIRD Data Element Priorities_RIBD v04092020.xlsx";
filename MRCRS "&priordir\MRCRS\NCIRD Data Element Priorities_Measles Rubella CRS v04092020.xlsx";
filename COVID "&mmgdir\COVID_19\COVID-19_V1_1_MMG-and-TS_F_20210921.xlsx";
filename LEGION "&priordir\LEGIONELLOSIS\Legionellosis_V1_0_MMG-and-TS_F_CSE_20230112.xlsx";
filename MEASLES "&priordir\MEASLES\Copy of Measles_V1_0_MMG-and-TS_F_CSE_20230112.xlsx";
filename RUB "&priordir\RUBELLA\Rubella_V1_0_MMG-and-TS_F_CSE_20230112.xlsx";
filename CRS "&priordir\CRS\Congenital Rubella Syndrome_V1_0_MMG-and-TS_F_CSE_20230112.xlsx";

/* Read in metadata with standard responses */
data responses;
  set resp.metadata;
run;

proc sql noprint;
   select response_flag, ncird_priority, de_identifier_list, condition_specific, ncird_response
   into :fg1-, :prior1-, :delist1-, :cond1-, :nr1- 
   from responses
   ;
   %let totalrows = &sqlobs;
quit;

/* Macro 'priority_dataset' creates datasets with information on NCIRD/CDC priorities for data elements */ 
/* It calls a second macro called 'importxlsx' and imports information on NCIRD/CDC priorities from the 
   priority list (doctype=prioritylist) or MMG spreadsheets (doctype=MMG) */

options mprint mlogic symbolgen;
%macro priority_dataset;
data prioritylist;
   length condition $20 condition_code 8 de_name $200 initial_de_identifier de_identifier $60 initial_ncird_priority $10 ncird_priority 8.;
   stop;
run;

/* 'Sheet' is name of Excel sheet, 'Startrow' is the row in the sheet on which metadata begins. Column names are created in macro priority_dataset */

   %if &condition=10180 or &condition=10190 or &condition=10030 %then %do;
      %importxlsx(datafile=MPV, doctype=prioritylist, datasetname=Genv2, sheet='Generic v2', startrow=19, condition_code=10000);
	  %importxlsx(datafile=MPV, doctype=prioritylist, datasetname=Mumps, sheet='Mumps', startrow=19, condition_code=10180);
      %importxlsx(datafile=MPV, doctype=prioritylist, datasetname=Pertussis, sheet='Pertussis', startrow=19, condition_code=10190);
      %importxlsx(datafile=MPV, doctype=prioritylist, datasetname=Varicella, sheet='Varicella', startrow=19, condition_code=10030);
   %end;
	%else %if &condition=10490 %then %do;
      %importxlsx(datafile=RIBD, doctype=prioritylist, datasetname=Genv2, sheet='Generic v2', startrow=19, condition_code=10000);
      %importxlsx(datafile=LEGION, doctype=MMG, datasetname=Legionellosis, sheet='Data Elements', startrow=2, condition_code=10490);
   %end;
   %else %if &condition=10590,10150,11723,10450 or &condition=10150 or &condition=10590 or &condition=11723 or 
      &condition=10450 %then %do;
	  %if &condition=10590,10150,11723,10450 %then %let condition_txt=RIBD;
      %importxlsx(datafile=RIBD, doctype=prioritylist, datasetname=Genv2, sheet='Generic v2', startrow=20, condition_code=10000);
	  %importxlsx(datafile=RIBD, doctype=prioritylist, datasetname=N_meningitidis, sheet='N. meningitidis', startrow=20, condition_code=10150);
      %importxlsx(datafile=RIBD, doctype=prioritylist, datasetname=H_influenzae, sheet='H. influenzae', startrow=20, condition_code=10590);
      %importxlsx(datafile=RIBD, doctype=prioritylist, datasetname=IPD, sheet='IPD', startrow=20, condition_code=11723);
      %importxlsx(datafile=RIBD, doctype=prioritylist, datasetname=Psittacosis, sheet='Psittacosis', startrow=20, condition_code=10450);
   %end;
   %else %if &condition=10200 or &condition=10370 %then %do;
      %importxlsx(datafile=MRCRS, doctype=prioritylist, datasetname=Genv2, sheet='Generic v2', startrow=19, condition_code=10000);
		 %importxlsx(datafile=RUB, doctype=MMG, datasetname=Rubella, sheet='Data Elements', startrow=2, condition_code=10200);
		  %importxlsx(datafile=CRS, doctype=MMG, datasetname=CRS, sheet='Data Elements', startrow=2, condition_code=10370);
/*      %importxlsx(datafile=MRCRS, doctype=prioritylist, datasetname=Measles, sheet='Measles', startrow=19, condition_code=10140);*/
/*      %importxlsx(datafile=MRCRS, doctype=prioritylist, datasetname=Rubella, sheet='Rubella', startrow=19, condition_code=10200);*/
/*      %importxlsx(datafile=MRCRS, doctype=prioritylist, datasetname=CRS, sheet='Congenital Rubella Syndrome', startrow=19, condition_code=10370);*/
   %end;
   %else %if &condition=10140 %then %do;
      %importxlsx(datafile=MRCRS, doctype=prioritylist, datasetname=Genv2, sheet='Generic v2', startrow=19, condition_code=10000);
      %importxlsx(datafile=MEASLES, doctype=MMG, datasetname=Measles, sheet='Data Elements', startrow=2, condition_code=10140);
   %end;
   %else %if &condition=11065 %then %do;
      %importxlsx(datafile=MPV, doctype=prioritylist, datasetname=Genv2, sheet=Generic v2, startrow=19, condition_code=10000);
      %importxlsx(datafile=COVID, doctype=MMG, datasetname=covid, sheet=Data Elements, startrow=2, condition_code=11065);
   %end;
%mend priority_dataset;
;;;;
%priority_dataset;

/* Read in Implementation Spreadsheet */
data impl (keep=DE_category condition DE_identifier DE_name initial_CDC_priority PHA_collected PHA_collection_notes PHA_justification);
  attrib Data_Element__DE__Identifier_Sen length=$60;
  set impl.&ISsheetname.n;
  rename Data_Element_Category=DE_Category
         Data_Element__DE__Identifier_Sen=DE_identifier
         Data_Element__DE__Name=DE_name
		 CDC_priority=initial_CDC_priority
         PHA_Collected__Yes_Only_Certain=PHA_collected
		 VAR28=PHA_collection_notes
		 For_All_CDC_Priority_1_or_2_Data=PHA_justification;
  if cmiss(of Data_Element_Category, Data_Element__DE__Identifier_Sen, Data_Element__DE__Name, CDC_priority, 
     PHA_Collected__Yes_Only_Certain, VAR28, For_All_CDC_Priority_1_or_2_Data) NE 7;
run;

/* Assign numeric condition code to implementation spreadsheet rows */
data impl1 (drop=reason_removed)
     removed;
   length reason_removed $25;
   set impl;
   if upcase(condition) in ('GEN V2', 'GENERIC') then 
      condition_code=10000;
   else if index(upcase(condition), 'MUMPS') then 
      condition_code=10180;
   else if index(upcase(condition), 'PERTUSSIS') then 
      condition_code=10190;
   else if index(upcase(condition), 'VARICELLA') then 
      condition_code=10030;
   else if index(upcase(condition), 'INFLUENZAE') or index(upcase(condition), 'FLU') then
      condition_code=10590;
   else if index(upcase(condition), 'MENINGITIDIS') or index(upcase(condition), 'MENINGOCOCCAL') 
      or index(upcase(condition), 'MENING') then
      condition_code=10150;
   else if index(upcase(condition), 'IPD') or index(upcase(condition),'INVASIVE PNEUMOCOCCAL DISEASE') then 
      condition_code=11723;
   else if index(upcase(condition), 'PSITTACOSIS') then 
      condition_code=10450;
   else if index(upcase(condition), 'LEGIONELLOSIS') then 
      condition_code=10490;
   else if index(upcase(condition), 'MEASLES') then 
      condition_code=10140;
   else if index(upcase(condition), 'CRS') or index(upcase(condition),'CONGENITAL RUBELLA SYNDROME') then 
      condition_code=10370;
   else if index(upcase(condition), 'RUBELLA') then 
      condition_code=10200;
   else if index(upcase(condition), 'COVID') then 
      condition_code=11065;
   else if condition=' ' then 
      condition_code=.;

   /* For RIBD, identify rows that contain information on ABCs */
   if index(upcase(condition), 'ABCS') then
      ABCS='Y';

   /* Create numeric CDC priority */
   if initial_cdc_priority in ('Required', 'R') then 
      cdc_priority=1;
   else if initial_cdc_priority in ('O','P') then
      cdc_priority=8;
   else if initial_cdc_priority='N/A' then 
      cdc_priority=9;
   else cdc_priority=input(initial_cdc_priority, BEST.);

   /* Remove "N/A" from DE Identifier */
   /* This step currently not needed per conversations with Samatha Chindam but possibly needed in future */
   *if index(de_identifier, 'N/A') then ide_identifier=substr(de_identifier, 6);
   /*else*/ ide_identifier=de_identifier;
   rename de_identifier=initial_de_identifier ide_identifier=de_identifier;

   /* Remove lab template variables by looking for the OBR code '30954-2' in DE Category */ 
   if index(de_category,'30954-2') then do;
      reason_removed='Lab Template';
      output removed;
   end;
   /* Remove blank rows by requirement that DE_identifier and DE_name must be populated */
   else if missing(de_identifier) then do; 
      reason_removed='No DE Identifier';
      output removed;
   end;
   else if missing(de_name) then do; 
      reason_removed='No DE Name';
      output removed;
   end;
   else output impl1;
run;

proc sort data=removed;
   by reason_removed;
run;

/* Sort and merge implementation spreadsheet and priority list. This step is needed until all MMGs contain the numeric priority */
proc sort data=prioritylist;
   by condition_code de_identifier de_name;
run;

proc sort data=impl1;
   by condition_code de_identifier de_name;
run;

data match imponly priorityonly;
  merge impl1 (in=in1) prioritylist (in=in2);
  where condition_code in (10000, &condition);
  by condition_code de_identifier;
  if in1 and in2 then do;
     if cdc_priority NE ncird_priority then priority_difference='Y';
     output match;
  end;
  else if in1 and not in2 then output imponly;
  else if in2 and not in1 then output priorityonly;
run;

data analysis;
  set match;
  /* Standardize collection response */
  if missing(pha_collected) then 
     pha_collected_num=9; /* Missing */
  else if index(upcase(pha_collected),"YES") or upcase(pha_collected)="Y" then
     pha_collected_num=1; /* Yes */
  else if index(upcase(pha_collected),"NO") or upcase(pha_collected)="N" then
     pha_collected_num=2; /* No */
  else if index(upcase(pha_collected),"CONDITIONS") then
     pha_collected_num=3; /* Only Certain Conditions */
  else if upcase(pha_collected)="N/A" then
     pha_collected_num=4; /* N/A */
  else pha_collected_num=8; /* Other */
run;

/* FOR RIBD: Compare responses for NNDSS and ABCs data elements */
%macro ABCscompare;
%if &condition=10590,10150,11723,10490,10450 or &condition=10150 or &condition=10590 or &condition=11723 or &condition=10490 or 
      &condition=10450 %then %do;

proc sort data=analysis;
   by condition_code ncird_priority de_identifier ABCs;
run;

/* Assign group_id and group_seq */
data analysis_;
  set analysis;
  by condition_code ncird_priority de_identifier;
  retain group_id 0;
  if first.de_identifier then 
     group_id=group_id+1;
  if first.de_identifier then 
     group_seq=0;
  group_seq+1;

  if ABCS='Y' then 
     ABCs_answer=pha_collected_num;
  else NNDSS_answer=pha_collected_num;
run;

proc transpose data=analysis_ out=temp;
   by group_id;
   var pha_collected_num;
run;

Data temp;
  set temp;
  /* If ABCs has Yes response and NNDSS has No response */
  if (col1=2 and col2=1) then
     flag=1;
  else if (col1=2 and col3=1) then
     flag=1;
run;

proc sql;
   create table analysis as
   select a.*, b.flag
   from analysis_ as a left join temp as b
   on a.group_id=b.group_id;
quit;
%end;
%mend ABCscompare;

%ABCscompare;

data analysis_response;
  set analysis;
 /* Assign response flag */
  /* ABCs but not NNDSS */
  if ABCs NE 'Y' and flag=1 then
     response_flag=1;
  /* Priority 1 and 2: Not collected */
  if (pha_collected_num=2 and NCIRD_priority in (1,2)) then
	 response_flag=2;
  /* All priorities: No response */
  else if pha_collected_num=9 then 
     response_flag=3;
  /* COVID-19 Lite: N/A Response */
  else if pha_collected_num=4 and condition_code=11065 then
	 response_flag=4;

  /* For RIBD Onboarding, clear responses for ABCs DEs */
  if ABCs='Y' then response_flag=.;
run;


/* Macro 'respond' calls to metadata to assign standard responses based on response_flag and ncird_priority */
%macro respond;
data analysis1;
   length ncird_response $500.;
   set analysis_response;

   %do i = 1 %to &totalrows;
      if missing(ncird_response) and (response_flag=&&&fg&i) and (ncird_priority=&&&prior&i) &&&delist&i &&&cond&i then
         ncird_response = "&&&nr&i";
   %end;
run;
%mend respond;

%respond;

/*
proc freq data=analysis1 noprint;
   by condition_code;
   format pha_collected_num COLLECTNUM. condition_code CONDITION.;
   table ncird_priority*pha_collected_num / out=freqtest missing norow nopct nocol;
run;
*/

/* Generate reports */
filename SUMMARY "&outputdir\&jurisdiction\&jurisdiction. &condition_txt. &DATE. Implementation Spreadsheet Automated Process Review &DATE..pdf";
filename REPORT1 "&outputdir\&jurisdiction\&jurisdiction Generic v2 (&condition_txt.) Implementation Spreadsheet NCIRD Review &DATE..xlsx";
filename REPORT2 "&outputdir\&jurisdiction\&jurisdiction &condition_txt. Implementation Spreadsheet NCIRD Review &DATE..xlsx";

/* Excel report to jurisdiction and for use in percent completeness report */
proc sort data=analysis1;
   by condition_code NCIRD_priority PHA_collected;
run;


ods listing exclude ALL;

%macro generate_excel;
/* Generic v2 Report */
ods excel file=report1 
      options (sheet_interval="none" sheet_name='Summary' embedded_titles='yes' flow='tables'); /* option 'flow' prevents carriage returns. It will only work in SAS 9.4 M4 or higher */

   title "&jurisdiction Generic v2 Implementation Spreadsheet NCIRD Review &DATE";
   proc report data=analysis1;
   where condition_code=10000;
      format condition_code CONDITION.;
      column condition_code de_name de_identifier ncird_priority pha_collected PHA_collection_notes pha_justification 
             /*PHA_mapped_de_desc */ ncird_response;
      define condition_code / "Condition" style=[width=1in just=left verticalalign=top] style(header)=[just=center];
      define de_name / "DE Name" style=[width=2in just=left verticalalign=top] style(header)=[just=center];
      define de_identifier / "DE Identifier" style=[width=1in just=left verticalalign=top] style(header)=[just=center];
      define ncird_priority / "Priority" style=[width=0.5in just=left verticalalign=top] style(header)=[just=center];
      define pha_collected / "PHA Collection" style=[width=1.6in just=left verticalalign=top] style(header)=[just=center];
      define pha_collection_notes / "PHA Collection Notes" style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
	  define pha_justification / "PHA Justification" style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
      define ncird_response / "NCIRD_Response &DATE." style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
   run;
ods excel close; 

/* Condition Specific Report */
%if &condition=10590,10150,11723,10450 or &condition=10150 or &condition=10590 or &condition=11723 or &condition=10450 %then %do;

   ods excel file=report2
      options (sheet_interval="none" sheet_name='Summary' embedded_titles='yes' 
/*flow='tables'*/
); /* option 'flow' prevents carriage returns. It will only work in SAS 9.4 M4 or higher */

   title "&jurisdiction Measles Implementation Spreadsheet NCIRD Review &DATE";
   proc report data=analysis1;
   where condition_code NE 10000;
      format condition_code CONDITION.;
      column condition_code de_name de_identifier ABCs ncird_priority pha_collected PHA_collection_notes pha_justification 
             /*PHA_mapped_de_desc */ ncird_response;
      define condition_code / "Condition" style=[width=1in just=left verticalalign=top] style(header)=[just=center];
      define de_name / "DE Name" style=[width=2in just=left verticalalign=top] style(header)=[just=center];
      define de_identifier / "DE Identifier" style=[width=1in just=left verticalalign=top] style(header)=[just=center];
      define ncird_priority / "Priority" style=[width=0.5in just=left verticalalign=top] style(header)=[just=center];
      define ABCs / "ABCs DE" style=[width=0.5in just=left verticalalign=top] style(header)=[just=center];
      define pha_collected / "PHA Collection" style=[width=1.6in just=left verticalalign=top] style(header)=[just=center];
      define pha_collection_notes / "PHA Collection Notes" style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
	  define pha_justification / "PHA Justification" style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
      define ncird_response / "NCIRD_Response &DATE." style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
   run;
ods excel close; 
%end;

%if &condition=10180 or &condition=10190 or &condition=10030 or &condition=10140 or &condition=10200 or
    &condition=10370 or &condition=11065 or &condition=10490 %then %do;

   ods excel file=report2
      options (sheet_name='NCIRD Review' embedded_titles='yes' start_at="1, 2" flow='tables'); /* option 'flow' prevents carriage returns. It will only work in SAS 9.4 M4 or higher */

   title "&jurisdiction &condition_txt Implementation Spreadsheet NCIRD Review &DATE";           /* output title name Row 398 */
   proc report data=analysis1;
   where condition_code NE 10000;
      format condition_code CONDITION.;
      column condition_code de_name de_identifier ncird_priority pha_collected PHA_collection_notes pha_justification /*PHA_mapped_de_desc */ ncird_response;
      define condition_code / "Condition" style=[width=1in just=left verticalalign=top] style(header)=[just=center];
      define de_name / "DE Name" style=[width=2in just=left verticalalign=top] style(header)=[just=center];
      define de_identifier / "DE Identifier" style=[width=1in just=left verticalalign=top] style(header)=[just=center];
      define ncird_priority / "Priority" style=[width=0.5in just=left verticalalign=top] style(header)=[just=center];
      define pha_collected / "PHA Collection" style=[width=1.6in just=left verticalalign=top] style(header)=[just=center];
      define pha_collection_notes / "PHA Collection Notes" style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
	  define pha_justification / "PHA Justification" style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
      define ncird_response / "NCIRD_Response &DATE." style=[width=2.5in just=left verticalalign=top] style(header)=[just=center];
   run;
ods excel close; 
%end;
%mend generate_excel;

%generate_excel;


/* PDF report for internal team with summary and validation of automation process */
ods pdf file=SUMMARY style=htmlblue;
   options nodate nonumber topmargin="0.5in" orientation=landscape;

title1 color=black h=3.5 "&jurisdiction &condition_txt Implementation Spreadsheet Automation Report";
title2 color=black h=2 "Report generated &weekdate. &time..";

proc freq data=analysis1;
where ABCS NE 'Y';
   by condition_code;
   format pha_collected_num COLLECTNUM. condition_code CONDITION.;
   table ncird_priority*pha_collected_num / missing norow nopct nocol;
run;

proc report data=analysis1 spanrows;
where ABCS NE 'Y';
   format pha_collected_num COLLECTNUM. condition_code CONDITION.; 
   where pha_collected_num=3;
   columns condition_code ncird_priority de_identifier de_name pha_collected_num pha_collection_notes pha_justification;
   define condition_code / "MMG" group style=[just=left verticalalign=top] style(header)=[just=center];
   define ncird_priority / "Priority" group width=10 style=[just=left verticalalign=top] style(header)=[just=center]; 
   define de_identifier / "DE Identifier" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define de_name / "DE Name" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collected_num / "PHA Collected" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collection_notes / "PHA Collection Notes" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_justification / "PHA Justification" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   compute before _page_ / style=[fontweight=bold color=black background=cadetblue];
      line "DEs Only Collected for Certain Conditions";  
   endcomp;
run;

proc report data=analysis1 spanrows;
where ABCS NE 'Y';
   format pha_collected_num COLLECTNUM. condition_code CONDITION.; 
   where ncird_priority=1 and pha_collected_num in (2,8,9);
   columns condition_code ncird_priority de_identifier de_name pha_collected_num pha_collection_notes pha_justification;
   define condition_code / "MMG" group style=[just=left verticalalign=top] style(header)=[just=center];
   define ncird_priority / "Priority" group width=10 style=[just=left verticalalign=top] style(header)=[just=center]; 
   define de_identifier / "DE Identifier" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define de_name / "DE Name" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collected_num / "PHA Collected" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collection_notes / "PHA Collection Notes" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_justification / "PHA Justification" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   compute before _page_ / style=[fontweight=bold color=black background=Gold];
      line "Priority 1 DEs Not Collected: Responses of No, Missing, or Other";  
   endcomp;
run;

proc report data=analysis1 spanrows;
where ABCS NE 'Y';
   format pha_collected_num COLLECTNUM. condition_code CONDITION.; 
   where ncird_priority=2 and pha_collected_num in (2,8,9);
   columns condition_code ncird_priority de_identifier de_name pha_collected_num pha_collection_notes pha_justification;
   define condition_code / "MMG" group style=[just=left verticalalign=top] style(header)=[just=center];
   define ncird_priority / "Priority" group width=10 style=[just=left verticalalign=top] style(header)=[just=center]; 
   define de_identifier / "DE Identifier" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define de_name / "DE Name" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collected_num / "PHA Collected" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collection_notes / "PHA Collection Notes" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_justification / "PHA Justification" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   compute before _page_ / style=[fontweight=bold color=black background=Goldenrod];
      line "Priority 2 DEs Not Collected: Responses of No, Missing, or Other";  
   endcomp;
run;

proc report data=analysis1 spanrows;
where ABCS NE 'Y';
   format pha_collected_num COLLECTNUM. condition_code CONDITION.; 
   where ncird_priority=3 and pha_collected_num in (2,8,9);
   columns condition_code ncird_priority de_identifier de_name pha_collected_num pha_collection_notes pha_justification;
   define condition_code / "MMG" group style=[just=left verticalalign=top] style(header)=[just=center];
   define ncird_priority / "Priority" group width=10 style=[just=left verticalalign=top] style(header)=[just=center]; 
   define de_identifier / "DE Identifier" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define de_name / "DE Name" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collected_num / "PHA Collected" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collection_notes / "PHA Collection Notes" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_justification / "PHA Justification" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   compute before _page_ / style=[fontweight=bold color=black background=honeydew];
      line "Priority 3 DEs Not Collected: Responses of No, Missing, or Other";  
   endcomp;
run;


proc report data=analysis1 spanrows;
where ABCS NE 'Y';
   format condition_code CONDITION.; 
   where not missing(pha_collection_notes);
   columns condition_code ncird_priority de_identifier de_name pha_collected pha_collection_notes pha_justification;
   define condition_code / "MMG" group style=[just=left verticalalign=top] style(header)=[just=center];
   define ncird_priority / "Priority" group width=10 style=[just=left verticalalign=top] style(header)=[just=center]; 
   define de_identifier / "DE Identifier" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define de_name / "DE Name" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collected / "PHA Collected" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collection_notes / "PHA Collection Notes" style=[width=2in just=left verticalalign=top] style(header)=[just=center];
   define pha_justification / "PHA Justification"  style=[width=2in just=left verticalalign=top] style(header)=[just=center];
   compute before _page_ / style=[fontweight=bold color=black background=coral];
      line "DEs with Jurisdiction Notes on Collection";  
   endcomp;
run;

/*
proc report data=analysis1;
   format pha_collected_num COLLECTNUM.; 
   where pha_collected_num in (8,9);
   columns ncird_priority de_identifier de_name pha_collected_num pha_collection_notes pha_justification;
   define ncird_priority / "Priority" width=10 style=[just=left verticalalign=top] style(header)=[just=center]; 
   define de_identifier / "DE Identifier" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define de_name / "DE Name" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collected_num / "PHA Collected" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_collection_notes / "PHA Collection Notes" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   define pha_justification / "PHA Justification" width=10 style=[just=left verticalalign=top] style(header)=[just=center];
   compute before _page_ / style=[fontweight=bold color=black background=Gold];
      line "DEs Missing a Response or Other";  
   endcomp;
run;
*/

/* Data elements that didn't merge between implementation spreadsheet and priority list */ 
/* For RIBD, there will be data elements with ABCS=Y, which are assumed to be ABCs-only */
*title3 color=black h=2 "Unmerged DEs between IS and NCIRD Priority List";
title4 color=black h=2 "Unmerged priority list DEs";
proc print data=priorityonly;
   var condition_code de_identifier;
run;

proc sort data=imponly;
   by ABCS;
run;

title4 color=black h=2 "Unmerged implementation spreadsheet DEs";
proc print data=imponly;
   var condition_code de_identifier;
run;

/* Rows that may have dropped out of the implementation spreadsheet if not assigned a condition */
proc print data=impl1;
where condition_code=.;
run;

/* Priority differences between implementation spreadsheet and NCIRD priority list */
title4 color=black h=2 "DEs with Priority Differences Between the Implmentation Spreadsheet and Priority List";
proc print data=match;
where priority_difference='Y';
var condition de_identifier de_name ncird_priority cdc_priority;
run;

title;
proc report data=removed;
   by reason_removed;
   columns condition DE_identifier DE_name DE_category PHA_collected;
   define DE_category / width=100;
   compute before _page_ / style=[fontweight=bold color=black background=gainsboro];
      line "Removed Implementation Spreadsheet Rows";  
   endcomp;
run;

ods pdf close;

libname _all_ clear; /* clear library references */



/* Example code for proc report
proc report data=nnad_nodups_freq spanrows;
format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS.;
label report_jurisdiction='Reporting Jurisdiction' case_status='Case Status';
where case_status in ('410605003','2931005','415684004','UNK');
   columns report_jurisdiction case_status count;
       define report_jurisdiction / group style=[width=2in fontsize=1];
       define case_status / group style=[width=2in fontsize=1];
	   define count /  style=[width=2in fontsize=1];
          /* Calculate Total */
/*
          rbreak after / summarize style=[fontweight=bold background=gainsboro];
          compute after;
             report_jurisdiction='Total';
          endcomp;
          /* Add header and footnotes */
/*
          compute before _page_ / style=[fontweight=bold];
             line "&weekdate.";  
          endcomp;
          compute after _page_/ style=[just=left fontsize=1];
             line "Provisional data as of &weekdate. &time..";
          endcomp;
run;
*/



