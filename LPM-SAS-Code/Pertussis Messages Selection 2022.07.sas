/*Updated by: Ying Shen on 5/23/2022  Updated nmi server name*/
/*Updated by: Ying Shen on 5/23/2022  Updated output location*/
/*Updated by: Ying Shen on 5/23/2022  Removed duplicates before proc transpose*/
/*Updated by: Ying Shen on 5/31/2022  Changed the year filter*/
/*Updated by: Ying Shen on 7/8/2022  Change reasons selection*/
/*Updated by: Ying Shen on 7/12/2022  Expanded the reasons from 20 to 41*/
/*                                    Added comments to make the code readable*/
/*                                    Remove duplicates from multiple samples */
/*Updated by: Ying Shen on 7/25/2022  Added nres where analysts can define the number of cases selected for each reason  */ 
/*Updated by: Ying Shen on 7/25/2022  Added allNum where analysts can define  total number of cases to select */ 
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
	keep caseid site birthd year event state culres pcrres serres dfares antibiot datefir casstat cough seizures vomit encephal
	paroxysm whoop race durcough epilink outbrel outbr hispanic hospital xray death vacname1-vacname6 type1-type6 vacdate1-vacdate6 
	labtest reaspert vaccin antibiot secondan datesec datecult datedfa datepcr firspec secspec antibiot outbname pertant expanded_caseid
	datet eventd import;
	where event=10190 and year in (2018,2019,2020,2021,2022) and state=&statem.;
run;

*Creating macro variables;
proc sql noprint;
	select compress(NAME) into :dtlist separated by " "
	from dictionary.columns
	where libname='WORK' and memname='NETSS' and NAME like '%date%' and Name not like "datet";

	/*creates idummy variable names*/
	select catt( 'i_', NAME)
	into :idtlist separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='NETSS' and NAME like '%date%' and Name not like "datet";

	select count(NAME) into :num separated by " " /*enumerates number of variables*/
	from dictionary.columns
	where libname='WORK' and memname='NETSS' and NAME like '%date%' and Name not like "datet";

	/*create list of variables to rename*/
	select catt('i_', NAME, '= ', NAME)
	into :relist separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='NETSS' and NAME like '%date%' and Name not like "datet";

quit;

*Array to convert data;
data netss;
	set netss;
	format &idtlist mmddyy10.;
	array dtchng{&num} &dtlist ;
	array idtchng{&num} &idtlist;
	do i=1 to &num;
			if dtchng{i} ne ' ' then do;
				idtchng{i}=input(dtchng{i}, mmddyy10.);
				if idtchng{i}=. then idtchng{i}=.E;
			end;
	end;
	drop &dtlist;
run;

*Renaming converted data variables to original variable names;
proc datasets lib=work nolist;
	modify netss;
	rename &relist;
run;
quit;

data netss;
	set netss;
	format ifirspec mmddyy10. isecspec mmddyy10. ibirthd ieventd mmddyy10.;	

	idurcough=input(durcough, 3.);

	if firspec ne ' ' then do;
		ifirspec=input(firspec, mmddyy10.);
		if ifirspec=. then ifirspec=.E;
	end;

	if secspec ne ' ' then do;
		isecspec=input(secspec, mmddyy10.);
		if isecspec=. then isecspec=.E;
	end;

	isecondan=input(secondan, 3.);
	ibirthd=datepart(birthd);
	ieventd=datepart(eventd);
	drop durcough firspec secspec secondan birthd eventd;
	rename idurcough=durcough ifirspec=firspec isecspec=secspec isecondan=secondan ibirthd=birthd ieventd=eventd;
run;

/*Define the selection Reasons*/
data var_all;
	set netss;
	length reason1-reason41 $500.;
	if birthd ne . then reason1='populated DOB';
/*	if birthd=. then reason4='missing DOB';*/
/*	if year(birthd)>2018 then reason4='incorrect DOB';*/
	if type1 not in (' ', 'U', '9', '0') and (type2 not in (' ', 'U', '9', '0') or type3 not in (' ', 'U', '9', '0') or type4 not in (' ', 'U', '9', '0') or type5 not in (' ', 'U', '9', '0') or type6 not in (' ', 'U', '9', '0')) then reason2='more than two vaccinations';
	if type1=' ' and type2=' ' and type3=' ' and type4=' ' and type5=' ' and type6=' ' and vacdate1=. and vacdate2=. and vacdate3=.
	and vacdate4=. and vacdate5=. and vacdate6=. then reason3='no vax';
		if vacdate1 ne . and vacdate2 ne . then do;
		if vacdate1<=vacdate2  then order2=1; else order2= 0;
		end;
		if vacdate1 ne . and vacdate2 ne .  and vacdate3 ne . then do;
		if (vacdate1<=vacdate2) and (vacdate2<=vacdate3) then order3= 1;
		else order3=0;
		end;
		if vacdate1 ne . and vacdate2 ne .  and vacdate3 ne . and vacdate4 ne .  then do;
		if (vacdate1<=vacdate2) and (vacdate2<=vacdate3)and (vacdate3<=vacdate4) then order4=1;
		else order4=0;
		end;
		if vacdate1 ne . and vacdate2 ne .  and vacdate3 ne . and vacdate4 ne . and vacdate5 ne .  then do;
		if (vacdate1<=vacdate2) and (vacdate2<=vacdate3)and (vacdate3<=vacdate4) and (vacdate4<=vacdate5) then order5=1;
		else order5=0;
		end;
		if vacdate1 ne . and vacdate2 ne .  and vacdate3 ne . and vacdate4 ne . and vacdate5 ne .  and vacdate6 ne .  then do;
		if (vacdate1<=vacdate2) and (vacdate2<=vacdate3)and (vacdate3<=vacdate4) and (vacdate4<=vacdate5) and (vacdate5<=vacdate6) then order6=1;
		else order6=0;
		end;
		if vacdate1 ne . and vacdate2 ne .  and vacdate3 ne . and vacdate4 ne . and vacdate5 ne .  and vacdate6 ne . then do;
		if (vacdate1<=vacdate2) and (vacdate2<=vacdate3)and (vacdate3<=vacdate4) and (vacdate4<=vacdate5) and (vacdate5<=vacdate6) then order7=1;
		else order7=0;
		end;
	if order2 =0 or order3 = 0 or order4 =0 or order5 =0 or order6 =0 or order7 =0 then reason4='out-of-order vax';
	if type1=' ' and type2=' ' and type3 ne ' ' and type4 ne ' ' and type5 ne ' ' and type6 ne ' ' and vacdate1 ne . and vacdate2 ne . then reason5='vax date only';
	if type1 ne ' ' and type2 ne ' ' and vacdate1=. and vacdate2=. and vacdate3=. and vacdate4=. and vacdate5=. and vacdate6=. then reason6='vax type only'; 
	if type1 not in (' ', 'U', '9', '0') and type2 not in (' ', 'U', '9', '0') and type3 not in (' ', 'U', '9', '0') and type4 not in (' ', 'U', '9', '0') and type5 not in (' ', 'U', '9', '0') and type6 not in (' ', 'U', '9', '0') then reason7='max vax';
	if (culres in ('P', 'I', 'S') and datecult ne .) and ((dfares in ('P', 'I', 'S') and datedfa ne .) or (pcrres in ('P', 'I', 'S') and datepcr ne .) or (serres in ('P', 'I', 'S') and (firspec ne . or secspec ne .))) then reason8='multiple lab tests';
	if culres in (' ', 'X') and dfares in (' ', 'X') and pcrres in (' ', 'X') and serres in (' ', 'X') then reason9='no lab testing';
	if serres in ('P', 'I', 'S') and secspec ne . and firspec ne . and secspec<firspec then reason10='out-of-order lab test';
	if culres=' ' and dfares=' ' and pcrres=' ' and serres=' ' and (datecult ne . or datedfa ne . or datepcr ne . or firspec ne . or secspec ne .) then reason11='result date only';
	if antibiot='Y' and datefir ne . and datesec ne . and pertant=' ' and secondan=' ' then reason12='antibio date only';
	if antibiot=' ' and datefir=. and secondan=. and datesec=. then reason13='no antibio';
	if datefir ne . and datesec ne . and datefir>datesec then reason14='out-of-order antibio';
	if antibiot ne ' ' and pertant not in ('.', ' ') and datefir ne . and secondan not in ('.', ' ') and datesec ne . then reason14='max antibio';
	
	if datet=1 and eventd ne . then reason16='valid onset date';
	if datet=2 and eventd ne . then reason17='valid diagnosis date';
	if datet=3 and eventd ne . then reason18='valid lab test date';
	if datet=4 and eventd ne . then reason19='valid county rep date';
	if datet=5 and eventd ne . then reason20='valid state rep date';
	if datet=9 and eventd ne . then reason21='valid unknown date';
	if datet=. and eventd ne . then reason22='valid missing type';
	if datet ne . and eventd=. then reason23='valid missing date';
	if cough='Y' and (seizures='Y' or vomit='Y' or encephal='Y' or paroxysm='Y' or whoop='Y') then reason24='multiple symptoms';
	if cough=' ' and seizures=' ' and vomit=' ' and encephal=' ' and paroxysm=' ' and whoop=' ' then reason25='no symptoms';
	if cough ne 'Y' and (seizures='Y' or vomit='Y' or encephal='Y' or paroxysm='Y' or whoop='Y') then reason26='no cough; other symptoms';
	if race in (1, 2, 3, 5) then reason27='valid race';
/*	if race=8 then reason28='other race';*/
/*	if race=9 then reason7='unknown race';*/
/*	if race=. then reason7='missing race';*/
	if durcough>. then reason28='cough duration populated';
	if durcough=999 then reason29='unknown cough duration';
/*	if durcough=. then reason8='cough duration missing';	*/

	array quick {6} epilink outbrel hospital death labtest vaccin; 
	array varname{6} reason30-reason35;
	do i=1 to 6;
		if quick{i} in ('Y', 'N', 'U') then varname{i}=catx(" ", vname(quick{i}), "valid value");
/*		if quick{i}=' ' then varname{i}=catx(" ", vname(quick{i}), "missing value");*/
/*		if quick{i} not in ('Y', 'N', 'U', ' ') then varname{i}=catx(" ", vname(quick{i}), "invalid value");*/
	end;
	drop i;

	if outbname ne ' ' then reason36='outbreak name present';
/*	if outbname=' ' then reason11='outbreak name missing';*/
	if hispanic in (1,2,9) then reason37='hispanic valid value';
/*	if hispanic=. then reason12='hispanic missing value';*/
	if xray in ('P', 'N', 'X', 'U') then reason38='xray valid value';
/*	if xray=' ' then reason14='xray missing value';*/
	if reaspert in ('1', '2', '3', '4', '5', '6', '7', '8', '9') then reason39='reaspert valid value';
/*	if reaspert not in ('1', '2', '3', '4', '5', '6', '7', '8', '9', ' ') then reason17='reaspert invalid value';*/
/*	if reaspert=' ' then reason17='reaspert missing value';*/
	if casstat in (1,2,3) then reason40='correct case status';
/*	if casstat not in (1,2,3,9) then reason19='incorrect case status';*/
/*	if casstat=. then reason19='missing case status';*/

	array dshift {15} &dtlist firspec secspec birthd eventd; 
	do k=1 to 15;
	if dshift{k}=.E then reason41='Shifted date';
	end;
	drop k;

run;


data var;
	set var_all;
run;

*Select first batch of cases based on the 18 reasons;
%macro loop;

%do i=1 %to 41;

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
%do i=2 %to 41;

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

ods excel file="&outpath\NCIRD_Requested_Pertussis_Cases_&stnm. run on &sysdate9..xlsx" options(embedded_titles='yes'
embedded_footnotes='yes' start_at='2, 1' frozen_headers='yes' title_footnote_nobreak='yes' sheet_name='NCIRD selected cases');

title bold height=24pt j=left "NCIRD Selected Pertussis Cases for &stnm. ";
title2 j=left "run on &sysdate9.";
title3 j=left "Total Number of Cases in NNAD: &totaln  ";
title4 j=left "Expected Sample Size: &allNum";


proc report data=selecteddata;
run;

ods excel close;




