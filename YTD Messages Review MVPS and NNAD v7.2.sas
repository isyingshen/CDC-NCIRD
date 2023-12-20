/**********************************************************************************/
 /* PROGRAM NAME: YTD Message Review MVPS - No Year                                */
 /* VERSION: 6.2                                                                   */
 /* CREATED: 2021/12/3                                                             */
 /*                                                                                */
 /* BY:  Ying Shen                                                                 */
 /*                                                                                */
 /* PURPOSE:  This program is to automate the process of                           */
 /*           reviewing the year-to-date messages in MVPS                          */
 /*                                                                                */ 
 /* INPUT:    jurisdiction line list in excel                                      */
 /*           mvps database                                                        */
 /*                                                                                */ 
 /* OUTPUT:  messages in both NNAD and Line List                                   */
 /*          messages in Line List only                                            */
 /*          messages in NNAD only                                                 */ 
 /*                                                                                */ 
 /* Date Modified: 2022/1/5                                                        */
 /* Modified by: Ying Shen                                                         */
 /* Changes: Combine MVPS and NNAD                                                 */
 /*                                                                                */ 
 /* Date Modified: 2022/4/25                                                       */
 /* Modified by: Ying Shen                                                         */
 /* Changes: Only output 500 for NNAD_only bucket                                  */
 /*                                                                                */ 
 /* Date Modified: 2022/9/18                                                       */
 /* Modified by: Ying Shen                                                         */
 /* Changes: Add the following info                                                */
 /*     Total message and Total unduplicated messages of Line List                 */
 /*     Total message and Total unduplicated messages of Cases current_record_flag=Y*/
 /*     Total message and Total unduplicated messages of Cases current_record_flag=N*/
 /*     Total message and Total unduplicated messages of Cases current_record_flag=E*/
 /*     Total message and Total unduplicated messages of Cases Not Received as COVID*/
 /*     Total message and Total unduplicated messages of MVPS total                */
 /*                                                                                */ 
 /* Date Modified: 2022/12/02                                                      */
 /* Modified by: Ying Shen                                                         */
 /* Changes: improved MVPS selection by separating two filters in two steps        */
 /*          changed proc report to proc export                                    */
 /*                                                                                */ 
 /* Date Modified: 2023/02/24                                                      */
 /* Modified by: Ying Shen                                                         */
 /* Changes: improve the code by resolving conflicts when users use local_record_id*/
 /*          in the linelist                                                       */
 /*      MVPS Summary Tab: Output 3 subcategories of messages not received as COVID*/
 /*                                                                                */ 
 /* Date Modified: 2023/5/10                                                       */
 /* Modified by: Ying Shen                                                         */
 /* Changes: Added port number 1201 to the mvpsdata\qsrv1                          */
 /*          Added a snippet to import a csv                                       */
 /*          Aded a snippet to export a csv d                                      */
 /*          Removed merges to improve the running time 
 /*  Date Modified: 2023/6/27
 /*  Modified by: Jheri Godfrey													   */
 /*			 Updated/changed "line_list_not_received2" to "line_list_not_received" */
 /*			 for proc sqls "noreceived_msg TRIMMED" and "noreceived_case TRIMMED"  */
 /*	         in *Get the summary numbers for Cases Not Received as COVID*section   */
 /*
 /* Date Modified: 2023/08/16                                                      */
 /* Modified by: Katherine Luce                                                    */
 /* Changes: Added a snippt to export a txt file for the "both_nnad_linelist".     */
 /*																				    */                                       							
 /* Date Modified: 2023/08/17														*/
 /* Modified by: Jheri Godfrey													    */
 /* Changes: Added sql table to create list of Trans IDs only for "both NNAD and Line List" */
 /*			 Added a snippet to import a csv file of trans IDs for "both_nnad_linelist" */
 /*		     Added a snippet to export a txt file of trans IDs for "both_nnad_linelist" */																
 /*			  																		*/
 /*	  Date Modified: 2023/11/15														*/
 /* Modified by: Jheri Godfrey													    */
 /* Changes: Added 'COVID19_MMG_V1.2' header to condition_specific_msg_guide        */
 /*			 																		*/
 /*		             																*/
 /*				                                           							*/                               
 /**********************************************************************************/


/*Update the following info*/
%let juris=SD; *jurisdiction 2 (or 3) letter abbreviation to match folder naming convention;
%let juris_code='46'; *jurisdiction code;
%let cond=COVID-19; *name of MMG condition(s) (COVID-19, Mumps, Pertussis, Varicella, Measles, Rubella, CRS, H flu, N mening, IPD, Psittacosis, Legionellosis);
/*%let year='2021'; *Enter the mmwr_year, don not remove the quotation mark;*/
/*Location of the file names*/
%let ytd_dir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\jheri_godfrey\YTD\SD;
/*%let ytd_dir=\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\&juris\&cond\YTD Messages;*/
%let lnlist=COVID_YTD_SDDOH.xlsx; *file name of line list from jurisdiction. Include the extension (e.g., .xlsx);
%let lnlisttab=COVID_YTD_SDDOH; *tab name of the line list excel;
%let IDcolumn=case_ID; * the local record ID column name in the LINE LIST;

/*MVPS db*/
libname mvps OLEDB provider="sqlncli11"
     properties = ( "data source"="MVPSdata,1201\QSRV1" "Integrated Security"="SSPI"
           "Initial Catalog"="MVPS_PROD" ) schema=hl7 access=readonly;

/* Import line list (excel) into sas */
proc import datafile="&ytd_dir\&lnlist"
	DBMS=EXCEL out=linelist replace;
	range = "&lnlisttab$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/* Import line list (CSV) into sas */
/*proc import datafile="&ytd_dir\&lnlist"
	out=linelist
	DBMS=csv
	replace;
	getnames=yes;
	run;*/

/*Convert num line list to char*/
data linelist;
      set linelist;
      newvar=compress(vvalue(&IDcolumn));
      drop &IDcolumn;
      rename newvar=&IDcolumn;
run;

/*proc contents data=linelist;*/
/*run;*/

/*Get all data from MVPS*/
Proc sql;
create table mvps_data_juri as
select distinct local_record_id
,current_record_flag
,national_reporting_jurisdiction_
,gen_msg_guide
,condition_specific_msg_guide
,mmwr_year
,msg_received_dttm
,mvps_datetime_updated
from mvps.message_meta_vw
where national_reporting_jurisdiction_=&juris_code;
quit;

/*Get jurisdiction data*/
proc sql;
create table mvps_data as
select *
from mvps_data_juri
where condition_specific_msg_guide in ('COVID19_MMG_V1.0','COVID19_MMG_V1.1','COVID19_MMG_V1.2');
quit;


/*Get cases that are flaged as "Y"*/
proc sql;
create table mvps_data_y as
select *
from mvps_data
where current_record_flag='Y';
quit;

/*Get the list where current_record_flag=Y in line list*/
/*proc sql;*/
/*create table line_list_Y as*/
/*select distinct a.&IDcolumn as LineListID*/
/*,b.**/
/*from linelist a*/
/*left join mvps_data_y b*/
/*on a.&IDcolumn=b.local_record_id;*/
/*quit;*/

/*Export extracted data into excel*/
/*proc sql;*/
/*create table line_list_found_Y as*/
/*select * from line_list_Y*/
/*where local_record_id is not null;*/
/*quit;*/

/*Re-write to remove joins*/
proc sql;
create table line_list_found_Y as
select *
from mvps_data_y
where local_record_id in
(select distinct &IDcolumn
from linelist);
quit;

/*Export extracted data into excel*/
/*PROC EXPORT DATA= line_list_found_Y*/
/*             OUTFILE= "&ytd_dir\Cases Check in MVPS run on &sysdate9..xlsx"*/
/*             DBMS=XLSX REPLACE;*/
/*      SHEET="Cases current_record_flag=Y";*/
/*RUN;*/

/*current_record_flag=N*/
/*select cases that are not found*/
/*proc sql;*/
/*create table line_list_N as*/
/*select distinct a.LineListID*/
/*,b.local_record_id*/
/*,b.current_record_flag*/
/*,b.gen_msg_guide*/
/*,b.condition_specific_msg_guide*/
/*,b.mmwr_year*/
/*from line_list_Y a*/
/*left join mvps_data b*/
/*on a.LineListID=b.local_record_id*/
/*where a.local_record_id is null*/
/*and b.current_record_flag='N';*/
/*quit;*/

/*Re-write to remove join*/
proc sql;
create table line_list_N as
select  
b.local_record_id
,b.current_record_flag
,b.gen_msg_guide
,b.condition_specific_msg_guide
,b.mmwr_year
from mvps_data b
where b.current_record_flag='N'
and local_record_id in
(select distinct &IDcolumn
from linelist)
and b.local_record_id not in
(select distinct local_record_id
from line_list_found_Y)
;
quit;

/*Export extracted data into excel*/
/*PROC EXPORT DATA= line_list_N*/
/*             OUTFILE= "&ytd_dir\Cases Check in MVPS run on &sysdate9..xlsx"*/
/*             DBMS=XLSX REPLACE;*/
/*      SHEET="Cases current_record_flag=N";*/
/*RUN;*/


/*Errored cases*/
/*proc sql;*/
/*create table line_list_E as*/
/*select distinct a.LineListID*/
/*,b.local_record_id*/
/*,b.current_record_flag*/
/*,b.gen_msg_guide*/
/*,b.condition_specific_msg_guide*/
/*,b.mmwr_year*/
/*from line_list_Y a*/
/*left join mvps_data b*/
/*on a.LineListID=b.local_record_id*/
/*where a.local_record_id is null*/
/*and b.current_record_flag='E';*/
/*quit;*/

/*Re-write to remove join*/
proc sql;
create table line_list_E as
select  
b.local_record_id
,b.current_record_flag
,b.gen_msg_guide
,b.condition_specific_msg_guide
,b.mmwr_year
from mvps_data b
where b.current_record_flag='E'
and local_record_id in
(select distinct &IDcolumn
from linelist)
and b.local_record_id not in
(select distinct local_record_id
from line_list_found_Y)
and b.local_record_id not in
(select distinct local_record_id
from line_list_N)
;
quit;

/*Export extracted data into excel*/
/*PROC EXPORT DATA= line_list_E*/
/*             OUTFILE= "&ytd_dir\Cases Check in MVPS run on &sysdate9..xlsx"*/
/*             DBMS=XLSX REPLACE;*/
/*      SHEET="Cases current_record_flag=E";*/
/*RUN;*/

/*Not received messages*/
/*proc sql;*/
/*create table line_list_not_received as*/
/*select distinct a.LineListID*/
/*,b.**/
/*from line_list_Y a*/
/*left join mvps_data b*/
/*on a.LineListID=b.local_record_id*/
/*where a.local_record_id is null */
/*make sure the massage is not flagged as Y and has no covid msh*/
/*and b.local_record_id not in*/
/*(select local_record_id*/
/*from line_list_N)*/
/*and b.local_record_id not in*/
/*(select local_record_id*/
/*from Line_list_E);*/
/*quit;*/

/*Re-write to remove join*/
proc sql;
create table line_list_not_received as
select *
from linelist
where &IDcolumn not in
(select distinct local_record_id
from line_list_found_Y)
and &IDcolumn not in
(select distinct local_record_id
from line_list_N)
and &IDcolumn not in
(select local_record_id
from Line_list_E);
quit;


/*Export extracted data into excel*/
/*PROC EXPORT DATA= line_list_not_received*/
/*             OUTFILE= "&ytd_dir\Cases Check in MVPS for &juris &sysdate9..xlsx"*/
/*             DBMS=XLSX REPLACE;*/
/*      SHEET="Cases Not Received as COVID";*/
/*RUN;*/


/*Get the summary numbers for Line List*/
proc sql noprint;
	select count(&IDcolumn) into :linelist_msg TRIMMED
	from linelist;

	select count (distinct &IDcolumn) into :linelist_case TRIMMED
	from linelist;
quit;

/*Get the summary numbers for Cases current_record_flag=Y*/
proc sql noprint;
	select count(local_record_id) into :y_msg TRIMMED
	from line_list_found_Y;

	select count (distinct local_record_id) into :y_case TRIMMED
	from line_list_found_Y;
quit;

/*Get the summary numbers for Cases current_record_flag=N*/
proc sql noprint;
	select count(local_record_id) into :n_msg TRIMMED
	from line_list_N;

	select count (distinct local_record_id) into :n_case TRIMMED
	from line_list_N;
quit;

/*Get the summary numbers for Cases current_record_flag=E*/
proc sql noprint;
	select count(local_record_id) into :e_msg TRIMMED
	from line_list_E;

	select count (distinct local_record_id) into :e_case TRIMMED
	from line_list_E;
quit;

/*Add datasets for summaries*/
proc sql;
/*Genv2 only messages*/
	create table line_list_not_received_genv2 as
	select * 
	from mvps_data_juri
	where local_record_id in 
	(select distinct &IDcolumn 
	from line_list_not_received)
	and gen_msg_guide is not null
	and condition_specific_msg_guide is null;

/*Messages sent under other condition msg headers*/
	create table line_list_not_received_othercond as
	select * 
	from mvps_data_juri
	where local_record_id in 
	(select distinct &IDcolumn 
	from line_list_not_received)
	and condition_specific_msg_guide is not null
	and condition_specific_msg_guide not in ('COVID19_MMG_V1.0','COVID19_MMG_V1.1','COVID19_MMG_V1.2');

/*Message not sent all all*/
	create table line_list_not_received_atAll as
	select *
	from line_list_not_received
	where &IDcolumn not in 
	(select distinct local_record_id
	from mvps_data_juri);
quit;

/*Append datasets for linelist not received*/
proc sql;
create table line_list_not_received2 as
select *
from line_list_not_received_genv2
union
select *
from line_list_not_received_othercond
union
select *
from line_list_not_received_atAll;

quit;

/*Get the summary numbers for Cases Not Received as COVID*/
proc sql noprint;
	select count(&IDcolumn) into : noreceived_msg TRIMMED
	from line_list_not_received;

	select count (distinct &IDcolumn) into : noreceived_case TRIMMED
	from line_list_not_received;

	select count(distinct local_record_id) into : noreceived_case_genV2 TRIMMED
	from line_list_not_received_genv2;

	select count(distinct local_record_id) into : noreceived_case_otherCond TRIMMED
	from line_list_not_received_othercond;

	select count(distinct &IDcolumn) into : noreceived_case_atAll TRIMMED
	from line_list_not_received_atAll;
quit;


/*Excel output. Analysts can copy the numbers to the email for CSELS and Jurisdiction*/

/*Tab: MVPS Summary*/
ods excel file="&ytd_dir\Cases Check in MVPS for &juris &sysdate9..xlsx" 
options(embedded_titles='yes'
embedded_footnotes='yes' start_at='2, 1' frozen_headers='yes' title_footnote_nobreak='yes' sheet_name='MVPS Summary');


title bold height=24pt j=left "MVPS Summary for &juris";
title2 j=left "There are &linelist_case cases (&linelist_msg rows) in &juris line list titled '&lnlist'. Our analysis of the cases represented by those messages was run on &sysdate9.. Below is the summary from our review titled 'Cases Check in MVPS for &juris run on &sysdate9..xlsx':";
title3 j=left " There are &y_case cases (&y_msg messages) flagged as 'Y' (see tab, Cases current_record_flag=Y)";
title4 j=left " There are &n_case cases (&n_msg messages) flagged as 'N' (see tab, Cases current_record_flag=N)";
title5 j=left " There are &e_case cases (&e_msg messages) flagged as 'E' (see tab, Cases current_record_flag=E)";
title6 j=left " There are &noreceived_case cases (&noreceived_msg messages) NOT received as COVID (see tab, Cases Not Received as COVID). Among these cases, &noreceived_case_genV2 cases are received as GENERIC messages; &noreceived_case_otherCond cases are received as conditions other than COVID-19 (Message Headers NOT 'COVID19_MMG_V1.0' or 'COVID19_MMG_V1.1' or 'COVID19_MMG_V1.2' ); &noreceived_case_atAll cases are NOT received in MVPS at all.";

/*Create a Mock report to finish this tab*/
proc sql;
	create table mocktable as
	select &IDcolumn as ID
	from linelist
	where &IDcolumn like '%end%';
quit;

data _null_;
  if nobs=0 then do;
     file print titles;
     put 'End';
  end;
  set mocktable nobs=nobs;
run;

proc report DATA= mocktable;   
run;

/*End of Tab: MVPS Summary*/
ods excel close;

/*Export extracted data into excel*/
PROC EXPORT DATA= line_list_found_Y
             OUTFILE= "&ytd_dir\Cases Check in MVPS for &juris &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="Cases current_record_flag=Y";
RUN;


/*If needed, export to csv*/
/*PROC EXPORT DATA= line_list_found_Y
            OUTFILE= "&ytd_dir\Cases Check in MVPS (Cases current_record_flag=Y) for &juris &sysdate9..csv"
             DBMS=CSV REPLACE;
RUN;*/

/*Export extracted data into excel*/
PROC EXPORT DATA= line_list_N
             OUTFILE= "&ytd_dir\Cases Check in MVPS for &juris &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="Cases current_record_flag=N";
RUN;

/*Export extracted data into excel*/
PROC EXPORT DATA= line_list_E
             OUTFILE= "&ytd_dir\Cases Check in MVPS for &juris &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="Cases current_record_flag=E";
RUN;

/*Export extracted data into excel*/
PROC EXPORT DATA= line_list_not_received2
             OUTFILE= "&ytd_dir\Cases Check in MVPS for &juris &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="Cases Not Received as COVID";
RUN;

/*Export extracted data into csv*/
/*PROC EXPORT DATA= line_list_not_received*/
            /*OUTFILE= "&ytd_dir\Cases Check in MVPS (Cases Not Received as COVID)for &juris &sysdate9..xlsx"*/
             /*DBMS=CSV REPLACE;*/
/*RUN;*/



 /********************************************************************/
 /* PROGRAM NAME: YTD Message Review NNAD                            */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2021/10/26                                              */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to automate the process of             */
 /*           reviewing the year-to-date messages in NNAD            */
 /*                                                                  */ 
 /* INPUT:    jurisdiction line list in excel                        */
 /*           nnad database                                          */
 /*           mvps database                                          */
 /*                                                                  */ 
 /* OUTPUT:  messages in both NNAD and Line List                     */
 /*          messages in Line List only                              */
 /*          messages in NNAD only                                   */ 
 /*                                                                  */ 
 /* Date Modified:  12/21/21                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Remove MVPS Check, comment out year check               */
 /********************************************************************/

/*Connect to NNAD PROD*/
libname nnad OLEDB provider="sqlncli11"
     properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1" "Integrated Security"="SSPI"
           "Initial Catalog"="NCIRD_DVD_VPD" ) schema=nndss access=readonly;

/*pull the NNAD COVID data*/
proc sql;
create table nnad_t1 as
select msh_id_disease
,local_record_id
,trans_id
,mmwr_year
,report_jurisdiction
from nnad.Stage4_NNDSScasesT1
where condition='11065'
and report_jurisdiction=&juris_code
/*and mmwr_year=&year*/
and msh_id_disease like '%COVID19%';
quit;

/*Cases in NNAD only*/
proc sql;
create table nnad_only as
select *
from nnad_t1
where local_record_id not in
(select &IDcolumn
from linelist);
quit;

proc sql;
create table nnad_only_500 as
select *
from nnad_t1 (obs=500)
where local_record_id not in
(select &IDcolumn
from linelist);
quit;

/*Cases in Line List only*/
proc sql;
create table linelist_only as
select *
from linelist
where &IDcolumn not in
(select local_record_id
from nnad_t1);
quit;

/*Cases in both NNAD and Line List*/
proc sql;
create table both_nnad_linelist as
select *
from nnad_t1
where local_record_id in
(select &IDcolumn
from linelist);
quit;

/*If needed, list of Trans IDs for both NNAD and Line List*/
/*proc sql;
create table both_nnad_linelist2 as
select trans_id
from nnad_t1
where local_record_id in
(select &IDcolumn
from linelist);
quit;*/

/*Export extracted data into excel*/
PROC EXPORT DATA= nnad_only_500
             OUTFILE= "&ytd_dir\Cases Check in NNAD run on &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="Cases_NNAD_Only_500";
RUN;

/*Export extracted data into excel*/
PROC EXPORT DATA= linelist_only
             OUTFILE= "&ytd_dir\Cases Check in NNAD run on &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="Cases_Line_List_Only";
RUN;

/*Export extracted data into excel*/
PROC EXPORT DATA= both_nnad_linelist
             OUTFILE= "&ytd_dir\Cases Check in NNAD run on &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="Both_NNAD_Line_list";
RUN;

/*If needed, export to csv*/
/*PROC EXPORT DATA= both_nnad_linelist /*line_list_found_Y
             OUTFILE= "&ytd_dir\Cases Check in NNAD (Both_NNAD_Line_list) for &juris &sysdate9..csv"
             DBMS=CSV REPLACE;
RUN;*/

/*If needed, export Trans ID list to txt */
/*PROC EXPORT DATA= both_nnad_linelist2
            OUTFILE= "&ytd_dir\Cases Check in NNAD (Both_NNAD_Line_list) for &juris &sysdate9..txt"
            DBMS=tab REPLACE;
RUN;*/

/*If needed, export Trans ID list to csv */
/*PROC EXPORT DATA= both_nnad_linelist2
             OUTFILE= "&ytd_dir\Cases Check in NNAD (Both_NNAD_Line_list) for &juris &sysdate9..csv"
             DBMS=CSV REPLACE;
RUN;*/


