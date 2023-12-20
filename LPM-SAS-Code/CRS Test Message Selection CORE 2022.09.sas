/*Created by: Ying Shen on 9/22/2022  Based on Psittacosis Test Message Selection    */
/*Revised by: Ying Shen on 9/22/2022  Reivise the reasons to 59 valid reasons        */
/*Note by Ying Shen on 9/22/2022      There is only one CRS case*/
/*                                    event state year caseid site expanded_caseid */
/*                                    10370 40 2019 256084 701 256084  */



/*Analysts need to change to appropriate state*/
%let statem=40;                          

/*Analysts can define the number of cases selected for each reason*/
%let nres=1;

/*Analysts can define total number of cases to select*/
%let allNum=50;

%let stnm=%sysfunc(fipnamel(&statem));
%let stabv=%sysfunc(fipstate(&statem));

/*Analysts need to change to appropriate output path*/
%let outpath= \\cdc.gov\project\NIP_Project_Store1\Surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\&stabv.\RIBD;

/*Connect to the SQL database*/
libname nmi OLEDB provider="sqloledb" 
      properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1" "Integrated Security"="SSPI" 
            "Initial Catalog"="NCIRD_DVD_VPD" ) schema=nndss access=readonly;  

/*Analyst will need to change years*/
 data netss;
	set nmi.stage2_netss;
	keep rectype update state year caseid site week event count county birthd age	agetype sex race hispanic eventd datet casstat	
	import outbr expanded_caseid event /*pathogen specific*/ stateid zipcode rash onset_sx rashdur fever temperat arthralg 
	lymphade conjunct parotit clindef meningit deaf orchitit encephal arthriti thrombo death cother specify hospital dayshosp 
	labtest igmres dateigm iggres dateacut dateconv otherlab method labconf vaccin vacdate vacdate1 vacdate2 vacdate3 dosesaft 
	reason dateheal dateinve transmis verified setother outbrel outbname source epilink traceable pregnant gestatio immunity 
	yeartest agetest seroconf yeardis agedis; 	 
	where event=10370 and year in (2019,2020,2021,2022) and state=&statem.;
run;

*Array to convert data;
data netss;
	set netss;
	format ionset_sx idateheal idateigm idateacut idateconv ivacdate ivacdate1-ivacdate3 idateinve mmddyy10.;
	array dtchng{10} onset_sx dateheal dateigm dateacut dateconv vacdate vacdate1-vacdate3 dateinve;
	array idtchng{10} ionset_sx idateheal idateigm idateacut idateconv ivacdate ivacdate1-ivacdate3 idateinve;
	array remove{10} remove1-remove10;

	do i=1 to 10;
			if dtchng{i} ne ' ' then do;
				remove{i}=ifn(lengthn(compress(dtchng{i}, "`~!@#$%^&*()-_=+|[]{};:',?", 'ak'))>=1,1,0);
				if remove{i}>0 then idtchng{i}=.E;
				if dtchng{i}='99/99/99' then idtchng{i}=.;
				else idtchng{i}=input(dtchng{i}, mmddyy10.);
			end;
	end;

	ieventd=datepart(eventd);
	ibirthd=datepart(birthd);

	drop onset_sx dateheal dateigm dateacut dateconv vacdate vacdate1-vacdate3 dateinve eventd birthd;
	rename ionset_sx=onset_sx idateheal=dateheal idateigm=dateigm idateacut=dateacut idateconv=dateconv ivacdate=vacdate
	ivacdate1=vacdate1 ivacdate2=vacdate2 ivacdate3=vacdate3 idateinve=dateinve ieventd=eventd ibirthd=birthd;

run;

data var_all;
	set netss;
		length reason1-reason59 $500.;
	*Stratify by DOB;
	if birthd ne . and birthd < today()then reason1='populated DOB';
	if birthd=. then reason2='missing DOB';
	if birthd > today() then reason3='incorrect DOB';
	*Stratify by event date;
	if datet=1 and eventd ne . then reason4='valid onset date';
	if datet=2 and eventd ne . then reason5='valid diagnosis date';
	if datet=3 and eventd ne . then reason6='valid lab test date';
	if datet=4 and eventd ne . then reason7='valid county report date';
	if datet=5 and eventd ne . then reason8='valid state report date';
	if datet=9 and eventd ne . then reason9='unknown date';
/*	if datet=. and eventd ne . then reason10='missing type';*/
/*	if datet ne . and eventd=. then reason2='missing date';*/
	*Stratify by race;
	if race in (1, 2, 6, 7) then reason10='valid AAPI race';
	if race in (3, 5) then reason11='valid white or African American race';
/*	if race=8 then reason3='other race';*/
/*	if race=9 then reason3='unknown race';*/
/*	if race=. then reason3='missing race';*/
	*Stratify by outbreak;
	if outbr in (1) then reason12='outbreak Yes';
	if outbr in (2) then reason13='outbreak NO';
/*	if outbr=. then reason4='outbreak missing';*/
/*	if outbr not in (1, 2, 9, .) then reason4='outbreak invalid value';*/
	*Stratify by ethnicity;
	if hispanic in (1) then reason14='hispanic or latino';
	if hispanic in (2) then reason15='not hispanic of latino';
/*	if hispanic=. then reason5='hispanic missing value';*/
	*Stratify by case status;
	if casstat in (1) then reason15='confirmed case status';
	if casstat in (2) then reason17='probable case status';
	if casstat in (3, 9) then reason18='suspect or unknown case status';
/*	if casstat=. then reason6='missing case status';*/
run;


data var;
	set var_all;
run;

*Select first batch of cases based on the all reasons;
%macro loop;

%do i=1 %to 59;

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
%do i=2 %to 59;

proc append base=reason1 data=reason&i force;
run;
%end;
%mend;
%append1;

/*Combine all reasons to a dataset*/
data part1_samples;
	set reason1;
/*	length selection_reason $3000.;*/
/*	drop samplingweight SelectionProb i;*/
	where selection_reason ne ' ';
/*	tests=catx('; ', reason1, reason2, reason3, reason4, reason5, reason6);*/
run;

/*Get the remaining sample number and total count*/
proc sql noprint;
	select &allNum - count(*) into :remains 
/*separated by " " */
	from work.part1_samples;

	select count(*) into :totaln 
/*separated by " "*/
	from work.var_all;
quit;

/*Select second batch of cases;*/
%macro loop2;
	%if (&totaln < &allNum or &totaln = &allNum) %then 
		%do;
			proc sql;
			create table part2_samples as
			select * 
			,"select all becasue total count <= &allNum" as selection_reason 
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


/*Formating data for excel out put for CSELS;*/

ods excel file="&outpath\NCIRD_Requested_CRS_Cases_&stnm. run on &sysdate9..xlsx" options(embedded_titles='yes'
embedded_footnotes='yes' start_at='2, 1' frozen_headers='yes' title_footnote_nobreak='yes' sheet_name='NCIRD selected cases');

title bold height=24pt j=left "NCIRD Selected CRS Cases for &stnm. ";
title2 j=left "run on &sysdate9.";
title3 j=left "Total Number of CRS Cases in NNAD: &totaln  ";
title4 j=left "Expected CRS Sample Size: &allNum";

proc report data=selecteddata;
run;

ods excel close;

