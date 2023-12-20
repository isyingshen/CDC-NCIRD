 /********************************************************************/
 /* PROGRAM NAME: Validation Automation for Mumps                    */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2022/8/30                                             	*/
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /* Revised based on Ying Shen COVID19 validation Automation         */
 /*                                                                  */
 /* PURPOSE:  This program is to automate the process of             */
 /*           Test Message Validation. It concludes two rounds of    */
 /*           validation. Validation1: all the sent variables are    */
 /*           matching what they are in NNAD. Validation2: all       */
 /*           not sent variables are not in NNAD                     */
 /*                                                                  */ 
 /* INPUT:    DD-extracted.xlsx                                      */
 /*           Mumps Local_record_ids                                 */
 /*                                                                  */ 
 /* OUTPUT: Validation_Report_Test_Record.xlsx                       */
 /*         Validation_Report_Untoggled_Var.xlsx                     */ 
 /*                                                                  */ 
 /* Date Modified: 2022-10-28                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: TM8 replace TM3 and TM7 replace TM4                     */
 /*          comment out TM3 and TM4                                 */
 /*                                                                  */ 
 /* Date Modified: 2022/10/21                                        */
 /* Modified by: Ying Shen                                           */
 /* Improve the contact type (M2F). It is automatically matched      */
 /*    in the Validation Report. (Same for Binational Report)        */
 /*                                                                  */
 /* Date Modified: 2028/8/8                                          */
 /* Modified by: Ying Shen                                           */
 /*    Correct a typo in %compare_non_lab(Test_Record__11,           */
 /*    test_record1_nnad_n, vali_2g_r2, vali_1f_r1, vali_2f_r1);     */
 /*    Change vali_2g_r2 to vali_2g_r1                               */
 /*                                                                  */
 /********************************************************************/

/*Tell This Validation Program ID of the Test Records*/
/*!!!!! needs to update before running the program*/
%let test_record1_nnad = Mumps_TC021;
%let test_record2_nnad = Mumps_TC02;
/*%let test_record3_nnad = 2018420729;*/
/*%let test_record4_nnad = 2018420731;*/
%let test_record5_nnad = Mumps_TC051;
%let test_record6_nnad = Mumps_TC06;
%let test_record7_nnad = Mumps_TC04;
%let test_record8_nnad = Mumps_TC03;

%let test_record1_nnad_n = nnad_&test_record1_nnad;
%let test_record2_nnad_n = nnad_&test_record2_nnad;
/*%let test_record3_nnad_n = nnad_&test_record3_nnad;*/
/*%let test_record4_nnad_n = nnad_&test_record4_nnad;*/
%let test_record5_nnad_n = nnad_&test_record5_nnad;
%let test_record6_nnad_n = nnad_&test_record6_nnad;
%let test_record7_nnad_n = nnad_&test_record7_nnad;
%let test_record8_nnad_n = nnad_&test_record8_nnad;

/*%put &test_record1_nnad_n;*/

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Non-COVID19 Starter Code Started to pull the toggled data

This is revised by Ying Shen
Remove Formats
No output

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
%let condtx = Mumps;
%let condcd = 10180;

%let rootdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NCIRD NNDSS Analytic Database (NNAD) for programs\Code\Pathogen Specific Code\NON_COVID;
%let macdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NCIRD NNDSS Analytic Database (NNAD) for programs\Code;

options noxwait NOQUOTELENMAX
        sasautos =  (sasautos,
                     "&macdir\NNAD Macros"
                     );
                     
/* excel dictionary with user extract flag */
libname usrD XLSX "&testdir\Output\DD-extracted.xlsx";


*This line connects to the NNAD Staging database;
/*CSP*/
libname NNAD OLEDB
        provider="sqlncli11"
        properties = ( "data source"="DSSV-INFC-1601\QSRV1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;
/*Desktop*/
/*libname NNAD OLEDB*/
/*        provider="sqloledb"*/
/*        properties = ( "data source"="DSSV-INFC-1601\QSRV1"*/
/*                       "Integrated Security"="SSPI"*/
/*                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;*/

proc sql noprint;
   /* create SAS dataset of the condition specific dictionary */
   create table stage4dict as
   select *
   from usrD.stage4dict;

   /* create SAS dataset of the variable tagged for extraction */
   create table extraction_variables as
   select Var_Name
   from stage4dict
   where  Extract = '1';
   
   /* macro vlist is used in data extraction */
   select Var_Name
   into :vlist separated by ' '
   from extraction_variables;

   %put List of variables to extract: &vlist;
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
   select a.*, b.*
   from stg4_Exl as a left join stg4_manual as b 
   on a.condition = b.condition and a.report_jurisdiction = b.report_jurisdiction and
      a.local_record_id = b.local_record_id and a.mmwr_year = b.mmwr_year and a.site = b.site and
      a.wsystem = b.wsystem and a.dup_sequenceID = b.dup_sequenceID ;
quit;

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
/*data stage4_clean stage4_remove;*/
/*   set stage4_&condcd;*/
/*   by firstkey;*/
/**/
/*   if ((first.firstkey) and (result_status NE 'X') and (case_status NE 'PHC178')) then*/
/*      output stage4_clean;*/
/*   else */
/*      output stage4_remove;*/
/*run;*/

/*Limit pull to the actual local record ids*/
data nnad_sas;
   set stage4_&condcd;
	where local_record_id in ("&test_record1_nnad", "&test_record2_nnad", "&test_record5_nnad", "&test_record6_nnad","&test_record7_nnad", "&test_record8_nnad");
run;

/*Transpose the starter code output*/
proc transpose data=nnad_sas out =var_value_NNAD_nl prefix=NNAD_;
	ID local_record_id;
	var _all_;
run;


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Non-COVID19 Starter Code End

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


/********************************************************************/
/*Non-repeating starts*/
/********************************************************************/
/*Get the Test Message Review Data*/
proc sql;
	create table vali_non_repeat as
	select DE_Name
	,Var_Name as Var_Name_Test_Message
	,Test_Record__11 
	,Test_Record__21 
/*	,Test_Record__31 */
/*	,Test_Record__41 */
	,Test_Record__51 
	,Test_Record__61 
	,Test_Record__71 
	,Test_Record__81 
	from extract_non_repeat;
quit;
/********************************************************************/
/*Non-repeating ends*/
/********************************************************************/

/********************************************************************/
/*Model 1G and 1.5GDT start*/
/********************************************************************/
/*Get the Test Message Review Data*/
proc sql;
create table vali_1g as
	select DE_Name
	,Var_Name_M1G as Var_Name_Test_Message
	,Test_Record__11 
	,Test_Record__21 
/*	,Test_Record__31 */
/*	,Test_Record__41 */
	,Test_Record__51 
	,Test_Record__61 
	,Test_Record__71 
	,Test_Record__81 
	from M1G_element2;
quit;
/********************************************************************/
/*Model 1G and 1GDT end*/
/********************************************************************/

/********************************************************************/
/*Model 2G starts*/
/********************************************************************/

%macro getm2g (tm_name, extracted_name, out_name);

/*Test_Record_&tm_num starts*/
/*Get the Test Message Review Data*/
proc sql;
	create table vali_2g_r1_orig as 
	select Data_Element__DE__Name
	,&tm_name as test_record
	from testMsgRev_clean
	where Data_Element__DE__Name in ('Type of Complications','Type of Complications Indicator','Signs and Symptoms','Signs and Symptoms Indicator');
quit;

/*Get the row number because I want to match Q and A*/
proc sql;
	create table vali_2g_r1_row as
	select * 
	,monotonic() as row
	from vali_2g_r1_orig;
quit;

/*Sort by DE*/
proc sort data=vali_2g_r1_row;
	by Data_Element__DE__Name row;
run;

/*Reassign the number to match Q and A*/
data vali_2g_r1_row_QA_match;
	set vali_2g_r1_row;
	by Data_Element__DE__Name;
	if first.Data_Element__DE__Name then QA_num=1;
	else QA_num +1;
run;

/*Separate Q and A :Type of Complications*/
proc sql;
/*Q*/
create table comp1_Q as
select *
from vali_2g_r1_row_QA_match
where Data_Element__DE__Name ='Type of Complications';


/*A*/
create table comp1_A as
select *
,test_record as test_record_A
from vali_2g_r1_row_QA_match
where Data_Element__DE__Name ='Type of Complications Indicator';
quit;

/*Merge Q and A*/
proc sql;
create table comp1_QA as
	select * 
	from comp1_Q as a
	left join comp1_A as b
	on a.QA_num=b.QA_num;
quit;

/*Separate Q and A: Signs and Symptoms*/
proc sql;
/*Q*/
create table signs_Q as
select *
from vali_2g_r1_row_QA_match
where Data_Element__DE__Name ='Signs and Symptoms';


/*A*/
create table signs_A as
select *
,test_record as test_record_A
from vali_2g_r1_row_QA_match
where Data_Element__DE__Name ='Signs and Symptoms Indicator';
quit;

/*Merge Q and A*/
proc sql;
create table signs_QA as
	select * 
	from signs_Q as a
	left join signs_A as b
	on a.QA_num=b.QA_num;
quit;

/*Append all 4 m2g*/
proc append base=comp1_QA data=signs_QA;
run;

/*Get the Var_Name*/
proc sql;
create table &out_name as
select 
distinct a.Data_Element__DE__Name as DE_Name
,b.Var_Name as Var_Name_Test_Message
,a.test_record_A as Test_Record_1
from comp1_QA as a
left join &extracted_name as b
on a.test_record=b.test_record
where a.test_record is not null
and a.test_record not in ('<blank>')
and b.Var_Name is not null;
quit;
/*Test_Record_1 ends*/

%mend getm2g;

%getm2g(Test_Record__11,complications_var_2G, vali_2g_r1);
%getm2g(Test_Record__21,complications_var_2G, vali_2g_r2);
/*%getm2g(Test_Record__31,complications_var_2G, vali_2g_r3);*/
/*%getm2g(Test_Record__41,complications_var_2G, vali_2g_r4);*/
%getm2g(Test_Record__51,complications_var_2G, vali_2g_r5);
%getm2g(Test_Record__61,complications_var_2G, vali_2g_r6);
%getm2g(Test_Record__71,complications_var_2G, vali_2g_r7);
%getm2g(Test_Record__81,complications_var_2G, vali_2g_r8);


/********************************************************************/
/*Model 1F starts*/
/********************************************************************/

proc sql;
/*test record1*/
create table vali_1F_r1 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__11
	from data1F_var;

/*test record2*/
create table vali_1F_r2 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__21
	from data1F_var;

/*test record3*/
create table vali_1F_r3 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__31
	from data1F_var;

/*test record4*/
create table vali_1F_r4 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__41
	from data1F_var;

/*test record5*/
create table vali_1F_r5 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__51
	from data1F_var;

/*test record6*/
create table vali_1F_r6 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__61
	from data1F_var;

/*test record7*/
create table vali_1F_r7 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__71
	from data1F_var;

/*test record8*/
create table vali_1F_r8 as
	select Data_Element__DE__Name as DE_Name
	,Var_Name1F as Var_Name_Test_Message
	,Test_Record__81
	from data1F_var;
quit;

/********************************************************************/
/*Model 1F ends*/
/********************************************************************/


/********************************************************************/
/*Model 2F starts*/
/********************************************************************/
%macro getm2f (tm_name, out_name);
proc sql;
create table &out_name as 
	select a.Data_Element__DE__Name as DE_Name
	,a.&tm_name
	,b.Var_Name as Var_Name_Test_Message
	from data_2F a
	left join data2F_var b
	on a.&tm_name=b.test_record;
quit;
%mend getm2f;

%getm2f (Test_Record__11,vali_2f_r1);
%getm2f (Test_Record__21,vali_2f_r2);
/*%getm2f (Test_Record__31,vali_2f_r3);*/
/*%getm2f (Test_Record__41,vali_2f_r4);*/
%getm2f (Test_Record__51,vali_2f_r5);
%getm2f (Test_Record__61,vali_2f_r6);
%getm2f (Test_Record__71,vali_2f_r7);
%getm2f (Test_Record__81,vali_2f_r8);

/********************************************************************/
/*Model 2F ends*/
/********************************************************************/

%macro compare_non_lab (tcsw_tm,nnad_tm,tm2g, tm1f, tm2f);
/*create vali_r1_all to store all record 1 data*/
proc sql;
	create table vali_r_all as
	select DE_Name
	,Var_Name_Test_Message
	,&tcsw_tm
	from vali_non_repeat
	union
	select DE_Name
	,Var_Name_Test_Message
	,&tcsw_tm
	from vali_1g;
quit;

/*Append data for test record1*/
proc append base =vali_r_all data=&tm2g Force;
run;
proc append base =vali_r_all data=&tm1f Force;
run;
proc append base =vali_r_all data=&tm2f Force;
run;

/*Output the comparison dataset*/
proc sql;
create table compare_r as
	select distinct b.DE_Name
	,b.Var_Name_Test_Message as Var_Name_TM
	,a._NAME_ as Var_Name_NNAD
	,a.&&&nnad_tm as Value_NNAD
	,b.&tcsw_tm
	,case 
	when compress(lowcase(a.&&&nnad_tm),,'s')=compress(lowcase(b.&tcsw_tm),,'s') then 'Y'
	when a.&&&nnad_tm is null and b.&tcsw_tm in ('.','','<blank>','NOT REPORTED','do not collect','N/A','NOT COLLECTED') then 'Y'
	when a.&&&nnad_tm is null and b.&tcsw_tm is null then 'Y'
	when a.&&&nnad_tm in ('.','','<blank>','NOT REPORTED','do not collect','N/A','NOT COLLECTED','NOT SENDING') and b.&tcsw_tm in ('.','','<blank>','NOT REPORTED','do not collect','N/A','NOT COLLECTED','NOT SENDING') then 'Y'
	when b.Var_Name_Test_Message in ('Black') and b.&tcsw_tm in ('2054-5') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('White') and b.&tcsw_tm in ('2106-3') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('Asian') and b.&tcsw_tm in ('2028-9') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('Race_unk') and b.&tcsw_tm in ('UNK') and a.&&&nnad_tm in ('Y') then 'Y'
		/*	Auto match contact type M2F*/
	when b.Var_Name_Test_Message in ('community_acquired') and b.&tcsw_tm in ('277057000') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('healthcare_contact') and b.&tcsw_tm in ('PHC2268') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('household_contact') and b.&tcsw_tm in ('PHC2127') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('contact_type_oth_txt') and b.&tcsw_tm in ('OTH') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('contact_type_unk') and b.&tcsw_tm in ('UNK') and a.&&&nnad_tm in ('Y') then 'Y'
/*	Auto match Binational Report M2F*/
	when b.Var_Name_Test_Message in ('binatl_product_exp') and b.&tcsw_tm in ('PHC1140') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('binatl_case_contacts') and b.&tcsw_tm in ('PHC1139') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('binatl_other_situations') and b.&tcsw_tm in ('PHC1141') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('binatl_exp_by_res') and b.&tcsw_tm in ('PHC1215') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('binatl_exp_in_country') and b.&tcsw_tm in ('PHC1138') and a.&&&nnad_tm in ('Y') then 'Y'
	when b.Var_Name_Test_Message in ('binatl_res_of_country') and b.&tcsw_tm in ('PHC1138') and a.&&&nnad_tm in ('Y') then 'Y'
end as Match
	from vali_r_all as b 
	left join var_value_NNAD_nl as a
	on compress(lowcase(b.Var_Name_Test_Message))=compress(lowcase(a._NAME_))

/*	where b.Var_Name_Test_Message is not null*/
	order by b.DE_Name,b.Var_Name_Test_Message;
quit;


/*Merge tables: Test Message Review and MMG Auto*/
proc sql;
create table DE_order as
	select * 
	from testMsgRev_clean as a
	left join mmgAuto_clean as b
	on (lowcase(a.DE_Identifier_Sent_in_HL7_Messag)=lowcase (b.DE_Identifier) or lowcase(a.Data_Element__DE__Name)=lowcase(b.DE_Name))
	order by order;
quit;


/*Better format the comparison*/
proc sql;
create table compare_r_better_format as
select a.condition
/*,a.DE_Name*/
,a.DE_Identifier_Sent_in_HL7_Messag as DE_Identifier
,b.DE_Name 
,b.Var_Name_TM as Var_Name
/*,b.Var_Name_NNAD as Var_Name_in_NNAD*/
,b.&tcsw_tm as Value_TM
,b.Value_NNAD as Value_NNAD
,b.Match
,order
from DE_order as a
full join compare_r as b
on compress(lowcase(a.DE_Name))=compress(lowcase(b.DE_Name))
where b.DE_Name is not null
order by condition desc,order asc,b.Var_Name_TM asc;
quit;

/*Dedup*/
options nolabel;
PROC SORT DATA=compare_r_better_format
 OUT=compare_r_better_format_dedup
 nodupkey ;
 BY condition DE_Name DE_Identifier Var_Name Value_TM Value_NNAD Match;
RUN ;

/*re-order */
proc sql;
create table compare_r_better_fmt_dedup_re as
select *
from compare_r_better_format_dedup
order by condition desc,order asc, Var_Name asc;
quit;


/*Export extracted data into excel*/
PROC EXPORT DATA= compare_r_better_fmt_dedup_re (keep=condition DE_Identifier DE_Name Var_Name Value_TM Value_NNAD Match)
/*             OUTFILE= "&testdir\validation_test_record_results.xlsx"*/
			OUTFILE= "&testdir\Validation_Report_Test_Record.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="validation_&tcsw_tm";
RUN;


%mend compare_non_lab;

%compare_non_lab(Test_Record__11,test_record1_nnad_n, vali_2g_r1, vali_1f_r1, vali_2f_r1);
%compare_non_lab(Test_Record__21,test_record2_nnad_n, vali_2g_r2, vali_1f_r2, vali_2f_r2);
/*%compare_non_lab(Test_Record__31,test_record3_nnad_n, vali_2g_r3, vali_1f_r3, vali_2f_r3);*/
/*%compare_non_lab(Test_Record__41,test_record4_nnad_n, vali_2g_r4, vali_1f_r4, vali_2f_r4);*/
%compare_non_lab(Test_Record__51,test_record5_nnad_n, vali_2g_r5, vali_1f_r5, vali_2f_r5);
%compare_non_lab(Test_Record__61,test_record6_nnad_n, vali_2g_r6, vali_1f_r6, vali_2f_r6);
%compare_non_lab(Test_Record__71,test_record7_nnad_n, vali_2g_r7, vali_1f_r7, vali_2f_r7);
%compare_non_lab(Test_Record__81,test_record8_nnad_n, vali_2g_r8, vali_1f_r8, vali_2f_r8);


/*Lab vars comparision starts*/
/*%let tcsw_tm =Test_Record__11;*/
/*%let nnad_tm=&test_record1_nnad;*/


/*Import M3_LabTestType_Q1*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M3_LabTestType_Q1 replace;
	range = "M3_LabTestType_Q1$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;
/*Import M3_SpecimenType_Q2*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M3_SpecimenType_Q2 replace;
	range = "M3_SpecimenType_Q2$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;


%macro compare_lab(tcsw_tm, nnad_tm);

/*Get the data from testMsgRev_clean*/
proc sql;
create table data_m3g_record as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,&tcsw_tm
	from testMsgRev_clean
/*Test Type	3G	INV290*/
/* Specimen Source	3G	31208-2*/
/*Test Result	3G	INV291*/
/*Test Result Quantitative	3G	LAB628*/
/*Result Units	3G	LAB115*/
/*Specimen Collection Date/Time	3G	68963-8*/
/*"Performing Laboratory Specimen*/
/*ID"	3G	LAB202*/
/*Performing Laboratory Type	3G	82771-7*/
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2','INV291','LAB628'
,'LAB115','68963-8','LAB202','82771-7');
quit;

/*Blue line: get the DE and test record*/
proc sql;
create table data_m3g_record_q1q2 as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,&tcsw_tm
	,monotonic() as row
	from data_m3g_record
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2');

	create table num_test_type as
	select Data_Element__DE__Name
	,count(*) as num_var
	from data_m3g_record_q1q2
	group by Data_Element__DE__Name;
	

	create table data_m3g_record_q1q2_2 as
	select a.Data_Element__DE__Name
	,a.&tcsw_tm
	,b.num_var
	,a.row
	from data_m3g_record_q1q2 as a
	left join num_test_type as b
	on a.Data_Element__DE__Name=b.Data_Element__DE__Name;
quit;

proc sort data=data_m3g_record_q1q2_2;
	by Data_Element__DE__Name row;
run;

data data_m3g_record_q1q2_3; 	
	set data_m3g_record_q1q2_2;
	by Data_Element__DE__Name;
	if first.Data_Element__DE__Name then Orig_instance=1;
	else Orig_instance+1;
run;

proc sort data=data_m3g_record_q1q2_3;
by Orig_instance;
run;

proc transpose data=data_m3g_record_q1q2_3 
				out=data_m3g_record_q1q2_tr;
		id Data_Element__DE__Name;
		by Orig_instance;
		var &tcsw_tm;
run;

proc sql;
/*Get the value of the test type and specimen source and the combo_var*/
create table data_m3g_record_q1q2_combo as
	select a.Orig_instance
	,a.Test_Type
	,a.Specimen_Source
	,b.Var_Name as test_type_var_name
	,c.Var_Name as specimen_var_name
	,cats(b.Var_Name,"_",c.Var_Name) as combo_var
	from data_m3g_record_q1q2_tr as a
	left join M3_LabTestType_Q1 as b
	on a.Test_Type=b.Code
	left join M3_SpecimenType_Q2 as c
	on a.Specimen_Source=c.code;

/*Get the max num of combo_var*/
	create table max_instance1 as
	select combo_var
	,count(combo_var) as max_instance
	from data_m3g_record_q1q2_combo
	group by combo_var;
	
/*Combine 2 tables above*/
	create table data_m3g_record_q1q2_combo_max as
	select *
	from data_m3g_record_q1q2_combo as a
	left join max_instance1 as b
	on a.combo_var=b.combo_var;
quit;


/*Get the number of Var_instance*/
data  data_m3g_record_q1q2_combo_inst;
	set  data_m3g_record_q1q2_combo_max;
	do var_instance =1 to max_instance;
	output;
	end;
run;


/*orange arrow: on the right hand side of the logic doc*/
/*get data*/
proc sql;
create table data_m3g_record_result as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,&tcsw_tm
	from data_m3g_record
	where DE_Identifier_Sent_in_HL7_Messag in ('INV291','LAB628','LAB115','68963-8','LAB202','82771-7');
quit;

proc sort data =data_m3g_record_result;
	by DE_Identifier_Sent_in_HL7_Messag;
run;

/*Get the Orig_instance*/
data data_m3g_record_result_2;
	set data_m3g_record_result;
	by DE_Identifier_Sent_in_HL7_Messag;
	if first.DE_Identifier_Sent_in_HL7_Messag then Orig_instance=1;
	else Orig_instance+1;
run;

/*Combine Blue line and Orange Line. Combine Q1Q2 and other DE*/
proc sql;
create table data_m3g_record_all as
	select a.*
	,b.*
	,c.Repeat_Postfix
	,cats(a.combo_var,c.Repeat_Postfix,"_",a.var_instance) as Var_Name_m3g
	from data_m3g_record_q1q2_combo_inst as a
	left join data_m3g_record_result_2 as b
	on a.Orig_instance=b.Orig_instance
	left join mmgAuto_clean as c
	on b.DE_Identifier_Sent_in_HL7_Messag=c.DE_Identifier
	where a.Test_Type not in('<blank>');
quit;

/*Combine Blue line and Orange Line. Combine Q1Q2 and other DE*/
proc sql;
create table data_m3g_record_all as
	select a.*
	,b.*
	,c.Repeat_Postfix
	,cats(a.combo_var,c.Repeat_Postfix,"_",a.var_instance) as Var_Name_m3g
	from data_m3g_record_q1q2_combo_inst as a
	left join data_m3g_record_result_2 as b
	on a.Orig_instance=b.Orig_instance
	left join mmgAuto_clean as c
	on b.DE_Identifier_Sent_in_HL7_Messag=c.DE_Identifier
	where a.Test_Type not in('<blank>');
quit;

/*Simplify the table*/
proc sql;
create table vali_3g_r as
	select distinct Data_Element__DE__Name as DE_Name
	,Var_Name_m3g as Var_Name_Test_Message
	,*
	from data_m3g_record_all;
quit;

/*Get the T3 vertical data*/
proc sql;
create table t3_vert as
select t3.condition
,t3.obx_3_1 as DE_Identifier
/*,t3.report_jurisdiction*/
/*,t3.local_record_id*/
,t3.var_name 
,t3.contentv_name
,t3.obx_5 
from NNAD.Stage3_NNDSSCasesT3_Vertical as t3
where t3.local_record_id in ("&&&nnad_tm");
quit;

/*Merge the converted tcsw data to NNAD data*/
proc sql;
create table compare_r_lab as
select r5.*
,t3.condition
,t3.DE_Identifier
/*,t3.report_jurisdiction*/
/*,t3.local_record_id*/
,t3.var_name 
,t3.contentv_name
,r5.var_name_test_message as Converted_Name_TM1
,t3.obx_5 
,r5.&tcsw_tm as Value_TM
,case
when t3.contentv_name =r5.var_name_test_message and t3.obx_5= r5.&tcsw_tm then "Y"
when t3.var_name in ('test_type')  and r5.&tcsw_tm is null then "Y"
when t3.var_name in ('spec_source')  and r5.&tcsw_tm is null then "Y"
end as Match
from t3_vert as t3
full join vali_3g_r as r5
on t3.contentv_name= r5.var_name_test_message
;
quit;

/*Export extracted data into excel*/
PROC EXPORT DATA= compare_r_lab
/*             OUTFILE= "&testdir\validation_test_record_results.xlsx"*/
			 OUTFILE= "&testdir\Validation_Report_Test_Record.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="validation_lab_&tcsw_tm";
RUN;
%mend compare_lab;

%compare_lab(Test_Record__11,test_record1_nnad);
%compare_lab(Test_Record__21,test_record2_nnad);
/*%compare_lab(Test_Record__31,test_record3_nnad);*/
/*%compare_lab(Test_Record__41,test_record4_nnad);*/
%compare_lab(Test_Record__51,test_record5_nnad);
%compare_lab(Test_Record__61,test_record6_nnad);
%compare_lab(Test_Record__71,test_record7_nnad);
%compare_lab(Test_Record__81,test_record8_nnad);


/********************************************************************/
/*NNAD -> Test Message starts*/
/*This is to toggled the untoggled vars and make sure they have no values*/
/********************************************************************/

/*Table to store the untoggled vars*/
proc sql;
	create table not_toggled_var as
	select b.tablename
	,b.Var_Name
	,b.sastype	
	,b.sqltype	
	,b.justlength	
	,b.DE_Identifier	
	,b.DE_Description	
	,b.value_set_content	
	,b.value_set_de_identifier	
	,b.netssforward
	,"1" as Extract
	from mmgAuto_clean a
	right join DataDictionary_extracted2F b
	on (a.DE_Identifier = b.DE_Identifier or a.DE_Name=b.DE_Description)
	where (a.Method in('1F','2F','2G','1G','1.5GDT')
	and b.Extract is null)
	or b.Var_Name='local_record_id'; 
quit;


/*Export extracted data into excel*/
/*PROC EXPORT DATA= not_toggled_var*/
/*             OUTFILE= "&testdir\Output\DD_Not_Toggled_Var.xlsx"*/
/*             DBMS=XLSX REPLACE;*/
/*      SHEET="stage4dict";*/
/*RUN;*/

/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

COVID-19 Starter Code Started

This code is used to pull NNAD data for the untoggled vars in test message review

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/* excel dictionary with user extract flag */

/*libname usrD2 XLSX "&testdir\Output\DD_Not_Toggled_Var.xlsx";*/

/* extract Stage4 variable list from excel dictionary and assign to macro */

proc sql noprint;
   select Var_Name
   into :vlist_n separated by ' '
   from not_toggled_var
   where Extract = '1' 
/*   where Extract = 1*/
   ;
quit;
%put List of variables to extract: &vlist_n;


/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Using the Macro provided will cut down on the processing time and create a ready-to-go analytic database.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
%extractstg4(outdatasetname=stg4_Exl_2,
             SQLlibname=NNAD,
             Stg4DictName=stage4dict,
             filter=%nrstr(condition in ("10180")),
             /*only edit below this comment line*/
             varlist= &vlist_n
            ); /* end of macro call */


;*/;*;*;*;*/;*';*";quit;run; /* this line exits from unbalanced quotation problem and others */

/* DEDUPLICATION AND DATA CLEANING FOR NNAD STAGE4 DATA*/
data stage4_11065_untoggle error_nokey_untoggle;
   set stg4_Exl_2;
  

   if (source_system in (5,15)) then 
      firstkey=cats(report_jurisdiction,compress(local_record_id)); /* For HL7 records, look at local_record_id */
   else if ((source_system=1) and (WSYSTEM=5)) then
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* For NETSS records created from MVPS, look at n_expandedcaseid */  
   else if ((source_system=1) and (WSYSTEM NE 5)) then
      firstkey=cats(report_jurisdiction,compress(local_record_id),site,mmwr_year); /* For other NETSS records, look at local_record_id (CASEID), site, mmwr_year */

   output stage4_11065_untoggle;

   if (firstkey = '') then
      output error_nokey_untoggle;
run;
proc sort tagsort data=stage4_11065_untoggle;
   by firstkey descending source_system ; /* Prefer HL7 record over NETSS duplicate, newer NETSS record over older */
run;


data nnad_untoggle;
   set stage4_11065_untoggle;

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

      if (remove{i} = 1) then
         new{i} = .E; *vaules with characters/special characters;
      else if (remove{i} = 2) then
         new{i} = .Y; *values with mathematical characters;
      else if (remove{i} = 0) then
         new{i} = input(old{i}, 4.); *converts to numeric;
   end;

   drop age_invest mmwr_week  illness_duration mmwr_year rage_invest
        rmmwr_week  rillness_duration rmmwr_year days_in_hosp
        rdays_in_hosp n_count rn_count;

   rename iage_invest=age_invest immwr_week=mmwr_week iillness_duration=illness_duration immwr_year=mmwr_year
          idays_in_hosp=days_in_hosp in_count=n_count;

   *Calculating age in years;

   if (iage_invest = .E) then
      age = .E;
   else if (age_invest_units = 'a') then
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

proc sql;
create table nnad_untoggled_var as
	select *
	from nnad_untoggle
where local_record_id in ("&test_record1_nnad", "&test_record2_nnad", "&test_record5_nnad","&test_record6_nnad", "&test_record7_nnad", "&test_record8_nnad");
quit;

/*Transpose the starter code output*/
proc transpose data=nnad_untoggled_var out =nnad_untoggled_var2 prefix=NNAD_;
	ID local_record_id;
	var _all_;
run;

/*Re-format the validation untoggled var output*/
proc sql;
create table nnad_untoggle_var_order as 
select distinct a.condition
/*,a.DE_Name*/
,a.DE_Identifier_Sent_in_HL7_Messag as DE_Identifier
,a.DE_Name 
/*,b.DE_Identifier*/
,c._NAME_ as Var_Name
,c.&test_record1_nnad_n as Value_Test_Record1
,c.&test_record2_nnad_n as Value_Test_Record2
/*,c.&test_record3_nnad_n as Value_Test_Record3*/
/*,c.&test_record4_nnad_n as Value_Test_Record4*/
,c.&test_record5_nnad_n as Value_Test_Record5
,c.&test_record6_nnad_n as Value_Test_Record6
,c.&test_record7_nnad_n as Value_Test_Record7
,c.&test_record8_nnad_n as Value_Test_Record8
,a.order
from DE_order as a
left join dataDict as b
on a.DE_Identifier_Sent_in_HL7_Messag=b.DE_Identifier
inner join nnad_untoggled_var2 as c
on b.Var_Name=c._NAME_
order by a.condition, a.order, c._NAME_;
quit;

/*Dedup*/
options nolabel;
PROC SORT DATA=nnad_untoggle_var_order
 OUT=nnad_untoggle_var_order_dedup
 nodupkey ;
 BY condition DE_Name DE_Identifier Var_Name Value_Test_Record1 Value_Test_Record2 Value_Test_Record5 Value_Test_Record6 Value_Test_Record7 Value_Test_Record8;
RUN ;

/*re-order */
proc sql;
create table nnad_untoggle_var_order_dedup_r as
select *
from nnad_untoggle_var_order_dedup
where Var_Name not in ('report_jurisdiction')
order by condition desc,order asc, Var_Name asc;
quit;

/*Export extracted data into excel*/
PROC EXPORT DATA= nnad_untoggle_var_order_dedup_r(keep=condition DE_Name DE_Identifier Var_Name Value_Test_Record1 Value_Test_Record2 Value_Test_Record5 Value_Test_Record6 Value_Test_Record7 Value_Test_Record8)
             OUTFILE= "&testdir\Validation_Report_Untoggled_Var.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="untoggled_var";
RUN;


/********************************************************************/
/*NNAD -> Test Message ends*/
/********************************************************************/
