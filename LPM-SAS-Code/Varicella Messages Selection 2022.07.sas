/*Updated by: Ying Shen on 5/23/2022  Updated output location*/
/*Updated by: Ying Shen on 5/23/2022  Do loops were changed from 20 to 19 as there are 19 in the array definition*/
/*Updated by: Ying Shen on 5/23/2022  Removed duplicates before proc transpose*/
/*Updated by: Ying Shen on 5/31/2022  Changed the year filter*/
/*Updated by: Ying Shen on 7/8/2022  Change reasons selection*/
/*Updated by: Ying Shen on 7/12/2022  Expanded the reasons from 6 to 12*/
/*                                    Added comments to make the code readable*/
/*                                    Remove duplicates from multiple samples */
/*Updated by: Ying Shen on 7/25/2022  Added nres where analysts can define the number of cases selected for each reason  */ 
/*Updated by: Ying Shen on 7/25/2022  Added allNum where analysts can define the total number of cases to select */ 
/*Updated by: Ying Shen on 7/27/2022  Added a date in the report title2 j=left "run on &sysdate9.";*/ 



/*Analysts need to change to appropriate state*/
%let statem=49; 

/*Analysts can define the number of cases selected for each reason*/
%let nres=3;

/*Analysts can define total number of cases to select*/
%let allNum=50;

%let stnm=%sysfunc(fipnamel(&statem));
%let stabv=%sysfunc(fipstate(&statem));

/*Analysts need to change to appropriate output path*/
%let outpath= \\cdc.gov\project\NIP_Project_Store1\Surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\&stabv.\MPV;


/*Connect to the SQL database*/
libname nmi OLEDB provider="sqloledb" 
      properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1" "Integrated Security"="SSPI" 
            "Initial Catalog"="NCIRD_DVD_VPD" ) schema=nndss access=readonly;  

/*Analyst will need to change years*/
 data netss;
	set nmi.stage2_netss;
	keep rectype state year caseid site week event county birthd age agetype sex race hispanic casstat
	outbrel outbr rectype state year caseid site week expanded_caseid datet eventd import; 	
	where event=10030 and year in (2018, 2019,2020,2021,2022) and state=&statem.; /*change to appropriate year*/
run;

*Convert to date type;
data netss;
	set netss;
	format ibirthd ieventd mmddyy10.;
	ibirthd=datepart(birthd);
	ieventd=datepart(eventd);
	drop birthd eventd;
	rename ibirthd=birthd ieventd=eventd;
run;

/*Define the selection Reasons*/
data var_all;
	set netss;
	length reason1-reason12 $500.;
	
	if birthd ne . then reason1='populated DOB';
/*	if birthd=. then reason1='missing DOB';*/
/*	if year(birthd)>2018 then reason1='incorrect DOB';*/
	if datet=1 and eventd ne . then reason2='valid onset date';
	if datet=2 and eventd ne . then reason3='valid diagnosis date';
	if datet=3 and eventd ne . then reason4='valid lab test date';
	if datet=4 and eventd ne . then reason5='valid county rep date';
	if datet=5 and eventd ne . then reason6='valid state rep date';
	if datet=9 and eventd ne . then reason7='valid unknown date';
/*	if datet=. and eventd ne . then reason2='missing type';*/
/*	if datet ne . and eventd=. then reason2='missing date';*/
	if race in (1, 2, 3, 5) then reason8='valid race';
	if race=8 then reason9='other race';
/*	if race=9 then reason3='unknown race';*/
/*	if race=. then reason3='missing race';*/
	if outbrel in ('Y', 'N', 'U') then reason10='valid outbr value';
	if hispanic in (1,2,9) then reason11='hispanic valid value';
/*	if hispanic=. then reason5='hispanic missing value';*/
	if casstat in (1,2,3) then reason12='correct case status';
/*	if casstat not in (1,2,3,9) then reason6='incorrect case status';*/
/*	if casstat=. then reason6='missing case status';*/

run;


data var;
	set var_all;
run;

*Select first batch of cases based on the 18 reasons;
%macro loop;

%do i=1 %to 12;

PROC SURVEYSELECT DATA=var noprint
	METHOD = SRS SAMprate=.5 SEED = 123 
	NMAX = &nres out=reason&i; 	
	STRATA reason&i;
	where reason&i ne ' ';
RUN;

data reason&i;
	set reason&i;
	selection_reason=reason&i;
run;

proc sql;
create table var as
	select *
	from var
	where expanded_caseid not in
	(select distinct expanded_caseid from reason&i);
quit;

%end;

%mend;
%loop;

/*Append all selected dataset*/
%macro append1;
%do i=2 %to 12;

proc append base=reason1 data=reason&i force;
run;
%end;
%mend;
%append1;

/*Combine all reasons to a dataset*/
data part1_samples;
	set reason1;
	where selection_reason ne ' ';
run;

/*Get the remaining sample number and total count*/
proc sql noprint;
	select &allNum - count(*) into :remains 
	from work.part1_samples;

	select count(*) into :totaln 
	from work.var_all;
quit;

/*Select second batch of cases;*/
%macro loop2;
	%if (&totaln < &allNum or &totaln = &allNum) %then 
		%do;
			proc sql;
			create table part2_samples as
			select * 
			,"select all becasue total count <= 50" as selection_reason 
			from work.var
			where caseid not in
			(select distinct caseid from part1_samples);
			quit;
		%end;

	%else 
/*		%if &totaln > &allNum and &remains > 0 %then */
		%do;
			proc sql;
			create table remaining_cases as
			select * 
			,"random selection" as selection_reason 
			from work.var
			where caseid not in
			(select distinct caseid from part1_samples);
			quit;

			PROC SURVEYSELECT DATA=remaining_cases noprint
				METHOD = SRS SAMprate=1 SEED = 123 
				NMAX = &remains out=part2_samples; 	
			RUN;
		%end;
%mend loop2;
%loop2;

/*Append the two samples*/
proc append base=part1_samples data=part2_samples force;
run;

/*Create a dataset with clean list and reason*/
proc sql;
create table selecteddata as
select distinct event
,state
,year
,caseid
,site
,expanded_caseid
,selection_reason
from part1_samples;
quit;


*formating data for excel out put for CSELS;

ods excel file="&outpath\NCIRD_Requested_Varicella_Cases_&stnm. run on &sysdate9..xlsx" options(embedded_titles='yes'
embedded_footnotes='yes' start_at='2, 1' frozen_headers='yes' title_footnote_nobreak='yes' sheet_name='NCIRD selected cases');

title bold height=24pt j=left "NCIRD Selected Varicella Cases for &stnm.";
title2 j=left "run on &sysdate9.";
title3 j=left "Total Number of Cases in NNAD: &totaln  ";
title4 j=left "Expected Sample Size: &allNum";


proc report data=selecteddata;
run;

ods excel close;
