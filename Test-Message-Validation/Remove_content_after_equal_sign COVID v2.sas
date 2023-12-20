/*Updated on 2021-10-1 added "^"*/

/********************************************************************/
 /* PROGRAM NAME: Remove content after = or ^                        */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2021/10/1                                              */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to remove any content after equal sign */
 /*           (=) or carat (^) so that the value will be automatically*/
 /*  	      	toggled and validated		                          */
 /*                                                                  */ 
 /* INPUT:  xlsx                                                     */
 /* OUTPUT: xlsx	                                                 */
 /*                                                                  */
 /* Date Modified: 2023-5-20                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Added macro to change TCSW column headers               */
 /*          commented out by default                                */
 /*                                                                  */ 
 /* Date Modified:                                                   */
 /* Modified by:                                                     */
 /* Changes:                                                         */
 /*                                                                  */
 /********************************************************************/

/*The directory of the test message review sheet*/
%let testdir =\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\Test Message Review\Automation;
%let test_message_form = OR COVID-19 NCIRD Test Message Review YS;

/*Define the sign = or ^*/
%let sign==^;

/*Added macro to change TCSW column headers: change the column headers to match the TCSW*/
/*%let Test_Record_1 = Test_Record_1;*/
/*%let Test_Record_1 = Test_Record_1;*/
/*%let Test_Record_1 = Test_Record_1;*/


/* Import NCIRD Test Message Review into sas */
proc import datafile="&testdir\&test_message_form..xlsx"
	DBMS=EXCEL out=testMsgRev replace;
	range = "NCIRD Review$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*proc contents data=testMsgRev;*/
/*run;*/

proc sql;
select Test_Record_1
,Test_Record_4
,Test_Record_5
from testMsgRev;
quit;

data testMsgRev1;
	set testMsgRev;
/*	num_semicolon=countc(Test_Record_4,";");*/
	if countc(Test_Record_1,";")=0 then 
/*		Test_Record_1_2=scan(Test_Record_1,1,"=");*/
		Test_Record_1_2=scan(Test_Record_1,1,"&sign");
	else 
	Test_Record_1_2=cats(scan(scan(Test_Record_1,1,";"),1,"&sign"),";",scan(scan(Test_Record_1,2,";"),1,"&sign"));
	
	if countc(Test_Record_4,";")=0 then 
/*		Test_Record_4_2=scan(Test_Record_4,1,"=");*/
		Test_Record_4_2=scan(Test_Record_4,1,"&sign");
	else 
	Test_Record_4_2=cats(scan(scan(Test_Record_4,1,";"),1,"&sign"),";",scan(scan(Test_Record_4,2,";"),1,"&sign"));
	
	if countc(Test_Record_5,";")=0 then 
/*		Test_Record_5_2=scan(Test_Record_5,1,"=");*/
		Test_Record_5_2=scan(Test_Record_5,1,"&sign");
	else 
	Test_Record_5_2=cats(scan(scan(Test_Record_5,1,";"),1,"&sign"),";",scan(scan(Test_Record_5,2,";"),1,"&sign"));

	drop Test_Record_1;
	rename Test_Record_1_2 =Test_Record_1;
	drop Test_Record_4;
	rename Test_Record_4_2 =Test_Record_4;
	drop Test_Record_5;
	rename Test_Record_5_2 =Test_Record_5;

run;

proc sql;
select 
/*Test_Record_4*/
/*,Test_Record_2_1*/
/*,num_semicolon*/
Test_Record_1
,Test_Record_4
,Test_Record_5
from testMsgRev1;
quit;


/*Export extracted data into excel*/
PROC EXPORT DATA= testMsgRev1
             OUTFILE= "&testdir\OR COVID-19 NCIRD Test Message Review YS2.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="NCIRD Review";
RUN;
