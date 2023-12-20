****************************************************************************************
Algorithm to compare MPV Limited Production Cases in NNAD Staging and NNAD Production

Developed by: Ying Shen
Originally written: 5/25/2022
                                                         
Date Modified: 2022/Jun/15                                                         
Modified by: Ying Shen                                                              
             Use all variables from NNAD database tables including T3 horizontal tables
	          USe master DD to only limit to the corresponding variables instead of all variables. But we don’t toggle variable.  We use flag for MVP

Test Cases for Mumps
local_record_id condition 
2019469431 10180 
2019469434 10180 
2019472630 10180 
2019473082 10180 
2019477510 10180 
2019469311 10180 

****************************************************************************************;

/*Update to appropriate state*/
%let statem=49; 
%let stabv=%sysfunc(fipnamel(&statem));
%let condn=Mumps; 

/*Update the list of local_record_id*/
%let locallist = '2019469431','2019472630';
/*Enter the local_record_ids that you want to compare*/
%let localid1 =2019469431;
%let localid2 =2019472630;

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

/*Select MPV variables with condition flags*/
proc sql;
create table dd as
select Var_Name
,tablename
from dataDict
where mumps='1' or pertussis ='1' or varicella='1';
quit;

/*According to the master data dictionary, MPV data are in T1, T2, T7 and T3 only*/
/*Get the data from NNAD Staging*/
%macro createdataset(inputtable=,outputtable=,);
proc sql;
create table &inputtable as
select *
from nnads.&inputtable
where condition in ("10180", "10190", "10030")
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

%createdataset(inputtable=Stage4_NNDSScasesT1,outputtable=stagingT1v);
%createdataset(inputtable=Stage4_NNDSScasesT2,outputtable=stagingT2v);
%createdataset(inputtable=Stage4_NNDSScasesT7,outputtable=stagingT7v);
/*%createdataset(inputtable=Stage3_NNDSSCasesT3_Vertical,outputtable=stagingT3v); */
%createdataset(inputtable=Stage4_NNDSScasesT3_11,outputtable=stagingT3_11v);
%createdataset(inputtable=Stage4_NNDSScasesT3_12,outputtable=stagingT3_12v);
%createdataset(inputtable=Stage4_NNDSScasesT3_13,outputtable=stagingT3_13v);
%createdataset(inputtable=Stage4_NNDSScasesT3_14,outputtable=stagingT3_14v);
%createdataset(inputtable=Stage4_NNDSScasesT3_17,outputtable=stagingT3_17v);
%createdataset(inputtable=Stage4_NNDSScasesT3_18,outputtable=stagingT3_18v);
%createdataset(inputtable=Stage4_NNDSScasesT3_19,outputtable=stagingT3_19v);
%createdataset(inputtable=Stage4_NNDSScasesT3_20,outputtable=stagingT3_20v);
%createdataset(inputtable=Stage4_NNDSScasesT3_22,outputtable=stagingT3_22v);
%createdataset(inputtable=Stage4_NNDSScasesT3_31,outputtable=stagingT3_31v);
%createdataset(inputtable=Stage4_NNDSScasesT3_9,outputtable=stagingT3_9v);



proc append base=stagingT1v data=stagingT2v force;run;
proc append base=stagingT1v data=stagingT7v force;run;
/*proc append base=stagingT1v data=stagingT3v force;run;*/
proc append base=stagingT1v data=stagingT3_11v force;run;
proc append base=stagingT1v data=stagingT3_12v force;run;
proc append base=stagingT1v data=stagingT3_13v force;run;
proc append base=stagingT1v data=stagingT3_14v force;run;
proc append base=stagingT1v data=stagingT3_17v force;run;
proc append base=stagingT1v data=stagingT3_18v force;run;
proc append base=stagingT1v data=stagingT3_19v force;run;
proc append base=stagingT1v data=stagingT3_20v force;run;
proc append base=stagingT1v data=stagingT3_22v force;run;
proc append base=stagingT1v data=stagingT3_31v force;run;
proc append base=stagingT1v data=stagingT3_9v force;run;


/*Get the data from NNAD PROD**/
%macro createdatasetp(inputtable=,outputtable=,);
proc sql;
create table &inputtable as
select *
from nnadp.&inputtable
where condition in ("10180", "10190", "10030")
and report_jurisdiction="&statem."
and local_record_id in (&locallist.); /*Test local record ID: 20212603068,20212602982,20212602711,20213023441  */
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

%createdatasetp(inputtable=Stage4_NNDSScasesT1,outputtable=prodT1v);
%createdatasetp(inputtable=Stage4_NNDSScasesT2,outputtable=prodT2v);
%createdatasetp(inputtable=Stage4_NNDSScasesT7,outputtable=prodT7v);
/*Test record for t3vertical: 2018408380,2018410713*/
/*%createdatasetp(inputtable=Stage3_NNDSSCasesT3_Vertical,outputtable=prodT3v); */
%createdatasetp(inputtable=Stage4_NNDSScasesT3_11,outputtable=prodT3_11v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_12,outputtable=prodT3_12v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_13,outputtable=prodT3_13v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_14,outputtable=prodT3_14v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_17,outputtable=prodT3_17v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_18,outputtable=prodT3_18v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_19,outputtable=prodT3_19v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_20,outputtable=prodT3_20v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_22,outputtable=prodT3_22v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_31,outputtable=prodT3_31v);
%createdatasetp(inputtable=Stage4_NNDSScasesT3_9,outputtable=prodT3_9v);


proc append base=prodT1v data=prodT2v force;run;
proc append base=prodT1v data=prodT7v force;run;
proc append base=prodT1v data=prodT3_11v force;run;
proc append base=prodT1v data=prodT3_12v force;run;
proc append base=prodT1v data=prodT3_13v force;run;
proc append base=prodT1v data=prodT3_14v force;run;
proc append base=prodT1v data=prodT3_17v force;run;
proc append base=prodT1v data=prodT3_18v force;run;
proc append base=prodT1v data=prodT3_19v force;run;
proc append base=prodT1v data=prodT3_20v force;run;
proc append base=prodT1v data=prodT3_22v force;run;
proc append base=prodT1v data=prodT3_31v force;run;
proc append base=prodT1v data=prodT3_9v force;run;

/*proc append base=prodT1v data=prodT3v force;run;*/

/*merge*/
proc sql;
create table mergedt1 (drop=_LABEL_ _NAME_)  as
select distinct dd.Var_Name as Varname
,dd.tablename as TableName, * 
from dd
left join stagingT1v a
on (dd.Var_Name =a._NAME_ and dd.tablename=a.TableName)
left join prodT1v b
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
             OUTFILE= "&outputpath\Utah &condn LPM Comparison Results run on &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="&matchVar";
RUN;

%mend compare;

/*Update the rows according to the actual number of local_record_ids*/
%compare (stgID=Staging_&localid1.,prodID=Prod_&localid1.,matchVar=Match_&localid1.);
%compare (stgID=Staging_&localid2.,prodID=Prod_&localid2.,matchVar=Match_&localid2.);


