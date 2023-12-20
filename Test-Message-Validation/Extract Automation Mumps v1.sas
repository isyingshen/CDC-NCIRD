 /********************************************************************/
 /* PROGRAM NAME: Extract Automation for Mumps                       */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2022/6/30                                               */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*      Revised from Ying Shen 2020 COVID Extract Automation        */
 /*                                                                  */
 /* PURPOSE:  This program is to automate the process of toggling    */
 /*                                                                  */ 
 /* INPUT:  TCSW.xlsx                                                */
 /*         MMG for auto.xlsx                                        */
 /*         DataDictionary - to extract.xlsx                         */
 /*         Repeating Model Look Ups.xlsx                            */
 /* OUTPUT: DataDictionary_tf_11065-extracted.xlsx		               */
 /*  	      Manual Toggling Report   			                        */
 /*                                                                  */ 
 /* Date Modified: 2022-10-28                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: TM8 replace TM3 and TM7 replace TM4                     */
 /*          comment out TM3 and TM4                                 */
 /*                                                                  */
 /* Date Modified: 2022/10/21                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: Updated the M2G and M2F manual review report            */
 /*          by adding the DE identifier                             */
 /*                                                                  */
 /********************************************************************/

/*The directory of the test message*/
%let testdir =\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\Test Message Review\Mumps Automation;

/*The name of test message form*/
%let test_message_form = UT_TCSW;

/* Import data dictionary into sas */
proc import datafile="&testdir\DataDictionary_eachcond.xlsx"
	DBMS=EXCEL out=dataDict replace;
	range = "Stage4MasterVars$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/* Import MMG Auto into sas: Mumps */
proc import datafile="&testdir\MMG for auto.xlsx"
	DBMS=EXCEL out=mmgAuto replace;
	range = "mumps$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/* Import MMG Auto into sas: generic */
proc import datafile="&testdir\MMG for auto.xlsx"
	DBMS=EXCEL out=mmgAuto_generic replace;
	range = "generic$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*Concatenate generic and COVID19 */
proc append base =mmgAuto data=mmgAuto_generic FORCE;
run;


/* Import NCIRD Test Message Review into sas */
proc import datafile="&testdir\&test_message_form..xlsx"
	DBMS=EXCEL out=testMsgRev_auto replace;
	range = "Mumps 20180504$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*If need to change the header, change it here*/
/*proc sql;*/
/*create table testMsgRev_auto2 as*/
/*select * */
/*,Rubella_TC011 as Test_Record_1*/
/*,Rubella_TC021 as Test_Record_2*/
/*,Rubella_TC031 as Test_Record_3*/
/*,Rubella_TC041 as Test_Record_4*/
/*,Rubella_TC051 as Test_Record_5*/
/*,Rubella_TC061 as Test_Record_6*/
/*,Rubella_TC071 as Test_Record_7*/
/*,Rubella_TC081 as Test_Record_8*/
/*,Rubella_TC091 as Test_Record_9*/
/*from testMsgRev_auto;*/
/*quit;*/

/*Clean the Test Message Review*/
/*a.	Filter by DE Identifier (remove blank DE Identifier)*/

proc sql;
create table testMsgRev_clean as
	select * from testMsgRev_auto
	where DE_Identifier_Sent_in_HL7_Messag is not null;
quit;

data testMsgRev_clean;
set testMsgRev_clean;
order=_n_;
run;

/*Clean the MMG Auto*/
/*a.	Filter by DE Identifier (remove blank DE Identifier)*/
proc sql;
create table mmgAuto_clean as
	select * from mmgAuto
	where DE_Identifier is not null;
quit;



/*Non-Repeating Variables starts*/
/*Merge tables: Test Message Review and MMG Auto*/
proc sql;
create table extract_non_repeat as
	select * 
	,'1' as Extract
	from testMsgRev_clean as a
	left join mmgAuto_clean as b
	on (lowcase(a.DE_Identifier_Sent_in_HL7_Messag)=lowcase (b.DE_Identifier) or lowcase(a.Data_Element__DE__Name)=lowcase(b.DE_Name))
	where b.May_Repeat ='N' 
	and (b.Repeating_Group='N' or b.Repeating_Group='NO')
	order by order;
	/*Filter by Test Record (all test records are null, <blank> or NOT REPORTED): No need to toggle */
/*	and (*/
/*	(Test_Record_1 is not null and Test_Record_1 not in ('<blank>','NOT REPORTED'))*/
/*	or (Test_Record_4 is not null and Test_Record_4 not in ('<blank>','NOT REPORTED'))*/
/*	or (Test_Record_5 is not null and Test_Record_5 not in ('<blank>','NOT REPORTED'))*/
/*	);*/
quit;


/*Add Extract to the original data dictionary*/
proc sql;
	create table DataDictionary_extracted1 as
	select a.tablename
	,a.Var_Name
	,a.sastype	
	,a.sqltype	
	,a.justlength	
	,a.DE_Identifier	
	,a.DE_Description	
	,a.value_set_content	
	,a.value_set_de_identifier	
	,a.netssforward
	,b.Extract
	from dataDict as a
	left join extract_non_repeat as b
	on lowcase(a.Var_Name) = lowcase(b.Var_Name)
	where mumps='1';
quit;


/*Import the non-repeating data elements/variables into sas. This is used to compare the */
/*proc import datafile="&testdir\Non-Repeating Data Elements.xlsx"*/
/*	DBMS=EXCEL out=non_repeat_DE replace;*/
/*	range = "sheet1$";*/
/*	getnames=yes;*/
/*	mixed = yes;*/
/*	scantext = yes;*/
/*	usedate=yes;*/
/*run;*/

/*Number of variables manual toggling*/
proc sql;
title justify=l"The following Non-Repeating Data Elements need manual review:";
	select DE_Identifier
	,DE_Name
	,Var_Name
	from mmgAuto_clean
	where lowcase(Var_Name) not in
	(select lowcase(Var_Name) from DataDictionary_extracted1)
	and mmgAuto_clean.May_Repeat ='N' 
	and (mmgAuto_clean.Repeating_Group='N' or mmgAuto_clean.Repeating_Group='NO');
quit;

/*Non Repeating Variables ends*/

/********************************************************************/
/*Model 1G and 1.5GDT starts*/
/********************************************************************/

/*Fetch the M1G model variables, merge with MMG auto*/
proc sql;
	create table M1G_element1 as
	select * 
	,monotonic() as row
	from testMsgRev_clean  as a
	left join mmgAuto_clean as b
	on a.DE_Identifier_Sent_in_HL7_Messag = b.DE_Identifier
	where b.Method like '%1G%' or b.Method like '%1.5GDT%'

/*	where a.DE_Identifier_Sent_in_HL7_Messag in(*/
/*	M1G*/
/*'77984-3','77984-3','77985-0','77986-8','77987-6',*/
/*'85658-3','85659-1','85078-4','85657-5','55753-8','INV1313','67453-1',*/
/*M1.5GDT*/
/*'82764-2','82754-3','82752-7','TRAVEL08','30956-7','30952-6','30973-2','30957-5',*/
/*'30959-1','VAC109','VAC153','VAC102','VAC147')*/
	order by order;
quit;

/*Sort by Data elements*/
proc sort data =M1G_element1 out=M1G_element1;
	by Data_Element__DE__Name order;
run;

/*Get the Sequential Number for each data elements, concatenate Repeat_Prefix and count*/
data M1G_element2;
	set M1G_element1;
	by Data_Element__DE__Name;
	if first.Data_Element__DE__Name then instance1G=1;
	else instance1G + 1;
	Var_Name_M1G = lowcase (cats(Repeat_Prefix,instance1G)); 
run;

/*Add a new variable called Extract*/
proc sql;
	alter table M1G_element2
	add Extract_M1G char(1);
quit;

/*Update Extract by adding flag 1*/
proc sql;
	update M1G_element2 
	set Extract_M1G ='1';
quit;

/*Add Extract to the original data dictionary*/
proc sql;
	create table DataDictionary_extracted2 as
	select a.tablename
	,a.Var_Name	
	,a.sastype	
	,a.sqltype	
	,a.justlength	
	,a.DE_Identifier	
	,a.DE_Description	
	,a.value_set_content	
	,a.value_set_de_identifier	
	,a.netssforward
	,Case 
	when a.Extract ='1' then '1'
	when b.Extract_M1G ='1' then '1'
	when (a.Extract ='1' and b.Extract_M1G ='1') then '1'
	end as Extract
	,b.Extract_M1G
	from DataDictionary_extracted1 as a
	left join M1G_element2 as b
	on a.Var_Name = b.Var_Name_M1G;
quit;

/*Number of variables manual toggling*/
proc sql;
title justify=l"The following M1G M1.5GDT Var Name need manual toggling(toggle additional flag):";
	select a.Condition
	,a.Data_Element__DE__Name
	,a.Var_Name_M1G
	from M1G_element2 a
	left join DataDictionary_extracted2 b
	on a.Var_Name_M1G = b.Var_Name
	where a.Var_Name_M1G not in 
	(select Var_Name
	from DataDictionary_extracted2)
	order by a.Condition;
quit;
/********************************************************************/
/*Model 1G and 1GDT ends*/
/********************************************************************/


/********************************************************************/
/*Model 2G starts*/
/********************************************************************/
/*Import Repeating Model Lookup into sas */

/*M2_Complications_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_Complications_Q replace;
	range = "M2_Complications_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*M2_Complications_Q: Test_Record_1*/
proc sql;
	create table complications1 as 
	select Test_Record__11 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;

/*M2_Complications_Q: Test_Record_2*/
proc sql;
	create table complications2 as 
	select Test_Record__21 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;
/*M2_Complications_Q: Test_Record_3*/
proc sql;
	create table complications3 as 
	select Test_Record__31 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;
/*M2_Complications_Q: Test_Record_4*/
proc sql;
	create table complications4 as 
	select Test_Record__41 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;
/*M2_Complications_Q: Test_Record_5*/
proc sql;
	create table complications5 as 
	select Test_Record__51 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;
/*M2_Complications_Q: Test_Record_6*/
proc sql;
	create table complications6 as 
	select Test_Record__61 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;
/*M2_Complications_Q: Test_Record_7*/
proc sql;
	create table complications7 as 
	select Test_Record__71 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;
/*M2_Complications_Q: Test_Record_8*/
proc sql;
	create table complications8 as 
	select Test_Record__81 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Type of Complications';
quit;


/*Append vars*/
proc append base=complications1 data=complications2 Force;run;
proc append base=complications1 data=complications3 Force;run;
proc append base=complications1 data=complications4 Force;run;
proc append base=complications1 data=complications5 Force;run;
proc append base=complications1 data=complications6 Force;run;
proc append base=complications1 data=complications7 Force;run;
proc append base=complications1 data=complications8 Force;run;

/*Get the Var_Name*/
proc sql;
create table complications_var_2G as
select distinct a.test_record
,Data_Element__DE__Name
,b.Var_Name
from complications1 as a
left join M2_Complications_Q as b
on a.test_record=b.OBX_5
where a.test_record is not null;
quit;

/*M2_Symptoms_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_Symptoms_Q replace;
	range = "M2_Symptoms_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*Symptoms: Test_Record_1*/
proc sql;
	create table symptoms1 as 
	select Test_Record__11 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_2*/
proc sql;
	create table symptoms2 as 
	select Test_Record__21 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_3*/
proc sql;
	create table symptoms3 as 
	select Test_Record__31 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_4*/
proc sql;
	create table symptoms4 as 
	select Test_Record__41 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_5*/
proc sql;
	create table symptoms5 as 
	select Test_Record__51 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_6*/
proc sql;
	create table symptoms6 as 
	select Test_Record__61 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_7*/
proc sql;
	create table symptoms7 as 
	select Test_Record__71 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_8*/
proc sql;
	create table symptoms8 as 
	select Test_Record__81 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;


/*Append vars*/
proc append base=symptoms1 data=symptoms2 Force;run;
proc append base=symptoms1 data=symptoms3 Force;run;
proc append base=symptoms1 data=symptoms4 Force;run;
proc append base=symptoms1 data=symptoms5 Force;run;
proc append base=symptoms1 data=symptoms6 Force;run;
proc append base=symptoms1 data=symptoms7 Force;run;
proc append base=symptoms1 data=symptoms8 Force;run;

/*Get the Var_Name*/
proc sql;
create table symptoms_var_2G as
select distinct a.test_record
,Data_Element__DE__Name
,b.Var_Name
from symptoms1 as a
left join M2_Symptoms_Q as b
on a.test_record=b.OBX_5
where a.test_record is not null;
quit;

/*Append vars from complications and Symptoms */
proc append base=complications_var_2G data=symptoms_var_2G FORCE;run;


/*Add a new variable called Extract*/
proc sql;
	alter table complications_var_2G
	add Extract_M2G char(1);
quit;

/*Update Extract by adding flag 1*/
proc sql;
	update complications_var_2G
	set Extract_M2G ='1';
quit;

/*Add the variables to the dictionary*/
proc sql;
	create table DataDictionary_extracted3 as
	select a.tablename
	,a.Var_Name	
	,a.sastype	
	,a.sqltype	
	,a.justlength	
	,a.DE_Identifier	
	,a.DE_Description	
	,a.value_set_content	
	,a.value_set_de_identifier	
	,a.netssforward
	,Case 
	when a.Extract ='1' then '1'
	when b.Extract_M2G ='1' then '1'
	when (a.Extract ='1' and b.Extract_M2G ='1') then '1'
	end as Extract
	,a.Extract_M1G
	,b.Extract_M2G
	from DataDictionary_extracted2 as a
	left join complications_var_2G as b
	on a.Var_Name = lowcase(b.Var_Name);
quit;

/*Number of variables manual toggling*/
proc sql;
title justify=l"The following M2G Var Name need manual toggling:";
	select a.Data_Element__DE__Name
   ,a.Var_Name as Var_Name_based_on_tcsw
   ,a.test_record as test_record_need_manual_review
   ,tcsw.Test_Record__11
   ,tcsw.Test_Record__21
/*   ,tcsw.Test_Record_3*/
/*   ,tcsw.Test_Record_4*/
   ,tcsw.Test_Record__51
	,tcsw.Test_Record__61
   ,tcsw.Test_Record__71
   ,tcsw.Test_Record__81
	from complications_var_2G a
/*	left join DataDictionary_extracted3 b*/
/*	on a.Var_Name= b.Var_Name*/
	left join testMsgRev_clean as tcsw
      on a.Data_Element__DE__Name = tcsw.Data_Element__DE__Name and (a.test_record=tcsw.Test_Record__11 or a.test_record=tcsw.Test_Record__21 or a.test_record=tcsw.Test_Record__31 or a.test_record=tcsw.Test_Record__41 or a.test_record=tcsw.Test_Record__51 OR a.test_record=tcsw.Test_Record__61 or a.test_record=tcsw.Test_Record__71 or a.test_record=tcsw.Test_Record__81)
	where lowcase(a.Var_Name) not in 
	(select Var_Name
	from DataDictionary_extracted3)
	and a.Var_Name is not null
	or (a.test_record is not null and a.test_record not in ('<blank>','N/A','Y=Yes','N=No','UNK=Unknown','NOT COLLECTED') and a.Var_Name is null);
quit;

/********************************************************************/
/*Model 2G ends*/
/********************************************************************/

/********************************************************************/
/*Model 1F starts*/
/********************************************************************/
/*Get the list of 1F DE*/
proc sql;
create table data_1F as
	select a.Data_Element__DE__Name
	,a.DE_Identifier_Sent_in_HL7_Messag
	,a.Test_Record__11
	,a.Test_Record__21
	,a.Test_Record__31
	,a.Test_Record__41
	,a.Test_Record__51
	,a.Test_Record__61
	,a.Test_Record__71
	,a.Test_Record__81
	,b.Repeat_Prefix
	,b.Method
	from testMsgRev_clean as a
	left join mmgAuto_clean as b
	on a.DE_Identifier_Sent_in_HL7_Messag =b.DE_Identifier
	where b.Method='1F';
quit;

/*Test Record from horizontal to vertical*/
proc sql;
create table data_1F_record1 as
	select Data_Element__DE__Name
	,Test_Record__11 as test_record
	from data_1F;
create table data_1F_record2 as
	select Data_Element__DE__Name
	,Test_Record__21 as test_record
	from data_1F;
create table data_1F_record3 as
	select Data_Element__DE__Name
	,Test_Record__31 as test_record
	from data_1F;
create table data_1F_record4 as
	select Data_Element__DE__Name
	,Test_Record__41 as test_record
	from data_1F;
create table data_1F_record5 as
	select Data_Element__DE__Name
	,Test_Record__51 as test_record
	from data_1F;
create table data_1F_record6 as
	select Data_Element__DE__Name
	,Test_Record__61 as test_record
	from data_1F;
create table data_1F_record7 as
	select Data_Element__DE__Name
	,Test_Record__71 as test_record
	from data_1F;
create table data_1F_record8 as
	select Data_Element__DE__Name
	,Test_Record__81 as test_record
	from data_1F;
quit;

/*Append vars*/
proc append base=data_1F_record1 data=data_1F_record2 FORCE;run;
proc append base=data_1F_record1 data=data_1F_record3 FORCE;run;
proc append base=data_1F_record1 data=data_1F_record4 FORCE;run;
proc append base=data_1F_record1 data=data_1F_record5 FORCE;run;
proc append base=data_1F_record1 data=data_1F_record6 FORCE;run;
proc append base=data_1F_record1 data=data_1F_record7 FORCE;run;
proc append base=data_1F_record1 data=data_1F_record8 FORCE;run;


/*Determine the maximum number of var */
proc sql;
create table data1F_vertical as
select *
,case 
	when (test_record like '%;%' or test_record like '%,%')  then 2
	when (test_record like '%;%;%' or test_record like '%,%,%') then 3
	when (test_record like '%;%;%;%' or test_record like '%,%,%,%') then 4
	when (test_record like '%;%;%;%;%' or test_record like '%,%,%,%,%') then 5
	when (test_record = '<blank>' or test_record = '' or test_record is null or test_record = 'NOT REPORTED') then 0
else 1
end as num_var

from data_1F_record1
order by Data_Element__DE__Name;

create table data1F_max_num_var as
select Data_Element__DE__Name
	,max(num_var) as max_num_var
	from data1F_vertical
	group by Data_Element__DE__Name
	having max_num_var >0;
quit;

/*Get the sequential instances for 1F*/
data data1F_max_num_var1;
	set data1F_max_num_var;
	do instance1F = 1 to max_num_var;
		output;
	end;
run;

/*Merge to get the Repeat_Prefix, Get the Vars, Mark as 1*/
proc sql;
create table data1F_var as
	select *
	,lowcase(cats(Repeat_Prefix,instance1F)) as Var_Name1F
	,'1' as Extract_1F
	from data1F_max_num_var1 as a
	left join data_1F as b
	on a.Data_Element__DE__Name = b.Data_Element__DE__Name;
quit;

/*Add the variables to the dictionary 1F*/
proc sql;
	create table DataDictionary_extracted1F as
	select a.tablename
	,a.Var_Name	
	,a.sastype
	,a.sqltype	
	,a.justlength	
	,a.DE_Identifier	
	,a.DE_Description	
	,a.value_set_content	
	,a.value_set_de_identifier	
	,a.netssforward
	,Case 
	when a.Extract ='1' then '1'
	when b.Extract_1F ='1' then '1'
	when (a.Extract ='1' and b.Extract_1F ='1') then '1'
	end as Extract
	,a.Extract_M1G
	,a.Extract_M2G
	,b.Extract_1F
	from DataDictionary_extracted3 as a
	left join data1F_var as b
	on a.Var_Name = b.Var_Name1F;
quit;

/*Number of variables manual toggling*/
proc sql;
title justify=l"The following M1F Var Name need manual toggling:";
	select a.Data_Element__DE__Name
	,a.Var_Name1F
	from data1F_var a
	left join DataDictionary_extracted3 b
	on a.Var_Name1F = b.Var_Name
	where a.Var_Name1F not in 
	(select Var_Name
	from DataDictionary_extracted1F)
	and a.Var_Name1F is not null;
quit;

/********************************************************************/
/*Model 1F ends*/
/********************************************************************/


/********************************************************************/
/*Model 2F starts*/
/********************************************************************/
/*Get the list of 2F DE*/
proc sql;
create table data_2F as
	select a.Data_Element__DE__Name
	,a.DE_Identifier_Sent_in_HL7_Messag
	,a.Test_Record__11
	,a.Test_Record__21
	,a.Test_Record__31
	,a.Test_Record__41
	,a.Test_Record__51
	,a.Test_Record__61
	,a.Test_Record__71
	,a.Test_Record__81
	,b.Repeat_Prefix
	,b.Method
	from testMsgRev_clean as a
	left join mmgAuto_clean as b
	on a.DE_Identifier_Sent_in_HL7_Messag =b.DE_Identifier
	where a.DE_Identifier_Sent_in_HL7_Messag in('77988-4')
	or a.DE_Identifier_Sent_in_HL7_Messag like '%PID_10%';
quit;

/*Test Record from horizontal to vertical*/
proc sql;
create table data_2F_record1 as
	select Data_Element__DE__Name
	,Test_Record__11 as test_record
	from data_2F;

create table data_2F_record2 as
	select Data_Element__DE__Name
	,Test_Record__21 as test_record
	from data_2F;

create table data_2F_record3 as
	select Data_Element__DE__Name
	,Test_Record__31 as test_record
	from data_2F;

create table data_2F_record4 as
	select Data_Element__DE__Name
	,Test_Record__41 as test_record
	from data_2F;
	
create table data_2F_record5 as
	select Data_Element__DE__Name
	,Test_Record__51 as test_record
	from data_2F;

create table data_2F_record6 as
	select Data_Element__DE__Name
	,Test_Record__61 as test_record
	from data_2F;

create table data_2F_record7 as
	select Data_Element__DE__Name
	,Test_Record__71 as test_record
	from data_2F;

create table data_2F_record8 as
	select Data_Element__DE__Name
	,Test_Record__81 as test_record
	from data_2F;
quit;

/*Append vars*/
proc append base=data_2F_record1 data=data_2F_record2 FORCE;run;
proc append base=data_2F_record1 data=data_2F_record3 FORCE;run;
proc append base=data_2F_record1 data=data_2F_record4 FORCE;run;
proc append base=data_2F_record1 data=data_2F_record5 FORCE;run;
proc append base=data_2F_record1 data=data_2F_record6 FORCE;run;
proc append base=data_2F_record1 data=data_2F_record7 FORCE;run;
proc append base=data_2F_record1 data=data_2F_record8 FORCE;run;

/*Import reapeating group lookup M2_Race_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_Race_Q replace;
	range = "M2_Race_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*Import reapeating group lookup M2_BinationalReport_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_BinationalReport_Q replace;
	range = "M2_BinationalReport_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*Get the var name*/
proc sql;
	create table data2F_var as
/*	select distinct a.Data_Element__DE__Name*/
/*	,a.test_record*/
/*	,b.Var_Name*/
/*	,'1' as Extract_2F*/
/*	from data_2F_record1 as a*/
/*	left join M2_ContactType_Q as b*/
/*	on a.test_record=b.OBX_5*/
/*	where a.Data_Element__DE__Name ='Contact Type'*/
/*	and a.test_record not in ('<blank>')*/
/*	union */
	select distinct a.Data_Element__DE__Name
	,a.test_record
	,b.Var_Name
	,'1' as Extract_2F
	from data_2F_record1 as a
	left join M2_Race_Q as b
	on a.test_record=b.PID_10
	where a.Data_Element__DE__Name ='Race Category'
	and a.test_record not in ('<blank>')
	union
	select distinct a.Data_Element__DE__Name
	,a.test_record
	,b.Var_Name
	,'1' as Extract_2F
	from data_2F_record1 as a
	left join M2_BinationalReport_Q as b
	on a.test_record=b.OBX_5
	where a.Data_Element__DE__Name ='Binational Reporting Criteria'
	and a.test_record not in ('<blank>');
quit;

/*Add the variables to the dictionary 1F*/
proc sql;
	create table DataDictionary_extracted2F as
	select a.tablename
	,a.Var_Name	
	,a.sastype
	,a.sqltype	
	,a.justlength	
	,a.DE_Identifier	
	,a.DE_Description	
	,a.value_set_content	
	,a.value_set_de_identifier	
	,a.netssforward
	,Case 
	when a.Extract ='1' then '1'
	when b.Extract_2F ='1' then '1'
	when (a.Extract ='1' and b.Extract_2F ='1') then '1'
	end as Extract
	,a.Extract_M1G
	,a.Extract_M2G
	,a.Extract_1F
	,b.Extract_2F
	from DataDictionary_extracted1F as a
	left join data2F_var as b
	on a.Var_Name = lowcase(b.Var_Name);
quit;

/*Number of variables manual toggling*/
proc sql;
title justify=l"The following M2F Var Name need manual toggling:";
	select a.Data_Element__DE__Name
	,a.Var_Name
	from data2F_var a
	where lowcase(a.Var_Name) not in 
	(select Var_Name
	from DataDictionary_extracted1F)
	and Var_Name is not null;
quit;


/********************************************************************/
/*Model 2F ends*/
/********************************************************************/

/********************************************************************/
/*Model 3G starts*/
/********************************************************************/

/*No longer needed as we uses T3_vertical*/

/********************************************************************/
/*Model 3G ends*/
/********************************************************************/



/*Export extracted data into excel*/
PROC EXPORT DATA= DataDictionary_extracted2F
             OUTFILE= "&testdir\Output\DD-extracted.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="stage4dict";
RUN;


/*Output the test records and the corresponding case ID  */
proc sql;
title justify=l"The Test Records and the Corresponding Case ID which will be used as the input of the Validation Automation Program.";
	select DE_Name
	,Var_Name as Var_Name_Test_Message
	,Test_Record__11 as Test_Record_1
	,Test_Record__21 as Test_Record_2
/*	TM8 replace TM3 and TM7 replace TM4, comment out TM3 and TM4*/
/*	,Test_Record__31 as Test_Record_3*/ 
/*	,Test_Record__41 as Test_Record_4*/
	,Test_Record__51 as Test_Record_5
	,Test_Record__61 as Test_Record_6
	,Test_Record__71 as Test_Record_7
	,Test_Record__81 as Test_Record_8
	
	from extract_non_repeat
	where Var_Name in ('local_record_id');
quit;

