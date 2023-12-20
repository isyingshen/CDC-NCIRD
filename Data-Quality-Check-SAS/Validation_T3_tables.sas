 /********************************************************************/
 /* PROGRAM NAME: Validation T3 tables                               */
 /* VERSION: 1.0                                                     */
 /* CREATED: 05Feb2021                                               */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to validate the lab variables by       */
 /*           comparing the t3_9 to t3_46 table variables to the     */
 /*           data dictionary                                        */
 /*                                                                  */ 
 /********************************************************************/

/*directory of the data dictionary*/
%let dictdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Ying.s\Forms;
%let output =\\cdc.gov\project\NIP_Project_Store1\Surveillance\Ying.s\Validations;

/*Connect to DB*/
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="dssv-infc-1601,53831\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;


%macro getT3var(t=t3tablename);
proc sql;
create table &t as
select * from NNAD.COVID19_NNDSSCases&t_vw (obs=1);
quit;

proc transpose data=&t out=&t_trans;
run;

proc print data=&t_trans;
run;

%mend getT3var;

/*t3_9*/
proc sql;
create table t3_9 as
select * from NNAD.COVID19_NNDSSCasest3_9_vw (obs=1);
quit;
proc transpose data=t3_9 out=t3_9_trans;
var _all_;
run;
data t3_9_trans;
	set t3_9_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_9_vw";
run;

/*t3_10*/
proc sql;
create table t3_10 as
select * from NNAD.COVID19_NNDSSCasest3_10_vw (obs=1);
quit;
proc transpose data=t3_10 out=t3_10_trans;
var _all_;
run;
data t3_10_trans;
	set t3_10_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_10_vw";
run;

/*t3_11*/
proc sql;
create table t3_11 as
select * from NNAD.COVID19_NNDSSCasest3_11_vw (obs=1);
quit;
proc transpose data=t3_11 out=t3_11_trans;
var _all_;
run;
data t3_11_trans;
	set t3_11_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_11_vw";
run;


/*t3_12*/
proc sql;
create table t3_12 as
select * from NNAD.COVID19_NNDSSCasest3_12_vw (obs=1);
quit;
proc transpose data=t3_12 out=t3_12_trans;
var _all_;
run;
data t3_12_trans;
	set t3_12_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_12_vw";
run;


/*t3_14*/
proc sql;
create table t3_14 as
select * from NNAD.COVID19_NNDSSCasest3_14_vw (obs=1);
quit;
proc transpose data=t3_14 out=t3_14_trans;
var _all_;
run;
data t3_14_trans;
	set t3_14_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_14_vw";
run;

/*t3_15*/
proc sql;
create table t3_15 as
select * from NNAD.COVID19_NNDSSCasest3_15_vw (obs=1);
quit;
proc transpose data=t3_15 out=t3_15_trans;
var _all_;
run;
data t3_15_trans;
	set t3_15_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_15_vw";
run;

/*t3_16*/
proc sql;
create table t3_16 as
select * from NNAD.COVID19_NNDSSCasest3_16_vw (obs=1);
quit;
proc transpose data=t3_16 out=t3_16_trans;
var _all_;
run;
data t3_16_trans;
	set t3_16_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_16_vw";
run;

/*t3_17*/
proc sql;
create table t3_17 as
select * from NNAD.COVID19_NNDSSCasest3_17_vw (obs=1);
quit;
proc transpose data=t3_17 out=t3_17_trans;
var _all_;
run;
data t3_17_trans;
	set t3_17_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_17_vw";
run;

/*t3_18*/
proc sql;
create table t3_18 as
select * from NNAD.COVID19_NNDSSCasest3_18_vw (obs=1);
quit;
proc transpose data=t3_18 out=t3_18_trans;
var _all_;
run;
data t3_18_trans;
	set t3_18_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_18_vw";
run;


/*t3_19*/
proc sql;
create table t3_19 as
select * from NNAD.COVID19_NNDSSCasest3_19_vw (obs=1);
quit;
proc transpose data=t3_19 out=t3_19_trans;
var _all_;
run;
data t3_19_trans;
	set t3_19_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_19_vw";
run;


/*t3_20*/
proc sql;
create table t3_20 as
select * from NNAD.COVID19_NNDSSCasest3_20_vw (obs=1);
quit;
proc transpose data=t3_20 out=t3_20_trans;
var _all_;
run;
data t3_20_trans;
	set t3_20_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_20_vw";
run;

/*t3_21*/
proc sql;
create table t3_21 as
select * from NNAD.COVID19_NNDSSCasest3_21_vw (obs=1);
quit;
proc transpose data=t3_21 out=t3_21_trans;
var _all_;
run;
data t3_21_trans;
	set t3_21_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_21_vw";
run;


/*t3_22*/
proc sql;
create table t3_22 as
select * from NNAD.COVID19_NNDSSCasest3_22_vw (obs=1);
quit;
proc transpose data=t3_22 out=t3_22_trans;
var _all_;
run;
data t3_22_trans;
	set t3_22_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_22_vw";
run;


/*t3_25*/
proc sql;
create table t3_25 as
select * from NNAD.COVID19_NNDSSCasest3_25_vw (obs=1);
quit;
proc transpose data=t3_25 out=t3_25_trans;
var _all_;
run;
data t3_25_trans;
	set t3_25_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_25_vw";
run;



/*t3_26*/
proc sql;
create table t3_26 as
select * from NNAD.COVID19_NNDSSCasest3_26_vw (obs=1);
quit;
proc transpose data=t3_26 out=t3_26_trans;
var _all_;
run;
data t3_26_trans;
	set t3_26_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_26_vw";
run;


/*t3_27*/
proc sql;
create table t3_27 as
select * from NNAD.COVID19_NNDSSCasest3_27_vw (obs=1);
quit;
proc transpose data=t3_27 out=t3_27_trans;
var _all_;
run;
data t3_27_trans;
	set t3_27_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_27_vw";
run;

/*t3_28*/
proc sql;
create table t3_28 as
select * from NNAD.COVID19_NNDSSCasest3_28_vw (obs=1);
quit;
proc transpose data=t3_28 out=t3_28_trans;
var _all_;
run;
data t3_28_trans;
	set t3_28_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_28_vw";
run;

/*t3_29*/
proc sql;
create table t3_29 as
select * from NNAD.COVID19_NNDSSCasest3_29_vw (obs=1);
quit;
proc transpose data=t3_29 out=t3_29_trans;
var _all_;
run;
data t3_29_trans;
	set t3_29_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_29_vw";
run;

/*t3_30*/
proc sql;
create table t3_30 as
select * from NNAD.COVID19_NNDSSCasest3_30_vw (obs=1);
quit;
proc transpose data=t3_30 out=t3_30_trans;
var _all_;
run;
data t3_30_trans;
	set t3_30_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_30_vw";
run;

/*t3_31*/
proc sql;
create table t3_31 as
select * from NNAD.COVID19_NNDSSCasest3_31_vw (obs=1);
quit;
proc transpose data=t3_31 out=t3_31_trans;
var _all_;
run;
data t3_31_trans;
	set t3_31_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_31_vw";
run;

/*t3_32*/
proc sql;
create table t3_32 as
select * from NNAD.COVID19_NNDSSCasest3_32_vw (obs=1);
quit;
proc transpose data=t3_32 out=t3_32_trans;
var _all_;
run;
data t3_32_trans;
	set t3_32_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_32_vw";
run;

/*t3_37*/
proc sql;
create table t3_37 as
select * from NNAD.COVID19_NNDSSCasest3_37_vw (obs=1);
quit;
proc transpose data=t3_37 out=t3_37_trans;
var _all_;
run;
data t3_37_trans;
	set t3_37_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_37_vw";
run;

/*t3_38*/
proc sql;
create table t3_38 as
select * from NNAD.COVID19_NNDSSCasest3_38_vw (obs=1);
quit;
proc transpose data=t3_38 out=t3_38_trans;
var _all_;
run;
data t3_38_trans;
	set t3_38_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_38_vw";
run;


/*t3_39*/
proc sql;
create table t3_39 as
select * from NNAD.COVID19_NNDSSCasest3_39_vw (obs=1);
quit;
proc transpose data=t3_39 out=t3_39_trans;
var _all_;
run;
data t3_39_trans;
	set t3_39_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_39_vw";
run;

/*t3_40*/
proc sql;
create table t3_40 as
select * from NNAD.COVID19_NNDSSCasest3_40_vw (obs=1);
quit;
proc transpose data=t3_40 out=t3_40_trans;
var _all_;
run;
data t3_40_trans;
	set t3_40_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_40_vw";
run;

/*t3_41*/
proc sql;
create table t3_41 as
select * from NNAD.COVID19_NNDSSCasest3_41_vw (obs=1);
quit;
proc transpose data=t3_41 out=t3_41_trans;
var _all_;
run;
data t3_41_trans;
	set t3_41_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_41_vw";
run;

/*t3_42*/
proc sql;
create table t3_42 as
select * from NNAD.COVID19_NNDSSCasest3_42_vw (obs=1);
quit;
proc transpose data=t3_42 out=t3_42_trans;
var _all_;
run;
data t3_42_trans;
	set t3_42_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_42_vw";
run;

/*t3_43*/
proc sql;
create table t3_43 as
select * from NNAD.COVID19_NNDSSCasest3_43_vw (obs=1);
quit;
proc transpose data=t3_43 out=t3_43_trans;
var _all_;
run;
data t3_43_trans;
	set t3_43_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_43_vw";
run;

/*t3_44*/
proc sql;
create table t3_44 as
select * from NNAD.COVID19_NNDSSCasest3_44_vw (obs=1);
quit;
proc transpose data=t3_44 out=t3_44_trans;
var _all_;
run;
data t3_44_trans;
	set t3_44_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_44_vw";
run;

/*t3_45*/
proc sql;
create table t3_45 as
select * from NNAD.COVID19_NNDSSCasest3_45_vw (obs=1);
quit;
proc transpose data=t3_45 out=t3_45_trans;
var _all_;
run;
data t3_45_trans;
	set t3_45_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_45_vw";
run;


/*t3_46*/
proc sql;
create table t3_46 as
select * from NNAD.COVID19_NNDSSCasest3_46_vw (obs=1);
quit;
proc transpose data=t3_46 out=t3_46_trans;
var _all_;
run;
data t3_46_trans;
	set t3_46_trans;
	format NNAD_tableN $char26.;
	NNAD_tableN="COVID19_NNDSScasesT3_46_vw";
run;


/*Append all t3 tables*/
data t3_all;
/*	length _NAME_ $32;*/
	format _NAME_ $char32.;
	set t3_9_trans;
run;

proc append base=t3_all data=t3_10_trans force;
run;
proc append base=t3_all data=t3_11_trans force;
run;
proc append base=t3_all data=t3_12_trans force;
run;
proc append base=t3_all data=t3_14_trans force;
run;
proc append base=t3_all data=t3_15_trans force;
run;
proc append base=t3_all data=t3_16_trans force;
run;
proc append base=t3_all data=t3_17_trans force;
run;
proc append base=t3_all data=t3_18_trans force;
run;
proc append base=t3_all data=t3_19_trans force;
run;
proc append base=t3_all data=t3_20_trans force;
run;
proc append base=t3_all data=t3_21_trans force;
run;
proc append base=t3_all data=t3_22_trans force;
run;
proc append base=t3_all data=t3_25_trans force;
run;
proc append base=t3_all data=t3_26_trans force;
run;
proc append base=t3_all data=t3_27_trans force;
run;
proc append base=t3_all data=t3_28_trans force;
run;
proc append base=t3_all data=t3_29_trans force;
run;
proc append base=t3_all data=t3_30_trans force;
run;
proc append base=t3_all data=t3_31_trans force;
run;
proc append base=t3_all data=t3_32_trans force;
run;
proc append base=t3_all data=t3_37_trans force;
run;
proc append base=t3_all data=t3_38_trans force;
run;
proc append base=t3_all data=t3_39_trans force;
run;
proc append base=t3_all data=t3_40_trans force;
run;
proc append base=t3_all data=t3_41_trans force;
run;
proc append base=t3_all data=t3_42_trans force;
run;
proc append base=t3_all data=t3_43_trans force;
run;
proc append base=t3_all data=t3_44_trans force;
run;
proc append base=t3_all data=t3_45_trans force;
run;
proc append base=t3_all data=t3_46_trans force;
run;

/*Add a flag*/
data t3_all;
	set t3_all;
	t3flag="1";
run;

/* Import data dictionary into sas */
proc import datafile="&dictdir\DataDictionary_tf_11065_New_EF.xlsx"
	DBMS=EXCEL out=stage4dict replace;
	range = "stage4dict_tf_11065$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*Add a flag*/
data stage4dict;
	set stage4dict;
	ddflag="1";
run;

proc contents data=t3_all;
run;
proc contents data=stage4dict;
run;

/*Compare t3 to dd*/
/*t3->dd*/
proc sql;
create table t3_dd_valid as
select t3_all.NNAD_tableN
,t3_all._NAME_
,stage4dict.ddflag
from t3_all 
left join stage4dict
on (t3_all._NAME_ =stage4dict.Var_Name and t3_all.NNAD_tableN=stage4dict.tablename);
quit;

/*dd->t3*/
proc sql;
create table dd_t3_valid as
select stage4dict.tablename
,stage4dict.Var_Name
,t3_all.t3flag
from stage4dict
left join t3_all 
on (t3_all._NAME_ =stage4dict.Var_Name and t3_all.NNAD_tableN=stage4dict.tablename);
quit;

/*Export data into excel*/
PROC EXPORT DATA= t3_dd_valid
             OUTFILE= "&output\T3_validation.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="t3_dd_valid";
RUN;

/*Export data into excel*/
PROC EXPORT DATA= dd_t3_valid
             OUTFILE= "&output\T3_validation.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="dd_t3_valid";
RUN;

