/*Updated by: Ying Shen on 6/23/2022  Updated output location                                                          */
/*Updated by: Ying Shen on 6/23/2022  Changed the year filter                                                          */
/*Updated by: Ying Shen on 6/23/2022  Updated the data source to DSPV-VPDN-1601,59308\qsrv1                            */
/*Updated by: Ying Shen on 6/23/2022  Changed incorrect DOB from absolute year to today() because it will need to update every time we run                               */
/*                                    from year(birthd)>2018 to birthd > today()                                       */
/*                                    Changed 	if casstat in (1,2,3) then reason6='correct case status'; to 	if casstat in (1,2,3,9) then reason6='correct case status';*/
/*Updated by: Ying Shen on 7/11/2022  Expanded the reasons */
/*                                    Added 6 Asian, 7 Native Hawaiian/Other PI to race  */
/*                                    Added comments to make the code readable  */
/*                                    Remove duplicates from multiple samples   */
/*Updated by: Ying Shen on 7/25/2022  Added nres where analysts can define the number of cases selected for each reason  */ 
/*Updated by: Ying Shen on 7/25/2022  Added allNum where analysts can define the total number of cases to select */
/*Updated by: Ying Shen on 7/27/2022  Added a date in the report title2 j=left "run on &sysdate9.";*/
/*Updated by: Ying Shen on 8/30/2022  Removed the shifted date as a reason to select messages, */

/*Analysts need to change to appropriate state*/
%let statem=49; 

/*Analysts can define the number of cases selected for each reason*/
%let nres=1;

/*Analysts can define total number of cases to select*/
%let allNum=10;

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
	keep caseid vacdate1 vacdate2 vacdate3 vacdate4 vacname1 vacname2 vacname3 vacname4 meningvac frstcult specimen1 specimen2 specimen3 serogrp eventd birthd 
	race casstat outbr outbname outcome infection1 infection2 infection3 daycare expanded_caseid event state year site datet hispanic birthd sulfa rifampin county; 	 
	where event=10150 and year in (2019,2020,2021,2022) and state=&statem.;
run;

*Array to convert data;
data netss;
	set netss;
	format ivacdate1-ivacdate4 ifrstcult ieventd ibirthd mmddyy10.;
	array dtchng{5} vacdate1-vacdate4 frstcult;
	array idtchng{5} ivacdate1-ivacdate4 ifrstcult;
	array remove{5} remove1-remove5;

	do i=1 to 5;
			if dtchng{i} ne ' ' then do;
				remove{i}=ifn(lengthn(compress(dtchng{i}, "`~!@#$%^&*()-_=+|[]{};:',?", 'ak'))>=1,1,0);
				if remove{i}>0 then idtchng{i}=.E;
				if dtchng{i}='99/99/99' then idtchng{i}=.;
				else idtchng{i}=input(dtchng{i}, mmddyy10.);
			end;
	end;

	ieventd=datepart(eventd);
	ibirthd=datepart(birthd);
	drop vacdate1-vacdate4 frstcult eventd birthd;
	rename ivacdate1=vacdate1 ivacdate2=vacdate2 ivacdate3=vacdate3 ivacdate4=vacdate4 ifrstcult=frstcult ieventd=eventd ibirthd=birthd;

run;

/*Define the selection Reasons*/
data var_all;
	set netss;
		length reason1-reason29 $500.;
	*ABCs stratification;
/*	if state=9 then reason1='ABCs';*/
/*	else if state=27 then reason1='ABCs';*/
/*	else if state=35 then reason1='ABCs';*/
/*	else if state=6 and county in (75, 13, 1) then reason1='ABCs';*/
/*	else if state=8 and county in (1, 5, 31, 35, 59) then reason1='ABCs';*/
/*	else if state=13 and county in (13, 15, 45, 57, 63, 67, 77, 89, 97, 113, 117, 121, 135, 151, 217, 223, 227, 247, 255, 297) then reason1='ABCs';*/
/*	else if state=24 and county in (3, 5, 13, 25, 27) then reason1='ABCs';*/
/*	else if  state=36 and county in (1, 21, 37, 39, 51, 55, 57, 69, 73, 83, 91, 93, 95, 117, 123) then reason1='ABCs';*/
/*	else if state=41 and county in (5, 51, 67) then reason1='ABCs';*/
/*	else if state=47 and county in (1, 9, 21, 37, 43, 57, 65, 89, 93, 105, 113, 145, 147, 149, 155, 157, 165, 173, 187, 189) then reason1='ABCs';*/
/*	else reason1='Not ABCs';*/
		*DOB stratification;
	if birthd ne . then reason1='populated DOB';
/*	if birthd=. then reason7='missing DOB';*/
/*	if year(birthd)>2019 then reason7='incorrect DOB';*/
	*vaccination stratification;
	if vacname1 in ('1','2','3','4','5','6','7','8') or (vacname2 in ('1','2','3','4','5','6','7','8') or vacname3 in ('1','2','3','4','5','6','7','8') or vacname4 in ('1','2','3','4','5','6','7','8')) then reason2='at least one vaccination';
	if vacname1 in ('1','2','3','4','5','6','7','8') and (vacname2 in ('1','2','3','4','5','6','7','8') or vacname3 in ('1','2','3','4','5','6','7','8') or vacname4 in ('1','2','3','4','5','6','7','8')) then reason3='more than two vaccinations';
/*	if vacname1=' ' and vacname2=' ' and vacname3=' ' and vacname4=' ' and vacdate1=. and vacdate2=. and vacdate3=. and vacdate4=. then reason4='no vax';*/
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
	if order2 =0 or order3 = 0 or order4=0 then reason4='out-of-order vax';
	if (vacname1=' ' and vacname2=' ' and vacname3=' ' and vacname4=' ') and (vacdate1 ne . or vacdate2 ne . or vacdate3 ne . or vacdate4 ne .) then reason5='vax date only';
	if (vacname1 ne ' ' or vacname2 ne ' ' or vacname3 ne ' ' or vacname4 ne ' ') and (vacdate1=. and vacdate2=. and vacdate3=. and vacdate4=.)  then reason6='vax type only'; 
	if vacname1 in ('1','2','3','4','5','6','7','8') and vacname2 in ('1','2','3','4','5','6','7','8') and vacname3 in ('1','2','3','4','5','6','7','8') and vacname4 in ('1','2','3','4','5','6','7','8') 
	and vacdate1 ne . and vacdate2 ne . and vacdate3 ne . and vacdate4 ne . then reason7='max vax';
	if meningvac in ('1','2','3', '9') then reason8='vaccinated valid value'; 
/*	if meningvac not in ('1','2','3', '9') then reason3='vaccinated invalid value';*/
/*	if meningvac=' ' then reason2='vaccinated missing value';*/
	*Laboatory stratification;
	if specimen1 in ('1','2','3','4','5','6','7','8','9') or specimen2 in ('1','2','3','4','5','6','7', '8', '9') or specimen3 in ('1','2','3','4','5','6','7','8','9') then reason9='at least one lab test';
	if specimen1 in ('1','2','3','4','5','6','7','8','9') and (specimen2 in ('1','2','3','4','5','6','7', '8', '9') or specimen3 in ('1','2','3','4','5','6','7','8','9')) then reason10='multiple lab tests';
	if specimen1=' ' and specimen2=' ' and specimen3=' ' then reason11='no lab tests';
	if frstcult=. and (specimen1 ne ' ' or specimen2 ne ' ' or specimen3 ne ' ') then reason12='specimen type only'; 
	if frstcult ne . and (specimen1= ' ' and specimen2=' ' and specimen3=' ') then reason13='date tested only';
	*Serogroup stratification;
	if serogrp in  ('1', '2', '3', '4', '5', '6', '8','9') then reason14='serogroup valid value';
/*	if serogrp not in ('1', '2', '3', '4', '5', '6', '8', '9') then reason5='serogroup invalid value';*/
/*	if serogrp='9' then reason5='serogroup unknown value';*/
/*	if serogrp=' ' then reason5='serogroup missing value';*/
	*Event date stratification;
	if datet=1 and eventd ne . then reason15='onset date';
	if datet=2 and eventd ne . then reason16='diagnosis date';
	if datet=3 and eventd ne . then reason17='lab test date';
	if datet=4 and eventd ne . then reason18='county rep date';
	if datet=5 and eventd ne . then reason19='state rep date';
	if datet=9 and eventd ne . then reason20='unknown date';
/*	if datet=. and eventd ne . then reason22='missing type';*/
/*	if datet ne . and eventd=. then reason23='missing date';*/
/*	*/
	*Race stratification;
	if race in (1, 2, 3, 5, 8,9) then reason21='valid race';
/*	if race=8 then reason8='other race';*/
/*	if race=9 then reason8='unknown race';*/
/*	if race=. then reason8='missing race';*/
	*Outbreak stratification;
	if outbr in (1, 2, 9) then reason22='outbreak valid value';
/*	if outbr=. then reason9='outbreak missing';*/
/*	if outbr not in (1, 2, 9, .) then reason9='outbreak invalid value';*/
	*Ethnicity stratification;
	if hispanic in (1,2,9) then reason23='hispanic valid value';
/*	if hispanic=. then reason10='hispanic missing value';*/
	*Infection type stratification;
	if infection1 in ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12', '99') or  (infection2 in ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12','99') or infection3 in ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12','99'))  then reason24='at least one symptom'; /*accept '01', '02', etc.?*/
	if infection1 in ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12', '99') and (infection2 in ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12','99') or infection3 in ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12','99'))  then reason25='multiple symptoms'; /*accept '01', '02', etc.?*/
/*	if infection1 not in ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12', '99',' ') or infection2 not in ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12', '99',' ') or infection3 not in ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12', '99', ' ') then reason11='incorrect symptom value';*/
/*	if infection1=' ' and infection2=' ' and infection3=' ' then reason11='missing symptoms';*/
/*	if infection1='99' and infection2='99' and infection3='99' then reason11='unknown symptoms';*/
/*	if infection1 in  ('1', '01',  '2', '02', '3', '03',  '4', '04', '5', '05',  '6', '06', '7', '07', '8', '08', '9', '09', '10', '11', '12') and infection2=' ' and infection3=' ' then reason29='one symptom';*/
	*Daycare stratification;
	if daycare in ('1','2','9') then reason26='daycare valid value';
/*	if daycare='9' then reason12='daycare unknown value';*/
/*	if daycare=' ' then reason12='daycare missing value';*/
	*Sulfa stratification;
	if sulfa in ('1','2','9') then reason27='sulfa valid value'; 
/*	if sulfa not in ('1','2','9') then reason13='sulfa invalid value';*/
/*	if sulfa=' ' then reason13='sulfa missing value';*/
	*Rifampin stratification;
	if rifampin in ('1','2','9') then reason28='rifampin valid value'; 
/*	if rifampin not in ('1','2','9') then reason14='rifampin invalid value';*/
/*	if rifampin=' ' then reason14='rifampin missing value';*/
	*Case status stratification;
	if casstat in (1,2,3,9) then reason29='correct case status';
/*	if casstat not in (1,2,3,9) then reason15='incorrect case status';*/
/*	if casstat=. then reason15='missing case status';*/
	*Shifted date stratification;
/*	array dshift {6}  vacdate1-vacdate3 frstcult eventd birthd; */
/*	do k=1 to 6;*/
/*		if dshift{k}=.E then reason34='Shifted date';*/
/*	end;*/
/*	drop k;*/
run;


data var;
	set var_all;
run;

*Select first batch of cases based on the all reasons;
%macro loop;

%do i=1 %to 29;

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
%do i=2 %to 29;

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

ods excel file="&outpath\NCIRD_Requested_N.meningitidis_Cases_&stnm. run on &sysdate9..xlsx" options(embedded_titles='yes'
embedded_footnotes='yes' start_at='2, 1' frozen_headers='yes' title_footnote_nobreak='yes' sheet_name='NCIRD selected cases');

title bold height=24pt j=left "NCIRD Selected N. meningitidis Cases for &stnm. ";
title2 j=left "run on &sysdate9.";
title3 j=left "Total Number of N. meningitidis Cases in NNAD: &totaln  ";
title4 j=left "Expected N. meningitidis Sample Size: &allNum";

proc report data=selecteddata;
run;

ods excel close;


