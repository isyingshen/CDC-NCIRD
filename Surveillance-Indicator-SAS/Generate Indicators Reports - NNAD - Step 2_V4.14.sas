/*----------------------------------------------------------------------------
This program produces the Indicator Reports for each state and the entire US. 
assumes that the appropriate data has been created beforehand using the same  
parameters (start and end year) for each condition.   
----------------------------------------------------------------------------*/ 

 /****************************************************************************************************/
 /* Date Modified: 2021/Mar/31                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: removed macro startyear and endyear because they are defined in "create" program        */
 /*          removed libname indrpts because it is definded in "create" program                      */
 /*          removed filepath because it is definded in "create" program                             */
 /*                                                                                                  */
 /* Date Modified: 2021/Apr/01                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: updated MumpsPctComp9 to MumpsPctComp10 because "include" program of Mumps              */
 /*          only has 10                                                                             */
 /*                                                                                                  */
 /* Date Modified: 2021/Apr/06                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: updated Today=4/28/2019 to &SYSDATE9.                                                   */
 /*                                                                                                  */
 /* Date Modified: 2021/Apr/09                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: removed the 4 indicators for mumps: 1)MumpsNumMeetClin 2)MumpsPctClinTest               */
 /*            3)MumpsPctVaxCompNVN 4)MumpsPctVaxComp                                                */
 /*                                                                                                  */
 /* Date Modified: 2021/Apr/19                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: Re-wrote Varicella Report according to Old Way Netss Code                               */
 /*                                                                                                  */
 /* Date Modified: 2021/Apr/22                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: Added Measles code                                                                      */
 /*                                                                                                  */
 /* Date Modified: 2021/May/12                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: Added H_flu code                                                                        */
 /*          Added Meningitidis code                                                                 */
 /*          Added IPD code                                                                          */
 /*                                                                                                  */
 /* Date Modified: 2021/Jan/31                                                                       */
 /* Modified by: Jodi Baldy                                                                          */
 /* Changes: Added NBS: AK, IN, PR, RMI                                                              */
 /*          Report Title chg'd to include all pathogens                                             */
 /*          Line 165 footnote text chg'd to Provisional Data Wk52 2020                              */
 /*          Rearranged order of pathogens to conform to reports prior to 2020                       */
 /*          Added footnote to measles to address the genotype testing for each of the 10 years      */
 /*                                                                                                  */
 /* Date Modified: 2022/Feb/02                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: Updated Varicella Code to make it display on the report                                 */
 /*                                                                                                  */
 /* Date Modified: 2022/Feb/07                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: removed italic in titles by adding ^{style[font_style=roman]}                           */
 /*                                                                                                  */
 /* Date Modified: 2022/Mar/16                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: Updated varicella report                                                                */
 /*  			Only include legacy and nmi                                                              */
 /*                                                                                                  */
 /* Date Modified: 2022/Mar/16                                                                       */
 /* Modified by: Jodi Baldy                                                                          */
 /* Changes: Updated varicella footnote re: data sources                                             */
 /*                                                                                                  */
 /* Date Modified: 2022/Mar/18                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: Updated the code of 'New York City' from 975771 to 975772                               */
 /*                                                                                                  */
 /* Date Modified: 2022/Mar/21                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: Updated mumps report: convert *** (values less than -1000) to NA                        */
 /*          for Median Number of Days from Symptom Onset to Public Health Report                    */
 /*                                                                                                  */
 /* Date Modified: 2022/Mar/22                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: applied the Mar/21 change to Measles, Rubella and Pertussis                             */
 /*                                                                                                  */ 
 /* Date Modified: 2022/Mar/23                                                                       */
 /* Modified by: Jodi Baldy                                                                          */
 /* Changes: added footnote for NA=not available (MMR & pert)                                        */   
 /*                                                                                                  */
 /* Date Mofified: 2022/Apr/5                                                                        */
 /* Modified by: Jodi Baldy                                                                          */
 /* Changes: corrected footnote for Hflu for completeness of 3 variables                             */ 
 /*                                                                                                  */
 /* Date Mofified: 2022/Apr/6                                                                        */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: -	Add a group name “Percent of Cases < 5 Years of Age with Vaccine History”             */  
 /*          -	Add Virgule † is for the Vaccine Name Not Required and ? is for Vaccine Name Required */                     
 /*                                                                                                  */
 /* Date Mofified: 2022/Apr/8                                                                        */
 /* Modified by: Ying Shen with Pam and Jodi                                                         */
 /* Changes: - remove NA for median # days if there is no cases for measles, mumps, rebella and      */  
 /*          pertussis                                                                               */
 /*          - (measlesMedianRepInt < -1000 and measlesMedianRepInt is not null)                     */
 /*          - added format=8.0 in median # days to measles, mumps, rebella and pertussis            */
 /*          - re-sequenced the table numbers                                                        */
 /*                                                                                                  */
 /* Date Mofified: 2022/Jun/8                                                                        */
 /* Modified by: Ying Shen                                                                           */
 /* Changes: - convert 0 to . for oth indicators if there is no cases for pertussis, mumps,          */
 /*          rubella and measles                                                                     */
 /*                                                                                                  */
 /* Date Mofified: 2022/Jun/13                                                                        */
 /* Modified by: Ying Shen                                                                           */
 /*              - If there is a sub-category, then if the sub-category is 0,                        */
 /*                the related indicators should be blank                                            */
 /*                this applied to h_flu, pertussis and IPD)                                         */
 /*              - The number of cases <5 should be “0” if it’s blank                                */
 /*		          (for IPD as well as hflu and pertussis)                                           */
 /*              - Fix Rubella decimal issue and only keep whole numbers                             */
 /*                Examed and fixed all indicators and make sure all indicators have whole numbers   */
 /*                                                                                                  */
 /* Date Mofified: 2022/Jun/14                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /*              Removed formats for mean and median (format = $3. ) for MMR and pertussis           */
 /*              in proc reports                                                                     */
 /*                                                                                                  */
 /* Date Mofified: 2022/Jun/21                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /*              Code blank to NA for Measles, Mumps, Rubella and Pertussis                          */
 /*                                                                                                  */
 /* Date Mofified: 2023/Mar/16                                                                       */
 /* Modified by: Ying Shen                                                                           */
 /*				  Add the Number of Female as an indicator: RubellaNumFemale                          */
 /*				  Add a column to the RUBELLA Surveillance Indicator National Report for              */
 /*                  “% Female Cases with Known Pregnancy Status”                                    */
 /* Modified by: Linda Baldy
				  Add virgule to column "% Female Cases with Known Pregnancy Status§"				 */
 /*				  Add foornote "§Includes female cases with known pregnancy (Y/N) status"            */
                                                           
 /****************************************************************************************************/
     
/*%Let StartYear = 2016 ; */
/*%Let EndYear = 2018 ;*/
/*%Let Folder = 2018Currentdata.files ; *use naming convention, e.g., 2017Wk52data.files;*/
/*%Let Today = 4/28/19; *enter today's date using convention MM/DD/YY;*/
/*%Let Today = today();*/
/*%Let FilePath = \\cdc\project\NIP_Project_Store1\surveillance\\Surveillance_Indicators_NNAD ;*/

/*-------------------------------------------------------------------------------
This is the macro that creates a separate Word file (.rtf) for each State or the
entire US.  There is a separate page for each condition.                          
-------------------------------------------------------------------------------*/

*libname IndRpts "&FilePath\Data\&Folder" ;
*Libname IndFmts "&FilePath\Data" ;
*libname library "\\cdc\csp_project\NCPHI_DISSS_NNDSS_NCIRD" access=readonly;

*options fmtsearch=(IndFmts library Work) ;
options nofmterr missing=' ' ; 
options nodate nonumber ; * suppress printing date and page number at top of output ;
options orientation=landscape ; 

/*Define Indrpts libref;*/
libname IndRpts "&FilePath\Data\&Folder" ;

PROC FORMAT;

VALUE STATE      
0='Total' 
1='Alabama'                                                    
2='Alaska'                                                     
4='Arizona'                                                    
5='Arkansas'                                                   
6='California'                                                 
8='Colorado'                                                   
9='Connecticut'                                                
10='Delaware'                                                   
11='Dist of Columbia'                                           
12='Florida'                                                    
13='Georgia'                                                    
15='Hawaii'                                                     
16='Idaho'                                                      
17='Illinois'                                                   
18='Indiana'                                                    
19='Iowa'                                                       
20='Kansas'                                                     
21='Kentucky'                                                   
22='Louisiana'                                                  
23='Maine'                                                      
24='Maryland'                                                   
25='Massachusetts'                                              
26='Michigan'                                                   
27='Minnesota'                                                  
28='Mississippi'                                                
29='Missouri'                                                   
30='Montana'                                                    
31='Nebraska'                                                   
32='Nevada'                                                     
33='New Hampshire'                                              
34='New Jersey'                                                 
35='New Mexico'                                                 
36='New York'                                                   
37='North Carolina'                                                 
38='North Dakota'                                                   
39='Ohio'                                                       
40='Oklahoma'                                                   
41='Oregon'                                                     
42='Pennsylvania'                                               
44='Rhode Island'                                               
45='South Carolina'                                                 
46='South Dakota'                                                   
47='Tennessee'                                                  
48='Texas'                                                      
49='Utah'                                                       
50='Vermont'                                                    
51='Virginia'                                                   
53='Washington'                                                 
54='West Virginia'                                                 
55='Wisconsin'                                                  
56='Wyoming'                                                    

60='American Samoa'                                                   				
66='Guam'                                                       
69='Northern Marianna Islands'                                          
975772='New York City'                                              
72='Puerto Rico'                                                                
75='Chicago'                                                                    
78='Virgin Islands';

value pctcomp 
low-<0 = 'NA'  /* negative numbers get a NA */
0='0' 
0<-<1 = '0'
1-high=[3.]
;
run ;

/*----------------------------------------------------------------------------
http://support.sas.com/resources/papers/stylesinprocs.pdf 
The STYLE= option uses six different location values to identify the part of 
the report that the option affects. The 3 used here in this report are:  
values and their associated default style elements follow:
 REPORTDenotes the structural, or underlying, part of the report. Default style element: Table
 COLUMNDenotes the cells in all the columns. Default style element: Data
 HEADERDenotes all column headers, including spanned headers. Default style element: Header
----------------------------------------------------------------------------*/

%Macro ReportStyle(FS=10pt) ;
style(report) = {borderwidth=1 cellpadding=2 cellspacing=0 background=White }
style(header) = {borderwidth=2 cellpadding=2 cellspacing=0 background=White 
      font_size=&FS font_face="TimesNewRoman" font_weight=bold }
style(column) = {borderwidth=2 cellpadding=2 cellspacing=0 background=White 
      font_size=&FS font_face="TimesNewRoman" }

;
%Mend ReportStyle ;


%macro doReport(State=) ;
ods _all_ close ;

%put Note: State = &State ;

%If &State = 0 %Then %Let StateName = National Summary;
%else %Let StateName = %sysfunc(putn(&State,state.)) ;
%put StateName = &StateName ;

%Let footnotetext = *** Current 2022 data (12/6/23) ;

%Let FootnoteOptions = j=left height=3 color=black font="times new roman" ;

ods path IndFmts.templates(update) sashelp.tmplmst(read) ;
ods rtf file="&FilePath\Output\&Folder\&StateName Indicator Reports &StartYear - &EndYear..rtf" Style=RTF BodyTitle ;

ods escapechar = '^' ;
title " " ;

title1 bold "^{style[font_style=roman]&StateName.}"; 
title2 bold "^{style[font_style=roman]Surveillance Indicators for Measles, Mumps, Rubella, Pertussis, H. influenzae, Meningococcal Disease,}" ;
title3 bold "^{style[font_style=roman]Invasive Pneumococcal Disease, and Varicella &StartYear.-&EndYear***}" ;

/*-------------------------------------------------------------------------------
Some states won't have cases for every year.  To ensure that they output for each
year, merge in data for each year so there's a row even if there are no cases for
that particular year.  
-------------------------------------------------------------------------------*/
data states ;
	format state state. ;
    do year = &StartYear to &EndYear ;
	 do state = &State ;
     	if state in (3,7,14,43,52,71-975771) then continue ; * these state codes are not defined ;
        if state le 56 or state = 975772 then output ;
	 end ;
    end ;
Run ;

Proc Sort data=States ;
     by Year ;
     run ;

/*-------------------------------------------------------------------------------
Measles
-------------------------------------------------------------------------------*/

/*Check if there is abnormal public health report date, if so, name is NA*/
proc sql;
create table measles_HL7_R1 as 
select *
,case 
when (measlesMedianRepInt < -1000 and measlesMedianRepInt is not null) then -100000
else measlesMedianRepInt
end as measlesMedianRepInt_R format=8.0
from IndRpts.measles_HL7;
quit;

data measles_HL7_R2;
	set measles_HL7_R1;
	newvar=vvalue(measlesMedianRepInt_R);/*Convert numeric MumpsMedianRepInt to character to check NA*/
	drop measlesMedianRepInt_R;
	rename newvar=measlesMedianRepInt_R;
run;

proc sql;
create table measles_HL7_R3 as 
select *
,case 
when measlesMedianRepInt_R like "%-100000%" then "NA"
when measlesMedianRepInt_R ="" and measlesCases ne 0 then "NA"
when measlesCases = 0 then ""
else measlesMedianRepInt_R
end as measlesMedianRepInt_R3
,case 
when measlesCases = 0 then .
else measlesPctComp10
end as measlesPctComp10_R
,case 
when measlesCases = 0 then .
else measlesPctConf
end as measlesPctConf_R
,case 
when measlesCases = 0 then .
else measlesImportPct
end as measlesImportPct_R
from measles_HL7_R2;
quit;

ods escapechar = '^' ;
Proc report data = measles_HL7_R3 nowd split='~' %ReportStyle(FS=11pt) ;
where state = &state; 
column ('Table 1.  Surveillance Indicators for Measles¶' Year measlesCases measlesPctComp10_R measlesMedianRepInt_R3 measlesPctConf_R measlesImportPct_R);

define Year/ display ' ' center style(column)={width=0.5in};
define measlesCases/ display "Number of Cases*" center format=comma6. style(column)={width=0.6in};
define measlesPctComp10_R/ display "Percent Completeness of Information for 10 Key~Variables **" center format = 3. style(column)={width=1.25in};
define measlesMedianRepInt_R3/ display "Median Number of Days from Symptom Onset to Public Health Report" center style(column)={width=1.5in};
define measlesPctConf_R/ display "Percent of Confirmed Cases that are Lab Confirmed" center format = 3. style(column)={width=1.25in};
/*define MumpsNumMeetClin / display "Cases Meeting Clinical Case Definition"   center  format=comma6. ;*/
/*define MumpsPctClinTest / display 'Percent of Clinically Compatible Cases with Lab Test'   center format=3. ;*/
define measlesImportPct_R/ display "Percent of Cases with Imported Source" center format = 3. style(column)={width=1.25in};
/*define MumpsPctVaxCompNVN / display "Vaccine Manufacturer^{dagger} Name Not Required" center format=pctcomp. ;*/
/*define MumpsPctVaxComp / display "Vaccine Manufacturer‡ Name Required" center format=pctcomp. style(header)={cellwidth=1.2in}; */

/*----------------------------------------------------------------------------
	Measles Footnotes differ between National and States Reports. 
	----------------------------------------------------------------------------*/
	footnote1 &Footnoteoptions "* Confirmed and unknown case status; unknown values are valid and missing values are invalid" ;
	footnote2 &footnoteoptions "** Clinical case definition, hospitalization, lab testing, vaccine information, "
	"date reported to health department, transmission setting, outbreak related, epidemiologic linkage, date of birth, and onset date" ;
	footnote3 &footnoteoptions "&Footnotetext" ;
	footnote4 &footnoteoptions "NA = not available" ; 
	footnote5 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote6 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 
	%If &State = 0 %Then %Do ;
	footnote7 &footnoteoptions "Genotype testing completed at CDC or at the four Vaccine-Preventable Disease Reference Centers: 58% in 2016, 80% in 2017, 55% in 2018, "
    "55% in 2019, 69% in 2020, 92% in 2021, and 79% in 2022." ;
	%End;

Run ;   /* End of measles */


/*-------------------------------------------------------------------------------
Mumps
-------------------------------------------------------------------------------*/

/*Check if there is abnormal public health report date, if so, name is NA*/
proc sql;
create table Mumps_HL7_R1 as 
select *
,case 
when  (MumpsMedianRepInt < -1000 and MumpsMedianRepInt is not null) then -100000
else MumpsMedianRepInt
end as MumpsMedianRepInt_R format=8.0
from IndRpts.Mumps_HL7;
quit;

data Mumps_HL7_R2;
	set Mumps_HL7_R1;
	newvar=vvalue(MumpsMedianRepInt_R);/*Convert numeric MumpsMedianRepInt to character to check NA*/
	drop MumpsMedianRepInt_R;
	rename newvar=MumpsMedianRepInt_R;
run;

proc sql;
create table Mumps_HL7_R3 as 
select *
,case 
when MumpsMedianRepInt_R like "%-100000%" then "NA"
when MumpsMedianRepInt_R ="" and MumpsCases ne 0 then "NA"
when MumpsCases = 0 then ""
else MumpsMedianRepInt_R
end as MumpsMedianRepInt_R3
,case 
when MumpsCases = 0 then .
else MumpsPctComp10
end as MumpsPctComp10_R
,case 
when MumpsCases = 0 then .
else MumpsPctConf
end as MumpsPctConf_R
,case 
when MumpsCases = 0 then .
else MumpsImportPct
end as MumpsImportPct_R
from Mumps_HL7_R2;
quit;


/*Proc report to generate and output report*/
ods escapechar = '^' ;
Proc report data = Mumps_HL7_R3 nowd split='~' %ReportStyle(FS=11pt) ;
where state = &state; 
column ('Table 2.  Surveillance Indicators for Mumps¶' Year MumpsCases MumpsPctComp10_R MumpsMedianRepInt_R3 MumpsPctConf_R MumpsImportPct_R);

define Year/ display ' ' center style(column)={width=0.5in};
define MumpsCases/ display "Number of Cases*" center format=comma6. style(column)={width=0.6in};
define MumpsPctComp10_R/ display "Percent Completeness of Information for 10 Key~Variables **" center format = 3. style(column)={width=1.25in};
define MumpsMedianRepInt_R3/ display "Median Number of Days from Symptom Onset to Public Health Report" center style(column)={width=1.5in};
define MumpsPctConf_R/ display "Percent of Confirmed Cases that are Lab Confirmed" center format = 3. style(column)={width=1.25in};
/*define MumpsNumMeetClin / display "Cases Meeting Clinical Case Definition"   center  format=comma6. ;*/
/*define MumpsPctClinTest / display 'Percent of Clinically Compatible Cases with Lab Test'   center format=3. ;*/
define MumpsImportPct_R/ display "Percent of Cases with Imported Source" center format = 3. style(column)={width=1.25in};
/*define MumpsPctVaxCompNVN / display "Vaccine Manufacturer^{dagger} Name Not Required" center format=pctcomp. ;*/
/*define MumpsPctVaxComp / display "Vaccine Manufacturer‡ Name Required" center format=pctcomp. style(header)={cellwidth=1.2in}; */
footnote1 &Footnoteoptions "* Confirmed, probable, and unknown case status; unknown values are valid and missing values are invalid." ;
footnote2 &footnoteoptions "** Includes clinical case definition, hospitalization, lab testing, vaccine information, date reported to health department, transmission setting, outbreak related, epidemiologic linkage, date of birth, and onset date." ;
footnote3 &footnoteoptions "&Footnotetext" ; 
footnote4 &footnoteoptions "NA = not available" ;
%If &State = 0 %Then %Do ;
footnote5 &Footnoteoptions "From 2016-2022, an average of 41% of mumps cases were reported as confirmed; 53% in 2016, 58% in 2017, 51% in 2018, 54% in 2019, 51% in 2020, 11% in 2021, and 7% in 2022." ;                                                      
%end ;
footnote6 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted , NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote7 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 
Run ;   /* End of mumps */
 

/*-------------------------------------------------------------------------------
Rubella
-------------------------------------------------------------------------------*/

/*Check if there is abnormal public health report date, if so, name is NA*/
proc sql;
create table rubella_HL7_R1 as 
select *
,case 
when (rubellaMedianRepInt < -1000 and rubellaMedianRepInt is not null) then -100000
else rubellaMedianRepInt
end as rubellaMedianRepInt_R format=8.0
from IndRpts.rubella_HL7;
quit;

data rubella_HL7_R2;
	set rubella_HL7_R1;
	newvar=vvalue(rubellaMedianRepInt_R);/*Convert numeric MumpsMedianRepInt to character to check NA*/
	drop rubellaMedianRepInt_R;
	rename newvar=rubellaMedianRepInt_R;
run;

proc sql;
create table rubella_HL7_R3 as 
select *
,case 
when rubellaMedianRepInt_R like "%-100000%" then "NA"
when rubellaMedianRepInt_R ="" and rubellaCases ne 0 then "NA"
when rubellaCases = 0 then ""
else rubellaMedianRepInt_R
end as rubellaMedianRepInt_R3
,case 
when rubellaCases = 0 then .
else rubellaPctComp10
end as rubellaPctComp10_R
,case 
when rubellaCases = 0 then .
else rubellaPctConf
end as rubellaPctConf_R
,case 
when rubellaCases = 0 then .
else rubellaImportPct
end as rubellaImportPct_R
from rubella_HL7_R2;
quit;


ods escapechar = '^' ;
Proc report data = rubella_HL7_R3 nowd split='~' %ReportStyle(FS=11pt) ;
where state = &state; 
column ('Table 3.  Surveillance Indicators for Rubella¶' Year rubellaCases rubellaPctComp10_R rubellaMedianRepInt_R3 rubellaPctConf_R rubellaImportPct_R RubellaNumFemale rubellaPregStatusPct);

define Year/ display ' ' center style(column)={width=0.5in};
define rubellaCases/ display "Number of Cases*" center format=comma6. style(column)={width=0.6in};
define rubellaPctComp10_R/ display "Percent Completeness of Information for 10 Key~Variables **" center format = 3. style(column)={width=1.25in};
define rubellaMedianRepInt_R3/ display "Median Number of Days from Symptom Onset to Public Health Report" center style(column)={width=1.5in};
define rubellaPctConf_R/ display "Percent of Confirmed Cases that are Lab Confirmed" center format = 3. style(column)={width=1.25in};
define rubellaImportPct_R/ display "Percent of Cases with Imported Source" center format = 3. style(column)={width=1.25in};
define RubellaNumFemale/ display "Number of Female Cases" center format = 3. style(column)={width=1.25in};
define rubellaPregStatusPct/ display "% Female Cases with Known Pregnancy Status§" center format = 3. style(column)={width=1.25in};

footnote1 &Footnoteoptions "* Confirmed, probable, and unknown case status; unknown values are valid and missing values are invalid." ;
footnote2 &footnoteoptions "** Includes clinical case definition, hospitalization, lab testing, vaccine information, date reported to health department, transmission setting, outbreak related, epidemiologic linkage, date of birth, and onset date." ;
footnote3 &footnoteoptions "&Footnotetext" ; 
footnote4 &footnoteoptions "§Includes female cases with known pregnancy (Y/N) status." ;
footnote5 &footnoteoptions "NA = not available" ;
footnote6 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote7 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 
Run ; /* End of rubella */ 


/*-------------------------------------------------------------------------------
H_influenzae
-------------------------------------------------------------------------------*/
proc sql;
create table hflu_hl7_R as 
select *
,case 
when Numcases = 0 then .
else MeanComplete
end as MeanComplete_R
/*The number of cases <5 should be “0” if it’s blank*/
,case 
when Numcases = 0 then .
when (Numcases ^=0 and NumcasesLT5 =.) then 0
else NumcasesLT5
end as NumcasesLT5_R
,case 
when Numcases = 0 then .
else SeroAllLT5Pct
end as SeroAllLT5Pct_R

/*If there is a sub-category, then if the sub-category is 0, the related indicators should be blank*/
/*(h_flu, pertussis and IPD)*/
,case 
when NumcasesLT5 = 0 then .
else ComplVacNVNPct
end as ComplVacNVNPct_R
,case 
when NumcasesLT5 = 0 then .
else ComplVacPCT
end as ComplVacPCT_R
from IndRpts.HFlu;
quit;


ods escapechar = '^' ;
Proc report data = hflu_hl7_R nowd split='~' %ReportStyle(FS=11pt) ;
where state = &state; 
column ('Table 4.  Surveillance Indicators for H. influenzae¶' Year Numcases MeanComplete_R NumcasesLT5_R SeroAllLT5Pct_R("Percent of Cases < 5 Years of Age with Complete Vaccine History" ComplVacNVNPct_R ComplVacPCT_R));

define Year/ display ' ' center style(column)={width=0.5in};
define Numcases/ display "Total Cases*" center format=comma6. style(column)={width=0.6in};
define MeanComplete_R/ display "Percent Completeness of Information for 3 Key Variables **" center format = 3. style(column)={width=1.25in};
define NumcasesLT5_R/ display "Cases < 5 Years of Age" center format = 3. style(column)={width=1.5in};
define SeroAllLT5Pct_R/ display "Percent of Cases < 5 Years of Age with Serotype Testing" center format = 3. style(column)={width=1.5in};
define ComplVacNVNPct_R/ display "Vaccine Name^{dagger}~ Not Required" center format = 3. style(column)={width=1.25in};
define ComplVacPCT_R/ display "Vaccine Name‡~ Required" center format = 3. style(column)={width=1.25in};

footnote1 &Footnoteoptions "* Confirmed, probable, and unknown case status; unknown values are valid and missing values are invalid." ;
footnote2 &footnoteoptions "** Includes clinical case definition, serotype, and vaccine information." ;
footnote3 &FootnoteOptions "^{dagger}does not include vaccine manufacturer name as a required variable.  ‡includes vaccine manufacturer name as a required variable." ;
footnote4 &footnoteoptions "&Footnotetext" ; 
footnote5 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote6 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 
Run ;   /* End of H_influenzae */


/*-------------------------------------------------------------------------------
Pertussis
-------------------------------------------------------------------------------*/
/*Check if there is abnormal public health report date, if so, name is NA*/
proc sql;
create table Pertussis_HL7_R1 as 
select *
,case 
when (PertMeanRepInt < -1000 and PertMeanRepInt is not null) then -100000
else PertMeanRepInt
end as PertMeanRepInt_R format=8.0
from IndRpts.Pertussis_HL7;
quit;

data Pertussis_HL7_R2;
	set Pertussis_HL7_R1;
	newvar=vvalue(PertMeanRepInt_R);/*Convert numeric MumpsMedianRepInt to character to check NA*/
	drop PertMeanRepInt_R;
	rename newvar=PertMeanRepInt_R;
run;

proc sql;
create table Pertussis_HL7_R3 as 
select *
,case 
when PertMeanRepInt_R like "%-100000%" then "NA"
when PertMeanRepInt_R ="" and PertCases ne 0 then "NA"
when PertCases = 0 then ""
else PertMeanRepInt_R
end as PertMeanRepInt_R3
,case 
when PertCases = 0 then .
else PertPctComp6
end as PertPctComp6_R
,case 
when PertCases = 0 then .
else PertPctVaxCompNVN
end as PertPctVaxCompNVN_R
,case 
when PertCases = 0 then .
else PertPctVaxComp
end as PertPctVaxComp_R
,case 
when PertCases = 0 then .
else PertNumMeetClin
end as PertNumMeetClin_R
,case 
when PertCases = 0 then .
else PertPctClinTest
end as PertPctClinTest_R
/*The number of cases <5 should be “0” if it’s blank*/
,case 
when PertCases = 0 then .
when (PertCases ^=0 and PertCases =.) then 0
else PertCasesu7
end as PertCasesu7_R

/*If there is a sub-category, then if the sub-category is 0, the related indicators should be blank*/
/*(h_flu, pertussis and IPD)*/
,case 
when PertCasesu7 = 0 then .
else PertPctVaxCompNVNu7
end as PertPctVaxCompNVNu7_R
,case 
when PertCasesu7 = 0 then .
else PertPctVaxCompu7
end as PertPctVaxCompu7_R
from Pertussis_HL7_R2;
quit;



ods rtf startpage=now ; * force a pagebreak ;
ods escapechar = '^' ;
proc report data=Pertussis_HL7_R3 nowd split='~'  %ReportStyle(FS=11pt) ; 
where state = &State ;
column ('Table 5.  Surveillance Indicators for Pertussis¶'  Year PertCases PertPctComp6_R PertMeanRepInt_R3 
       ("Percent of All Cases with ~Complete Vaccine History" PertPctVaxCompNVN_R PertPctVaxComp_R)
        PertNumMeetClin_R PertPctClinTest_R PertCasesu7_R 
	   ("Percent of Cases < 7 Years of Age with Complete Vaccine History" PertPctVaxCompNVNu7_R PertPctVaxCompu7_R)); 

define Year/ display ' ' center  ;
define PertCases / display "Total~Cases*" center format=comma6.;
define PertPctComp6_R / display "Percent Completeness of Information for 6 Key** Variables"   center format=3.;
define PertMeanRepInt_R3 / display "Mean Number of Days from Symptom Onset to Public Health Report" center style(header)={cellwidth=1.2in}; * style statement widens header cell and reduces overall length of report ;
define PertPctVaxCompNVN_R / display "Vaccine Manufacturer^{dagger} Name Not Required"   center format=pctcomp. ;
define PertPctVaxComp_R / display "Vaccine Manufacturer‡ Name Required"   center format=pctcomp. style(header)={cellwidth=1.2in};
define PertNumMeetClin_R / display "Cases Meeting Clinical Case Definition"   center  format=comma6. ;
define PertPctClinTest_R / display 'Percent of Clinically Compatible Cases with Lab Test'   center format=3. ;
define PertCasesu7_R / display "Cases < 7 Years of Age"   center format=comma6. ;
define PertPctVaxCompNVNu7_R / display "Vaccine Manufacturer^{dagger} Name Not Required"   center format=pctcomp. ;
define PertPctVaxCompu7_R / display "Vaccine Manufacturer‡ Name Required"   center format=pctcomp. style(header)={cellwidth=1.2in}; 
footnote1 &footnoteoptions "* Includes confirmed, probable, and unknown case status; unknown values are valid and missing values are invalid." ;
footnote2 &footnoteoptions "** Includes clinical case definition, hospitalization/complications, antibiotic treatment, laboratory testing, vaccine information, and epidemiologic data." ;
footnote3 &FootnoteOptions "^{dagger}does not include vaccine manufacturer name as a required variable.  ‡includes vaccine manufacturer name as a required variable." ;
footnote4 &footnoteoptions "&Footnotetext" ;
footnote5 &footnoteoptions "NA = not available" ;
%If &State = 0 %Then %Do ;
footnote6 &footnoteoptions "From 2016-2022, an average of 57% of pertussis cases were reported as confirmed; " 
                           "76% in 2016, 76% in 2017, 76% in 2018, 75% in 2019, 73% in 2020, 41% in 2021, and 50% in 2022." ;
%end ;
footnote7 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote8 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 

run ; /* end of Pertussis */


/*-------------------------------------------------------------------------------
Meningococcal Disease
-------------------------------------------------------------------------------*/
ods escapechar = '^' ;
Proc report data = indrpts.Mening nowd split='~' %ReportStyle(FS=11pt) ;
where state = &state; 
column ('Table 6.  Surveillance Indicators for Meningococcal Disease¶' Year Numcases MeanComplete NumConfirmed Pct_Known Pct_Sero
("Percent of Cases with ~Complete Vaccine History" Pct_ComplNVN Pct_Complete));

define Year/ display ' ' center 
						style(column)={width=1.25in};
define Numcases / display "Total~Cases*" center  format=comma6.  
						style(column)={width=1.25in};
define MeanComplete / display "Percent Completeness of Information ~for 2 Key**~ Variables" center format=3. 
                       style(column)={width=1.25in};
define NumConfirmed / display "Number of~Confirmed~Cases"   center format=comma6. 
                       style(column)={width=1.25in};
define Pct_Known / display 'Percent of Cases~with Known~Outcome' format=3.   center
                       style(column)={width=1.25in};
Define Pct_Sero / display 'Percent of~Confirmed Cases~with Serogroup~Testing' format=3. center   
                       style(column)={width=1.25in};
define Pct_ComplNVN / display "Vaccine Name^{dagger}~ Not Required" format=pctcomp. center 
style(header)={cellwidth=1.25in}; 
define Pct_Complete / display "Vaccine Name‡~ Required" format=pctcomp. center  
style(header)={cellwidth=1.25in};  ;
footnote1 &Footnoteoptions "* Confirmed, probable, and unknown case status; unknown values are valid and missing values are invalid." ;
footnote2 &footnoteoptions "** Includes birthdate/age, and event date." ;
footnote3 &FootnoteOptions "^{dagger}does not include vaccine manufacturer name as a required variable.  ‡includes vaccine manufacturer name as a required variable." ;
footnote4 &footnoteoptions "&Footnotetext" ; 
footnote5 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote6 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 
Run ;    /* End of Meningococcal Disease */


/*-------------------------------------------------------------------------------
Invasive Pneumococcal Disease (aka IPD)                                                                  
-------------------------------------------------------------------------------*/
proc sql;
create table ipd_hl7_R as 
select *
,case 
when Numcases = 0 then .
else MeanComplete
end as MeanComplete_R
,case 
when Numcases = 0 then .
else Pct_Sero
end as Pct_Sero_R
,case 
when Numcases = 0 then .
else Pct_ComplNVN
end as Pct_ComplNVN_R

,case 
when Numcases = 0 then .
else Pct_Complete
end as Pct_Complete_R
/*The number of cases <5 should be “0” if it’s blank*/
,case 
when Numcases = 0 then .
when (Numcases ^=0 and Numcases5 =.) then 0
else Numcases5
end as Numcases5_R

/*If there is a sub-category, then if the sub-category is 0, the related indicators should be blank*/
/*(h_flu, pertussis and IPD)*/
,case 
when (Numcases5 = 0 or Numcases5 =.) then .
else Pct_Sero5
end as Pct_Sero5_R
,case 
when (Numcases5 = 0 or Numcases5 =.) then .
else Pct_ComplNVN5
end as Pct_ComplNVN5_R
,case 
when (Numcases5 = 0 or Numcases5 =.) then .
else Pct_Complete5
end as Pct_Complete5_R

from IndRpts.IPD;
quit;



ods rtf startpage=now ;
ods escapechar='^' ;
proc report data=ipd_hl7_R nowd split='~' %ReportStyle(FS=11pt) ;
where state = &State ;
column ('Table 7.  Surveillance Indicators for Invasive Pneumococcal Disease¶' 
      Year Numcases MeanComplete_R Pct_Sero_R 
      ("Percent of All Cases with ~Complete Vaccine History" Pct_ComplNVN_R Pct_Complete_R)
	  numcases5_R pct_sero5_R ("Percent of Cases < 5 Years of Age with Complete Vaccine History" pct_complNVN5_R Pct_complete5_R)
)
; 

define Year/ display ' ' center  ;
define Numcases / display "Total~Cases*"   center  format=comma6.;
define MeanComplete_R / display "Percent~Completeness~of Information for 3 Key**~Variables"   center format=3. 
     style(header)={cellwidth=1.2in};
*define NumConfirmed / display "Number of~Confirmed~Cases"   center format=comma6. ;
Define Pct_Sero_R / display 'Percent of~Confirmed Cases~with Serotype~Testing' format=3. center
     style(header)={cellwidth=1.2in};
define Pct_ComplNVN_R / display "Vaccine Name^{dagger}~ Not Required" center format=pctcomp. 
     style(header)={cellwidth=1.2in}; ;
define Pct_Complete_R / display "Vaccine Name‡~ Required"  center   format=pctcomp.
     style(header)={cellwidth=1.2in}; ;

define Numcases5_R / display "Cases < 5 Years of Age"   center  format=comma6.
     style(header)={cellwidth=.8in};
Define Pct_Sero5_R / display 'Percent of Confirmed Cases < 5 Years of Age with Serotype Testing' format=3. center  
     style(header)={cellwidth=1.2in};
define Pct_ComplNVN5_R / display "Vaccine Name^{dagger}~ Not Required" center format=pctcomp. 
     style(header)={cellwidth=1.2in} ;
define Pct_Complete5_R / display "Vaccine Name‡~ Required"  center   format=pctcomp.
     style(header)={cellwidth=1.2in};


footnote1 &FootnoteOptions "* For event code 11723, includes confirmed case status (cases prior to 2017) and confirmed and probable case status (cases 2017 forward); "
"unknown values are valid and missing values are invalid; "
"includes all notifications sent to CDC through NNDSS and therefore may include cases not published online (e.g., MMWR, CDC WONDER [https://wonder.cdc.gov])."  ;
footnote2 &FootnoteOptions "** Clinical case definition (e.g., specimen type), serotype, vaccine information" ;
footnote3 &FootnoteOptions "^{dagger}Does not include vaccine name as a required variable.  ‡Includes vaccine name as a required variable." ;
footnote4 &footnoteoptions "&Footnotetext" ;
footnote5 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote6 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ;  

run ; /* End of IPD */


/*----------------------------------------------------------------------------
Varicella
----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------
Combine the Legacy and NMI versions of the Varicella data into one dataset.  
----------------------------------------------------------------------------*/

/*proc sort data=IndRpts.Varicella_legacy ; by Year State ; run ;*/
/*proc sort data=IndRpts.Varicella_nmi ; by Year State ; run ;*/

data Varicella_both ;
     merge IndRpts.Varicella_legacy (in=h)
		   IndRpts.Varicella_nmi (in=h_nmi);
     by Year State ;
 run ; 

ods rtf startpage=now ;
ods escapechar='^' ;

Proc Report data=Varicella_Both nowd  split='~' %ReportStyle(FS=10pt) ;
where state = &state ;
column ('Table 8.  Surveillance Indicators for Varicella¶' 
      Year  
		('Total~Cases*'  NumCases_HL7 NumCases_nmi) 
		('Percent of Cases with Complete Information on Age'  AgePct_HL7 AgePct_nmi) 
      ('Percent of Cases with Complete Information on Number of Lesions'  LesionsPct_HL7 LesionsPct_nmi)
      ('Percent of Cases with Complete Information on Hospitalization'  HospPct_HL7 HospPct_nmi) 
      ('Percent of Cases Confirmed' CaseConfirmedPct_HL7 CaseConfirmedPct_nmi) 
      ('Percent of Cases with Laboratory Testing' LabTestsPct_HL7 LabTestsPct_nmi) 
      ('Percent of Cases Related to Outbreaks' OutbreakPct_HL7 OutbreakPct_nmi) 
      ("Percent of Cases with Complete^{dagger}~ Information on Vaccine History" VacHistoryPct_HL7 VacHistoryPct_nmi) 
)
; 
define Year/ display ' ' center format=6. ;

define NumCases_HL7 / display  'LEGACY' center format=comma6.;;
define NumCases_NMI / display  'DMI' center format=comma6. ;;

define AgePct_HL7 / display  'LEGACY' center format=3. ;;
define AgePct_nmi / display  'DMI' center format=3. ;;

Define LesionsPct_HL7 / display 'LEGACY' center format=3. ;;
Define LesionsPct_nmi / display 'DMI' center format=3. ;;

define HospPct_HL7 / display 'LEGACY' center  format=3. ;;
Define HospPct_nmi / display 'DMI' center format=3. ;;

define CaseConfirmedPct_HL7 / display 'LEGACY' center  format=3.;;
Define CaseConfirmedPct_nmi / display 'DMI' center format=3. ;;

define LabTestsPct_HL7 / display 'LEGACY' center  format=3. ;;  
Define LabTestsPct_nmi / display 'DMI' center format=3. ;; 

define OutbreakPct_HL7 / display 'LEGACY' center format=3. ;;
Define OutbreakPct_nmi / display 'DMI' center format=3. ;;

Define VacHistoryPct_HL7 / display 'LEGACY' center format=3.;;
Define VacHistoryPct_nmi / display 'DMI' center format=3. ;;

/*----------------------------------------------------------------------------
Footnotes are the same for both National and State Varicella Reports
----------------------------------------------------------------------------*/
footnote1 &footnoteoptions "* Confirmed and probable case status; unknown and missing values are invalid; " 
"'LEGACY' includes cases and data found in legacy varicella message mapping guide; 'DMI' includes cases and data found in NETSS and varicella v3 "
"message mapping guide" ;
footnote2 &FootnoteOptions "^{dagger}Vaccine name/manufacturer is not required." ;
footnote3 &footnoteoptions "&Footnotetext" ;
footnote4 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote5 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 

run ; /* End of Varicella */


ods _All_ close ;
%mend doReport ;


/*-------------------------------------------------------------------------------
Run the macro separately for each state and for the entire US.  A separate Excel
will be created.  
-------------------------------------------------------------------------------*/
%DoReport(State=0 );
%DoReport(State=1 );
%DoReport(State=2 );
%DoReport(State=4 );
%DoReport(State=5 );
%DoReport(State=6 );
%DoReport(State=8 );
%DoReport(State=9 );
%DoReport(State=10 );
%DoReport(State=11 );
%DoReport(State=12 );
%DoReport(State=13 );
%DoReport(State=15 );
%DoReport(State=16 );
%DoReport(State=17 );
%DoReport(State=18 );
%DoReport(State=19 );
%DoReport(State=20 );
%DoReport(State=21 );
%DoReport(State=22 );
%DoReport(State=23 );
%DoReport(State=24 );
%DoReport(State=25 );
%DoReport(State=26 );
%DoReport(State=27 );
%DoReport(State=28 );
%DoReport(State=29 );
%DoReport(State=30 );
%DoReport(State=31 );
%DoReport(State=32 );
%DoReport(State=33 );
%DoReport(State=34 );
%DoReport(State=35 );
%DoReport(State=36 );
%DoReport(State=37 );
%DoReport(State=38 );
%DoReport(State=39 );
%DoReport(State=40 );
%DoReport(State=41 );
%DoReport(State=42 );
%DoReport(State=44 );
%DoReport(State=45 );
%DoReport(State=46 );
%DoReport(State=47 );
%DoReport(State=48 );
%DoReport(State=49 );
%DoReport(State=50 );
%DoReport(State=51 );
%DoReport(State=53 );
%DoReport(State=54 );
%DoReport(State=55 );
%DoReport(State=56 );
%DoReport(State=60 );
%DoReport(State=66 );
%DoReport(State=69 );
%DoReport(State=975772 );
%DoReport(State=72 );
%DoReport(State=78 );

ods listing ;
libname IndRpts clear ;
