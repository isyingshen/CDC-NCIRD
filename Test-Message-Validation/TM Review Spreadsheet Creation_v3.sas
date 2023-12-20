/*Changed on 7/26/21 by Ying Shen*/
/*        Updated the way of reading excel because it kept giving me an error*/
/*Changed on 5/2/23 by Ying Shen and Katherine Luce*/
/*		  Updated the code to a proc sql to merge instead of data-merge*/

%let jurs=DC ; *jurisdiction 2 (or 3) letter abbreviation to match folder naming convention;
%let cond=COVID-19 ; *name of MMG condition(s) (COVID-19, Mumps, Pertussis, Varicella, Measles, Rubella, CRS, H flu, N mening, IPD, Psittacosis, Legionellosis);
%let isfile=COVID19_DC Health_Implementation Spreadsheet_DC_11182022_KL.xlsx ; *copy filename of implementation spreadsheet with .xslx extension;
%let issheet='COVID19' ; *copy sheet name from implementation spreadsheet;
%let tcfile= DC_COVID19_TCSW_04282023_KL.xlsx ; *copy filename of test case scenario worksheet;
%let tcsheet='COVID-19 TCSW' ; *copy sheet name from test case scenario worksheet;

libname impl xlsx "\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\&jurs\&cond\&isfile";
libname tcsw xlsx "\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\&jurs\&cond\&tcfile";

options fullstimer;


/* Import is into sas */
/*proc import datafile="\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\&jurs\&cond\&isfile"*/
/*	DBMS=EXCEL out=impl_file replace;*/
/*	range = "COVID19$";*/
/*	getnames=yes;*/
/*	mixed = yes;*/
/*	scantext = yes;*/
/*	usedate=yes;*/
/*run;*/

data impl;
	set impl.&issheet.n (keep= condition Data_Element__DE__Identifier_Sen Data_Element__DE__Name PHA_Collected__Yes_Only_Certain);
	where Data_Element__DE__Identifier_Sen is not null and condition is not null;
	n_Data_Element__DE__Name=compress(Data_Element__DE__Name,'0D0A'x);
	n_Data_Element__DE__Identifier=compress(Data_Element__DE__Identifier_Sen,'0D0A'x);
	drop Data_Element__DE__Name Data_Element__DE__Identifier_Sen;
	rename n_Data_Element__DE__Identifier=DE_identifier 
           n_Data_Element__DE__Name=DE_name
           PHA_Collected__Yes_Only_Certain=PHA_collected;
run;


data tcsw;
	set tcsw.&tcsheet.n;
	if condition = 'COVID-19' then condition='COVID19';
	where row ne ' ';
	n_row=input(row,3.);
	n_Data_Element__DE__Name=compress(Data_Element__DE__Name,'0D0A'x);
	n_DE_Identifier_Sent_in_HL7=compress(DE_Identifier_Sent_in_HL7_Messag,'0D0A'x);
	drop row DE_Identifier_Sent_in_HL7_Messag Data_Element__DE__Name;
	rename n_DE_Identifier_Sent_in_HL7=DE_identifier 
			n_Data_Element__DE__Name=DE_name
			Data_Element_Description=DE_Description
			n_row=Row;
run;


proc sort data=impl;
	by DE_Name de_identifier;
run;

proc sort data=tcsw;
	by DE_Name de_identifier;
run;
/*Use proc sql to merge instead of data-merge*/
proc sql;
create table review as
select *
from tcsw as a
inner join impl as b
on (a.DE_Name=b.DE_Name and a.de_identifier=b.de_identifier);
quit;

/*
data review impl_o tcsw_o;
	merge impl (in=a) tcsw (in=b);
	by DE_Name de_identifier;
	if a and b then output review;
	if b and not a then output review;
	if a and not b then output impl_o;
run;*/

data tcsw_rev;
	set review;
	where DE_Name ne ' ' and row >=1;
	NCIRD_Review_TM_1=' ';
	NCIRD_Review_TM_2=' ';
	NCIRD_Review_TM_3=' ';
	NCIRD_Review_TM_4=' ';
	NCIRD_Review_TM_5=' ';
run;

proc sort data=tcsw_rev;
	by Row;
run;

ods excel file ="\\cdc.gov\project\NIP_Project_Store1\surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Jurisdiction Onboarding\&jurs\&cond\Test Messages\&jurs &cond NCIRD Test Message Review.xlsx"
options (sheet_interval='none' absolute_row_height='20px' sheet_name='NCIRD Review' );

proc report data=tcsw_rev;
	column Row  Condition DE_Name DE_Identifier DE_Code_System DE_Description Data_Type CDC_Priority May_Repeat Value_Set_Name__VADS_Hyperlink_ Value_Set_Code PHA_Mapping___OPTIONAL_ PHA_Collected 
		Test_Record_1 Test_Record_1_1 NCIRD_Review_TM_1 Test_Record_2 Test_Record_2_1 NCIRD_Review_TM_2 
		Test_Record_3 Test_Record_3_1 NCIRD_Review_TM_3 Test_Record_4 Test_Record_4_1 NCIRD_Review_TM_4 
		Test_Record_5 Test_Record_5_1 NCIRD_Review_TM_5;
	define row / order style(header)=[fontfamily=calibri fontsize=1 foreground=black] 
						style(column)=[fontfamily=calibri fontsize=1 foreground=black ];
	define Condition / style(header)=[fontfamily=calibri fontsize=1 foreground=black]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define DE_Name / 'Data Element (DE) Name' style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.53in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define DE_Identifier / 'DE Identifier Sent in HL7 Message'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.27in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define DE_Code_System / 'DE Code System'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=0.75in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define DE_Description  / 'Dat

;a Element Description'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=2.2in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Data_Type / 'Data Type'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define CDC_Priority / 'CDC Priority'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define May_Repeat / 'May Repeat'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Value_Set_Name__VADS_Hyperlink_ / 'Value Set Name (VADS Hyperlink)'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Value_Set_Code / 'Value Set Code'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.7in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define PHA_Mapping___OPTIONAL_ / 'PHA Mapping *OPTIONAL*' style(header)=[just=center background=lightgoldenrodyellow fontfamily=calibri fontsize=1 foreground=black width=0.75in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define PHA_Collected / 'PHA Collected' style(header)=[just=center background=mistyrose fontfamily=calibri fontsize=1 foreground=black width=1in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_1 / 'Test Record 1 (CSELS template)'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_1_1 / 'Test Record 1' style(header)=[just=center background=seashell fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define NCIRD_Review_TM_1 / 'NCIRD Review Test Record 1' style(header)=[just=center  background=gainsboro fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_2 / 'Test Record 2 (CSELS template)'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_2_1 / 'Test Record 2'  style(header)=[just=center background=seashell fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define NCIRD_Review_TM_2 / 'NCIRD Review Test Record 2' style(header)=[just=center  background=gainsboro fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_3 / 'Test Record 3 (CSELS template)' style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_3_1 / 'Test Record 3'  style(header)=[just=center background=seashell fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define NCIRD_Review_TM_3 / 'NCIRD Review Test Record 3' style(header)=[just=center  background=gainsboro fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_4 / 'Test Record 4 (CSELS template)'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_4_1 / 'Test Record 4' style(header)=[just=center background=seashell fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define NCIRD_Review_TM_4 / 'NCIRD Review Test Record 4 (update to Test Record 3)' style(header)=[just=center  background=gainsboro fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_5 / 'Test Record 5 (CSELS template)'  style(header)=[just=center fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define Test_Record_5_1 / 'Test Record 5' style(header)=[just=center background=seashell fontfamily=calibri fontsize=1 foreground=black width=1.5in]
						style(column)=[fontfamily=calibri fontsize=1 foreground=black];
	define NCIRD_Review_TM_5 / 'NCIRD Review Test Record 5 (update to Test Record 2)' style(header)=[just=center  background=gainsboro fontfamily=calibri fontsize=1 foreground=black width=1.5in]
					style(column)=[fontfamily=calibri fontsize=1 foreground=black];

	compute NCIRD_Review_TM_5;
	if DE_Identifier =' ' then do;
	call define ('Row',"style", "style=[background=lightgray]");
	call define ('Condition', "style", "style=[background=lightgray]");
	call define ('DE_Name',"style", "style=[background=lightgray]");
	call define ('DE_Identifier',"style", "style=[background=lightgray]");
	call define ('DE_Code_System',"style", "style=[background=lightgray]");
	call define ('DE_Description',"style", "style=[background=lightgray]");
	call define ('Data_Type',"style", "style=[background=lightgray]");
	call define ('CDC_Priority',"style", "style=[background=lightgray]");
	call define ('May_Repeat',"style", "style=[background=lightgray]");
	call define ('Value_Set_Name__VADS_Hyperlink_', "style", "style=[background=lightgray]");
	call define ('Value_Set_Code',"style", "style=[background=lightgray]");
	call define ('PHA_Mapping___OPTIONAL_',"style", "style=[background=lightgray]");
	call define ('PHA_Collected',"style", "style=[background=lightgray]");
	call define ('Test_Record_1',"style", "style=[background=lightgray]");
	call define ('Test_Record_1_1',"style", "style=[background=lightgray]");
	call define ('NCIRD_Review_TM_1',"style", "style=[background=lightgray]");
	call define ('Test_Record_2',"style", "style=[background=lightgray]");
	call define ('Test_Record_2_1',"style", "style=[background=lightgray]");
	call define ('NCIRD_Review_TM_2', "style", "style=[background=lightgray]");
	call define ('Test_Record_3',"style", "style=[background=lightgray]");
	call define ('Test_Record_3_1',"style", "style=[background=lightgray]");
	call define ('NCIRD_Review_TM_3',"style", "style=[background=lightgray]");
	call define ('Test_Record_4',"style", "style=[background=lightgray]");
	call define ('Test_Record_4_1',"style", "style=[background=lightgray]");
	call define ('NCIRD_Review_TM_4',"style", "style=[background=lightgray]");
	call define ('Test_Record_5',"style", "style=[background=lightgray]");
	call define ('Test_Record_5_1',"style", "style=[background=lightgray]");
	call define ('NCIRD_Review_TM_5', "style", "style=[background=lightgray]");
	end;
	else if PHA_Collected= 'Yes - currently collected' then do;
	call define ('PHA_Collected',"style", "style=[background=honeydew foreground=Darkgreen]");
	end;
	else if PHA_Collected= 'Yes - adding to system' then do;
	call define ('PHA_Collected',"style", "style=[background=honeydew foreground=Darkgreen]");
	end;
	else if PHA_Collected = 'Only certain conditions' then do;
	call define ('PHA_Collected',"style", "style=[background=LightGoldenrodYellow foreground=Darkgoldenrod]");
	end;
	else if PHA_Collected = 'No' then do;
	call define ('PHA_Collected',"style", "style=[background=lightpink foreground=firebrick]");
	end;
	endcomp;

run;
proc contents data=tcsw;
run;
proc contents data=impl;
run;
ods excel close;
