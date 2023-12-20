 /********************************************************************/
 /* PROGRAM NAME: Validation Data Dictionary                         */
 /* VERSION: 1.0                                                     */
 /* CREATED: 08Feb2021                                               */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to validate the lab variables by       */
 /*           comparing the Data Dictionary variables to the         */
 /*           Repeating Model Lookups                                */
 /*                                                                  */ 
 /********************************************************************/

/*directory of the data dictionary*/
%let dictdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Ying.s\Forms;
%let q1q2ToolDir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Ying.s\Q1_Q2_combo_Priority;
%let output =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Ying.s\Validations;


/*Connect to DB*/
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="dssv-infc-1601,53831\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;

/* Import data dictionary into sas */
proc import datafile="&dictdir\DataDictionary_tf_11065_New_EF.xlsx"
	DBMS=EXCEL out=stage4dict replace;
	range = "stage4dict_tf_11065$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/* Import Q1Q2 Combo Priority Tool into sas */
proc import datafile="&q1q2ToolDir\Q1Q2_Combo_Priority_Tool.xlsx"
	DBMS=EXCEL out=q1q2_combo_priority replace;
	range = "Q1Q2_combo_Priority$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*dd->rmlu: make sure all vars in the Data Dict are prioritized in the Q1Q2 Combo Priority Tool*/
proc sql;
create table stage4dict2 as
	select tablename
	,Var_Name
	/*remove instances 1,2,3...*/
/*	,compress(lower(Var_Name), 'abcdefghijklmnopqrstuvwxyz_', 'kis') as Var_Combo_DD*/
	,prxchange('s/\_\d+//',-1,compress(lower(Var_Name))) as Var_Combo_DD
	/*add ddflag*/
	,"1" as ddflag
	from stage4dict
	where Var_Name not like '%collct_dt%'
	and Var_Name not like '%lab_type%'
	and Var_Name not like '%qnt_rslt%'
	and Var_Name not like '%spec_id%'
	and Var_Name not like '%_unit_%'
	and Var_Name not like '%addtl_flag%'
	and tablename not in ('COVID19_NNDSScasesT1_vw', 'COVID19_NNDSScasesT2_vw','COVID19_NNDSScasesT4_vw',
'COVID19_NNDSScasesT5_vw','COVID19_NNDSScasesT6_vw','COVID19_NNDSScasesT7_vw');

/*Get all the prioritzed combo*/
create table q1q2_combo_priority2 as
	select distinct Var_Combo
	,Var_Combo as Var_Combo_RMLU
	,Combo_Priority
	from q1q2_combo_priority
	where Combo_Priority='Y';
quit;

proc sql;
create table dd_rmlu_valid as
	select a.tablename as Table_Name
	,a.Var_Name
	,b.Var_Combo
	,b.Combo_Priority
	,case
	when a.Var_Name like 'im_%' then "im: miss test type"
	when a.Var_Name like '%_im%' then "im: miss specimen source"
	end as Ying_Comment
	from stage4dict2 as a
	left join q1q2_combo_priority2 as b
	on lower(compress(a.Var_Combo_DD)) = lower (compress(b.Var_Combo_RMLU));
quit;

/*rmlu->dd	make sure all the prioritized Q1Q2 Combos in the RMLUs are found in the Data Dictionary*/
proc sql;
create table rmlu_dd_valid as
	select a.Var_Combo
	,a.Combo_Priority
	,b.tablename as Table_Name
	,b.Var_Name
	,b.ddflag
	from q1q2_combo_priority2 as a
	left join stage4dict2 as b
	on lower(compress(a.Var_Combo_RMLU)) = lower (compress(b.Var_Combo_DD))
	where a.Combo_Priority ='Y';
quit;

/*Export data into excel*/
PROC EXPORT DATA= dd_rmlu_valid
             OUTFILE= "&output\Validation2_Compare_DD_to_RMLU &SYSDATE9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="dd_rmlu_valid";
RUN;

/*Export data into excel*/
PROC EXPORT DATA= rmlu_dd_valid
             OUTFILE= "&output\Validation2_Compare_DD_to_RMLU &SYSDATE9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="rmlu_dd_valid";
RUN;
