/********************************************************************/
 /* PROGRAM NAME: Extract Automation                                 */
 /* VERSION: 7.0                                                     */
 /* CREATED: 2020/11/10                                              */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to automate the process of toggling    */
 /*                                                                  */ 
 /* INPUT:  COVID-19 NCIRD Test Message Review.xlsx                  */
 /*         MMG for auto.xlsx                                        */
 /*         DataDictionary_tf_11065-to extract.xlsx                  */
 /*         Repeating Model Look Ups.xlsx                            */
 /* OUTPUT: DataDictionary_tf_11065-extracted.xlsx		             */
 /*  	    Manual Toggling Report   			                     */
 /*                                                                  */ 
 /* Date Modified: 2020/11/10                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: Automate toggling non-repeating data elements           */
 /*                                                                  */ 
 /* Date Modified: 2020/11/12                                        */
 /* Modified by: Ying Shen                                           */  
 /* Changes: Automate toggling Model1 data elements                  */
 /*                                                                  */
 /* Date Modified: 2020/11/23                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: changed to use DE_Identifier to match different tables  */
 /*	         instead of DE_Name. Remove "N/A:".                    */
 /*                                                                  */
 /* Date Modified: 2020/12/07                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: Add back the Data Elements or Variables with values of  */
 /*          <blank>,null,Not Reported                               */
 /*                                                                  */
 /* Date Modified: 2021/9/10                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Added INV949 -WGS_ID                                    */
 /*                                                                  */
 /* Date Modified: 2021/9/27                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Changed M3G as we use T3 vertical table to compare      */
 /*                                                                  */
 /* Date Modified: 2022/1/19                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Rename testMsgRev to testMsgRev_auto so that the name   */
 /*          can be different from the remove_equal_sign program     */
 /*                                                                  */
 /* Date Modified: 2022/2/8                                          */
 /* Modified by: Ying Shen                                           */
 /* Changes: 1. Keep the original order for M1G and M1.5G by adding  */
 /*             data testMsgRev_clean;                               */
 /*              set testMsgRev_clean;                               */
 /*              order=_n_;                                          */
 /*             run;                                                 */
 /*          2. in proc sql, added order by order;                   */
 /*                                                                  */
 /* Date Modified: 2022/7/21                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Added WGS_id INV949 to M3G for TM4 and TM1              */
 /*                                                                  */
 /* Date Modified: 2022/8/15                                         */
 /* Modified by: Ying Shen                                           */
 /* 1. This update is triggered by immunosuppressive_conditio was    */
 /*    truncated in the Var_Name for M2G                             */
 /*    I updated the length(32) of columns before the append         */
 /* 2. Updated the manual report titles. Corrected typos             */
 /*                                                                  */
 /* 3. Added Data_Element__DE__Name to all M2Gs: expo1-5, expo_var_2G,*/
 /*    clinical_find1-5, clinical_find_var_2G,symptoms1-5,            */
 /*    symptoms_var_2G,risk_factor1-5,risk_factor_var_2G              */
 /*                                                                  */
 /* Date Modified: 2022/10/21                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: Updated the M2G and M2F manual review report            */
 /*          by adding the DE identifier                             */
 /********************************************************************/

/*The directory of the test message*/
%let testdir =\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\Test Message Review\COVID Automation;

/*The name of test message form*/
%let test_message_form = WI TM;

/* Import data dictionary into sas */
proc import datafile="&testdir\DataDictionary_tf_11065.xlsx"
	DBMS=EXCEL out=dataDict replace;
	range = "stage4dict_tf_11065$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/* Import MMG Auto into sas: COVID19 */
proc import datafile="&testdir\MMG for auto.xlsx"
	DBMS=EXCEL out=mmgAuto replace;
	range = "COVID19$";
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
	range = "NCIRD Review$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

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
	on lowcase(a.Var_Name) = lowcase(b.Var_Name);
quit;


/*Non-Repeating Variables starts*/

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
/*Model 1G and 1GDT starts*/
/********************************************************************/

/*Fetch the M1G model variables, merge with MMG auto*/
proc sql;
	create table M1G_element1 as
	select * 
	,monotonic() as row
	from testMsgRev_clean  as a
	left join mmgAuto_clean as b
	on a.DE_Identifier_Sent_in_HL7_Messag = b.DE_Identifier
	where a.DE_Identifier_Sent_in_HL7_Messag in(
/*	M1G*/
'77984-3','77984-3','77985-0','77986-8','77987-6',
'85658-3','85659-1','85078-4','85657-5','55753-8','INV1313','67453-1',
/*M1.5GDT*/
'82764-2','82754-3','82752-7','TRAVEL08','30956-7','30952-6','30973-2','30957-5',
'30959-1','VAC109','VAC153','VAC102','VAC147'
)
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
title justify=l"The following M1G M1.5GDT Var_Names need manual toggling(toggle additional flag):";
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
/*M2_COVIDExposure_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_COVIDExposure_Q replace;
	range = "M2_COVIDExposure_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*The following code is to change the length of Var_name to 32*/
data M2_COVIDExposure_Q;
	length Var_Name $32.;
	set M2_COVIDExposure_Q;
run;

/*Exposure: Test_Record_1*/
proc sql;
	create table expo1 as 
	select Test_Record_1 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Exposure';
quit;
/*Exposure: Test_Record_4*/
proc sql;
	create table expo4 as 
	select Test_Record_4 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Exposure';
quit;
/*Exposure: Test_Record_5*/
proc sql;
	create table expo5 as 
	select Test_Record_5 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Exposure';
quit;

/*Append vars*/
proc append base=expo1 data=expo4 Force;
run;
proc append base=expo1 data=expo5 Force;
run;

/*Get the Var_Name*/
proc sql;
create table expo_var_2G as
select distinct a.test_record
,a.Data_Element__DE__Name
,b.Var_Name
from expo1 as a
left join M2_COVIDExposure_Q as b
on a.test_record=b.OBX_5
where a.test_record is not null;
quit;

/*M2_ClinicalFinding_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_ClinicalFinding_Q replace;
	range = "M2_ClinicalFinding_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*The following code is to change the length of Var_name to 32*/
data M2_ClinicalFinding_Q;
	length Var_Name $32.;
	set M2_ClinicalFinding_Q;
run;

/*ClinicalFinding: Test_Record_1*/
proc sql;
	create table clinical_find1 as 
	select Test_Record_1 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Clinical Finding';
quit;
/*ClinicalFinding: Test_Record_4*/
proc sql;
	create table clinical_find4 as 
	select Test_Record_4 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Clinical Finding';
quit;
/*ClinicalFinding: Test_Record_5*/
proc sql;
	create table clinical_find5 as 
	select Test_Record_5 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Clinical Finding';
quit;

/*Append vars*/
proc append base=clinical_find1 data=clinical_find4 Force;
run;
proc append base=clinical_find1 data=clinical_find5 Force;
run;

/*Get the Var_Name*/
proc sql;
create table clinical_find_var_2G as
select distinct a.test_record
,a.Data_Element__DE__Name
,b.Var_Name
from clinical_find1 as a
left join M2_ClinicalFinding_Q as b
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

/*The following code is to change the length of Var_name to 32*/
data M2_Symptoms_Q;
	length Var_Name $32.;
	set M2_Symptoms_Q;
run;


/*Symptoms: Test_Record_1*/
proc sql;
	create table symptoms1 as 
	select Test_Record_1 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_4*/
proc sql;
	create table symptoms4 as 
	select Test_Record_4 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;
/*Symptoms: Test_Record_5*/
proc sql;
	create table symptoms5 as 
	select Test_Record_5 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name ='Signs and Symptoms';
quit;

/*Append vars*/
proc append base=symptoms1 data=symptoms4 Force;
run;
proc append base=symptoms1 data=symptoms5 Force;
run;

/*Get the Var_Name*/
proc sql;
create table symptoms_var_2G as
select distinct a.test_record
,a.Data_Element__DE__Name
,b.Var_Name
from symptoms1 as a
left join M2_Symptoms_Q as b
on a.test_record=b.OBX_5
where a.test_record is not null;
quit;

/*M2_RiskFactors_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_RiskFactors_Q replace;
	range = "M2_RiskFactors_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*The following code is to change the length of Var_name to 32*/
data M2_RiskFactors_Q;
	length Var_Name $32.;
	set M2_RiskFactors_Q;
run;

/*RiskFactors: Test_Record_1*/
proc sql;
	create table risk_factor1 as 
	select Test_Record_1 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name like 'Patient Epidemiological Risk%';
quit;
/*RiskFactors: Test_Record_4*/
proc sql;
	create table risk_factor4 as 
	select Test_Record_4 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name like 'Patient Epidemiological Risk%';
quit;
/*RiskFactors: Test_Record_5*/
proc sql;
	create table risk_factor5 as 
	select Test_Record_5 as test_record
	,Data_Element__DE__Name
	from testMsgRev_clean
	where Data_Element__DE__Name like 'Patient Epidemiological Risk%';
quit;

/*Append vars*/
proc append base=risk_factor1 data=risk_factor4 Force;
run;
proc append base=risk_factor1 data=risk_factor5 Force;
run;

/*Get the Var_Name*/
proc sql;
	create table risk_factor_var_2G as
	select distinct a.test_record
	,a.Data_Element__DE__Name
	,b.Var_Name
	from risk_factor1 as a
	left join M2_RiskFactors_Q as b
	on a.test_record=b.OBX_5
	where a.test_record not in ('Y','N')
	and a.test_record is not null ;
quit;


/*Append vars from Exposure,ClinicalFinding,RiskFactors and Symptoms */
proc append base=expo_var_2G data=clinical_find_var_2G FORCE;
run;
proc append base=expo_var_2G data=symptoms_var_2G FORCE;
run;
proc append base=expo_var_2G data=risk_factor_var_2G FORCE;
run;

/*Add a new variable called Extract*/
proc sql;
	alter table expo_var_2G
	add Extract_M2G char(1);
quit;

/*Update Extract by adding flag 1*/
proc sql;
	update expo_var_2G
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
	left join expo_var_2G as b
	on a.Var_Name = lowcase(b.Var_Name);
quit;

/*Number of variables manual toggling*/
proc sql;
title justify=l"The following M2G Var_Names need manual toggling/review:";
	select 
	a.Data_Element__DE__Name
	,a.Var_Name as Var_Name_based_on_tcsw
	,a.test_record as test_record_need_manual_review
	,tcsw.Test_Record_1
	,tcsw.Test_Record_4
	,tcsw.Test_Record_5
	from expo_var_2G a
/*	left join DataDictionary_extracted3 b*/
/*	on a.Var_Name= b.Var_Name*/
	left join testMsgRev_clean as tcsw
	on a.Data_Element__DE__Name = tcsw.Data_Element__DE__Name and (a.test_record=tcsw.Test_Record_1 or a.test_record=tcsw.Test_Record_4 or a.test_record=tcsw.Test_Record_5)
	where lowcase(a.Var_Name) not in 
	(select Var_Name
	from DataDictionary_extracted3)
	and a.Var_Name is not null
	or (a.test_record is not null and a.test_record not in ('<blank>','N/A','Y=Yes','N=No','UNK=Unknown') and a.Var_Name is null);
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
	,a.Test_Record_1
	,a.Test_Record_4 as Test_Record_4
	,a.Test_Record_5 as Test_Record_5
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
	,Test_Record_1 as test_record
	from data_1F;

create table data_1F_record4 as
	select Data_Element__DE__Name
	,Test_Record_4 as test_record
	from data_1F;
	
create table data_1F_record5 as
	select Data_Element__DE__Name
	,Test_Record_5 as test_record
	from data_1F;
quit;

/*Append vars*/
proc append base=data_1F_record1 data=data_1F_record4 FORCE;
run;
proc append base=data_1F_record1 data=data_1F_record5 FORCE;
run;

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
title justify=l"The following M1F Var_Names need manual toggling:";
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
	,a.Test_Record_1
	,a.Test_Record_4 as Test_Record_4
	,a.Test_Record_5 as Test_Record_5
	,b.Repeat_Prefix
	,b.Method
	from testMsgRev_clean as a
	left join mmgAuto_clean as b
	on a.DE_Identifier_Sent_in_HL7_Messag =b.DE_Identifier
	where a.DE_Identifier_Sent_in_HL7_Messag in('77988-4','INV603')
	or a.DE_Identifier_Sent_in_HL7_Messag like '%PID_10%';
quit;

/*Test Record from horizontal to vertical*/
proc sql;
create table data_2F_record1 as
	select Data_Element__DE__Name
	,Test_Record_1 as test_record
	from data_2F;

create table data_2F_record4 as
	select Data_Element__DE__Name
	,Test_Record_4 as test_record
	from data_2F;
	
create table data_2F_record5 as
	select Data_Element__DE__Name
	,Test_Record_5 as test_record
	from data_2F;
quit;

/*Append vars*/
proc append base=data_2F_record1 data=data_2F_record4 FORCE;
run;
proc append base=data_2F_record1 data=data_2F_record5 FORCE;
run;

/*Import reapeating group lookup M2_ContactType_Q*/
proc import datafile="&testdir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=M2_ContactType_Q replace;
	range = "M2_ContactType_Q$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

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
	select distinct a.Data_Element__DE__Name
	,a.test_record
	,b.Var_Name
	,'1' as Extract_2F
	from data_2F_record1 as a
	left join M2_ContactType_Q as b
	on a.test_record=b.OBX_5
	where a.Data_Element__DE__Name ='Contact Type'
	and a.test_record not in ('<blank>')
	union 
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
title justify=l"The following M2F Var_Names need manual toggling:";
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
/*M3G Test Record5 start*/
/*Get the data from testMsgRev_clean*/
proc sql;
create table data_m3g_record5 as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_5
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
	/*	wgs_id 'INV949'*/
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2','INV291','LAB628','INV949'
,'LAB115','68963-8','LAB202','82771-7','INV949');
quit;

/*Blue line: get the DE and test record*/
proc sql;
create table data_m3g_record5_q1q2 as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_5
	,monotonic() as row
	from data_m3g_record5
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2');

	create table num_test_type as
	select Data_Element__DE__Name
	,count(*) as num_var
	from data_m3g_record5_q1q2
	group by Data_Element__DE__Name;
	
	create table data_m3g_record5_q1q2_2 as
	select a.Data_Element__DE__Name
	,a.Test_Record_5
	,b.num_var
	,a.row
	from data_m3g_record5_q1q2 as a
	left join num_test_type as b
	on a.Data_Element__DE__Name=b.Data_Element__DE__Name;
quit;

proc sort data=data_m3g_record5_q1q2_2;
	by Data_Element__DE__Name row;
run;

data data_m3g_record5_q1q2_3; 	
	set data_m3g_record5_q1q2_2;
	by Data_Element__DE__Name;
	if first.Data_Element__DE__Name then Orig_instance=1;
	else Orig_instance+1;
run;

proc sort data=data_m3g_record5_q1q2_3;
by Orig_instance;
run;

proc transpose data=data_m3g_record5_q1q2_3 
				out=data_m3g_record5_q1q2_tr;
		id Data_Element__DE__Name;
		by Orig_instance;
		var Test_Record_5;
run;

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


proc sql;
/*Get the value of the test type and specimen source and the combo_var*/
create table data_m3g_record5_q1q2_combo as
	select a.Orig_instance
	,a.Test_Type
	,a.Specimen_Source
	,b.Var_Name as test_type_var_name
	,c.Var_Name as specimen_var_name
	,cats(b.Var_Name,"_",c.Var_Name) as combo_var
	from data_m3g_record5_q1q2_tr as a
	left join M3_LabTestType_Q1 as b
	on a.Test_Type=b.Code
	left join M3_SpecimenType_Q2 as c
	on a.Specimen_Source=c.code;

/*Get the max num of combo_var*/
	create table max_instance as
	select combo_var
	,count(combo_var) as max_instance
	from data_m3g_record5_q1q2_combo
	group by combo_var;
	
/*Combine 2 tables above*/
	create table data_m3g_record5_q1q2_combo_max as
	select *
	from data_m3g_record5_q1q2_combo as a
	left join max_instance as b
	on a.combo_var=b.combo_var;
quit;


/*Get the number of Var_instance*/
data  data_m3g_record5_q1q2_combo_inst;
	set  data_m3g_record5_q1q2_combo_max;
	do var_instance =1 to max_instance;
	output;
	end;
run;


/*orange arrow: on the right hand side of the logic doc*/
/*get data*/
proc sql;
create table data_m3g_record5_result as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_5
	from data_m3g_record5
	where DE_Identifier_Sent_in_HL7_Messag in ('INV291','LAB628','LAB115','68963-8','LAB202','82771-7','INV949');
quit;

proc sort data =data_m3g_record5_result;
	by DE_Identifier_Sent_in_HL7_Messag;
run;

/*Get the Orig_instance*/
data data_m3g_record5_result_2;
	set data_m3g_record5_result;
	by DE_Identifier_Sent_in_HL7_Messag;
	if first.DE_Identifier_Sent_in_HL7_Messag then Orig_instance=1;
	else Orig_instance+1;
run;

/*Combine Blue line and Orange Line. Combine Q1Q2 and other DE*/
proc sql;
	create table data_m3g_record5_all as
	select a.*
	,b.*
	,c.Repeat_Postfix
	,cats(a.combo_var,c.Repeat_Postfix,"_",a.var_instance) as Var_Name_m3g
	from data_m3g_record5_q1q2_combo_inst as a
	left join data_m3g_record5_result_2 as b
	on a.Orig_instance=b.Orig_instance
	left join mmgAuto_clean as c
	on b.DE_Identifier_Sent_in_HL7_Messag=c.DE_Identifier;
quit;

/*M3G Test Record5 End*/


/*M3G Test Record4 Start*/
/*Get the data from testMsgRev_clean*/
proc sql;
create table data_m3g_record4 as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_4
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
	/*	wgs_id 'INV949'*/
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2','INV291','LAB628','INV949'
,'LAB115','68963-8','LAB202','82771-7');
quit;

/*Blue line: get the DE and test record*/
proc sql;
create table data_m3g_record4_q1q2 as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_4
	,monotonic() as row
	from data_m3g_record4
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2');

	create table num_test_type4 as
	select Data_Element__DE__Name
	,count(*) as num_var
	from data_m3g_record4_q1q2
	group by Data_Element__DE__Name;

	create table data_m3g_record4_q1q2_2 as
	select a.Data_Element__DE__Name
	,a.Test_Record_4
	,a.row
	from data_m3g_record4_q1q2 as a
	left join num_test_type4 as b
	on a.Data_Element__DE__Name=b.Data_Element__DE__Name;
quit;

proc sort data=data_m3g_record4_q1q2_2;
	by Data_Element__DE__Name row;
run;

data data_m3g_record4_q1q2_3; 	
	set data_m3g_record4_q1q2_2;
	by Data_Element__DE__Name;
	if first.Data_Element__DE__Name then Orig_instance=1;
	else Orig_instance+1;
run;

proc sort data=data_m3g_record4_q1q2_3;
by Orig_instance;
run;

proc transpose data=data_m3g_record4_q1q2_3 
				out=data_m3g_record4_q1q2_tr;
		id Data_Element__DE__Name;
		by Orig_instance;
		var Test_Record_4;
run;

proc sql;
/*Get the value of the test type and specimen source and the combo_var*/
create table data_m3g_record4_q1q2_combo as
	select a.Orig_instance
	,a.Test_Type
	,a.Specimen_Source
	,b.Var_Name as test_type_var_name
	,c.Var_Name as specimen_var_name
	,cats(b.Var_Name,"_",c.Var_Name) as combo_var
	from data_m3g_record4_q1q2_tr as a
	left join M3_LabTestType_Q1 as b
	on a.Test_Type=b.Code
	left join M3_SpecimenType_Q2 as c
	on a.Specimen_Source=c.code;

/*Get the max num of combo_var*/
	create table max_instance4 as
	select combo_var
	,count(combo_var) as max_instance
	from data_m3g_record4_q1q2_combo
	group by combo_var;
	
/*Combine 2 tables above*/
	create table data_m3g_record4_q1q2_combo_max as
	select *
	from data_m3g_record4_q1q2_combo as a
	left join max_instance4 as b
	on a.combo_var=b.combo_var;
quit;


/*Get the number of Var_instance*/
data  data_m3g_record4_q1q2_combo_inst;
	set  data_m3g_record4_q1q2_combo_max;
	do var_instance =1 to max_instance;
	output;
	end;
run;


/*orange arrow: on the right hand side of the logic doc*/
/*get data*/
proc sql;
create table data_m3g_record4_result as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_4
	from data_m3g_record4
	where DE_Identifier_Sent_in_HL7_Messag in ('INV291','LAB628','LAB115','68963-8','LAB202','82771-7','INV949');
quit;

proc sort data =data_m3g_record4_result;
	by DE_Identifier_Sent_in_HL7_Messag;
run;

/*Get the Orig_instance*/
data data_m3g_record4_result_2;
	set data_m3g_record4_result;
	by DE_Identifier_Sent_in_HL7_Messag;
	if first.DE_Identifier_Sent_in_HL7_Messag then Orig_instance=1;
	else Orig_instance+1;
run;

/*Combine Blue line and Orange Line. Combine Q1Q2 and other DE*/
proc sql;
create table data_m3g_record4_all as
	select a.*
	,b.*
	,c.Repeat_Postfix
	,cats(a.combo_var,c.Repeat_Postfix,"_",a.var_instance) as Var_Name_m3g
	from data_m3g_record4_q1q2_combo_inst as a
	left join data_m3g_record4_result_2 as b
	on a.Orig_instance=b.Orig_instance
	left join mmgAuto_clean as c
	on b.DE_Identifier_Sent_in_HL7_Messag=c.DE_Identifier
	where a.Test_Type not in('<blank>');
quit;
/*M3G Test Record4 End*/


/*M3G Test Record1 Start*/
/*Get the data from testMsgRev_clean*/
proc sql;
create table data_m3g_record1 as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_1
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
/*	wgs_id 'INV949'*/
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2','INV291','LAB628','INV949'
,'LAB115','68963-8','LAB202','82771-7');
quit;

/*Blue line: get the DE and test record*/
proc sql;
create table data_m3g_record1_q1q2 as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_1
	,monotonic() as row
	from data_m3g_record1
	where DE_Identifier_Sent_in_HL7_Messag in ('INV290','31208-2');

	create table num_test_type1 as
	select Data_Element__DE__Name
	,count(*) as num_var
	from data_m3g_record1_q1q2
	group by Data_Element__DE__Name;
	

	create table data_m3g_record1_q1q2_2 as
	select a.Data_Element__DE__Name
	,a.Test_Record_1
	,b.num_var
	,a.row
	from data_m3g_record1_q1q2 as a
	left join num_test_type1 as b
	on a.Data_Element__DE__Name=b.Data_Element__DE__Name;
quit;

proc sort data=data_m3g_record1_q1q2_2;
	by Data_Element__DE__Name row;
run;

data data_m3g_record1_q1q2_3; 	
	set data_m3g_record1_q1q2_2;
	by Data_Element__DE__Name;
	if first.Data_Element__DE__Name then Orig_instance=1;
	else Orig_instance+1;
run;

proc sort data=data_m3g_record1_q1q2_3;
by Orig_instance;
run;

proc transpose data=data_m3g_record1_q1q2_3 
				out=data_m3g_record1_q1q2_tr;
		id Data_Element__DE__Name;
		by Orig_instance;
		var Test_Record_1;
run;

proc sql;
/*Get the value of the test type and specimen source and the combo_var*/
create table data_m3g_record1_q1q2_combo as
	select a.Orig_instance
	,a.Test_Type
	,a.Specimen_Source
	,b.Var_Name as test_type_var_name
	,c.Var_Name as specimen_var_name
	,cats(b.Var_Name,"_",c.Var_Name) as combo_var
	from data_m3g_record1_q1q2_tr as a
	left join M3_LabTestType_Q1 as b
	on a.Test_Type=b.Code
	left join M3_SpecimenType_Q2 as c
	on a.Specimen_Source=c.code;

/*Get the max num of combo_var*/
	create table max_instance1 as
	select combo_var
	,count(combo_var) as max_instance
	from data_m3g_record1_q1q2_combo
	group by combo_var;
	
/*Combine 2 tables above*/
	create table data_m3g_record1_q1q2_combo_max as
	select *
	from data_m3g_record1_q1q2_combo as a
	left join max_instance1 as b
	on a.combo_var=b.combo_var;
quit;


/*Get the number of Var_instance*/
data  data_m3g_record1_q1q2_combo_inst;
	set  data_m3g_record1_q1q2_combo_max;
	do var_instance =1 to max_instance;
	output;
	end;
run;


/*orange arrow: on the right hand side of the logic doc*/
/*get data*/
proc sql;
create table data_m3g_record1_result as
	select DE_Identifier_Sent_in_HL7_Messag
	,Data_Element__DE__Name
	,Test_Record_1
	from data_m3g_record1
	where DE_Identifier_Sent_in_HL7_Messag in ('INV291','LAB628','LAB115','68963-8','LAB202','82771-7','INV949');
quit;

proc sort data =data_m3g_record1_result;
	by DE_Identifier_Sent_in_HL7_Messag;
run;

/*Get the Orig_instance*/
data data_m3g_record1_result_2;
	set data_m3g_record1_result;
	by DE_Identifier_Sent_in_HL7_Messag;
	if first.DE_Identifier_Sent_in_HL7_Messag then Orig_instance=1;
	else Orig_instance+1;
run;

/*Combine Blue line and Orange Line. Combine Q1Q2 and other DE*/
proc sql;
create table data_m3g_record1_all as
	select a.*
	,b.*
	,c.Repeat_Postfix
	,cats(a.combo_var,c.Repeat_Postfix,"_",a.var_instance) as Var_Name_m3g
	from data_m3g_record1_q1q2_combo_inst as a
	left join data_m3g_record1_result_2 as b
	on a.Orig_instance=b.Orig_instance
	left join mmgAuto_clean as c
	on b.DE_Identifier_Sent_in_HL7_Messag=c.DE_Identifier
	where a.Test_Type not in('<blank>');
quit;
/*M3G Test Record1 End*/

/*Get the var name*/
/*proc sql;*/
/*	create table data3G_var as*/
/*	select distinct Var_Name_m3g*/
/*	,DE_Identifier_Sent_in_HL7_Messag*/
/*	,Data_Element__DE__Name*/
/*	,'1' as Extract_3G*/
/*	from data_m3g_record5_all*/
/*	union */
/*	select distinct Var_Name_m3g*/
/*	,DE_Identifier_Sent_in_HL7_Messag*/
/*	,Data_Element__DE__Name*/
/*	,'1' as Extract_3G*/
/*	from data_m3g_record4_all*/
/*	union*/
/*	select distinct Var_Name_m3g*/
/*	,DE_Identifier_Sent_in_HL7_Messag*/
/*	,Data_Element__DE__Name*/
/*	,'1' as Extract_3G*/
/*	from data_m3g_record1_all;*/
/*quit;*/

/*Add the variables to the dictionary */
/*proc sql;*/
/*	create table DataDictionary_extracted3G as*/
/*	select a.tablename*/
/*	,a.Var_Name	*/
/*	,a.sastype*/
/*	,a.sqltype	*/
/*	,a.justlength	*/
/*	,a.DE_Identifier	*/
/*	,a.DE_Description	*/
/*	,a.value_set_content	*/
/*	,a.value_set_de_identifier	*/
/*	,a.netssforward*/
/*	,Case */
/*	when a.Extract ='1' then '1'*/
/*	when b.Extract_3G ='1' then '1'*/
/*	when (a.Extract ='1' and b.Extract_3G ='1') then '1'*/
/*	end as Extract*/
/*	,a.Extract_M1G*/
/*	,a.Extract_M2G*/
/*	,a.Extract_1F*/
/*	,a.Extract_2F*/
/*	,b.Extract_3G*/
/*	from DataDictionary_extracted2F as a*/
/*	left join data3G_var as b*/
/*	on lowcase(a.Var_Name) = lowcase(b.Var_Name_m3g);*/
/*quit;*/

/*Number of variables manual toggling*/
/*proc sql;*/
/*title justify=l"The following M3G Var Name need review(these variables should not be in priority combo):";*/
/*	select a.DE_Identifier_Sent_in_HL7_Messag*/
/*	,a.Data_Element__DE__Name*/
/*	,a.Var_Name_m3g*/
/*	from data3G_var a*/
/*	where lowcase(a.Var_Name_m3g) not in */
/*	(select Var_Name*/
/*	from DataDictionary_extracted3G)*/
/*	and Var_Name_m3g is not null;*/
/*quit;*/


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
	,Test_Record_1
	,Test_Record_4 as Test_Record_4
	,Test_Record_5 as Test_Record_5
	from extract_non_repeat
	where Var_Name in ('local_record_id');
quit;

