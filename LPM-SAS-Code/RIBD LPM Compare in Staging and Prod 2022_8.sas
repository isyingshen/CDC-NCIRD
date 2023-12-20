****************************************************************************************
Algorithm to compare RIBD Limited Production Cases in NNAD Staging and NNAD Production

Developed by: Ying Shen
Originally written: 5/25/2022
                                                         
Date Modified: 2022/Jun/15                                                         
Modified by: Ying Shen                                                              
             Use all variables from NNAD database tables including T3 horizontal tables
	          USe master DD to only limit to the corresponding variables instead of all variables. But we don’t toggle variable.  We use flag for MVP

                                                         
Date Modified: 2022/Aug/23                                                         
Modified by: Ying Shen                                                              
             Revised by changing the condition name and condition code
				 Added all possible tables including T3 horizontal tables
****************************************************************************************;
/* Condition name   :   H_influenzae   N_meningitidis IPD   Psittacosis Legionellosis  */
/* Condition code:      10590          10150          11723 10450       10490          */

%let condtx = N_meningitidis;
%let condcd = 10150;

/*Update to appropriate state*/
%let statem=36; 
%let stabv=%sysfunc(fipnamel(&statem));

/*Legionellosis test record: 12232004561, 15637744531 statem=13*/
/*H_flu test record: 100007, 100026 statem=48*/
/*IPD test record: 101116, 101133 state=48*/
/*N_meningitidis 100796, 100803 36 */
 

/*Update the list of local_record_id*/
%let locallist = '100796','100803';
/*Enter the local_record_ids that you want to compare*/
%let localid1 =100796;
%let localid2 =100803;

/*Update the results/output path*/
%let outputpath=\\cdc.gov\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NCIRD NNDSS Analytic Database (NNAD) for programs\LPM Data Comparison;

/*Connect to NNAD Staging*/
libname NNADS OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSSV-INFC-1601\QSRV1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;
/*Connect to NNAD PROD*/
libname NNADP OLEDB provider="sqloledb" 
      properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1" "Integrated Security"="SSPI" 
            "Initial Catalog"="NCIRD_DVD_VPD" ) schema=nndss access=readonly;  

/* Import data dictionary into sas */
proc import datafile="\\cdc\project\NIP_Project_Store1\Surveillance\surveillance_ncird_3\NCIRD NNDSS Analytic Database (NNAD) for programs\Code\Pathogen Specific Code\NON_COVID\Formats\DataDictionary_eachcond.xlsx"
	DBMS=EXCEL out=dataDict replace;
	range = "Stage4MasterVars$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;

/*Select variables with condition flags*/
proc sql;
create table dd as
select Var_Name
,tablename
from dataDict
where &condtx='1';
quit;


/*Get the data from NNAD Staging*/
%macro createdataset(inputtable=,outputtable=,);
proc sql;
create table &inputtable as
select *
from nnads.&inputtable
where condition in ("&condcd")
and report_jurisdiction="&statem."
and local_record_id in (&locallist.); /*Test local record ID: 20212603068,20212602982,20212602711,20213023441  */
quit;

/*transpose data*/
proc transpose data=&inputtable out=stagingT1t prefix=Staging_;
	id local_record_id;
	var _all_;
	run;

/*Convert to vertical for comparison*/
proc sql;
create table &outputtable as
select *
,"&inputtable" as TableName
from stagingT1t;
quit;

%mend createdataset;

%createdataset(inputtable=Stage4_NNDSScasesT1,outputtable=stagingT1);
%createdataset(inputtable=Stage4_NNDSScasesT2,outputtable=stagingT2);
%createdataset(inputtable=Stage4_NNDSScasesT4,outputtable=stagingT4);
%createdataset(inputtable=Stage4_NNDSScasesT5,outputtable=stagingT5);
%createdataset(inputtable=Stage4_NNDSScasesT6,outputtable=stagingT6);
%createdataset(inputtable=Stage4_NNDSScasesT7,outputtable=stagingT7);
%createdataset(inputtable=Stage4_NNDSScasesT8,outputtable=stagingT8);
/*%createdatasetp(inputtable=Stage3_NNDSSCasesT3_Vertical,outputtable=prodT3v); */
%createdataset(inputtable=Stage4_NNDSScasesT3_1,outputtable=stagingT3_1);
%createdataset(inputtable=Stage4_NNDSScasesT3_2,outputtable=stagingT3_2);
%createdataset(inputtable=Stage4_NNDSScasesT3_3,outputtable=stagingT3_3);
%createdataset(inputtable=Stage4_NNDSScasesT3_4,outputtable=stagingT3_4);
%createdataset(inputtable=Stage4_NNDSScasesT3_5,outputtable=stagingT3_5);
%createdataset(inputtable=Stage4_NNDSScasesT3_6,outputtable=stagingT3_6);
%createdataset(inputtable=Stage4_NNDSScasesT3_7,outputtable=stagingT3_7);
%createdataset(inputtable=Stage4_NNDSScasesT3_8,outputtable=stagingT3_8);
%createdataset(inputtable=Stage4_NNDSScasesT3_9,outputtable=stagingT3_9);
%createdataset(inputtable=Stage4_NNDSScasesT3_10,outputtable=stagingT3_10);
%createdataset(inputtable=Stage4_NNDSScasesT3_11,outputtable=stagingT3_11);
%createdataset(inputtable=Stage4_NNDSScasesT3_12,outputtable=stagingT3_12);
%createdataset(inputtable=Stage4_NNDSScasesT3_13,outputtable=stagingT3_13);
%createdataset(inputtable=Stage4_NNDSScasesT3_14,outputtable=stagingT3_14);
%createdataset(inputtable=Stage4_NNDSScasesT3_15,outputtable=stagingT3_15);
%createdataset(inputtable=Stage4_NNDSScasesT3_16,outputtable=stagingT3_16);
%createdataset(inputtable=Stage4_NNDSScasesT3_17,outputtable=stagingT3_17);
%createdataset(inputtable=Stage4_NNDSScasesT3_18,outputtable=stagingT3_18);
%createdataset(inputtable=Stage4_NNDSScasesT3_19,outputtable=stagingT3_19);
%createdataset(inputtable=Stage4_NNDSScasesT3_20,outputtable=stagingT3_20);
%createdataset(inputtable=Stage4_NNDSScasesT3_21,outputtable=stagingT3_21);
%createdataset(inputtable=Stage4_NNDSScasesT3_22,outputtable=stagingT3_22);
%createdataset(inputtable=Stage4_NNDSScasesT3_23,outputtable=stagingT3_23);
%createdataset(inputtable=Stage4_NNDSScasesT3_24,outputtable=stagingT3_24);
%createdataset(inputtable=Stage4_NNDSScasesT3_25,outputtable=stagingT3_25);
%createdataset(inputtable=Stage4_NNDSScasesT3_26,outputtable=stagingT3_26);
%createdataset(inputtable=Stage4_NNDSScasesT3_27,outputtable=stagingT3_27);
%createdataset(inputtable=Stage4_NNDSScasesT3_28,outputtable=stagingT3_28);
%createdataset(inputtable=Stage4_NNDSScasesT3_29,outputtable=stagingT3_29);
%createdataset(inputtable=Stage4_NNDSScasesT3_30,outputtable=stagingT3_30);
%createdataset(inputtable=Stage4_NNDSScasesT3_31,outputtable=stagingT3_31);
%createdataset(inputtable=Stage4_NNDSScasesT3_32,outputtable=stagingT3_32);
%createdataset(inputtable=Stage4_NNDSScasesT3_33,outputtable=stagingT3_33);
%createdataset(inputtable=Stage4_NNDSScasesT3_34,outputtable=stagingT3_34);
%createdataset(inputtable=Stage4_NNDSScasesT3_35,outputtable=stagingT3_35);
%createdataset(inputtable=Stage4_NNDSScasesT3_36,outputtable=stagingT3_36);
%createdataset(inputtable=Stage4_NNDSScasesT3_37,outputtable=stagingT3_37);
%createdataset(inputtable=Stage4_NNDSScasesT3_38,outputtable=stagingT3_38);
%createdataset(inputtable=Stage4_NNDSScasesT3_39,outputtable=stagingT3_39);
%createdataset(inputtable=Stage4_NNDSScasesT3_40,outputtable=stagingT3_40);
%createdataset(inputtable=Stage4_NNDSScasesT3_41,outputtable=stagingT3_41);
%createdataset(inputtable=Stage4_NNDSScasesT3_42,outputtable=stagingT3_42);
%createdataset(inputtable=Stage4_NNDSScasesT3_43,outputtable=stagingT3_43);
%createdataset(inputtable=Stage4_NNDSScasesT3_44,outputtable=stagingT3_44);
%createdataset(inputtable=Stage4_NNDSScasesT3_45,outputtable=stagingT3_45);
%createdataset(inputtable=Stage4_NNDSScasesT3_46,outputtable=stagingT3_46);
%createdataset(inputtable=Stage4_NNDSScasesT3_47,outputtable=stagingT3_47);
%createdataset(inputtable=Stage4_NNDSScasesT3_48,outputtable=stagingT3_48);
%createdataset(inputtable=Stage4_NNDSScasesT3_49,outputtable=stagingT3_49);
%createdataset(inputtable=Stage4_NNDSScasesT3_50,outputtable=stagingT3_50);
%createdataset(inputtable=Stage4_NNDSScasesT3_51,outputtable=stagingT3_51);
%createdataset(inputtable=Stage4_NNDSScasesT3_52,outputtable=stagingT3_52);
%createdataset(inputtable=Stage4_NNDSScasesT3_53,outputtable=stagingT3_53);
%createdataset(inputtable=Stage4_NNDSScasesT3_54,outputtable=stagingT3_54);
%createdataset(inputtable=Stage4_NNDSScasesT3_55,outputtable=stagingT3_55);
%createdataset(inputtable=Stage4_NNDSScasesT3_56,outputtable=stagingT3_56);
%createdataset(inputtable=Stage4_NNDSScasesT3_57,outputtable=stagingT3_57);
%createdataset(inputtable=Stage4_NNDSScasesT3_58,outputtable=stagingT3_58);
%createdataset(inputtable=Stage4_NNDSScasesT3_59,outputtable=stagingT3_59);
%createdataset(inputtable=Stage4_NNDSScasesT3_60,outputtable=stagingT3_60);
%createdataset(inputtable=Stage4_NNDSScasesT3_61,outputtable=stagingT3_61);


/*Union all tables*/
proc sql;
create table union_stg as
select * from stagingT1 union
select * from stagingT2 union
select * from stagingT4 union
select * from stagingT5 union
select * from stagingT6 union
select * from stagingT7 union
select * from stagingT8 union
select * from stagingT3_1 union
select * from stagingT3_2 union
select * from stagingT3_3 union
select * from stagingT3_4 union
select * from stagingT3_5 union
select * from stagingT3_6 union
select * from stagingT3_7 union
select * from stagingT3_8 union
select * from stagingT3_9 union
select * from stagingT3_10 union
select * from stagingT3_11 union
select * from stagingT3_12 union
select * from stagingT3_13 union
select * from stagingT3_14 union
select * from stagingT3_15 union
select * from stagingT3_16 union
select * from stagingT3_17 union
select * from stagingT3_18 union
select * from stagingT3_19 union
select * from stagingT3_20 union
select * from stagingT3_21 union
select * from stagingT3_22 union
select * from stagingT3_23 union
select * from stagingT3_24 union
select * from stagingT3_25 union
select * from stagingT3_26 union
select * from stagingT3_27 union
select * from stagingT3_28 union
select * from stagingT3_29 union
select * from stagingT3_30 union
select * from stagingT3_31 union
select * from stagingT3_32 union
select * from stagingT3_33 union
select * from stagingT3_34 union
select * from stagingT3_35 union
select * from stagingT3_36 union
select * from stagingT3_37 union
select * from stagingT3_38 union
select * from stagingT3_39 union
select * from stagingT3_40 union
select * from stagingT3_41 union
select * from stagingT3_42 union
select * from stagingT3_43 union
select * from stagingT3_44 union
select * from stagingT3_45 union
select * from stagingT3_46 union
select * from stagingT3_47 union
select * from stagingT3_48 union
select * from stagingT3_49 union
select * from stagingT3_50 union
select * from stagingT3_51 union
select * from stagingT3_52 union
select * from stagingT3_53 union
select * from stagingT3_54 union
select * from stagingT3_55 union
select * from stagingT3_56 union
select * from stagingT3_57 union
select * from stagingT3_58 union
select * from stagingT3_59 union
select * from stagingT3_60 union
select * from stagingT3_61 ;
quit;


/*Get the data from NNAD PROD**/
%macro createdatasetp(inputtable=,outputtable=,);
proc sql;
create table &inputtable as
select *
from nnadp.&inputtable
where condition in ("&condcd")
and report_jurisdiction="&statem."
and local_record_id in (&locallist.); 
quit;

/*transpose data*/
proc transpose data=&inputtable out=stagingT1t prefix=Prod_;
	id local_record_id;
	var _all_;
	run;

/*Convert to vertical for comparison*/
proc sql;
create table &outputtable as
select *
,"&inputtable" as TableName
from stagingT1t;
quit;

%mend createdatasetp;

%createdatasetp(inputtable=Stage4_NNDSScasesT1,outputtable=prodT1);
%createdatasetp(inputtable=Stage4_NNDSScasesT2,outputtable=prodT2);
%createdatasetp(inputtable=Stage4_NNDSScasesT4,outputtable=prodT4);
%createdatasetp(inputtable=Stage4_NNDSScasesT5,outputtable=prodT5);
%createdatasetp(inputtable=Stage4_NNDSScasesT6,outputtable=prodT6);
%createdatasetp(inputtable=Stage4_NNDSScasesT7,outputtable=prodT7);
%createdatasetp(inputtable=Stage4_NNDSScasesT8,outputtable=prodT8);

/*%createdatasetp(inputtable=Stage3_NNDSSCasesT3_Vertical,outputtable=prodT3v); */
%createdataset(inputtable=Stage4_NNDSScasesT3_1,outputtable=prodT3_1);
%createdataset(inputtable=Stage4_NNDSScasesT3_2,outputtable=prodT3_2);
%createdataset(inputtable=Stage4_NNDSScasesT3_3,outputtable=prodT3_3);
%createdataset(inputtable=Stage4_NNDSScasesT3_4,outputtable=prodT3_4);
%createdataset(inputtable=Stage4_NNDSScasesT3_5,outputtable=prodT3_5);
%createdataset(inputtable=Stage4_NNDSScasesT3_6,outputtable=prodT3_6);
%createdataset(inputtable=Stage4_NNDSScasesT3_7,outputtable=prodT3_7);
%createdataset(inputtable=Stage4_NNDSScasesT3_8,outputtable=prodT3_8);
%createdataset(inputtable=Stage4_NNDSScasesT3_9,outputtable=prodT3_9);
%createdataset(inputtable=Stage4_NNDSScasesT3_10,outputtable=prodT3_10);
%createdataset(inputtable=Stage4_NNDSScasesT3_11,outputtable=prodT3_11);
%createdataset(inputtable=Stage4_NNDSScasesT3_12,outputtable=prodT3_12);
%createdataset(inputtable=Stage4_NNDSScasesT3_13,outputtable=prodT3_13);
%createdataset(inputtable=Stage4_NNDSScasesT3_14,outputtable=prodT3_14);
%createdataset(inputtable=Stage4_NNDSScasesT3_15,outputtable=prodT3_15);
%createdataset(inputtable=Stage4_NNDSScasesT3_16,outputtable=prodT3_16);
%createdataset(inputtable=Stage4_NNDSScasesT3_17,outputtable=prodT3_17);
%createdataset(inputtable=Stage4_NNDSScasesT3_18,outputtable=prodT3_18);
%createdataset(inputtable=Stage4_NNDSScasesT3_19,outputtable=prodT3_19);
%createdataset(inputtable=Stage4_NNDSScasesT3_20,outputtable=prodT3_20);
%createdataset(inputtable=Stage4_NNDSScasesT3_21,outputtable=prodT3_21);
%createdataset(inputtable=Stage4_NNDSScasesT3_22,outputtable=prodT3_22);
%createdataset(inputtable=Stage4_NNDSScasesT3_23,outputtable=prodT3_23);
%createdataset(inputtable=Stage4_NNDSScasesT3_24,outputtable=prodT3_24);
%createdataset(inputtable=Stage4_NNDSScasesT3_25,outputtable=prodT3_25);
%createdataset(inputtable=Stage4_NNDSScasesT3_26,outputtable=prodT3_26);
%createdataset(inputtable=Stage4_NNDSScasesT3_27,outputtable=prodT3_27);
%createdataset(inputtable=Stage4_NNDSScasesT3_28,outputtable=prodT3_28);
%createdataset(inputtable=Stage4_NNDSScasesT3_29,outputtable=prodT3_29);
%createdataset(inputtable=Stage4_NNDSScasesT3_30,outputtable=prodT3_30);
%createdataset(inputtable=Stage4_NNDSScasesT3_31,outputtable=prodT3_31);
%createdataset(inputtable=Stage4_NNDSScasesT3_32,outputtable=prodT3_32);
%createdataset(inputtable=Stage4_NNDSScasesT3_33,outputtable=prodT3_33);
%createdataset(inputtable=Stage4_NNDSScasesT3_34,outputtable=prodT3_34);
%createdataset(inputtable=Stage4_NNDSScasesT3_35,outputtable=prodT3_35);
%createdataset(inputtable=Stage4_NNDSScasesT3_36,outputtable=prodT3_36);
%createdataset(inputtable=Stage4_NNDSScasesT3_37,outputtable=prodT3_37);
%createdataset(inputtable=Stage4_NNDSScasesT3_38,outputtable=prodT3_38);
%createdataset(inputtable=Stage4_NNDSScasesT3_39,outputtable=prodT3_39);
%createdataset(inputtable=Stage4_NNDSScasesT3_40,outputtable=prodT3_40);
%createdataset(inputtable=Stage4_NNDSScasesT3_41,outputtable=prodT3_41);
%createdataset(inputtable=Stage4_NNDSScasesT3_42,outputtable=prodT3_42);
%createdataset(inputtable=Stage4_NNDSScasesT3_43,outputtable=prodT3_43);
%createdataset(inputtable=Stage4_NNDSScasesT3_44,outputtable=prodT3_44);
%createdataset(inputtable=Stage4_NNDSScasesT3_45,outputtable=prodT3_45);
%createdataset(inputtable=Stage4_NNDSScasesT3_46,outputtable=prodT3_46);
%createdataset(inputtable=Stage4_NNDSScasesT3_47,outputtable=prodT3_47);
%createdataset(inputtable=Stage4_NNDSScasesT3_48,outputtable=prodT3_48);
%createdataset(inputtable=Stage4_NNDSScasesT3_49,outputtable=prodT3_49);
%createdataset(inputtable=Stage4_NNDSScasesT3_50,outputtable=prodT3_50);
%createdataset(inputtable=Stage4_NNDSScasesT3_51,outputtable=prodT3_51);
%createdataset(inputtable=Stage4_NNDSScasesT3_52,outputtable=prodT3_52);
%createdataset(inputtable=Stage4_NNDSScasesT3_53,outputtable=prodT3_53);
%createdataset(inputtable=Stage4_NNDSScasesT3_54,outputtable=prodT3_54);
%createdataset(inputtable=Stage4_NNDSScasesT3_55,outputtable=prodT3_55);
%createdataset(inputtable=Stage4_NNDSScasesT3_56,outputtable=prodT3_56);
%createdataset(inputtable=Stage4_NNDSScasesT3_57,outputtable=prodT3_57);
%createdataset(inputtable=Stage4_NNDSScasesT3_58,outputtable=prodT3_58);
%createdataset(inputtable=Stage4_NNDSScasesT3_59,outputtable=prodT3_59);
%createdataset(inputtable=Stage4_NNDSScasesT3_60,outputtable=prodT3_60);
%createdataset(inputtable=Stage4_NNDSScasesT3_61,outputtable=prodT3_61);


/*Union all tables*/
proc sql;
create table union_prod as
select * from prodT1 union
select * from prodT2 union
select * from prodT4 union
select * from prodT5 union
select * from prodT6 union
select * from prodT7 union
select * from prodT8 union
select * from prodT3_1 union
select * from prodT3_2 union
select * from prodT3_3 union
select * from prodT3_4 union
select * from prodT3_5 union
select * from prodT3_6 union
select * from prodT3_7 union
select * from prodT3_8 union
select * from prodT3_9 union
select * from prodT3_10 union
select * from prodT3_11 union
select * from prodT3_12 union
select * from prodT3_13 union
select * from prodT3_14 union
select * from prodT3_15 union
select * from prodT3_16 union
select * from prodT3_17 union
select * from prodT3_18 union
select * from prodT3_19 union
select * from prodT3_20 union
select * from prodT3_21 union
select * from prodT3_22 union
select * from prodT3_23 union
select * from prodT3_24 union
select * from prodT3_25 union
select * from prodT3_26 union
select * from prodT3_27 union
select * from prodT3_28 union
select * from prodT3_29 union
select * from prodT3_30 union
select * from prodT3_31 union
select * from prodT3_32 union
select * from prodT3_33 union
select * from prodT3_34 union
select * from prodT3_35 union
select * from prodT3_36 union
select * from prodT3_37 union
select * from prodT3_38 union
select * from prodT3_39 union
select * from prodT3_40 union
select * from prodT3_41 union
select * from prodT3_42 union
select * from prodT3_43 union
select * from prodT3_44 union
select * from prodT3_45 union
select * from prodT3_46 union
select * from prodT3_47 union
select * from prodT3_48 union
select * from prodT3_49 union
select * from prodT3_50 union
select * from prodT3_51 union
select * from prodT3_52 union
select * from prodT3_53 union
select * from prodT3_54 union
select * from prodT3_55 union
select * from prodT3_56 union
select * from prodT3_57 union
select * from prodT3_58 union
select * from prodT3_59 union
select * from prodT3_60 union
select * from prodT3_61 ;
quit;


/*proc append base=prodT1v data=prodT3v force;run;*/

/*merge*/
proc sql;
create table mergedt1 (drop=_LABEL_ _NAME_)  as
select distinct dd.Var_Name as Varname
,dd.tablename as TableName, * 
from dd
left join union_stg a
on (dd.Var_Name =a._NAME_ and dd.tablename=a.TableName)
left join union_prod b
on a._NAME_ = b._NAME_
where a._Name_ not in ('dup_SequenceID','condition','ContentID','legacy_case_id','mmwr_year','report_jurisdiction','site','trans_id','wsystem','local_record_id');
quit;


%macro compare (stgID=,prodID=,matchVar=,);
/*data array1;*/
/*array localarray{&localcount.} $ 20 local1-local&localcount. (&locallist.);*/
/*run;*/

proc sql;
create table compare as
select distinct Varname
,TableName
,&stgID
,&prodID
,case 
	when &stgID = &prodID then "Y"
end as &matchVar
from mergedt1;
quit;

/*Export extracted data into excel*/
PROC EXPORT DATA= compare
             OUTFILE= "&outputpath\&stabv &condtx LPM Comparison run on &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="&matchVar";
RUN;

%mend compare;

/*Update the rows according to the actual number of local_record_ids*/
%compare (stgID=Staging_&localid1.,prodID=Prod_&localid1.,matchVar=Match_&localid1.);
%compare (stgID=Staging_&localid2.,prodID=Prod_&localid2.,matchVar=Match_&localid2.);


