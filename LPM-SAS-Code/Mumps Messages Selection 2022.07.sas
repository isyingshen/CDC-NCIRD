/*Updated by: Ying Shen on 5/23/2022  Updated output location*/
/*Updated by: Ying Shen on 5/23/2022  Do loops were changed from 20 to 19 as there are 19 in the array definition*/
/*Updated by: Ying Shen on 5/23/2022  Removed duplicates before proc transpose*/
/*Updated by: Ying Shen on 5/31/2022  Changed the year filter*/
/*Updated by: Ying Shen on 7/8/2022  Change reasons selection*/
/*Updated by: Ying Shen on 7/12/2022  Expanded the reasons from 20 to 32*/
/*                                    Added 6 Asian, 7 Native Hawaiian/Other PI to race*/
/*                                    Added comments to make the code readable*/
/*                                    Remove duplicates from multiple samples */
/*Updated by: Ying Shen on 7/25/2022  Added nres where analysts can define the number of cases selected for each reason  */ 
/*Updated by: Ying Shen on 7/25/2022  Added allNum where analysts can define the total number of cases to select */ 
/*Updated by: Ying Shen on 7/27/2022  Added a date in the report title2 j=left "run on &sysdate9.";*/

/*Analysts need to change to appropriate state*/
%let statem=49; 

/*Analysts can define the number of cases selected for each reason*/
%let nres=2;

/*Analysts can define total number of cases to select*/
%let allNum=20;

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
	keep caseid vacdate vacdate1 vacdate2 vacdate3 igmres dateigm iggres dateacut dateconv otherlab method eventd datet casstat hospital birthd
	meningit encephal deaf orchitit parotit outbrel setother transmis epilink source labtest labconf vaccin caseid expanded_caseid event state year site; 	
	where event=10180 and year in (2019) and state=&statem.;
run;


*Array to convert data;
data netss;
	set netss;
	format ivacdate mmddyy8. ivacdate1-ivacdate3 idateigm idateacut idateconv ieventd ibirthd mmddyy10.;
	array dtchng{6} vacdate1-vacdate3 dateigm dateacut dateconv ;
	array idtchng{6} ivacdate1-ivacdate3 idateigm idateacut idateconv;
	do i=1 to 6;
			if dtchng{i} ne ' ' then do;
				idtchng{i}=input(dtchng{i}, mmddyy10.);
				if idtchng{i}=. then idtchng{i}=.E;
			end;
	end;

	if vacdate ne ' ' then do;
		ivacdate=input(vacdate, mmddyy8.);
		if ivacdate=. then ivacdate=.E;
	end;
	
	ieventd=datepart(eventd);
	ibirthd=datepart(birthd);
	drop vacdate vacdate1-vacdate3 dateigm dateacut dateconv eventd birthd;
	rename ivacdate=vacdate ivacdate1=vacdate1 ivacdate2=vacdate2 ivacdate3=vacdate3 idateigm=dateigm idateacut=dateacut 
	idateconv=dateconv ieventd=eventd ibirthd=birthd;

run;

/*Define the selection Reasons*/
data var_all;
	set netss;
		length reason1-reason32 $500.;
		if casstat in (1,2,3,9) then reason1='correct case status';
/*		if  vacdate=. and vacdate1=. and vacdate2=. and vacdate3=. then reason1='vacdate no vax';*/
		if vacdate1 ne . and vacdate2 ne . then do;
		if vacdate1<=vacdate2  then order2=1; else order2= 0;
		end;
		if vacdate1 ne . and vacdate2 ne .  and vacdate3 ne . then do;
		if (vacdate1<=vacdate2) and (vacdate2<=vacdate3) then order3= 1;
		else order3=0;
		end;
/*	if order2 =0 or order3 = 0 then reason2='out-of-order vax';*/
	if vacdate ne . then reason31='at least one vax';
	if vacdate ne . and (vacdate1 ne . or vacdate2 ne . or vacdate3 ne .) then reason2='more than 2 vax';	
	if vacdate ne . and vacdate1 ne . and vacdate2 ne . and vacdate3 ne . then reason3='4 vax';
	if (igmres in ('X', ' ') and dateigm=.) and iggres in ('X', ' ') and dateacut=. and dateconv=.  and otherlab in ('X', ' ') and method=' ' then reason4='no lab tests';
	if (igmres in ('P', 'I', 'E') and dateigm ne .) or (iggres in ('P', 'I', 'E') and (dateacut ne . or dateconv ne .)) then reason5='at least one lab test';
	if (igmres in ('P', 'I', 'E') and dateigm ne .) and ((iggres in ('P', 'I', 'E') and (dateacut ne . or dateconv ne .)) or (otherlab in ('P', 'I', 'E') and method ne ' ')) then reason6='multiple lab tests';
	if iggres in ('P', 'I', 'E') and dateconv ne . and dateacut ne . and dateconv<dateacut then reason7='out-of-order lab dates';
	if (igmres in ('X', ' ') and dateigm ne .) or (iggres in ('X', ' ') and (dateacut ne . or dateconv ne .)) then reason8='lab date but no result';
	if (igmres in ('P', 'I', 'E') and dateigm=.) and ((iggres in ('P', 'I', 'E') and (dateacut=. or dateconv=.))) then reason9='lab result but no date';
	if datet=1 and eventd ne . then reason10='valid onset date';
	if datet=2 and eventd ne . then reason11='valid diagnosis date';
	if datet=3 and eventd ne . then reason12='valid lab test date';
	if datet=4 and eventd ne . then reason13='valid county rep date';
	if datet=5 and eventd ne . then reason14='valid state rep date';
	if datet=9 and eventd ne . then reason15='valid unknown date';
/*	if datet=. and eventd ne . then reason3='missing type';*/
/*	if datet ne . and eventd=. then reason3='missing date';*/
	if birthd ne . then reason16='populated DOB';
/*	if birthd=. then reason4='missing DOB';*/
/*	if year(birthd)>2018 then reason4='incorrect DOB';*/

	array quick {14} hospital meningit encephal deaf orchitit parotit outbrel setother transmis epilink source labtest labconf vaccin; 
	array varname{14} reason17-reason30;
	do i=1 to 14;
		if quick{i} in ('Y', 'N', 'U') then varname{i}=catx(" ", vname(quick{i}), "valid value");
/*		if quick{i}=' ' then varname{i}=catx(" ", vname(quick{i}), "missing value");*/
/*		if quick{i} not in ('Y', 'N', 'U', ' ') then varname{i}=catx(" ", vname(quick{i}), "invalid value");*/
	end;
	drop i;

/*	if casstat in (1,2,3,9) then reason31='correct case status';*/
/*	if casstat not in (1,2,3,9) then reason19='incorrect case status';*/
/*	if casstat=. then reason19='missing case status';*/

	array dshift {9}  vacdate vacdate1-vacdate3 dateigm dateacut dateconv eventd birthd; 
	do k=1 to 9;
		if dshift{k}=.E then reason32='Shifted date';
	end;
	drop k;
run;

data var;
	set var_all;
run;

*Select first batch of cases based on the 18 reasons;
%macro loop;

%do i=1 %to 32;

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
%do i=2 %to 32;

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


*formating data for excel out put for CSELS;

ods excel file="&outpath\NCIRD_Requested_Mumps_Cases_&stnm. run on &sysdate9..xlsx" options(embedded_titles='yes'
embedded_footnotes='yes' start_at='2, 1' frozen_headers='yes' title_footnote_nobreak='yes' sheet_name='NCIRD selected cases');

title bold height=24pt j=left "NCIRD Selected Mumps Cases for &stnm.";
title2 j=left "run on &sysdate9.";
title3 j=left "Total Number of Cases in NNAD: &totaln  ";
title4 j=left "Expected Sample Size: &allNum";


proc report data=selecteddata;
run;

ods excel close;


