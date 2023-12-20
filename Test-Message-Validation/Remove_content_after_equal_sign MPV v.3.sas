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
 /*
 /*  Date Modified: 2023-7-10 */
 /*                                                                  */ 
 /* Date Modified:                                                   */
 /* Modified by:                                                     */
 /* Changes:                                                         */
 /*                                                                  */
 /********************************************************************/

/*The directory of the test message review sheet*/
%let testdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Katherine_Luce\MMG Onboarding\Mumps\UT;
%let test_message_form = UT_TCSW 2;

/*Define the sign = or ^*/
%let sign==;

/*Added macro to change TCSW column headers: change the column headers to match the TCSW*/
/*%let Test_Record_1 = Test_Record_1;*/
/*%let Test_Record_1 = Test_Record_1;*/
/*%let Test_Record_1 = Test_Record_1;*/


/* Import TCSW into sas. NOTE: User will need to update the range to match the title of the tab in the TCSW */
proc import datafile="&testdir\&test_message_form..xlsx"
	DBMS=EXCEL out=testMsgRev replace;
	range = "Mumps 20180504$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

proc contents data=testMsgRev;
run;

proc sql;
select Test_Record__11
,Test_Record__21
,Test_Record__31
,Test_Record__41
,Test_Record__51
,Test_Record__61
,Test_Record__71
,Test_Record__81
/*,Test_Record__91*/
from testMsgRev;
quit;

data testMsgRev1;
	set testMsgRev;
/*	num_semicolon=countc(Test_Record_4,";");*/

	if countc(Test_Record__11,";")=0 then 
/*		Test_Record_1_2=scan(Test_Record_1,1,"=");*/
		Test_Record__11_2=scan(Test_Record__11,1,"&sign");
	else 
	Test_Record__11_2=cats(scan(scan(Test_Record__11,1,";"),1,"&sign"),";",scan(scan(Test_Record__11,2,";"),1,"&sign"));



	if countc(Test_Record__21,";")=0 then 
/*		Test_Record_2_2=scan(Test_Record_2,1,"=");*/
		Test_Record__21_2=scan(Test_Record__21,1,"&sign");
	else 
	Test_Record__21_2=cats(scan(scan(Test_Record__21,1,";"),1,"&sign"),";",scan(scan(Test_Record__21,2,";"),1,"&sign"));

	


	if countc(Test_Record__31,";")=0 then 
/*		Test_Record_3_2=scan(Test_Record_3,1,"=");*/
		Test_Record__31_2=scan(Test_Record__31,1,"&sign");
	else 
	Test_Record__31_2=cats(scan(scan(Test_Record__31,1,";"),1,"&sign"),";",scan(scan(Test_Record__31,2,";"),1,"&sign"));



	
	if countc(Test_Record__41,";")=0 then 
/*		Test_Record_4_2=scan(Test_Record_4,1,"=");*/
		Test_Record__41_2=scan(Test_Record__41,1,"&sign");
	else 
	Test_Record__41_2=cats(scan(scan(Test_Record__41,1,";"),1,"&sign"),";",scan(scan(Test_Record__41,2,";"),1,"&sign"));



	
	if countc(Test_Record__51,";")=0 then 
/*		Test_Record_5_2=scan(Test_Record_5,1,"=");*/
		Test_Record__51_2=scan(Test_Record__51,1,"&sign");
	else 
	Test_Record__51_2=cats(scan(scan(Test_Record__51,1,";"),1,"&sign"),";",scan(scan(Test_Record__51,2,";"),1,"&sign"));



	
	if countc(Test_Record__61,";")=0 then 
/*		Test_Record_6_2=scan(Test_Record_6,1,"=");*/
		Test_Record__61_2=scan(Test_Record__61,1,"&sign");
	else 
	Test_Record__61_2=cats(scan(scan(Test_Record__61,1,";"),1,"&sign"),";",scan(scan(Test_Record__61,2,";"),1,"&sign"));




	if countc(Test_Record__71,";")=0 then 
/*		Test_Record_71_2=scan(Test_Record_7,1,"=");*/
		Test_Record__71_2=scan(Test_Record__71,1,"&sign");
	else 
	Test_Record__71_2=cats(scan(scan(Test_Record__71,1,";"),1,"&sign"),";",scan(scan(Test_Record__71,2,";"),1,"&sign"));




	if countc(Test_Record__81,";")=0 then 
/*		Test_Record_2_2=scan(Test_Record_8,1,"=");*/
		Test_Record__81_2=scan(Test_Record__81,1,"&sign");
	else 
	Test_Record__81_2=cats(scan(scan(Test_Record__81,1,";"),1,"&sign"),";",scan(scan(Test_Record__81,2,";"),1,"&sign"));

	
	/*if countc(Test_Record_91,";")=0 then 
/*		Test_Record_91_2=scan(Test_Record_91,1,"=");*/
		/*Test_Record_91_2=scan(Test_Record_91,1,"&sign");
	else 
	Test_Record_91_2=cats(scan(scan(Test_Record_91,1,";"),1,"&sign"),";",scan(scan(Test_Record_91,2,";"),1,"&sign"));*/


	drop Test_Record__11;
	rename Test_Record__11_2 =Test_Record__11;

	drop Test_Record__21;
	rename Test_Record__21_2 =Test_Record__21;

	drop Test_Record__31;
	rename Test_Record__31_2 =Test_Record__31;

	drop Test_Record__41;
	rename Test_Record__41_2 =Test_Record__41;

	drop Test_Record__51;
	rename Test_Record__51_2 =Test_Record__51;

	drop Test_Record__61;
	rename Test_Record__61_2 =Test_Record__61;

	drop Test_Record__71;
	rename Test_Record__71_2 =Test_Record__71;

	drop Test_Record__81;
	rename Test_Record__81_2 =Test_Record__81;

	/*drop Test_Record__91;
	rename Test_Record__91_2 =Test_Record__91;*/



run;

proc sql;
select 
/*Test_Record_4*/
/*,Test_Record_2_1*/
/*,num_semicolon*/
Test_Record__11
,Test_Record__21
,Test_Record__31
,Test_Record__41
,Test_Record__51
,Test_Record__61
,Test_Record__71
,Test_Record__81
/*,Test_Record__91*/
from testMsgRev1;
quit;


/*Export extracted data into excel*/
PROC EXPORT DATA= testMsgRev1
             OUTFILE= "&testdir\UT_TCSW3.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="NCIRD Review";
RUN;
