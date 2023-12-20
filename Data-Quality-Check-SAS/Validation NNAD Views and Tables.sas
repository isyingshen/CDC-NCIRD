 /********************************************************************/
 /* PROGRAM NAME: Validation NNAD Views                              */
 /* VERSION: 1.0                                                     */
 /* CREATED: 02NOV2022                                               */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to validate the view variables by      */
 /*           comparing t1 to t8 table variables to the              */
 /*           corresponding view variables;                          */
 /*           The comparison is comprehensive and bi-directional     */ 
 /*           The comparison is for COVID views only                 */ 
 /********************************************************************/
          

/*Connect to NNAD DB*/
%let PROD = DSPV-VPDN-1601,59308\qsrv1;
%let STAGING = dssv-infc-1601,53831\qsrv1;
%let TEST = DSTV-INFC-1601\QSRV1;
%let DEV = DSDV-INFC-1601\QSRV1;
%let datascr = &PROD;


libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="&datascr"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;


/*Directory of the data dictionary*/
%let dictdir =\\cdc.gov\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\NMI\Dev\Outputs;

/*Import data dictionary into sas */
proc import datafile="&dictdir\DataDictionary_eachcond.xlsx"
	DBMS=EXCEL out=stage4dict replace;
	range = "Stage4MasterVars$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*proc contents data=stage4dict;*/
/*run;*/

/*Get all COVID variables*/
proc sql;
create table covidVar as
select Var_Name from stage4dict
where COVID19='1';
quit;

%macro validateView(tablename, viewname); 

/*Get table variables*/
proc sql;
create table table1 as
select * 
from NNAD.&tablename(obs=1);
quit;

/*Transpose table variables*/
proc contents data=table1 out=table_trans (keep=name) noprint;
run;

/*Get view variables*/
proc sql;
create table view1 as
select * 
from NNAD.&viewname(obs=1);
quit;

/*Transpose view variables*/
proc contents data=view1 out=view_trans (keep=name) noprint;
run;

/*Get the report*/
proc sql;
title "Variables in &tablename but NOT in &viewname";
title2 "data source=&datascr";
select * from table_trans
where name not in 
(select name from view_trans)
and name in
(select * from covidVar);

title "Variables in &viewname but NOT in &tablename";
title2 "data source=&datascr";
select * from view_trans
where name not in 
(select name from table_trans);
quit;

%mend validateView;

%validateView(Stage4_NNDSScasesT1,COVID19_NNDSSCasesT1_vw);
%validateView(Stage4_NNDSScasesT2,COVID19_NNDSSCasesT2_vw);
%validateView(Stage4_NNDSScasesT4,COVID19_NNDSSCasesT4_vw);
%validateView(Stage4_NNDSScasesT5,COVID19_NNDSSCasesT5_vw);
%validateView(Stage4_NNDSScasesT7,COVID19_NNDSSCasesT7_vw);
%validateView(Stage4_NNDSScasesT8,COVID19_NNDSSCasesT8_vw);
%validateView(Stage3_NNDSSCasesT3_Vertical,COVID19_NNDSSCasesT3_Vertical_vw);

/*%validateView(Stage4_NNDSScasesT6,COVID19_NNDSSCasesT6_vw);*/
/*table6*/

/*Get table variables*/
proc sql;
create table table6 as
select * 
from NNAD.Stage4_NNDSScasesT6(obs=1);
quit;

/*Transpose table variables*/
proc contents data=table6 out=table6_trans (keep=name) noprint;
run;

/*Get the report*/
proc sql;
title "Variables in Stage4_NNDSScasesT6 but NOT in COVID19_NNDSSCasesT6_vw";
title2 "data source=&datascr";
title3 "Note: there is NO COVID19_NNDSSCasesT6_vw";
select * from table6_trans
where name in
(select * from covidVar)
and name not in ('condition', 
'local_record_id', 
'mmwr_year',
'report_jurisdiction' 
);
quit;




