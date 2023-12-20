proc sql;
select *
from RubellaPregStatusPct;
quit;

proc contents data=rubella_HL7;
run;

data rubella_HL7;
set IndRpts.rubella_HL7;;
run;


/*rubellla*/

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

%Let footnotetext = *** Provisional week 52 2022 data ;

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
/*footnote5 &footnoteoptions "NA = not available" ;*/
%If &State > 0 %Then %Do ;
footnote5 &Footnoteoptions "NA = not available" ;                                                      
%end ;
footnote6 &footnoteoptions "¶Results may not accurately represent jurisdiction-based data or surveillance effort for those jurisdictions "
"that have transmitted case notifications via NBS during any of the years included in this report (AK, AL, AR, DC†, ID, IN, KY, LA, MD, ME, "
"MS [Covid-19 only], MT, NE, NM, NV, RI, TN, TX, VA, VT, WV, WY, CNMI†, Guam†, Puerto Rico†, RMI†, USVI† (†Surveillance Indicator "   
"Reports are not available for these jurisdictions)" ;
footnote7 &footnoteoptions "NOTE: the COVID-19 pandemic has limited the availability of resources needed for reconciliation and close-out of NNDSS data; therefore, these data "
"should be interpreted in the context of these circumstances." ; 
Run ; /* End of rubella */ 




ods _All_ close ;
%mend doReport ;

%DoReport(State=0 );
%DoReport(State=1 );
