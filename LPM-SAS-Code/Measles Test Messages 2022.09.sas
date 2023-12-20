/*Created by: Ying Shen on 9/22/2022  Based on CRS Test Message Selection    */
/*Revised by: Ying Shen on 9/22/2022  Reivise the reasons to 52 valid reasons        */




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
	import outbr expanded_caseid event /*pathogen specific*/ stateid zipcode rash onset_sx rashdur general fever temperat cough	
	coryza conjunct clindef otitis diarrhea pneumon encephal thrombo	death cother specify hospital	dayshosp	labtest	igmres	dateigm	
	iggres dateacut dateconv otherlab	 method labconf vaccin reason vacdate vacdate1 vacdate2 vacdate3 dosesbef dosesaft 
	reasonno reasonad dateheal dateinve transmis verified setother outbrel outbname source epilink traceable; 	 
	where event=10140 and year in (2019,2020,2021,2022) and state=&statem.;
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
		length reason1-reason52 $500.;
	if birthd ne . then reason1='populated DOB';
/*	if birthd=. then reason4='missing DOB';*/
/*	if year(birthd)>2019 then reason4='incorrect DOB';*/
/*	if  vacdate=. and vacdate1=. and vacdate2=. and vacdate3=. then reason1='no vax';*/
	if vacdate1 ne . and vacdate2 ne . then do;
	if vacdate1<=vacdate2  then order2=1; else order2= 0;
	end;
	if vacdate1 ne . and vacdate2 ne .  and vacdate3 ne . then do;
	if (vacdate1<=vacdate2) and (vacdate2<=vacdate3) then order3= 1;
	else order3=0;
	end;
	if order2 =0 or order3 = 0 then reason2='out-of-order vax date';
	if vacdate ne . or (vacdate1 ne . or vacdate2 ne . or vacdate3 ne .) then reason3='at least 1 vax date';	
	if vacdate ne . and (vacdate1 ne . or vacdate2 ne . or vacdate3 ne .) then reason4='more than 2 vax date';	
	if vacdate ne . and vacdate1 ne . and vacdate2 ne . and vacdate3 ne . then reason5='max vax date';
/*	if (igmres in ('X', ' ') and dateigm=.) and iggres in ('X', ' ') and dateacut=. and dateconv=.  and otherlab in ('X', ' ') and method=' ' then reason2='no lab tests';*/
	if (igmres in ('P', 'I', 'E') and dateigm ne .) or ((iggres in ('P', 'I', 'E') and (dateacut ne . or dateconv ne .)) or (otherlab in ('P', 'I', 'E') and method ne ' ')) then reason6='at least 1 igm test';
	if (igmres in ('P', 'I', 'E') and dateigm ne .) and ((iggres in ('P', 'I', 'E') and (dateacut ne . or dateconv ne .)) or (otherlab in ('P', 'I', 'E') and method ne ' ')) then reason7='multiple igm tests';
/*	if iggres in ('P', 'I', 'E') and dateconv ne . and dateacut ne . and dateconv<dateacut then reason2='out-of-order lab dates';*/
	if (igmres in ('X', ' ') and dateigm ne .) or (iggres in ('X', ' ') and (dateacut ne . or dateconv ne .)) then reason8='lab date but no result';
	if (igmres in ('P', 'I', 'E') and dateigm=.) and ((iggres in ('P', 'I', 'E') and (dateacut=. or dateconv=.))) then reason9='lab result but no date';
	if datet=1 and eventd ne . then reason10='valid onset date';
	if datet=2 and eventd ne . then reason11='valid diagnosis date';
	if datet=3 and eventd ne . then reason12='valid lab test date';
	if datet=4 and eventd ne . then reason13='valid county rep date';
	if datet=5 and eventd ne . then reason14='valid state rep date';
/*	if datet=9 and eventd ne . then reason3='unknown date';*/
/*	if datet=. and eventd ne . then reason3='missing type';*/
/*	if datet ne . and eventd=. then reason3='missing date';*/
	
	if rashdur>. then reason15='rash duration populated';
/*	if rashdur=999 then reason5='Unknown rash duration';*/
/*	if rashdur=. then reason5='rash duration missing';*/
/*	if temperat<95 then reason6='temperatur too low';*/
	if 95<=temperat<=120 then reason16='populated temperature';
/*	if temperat=999 then reason6='unknown temperature';*/
/*	if temperat=. then reason6='missing temperature';*/
	if .<dayshosp<998 then reason17="days hospital populated";
/*	if dayshosp=. then reason7='days hospital missing';*/
/*	if dayshosp=999 then reason7='unknown days hospitalized';*/
	if .<transmis<15 then reason18='populated transmission setting';
/*	if transmis=. then reason8='missing transmission setting';*/
/*	if transmis=9 then reason8='unknown transmission setting';*/
	if .<reason<=8 then reason19='populated reason not received vax';
/*	if reason=. then reason9='missing reason';*/
/*	if reason=9 then reason9='unknown reason';*/
 	if dosesbef=0 or 1<=dosesbef<=2 then reason20='populated doses before 1st birthday';
/*	if dosesbef=. then reason10='missing doses before 1st birthday';*/
/*	if dosesbef=9 then reason10='unknown doses before 1st birthday';*/
 	if dosesaft=0 or 1<=dosesaft<=3 then reason21='populated doses after 1st birthday';
/*	if dosesaft=. then reason11='missing doses after 1st birthday';*/
/*	if dosesaft=9 then reason11='unknown doses after 1st birthday';*/
	if 1<=reasonno<=8 then reason22='populated reason 0 dose were given';
/*	if reasonno=. then reason12='missing reason not vaccinated';*/
/*	if reasonno=9 then reason12='unknown reason not vaccinated';*/
	if 1<=reasonad<=8 then reason23='populated reason additional doses not given';
/*	if reasonad=. then reason13='missing reason additional vaccines not given';*/
/*	if reasonad=9 then reason13='unknown reason additional vaccines not given';*/

	array quick {23} outbrel rash general fever cough coryza conjunct clindef otitis diarrhea pneumon encephal thrombo death cother
	hospital labtest labconf vaccin verified outbrel epilink traceable; 
	array varname{23} reason24-reason46;
	do i=1 to 23;
		if quick{i} in ('Y', 'N', 'U') then varname{i}=catx(" ", vname(quick{i}), "valid value");
/*		if quick{i}=' ' then varname{i}=catx(" ", vname(quick{i}), "missing value");*/
/*		if quick{i} not in ('Y', 'N', 'U', ' ') then varname{i}=catx(" ", vname(quick{i}), "invalid value");*/
	end;
	drop i;

	if casstat in (1,2,3) then reason47='correct case status';
/*	if casstat not in (1,2,3,9) then reason38='incorrect case status';*/
/*	if casstat=. then reason38='missing case status';*/

	array char{5} specify method setother outbname source;
	array reas{5} reason48-reason52;

	do j=1 to 5;
/*		if char{j}=' ' then reas{j}=catx(" ", vname(char{j}), "missing value");*/
		if char{j} ne ' ' then reas{j}=catx(" ", vname(char{j}), "populated");
	end;
	drop j;

/*	array dshift {12} onset_sx dateheal dateinve dateigm dateacut dateconv eventd birthd vacdate vacdate1-vacdate3; */
/*	do k=1 to 12;*/
/*		if dshift{k}=.E then reason44='Shifted date';*/
/*	end;*/
/*	drop k;*/
run;



data var;
	set var_all;
run;

*Select first batch of cases based on the all reasons;
%macro loop;

%do i=1 %to 52;

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
%do i=2 %to 52;

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

ods excel file="&outpath\NCIRD_Requested_Measles_Cases_&stnm. run on &sysdate9..xlsx" options(embedded_titles='yes'
embedded_footnotes='yes' start_at='2, 1' frozen_headers='yes' title_footnote_nobreak='yes' sheet_name='NCIRD selected cases');

title bold height=24pt j=left "NCIRD Selected Measles Cases for &stnm. ";
title2 j=left "run on &sysdate9.";
title3 j=left "Total Number of CRS Cases in NNAD: &totaln  ";
title4 j=left "Expected Measles Sample Size: &allNum";

proc report data=selecteddata;
run;

ods excel close;
