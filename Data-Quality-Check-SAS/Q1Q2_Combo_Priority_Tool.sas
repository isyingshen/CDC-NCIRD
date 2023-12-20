 /********************************************************************/
 /* PROGRAM NAME: Q1Q2 Combo Priority Tool                           */
 /* VERSION: 1.0                                                     */
 /* CREATED: 05Feb2021                                               */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to generate the Q1Q2 Combo Priority    */
 /*           Tool (excel spreadsheet)                               */
 /*                                                                  */ 
 /* INPUT:  Repeating Model Look Ups.xlsx                            */
 /*                                                                  */ 
 /* OUTPUT: Q1Q2_Combo_Priority_Tool_SAS.xlsx		                  */
 /*  	                            			                           */
 /* Date Modified: 2021/2/22                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Consider 'im' in the test type and specimen source      */
 /*  	                            			                           */
 /* Date Modified: 2021/7/28                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Added a macro                                           */
 /*			10180	Mumps                                              */
 /*			10190	Pertussis                                          */
 /*			10030	Varicella                                          */
 /*			10150	N. meningitidis                                    */
 /*			10590	H. influenzae                                      */
 /*			10490	Legionellosis                                      */
 /*			10450	Psittacosis                                        */
 /*			10140	Measles                                            */
 /*			10200	Rubella                                            */
 /*			11723	Invasive Pneumococcal Disease (IPD)                */
 /*			10370	Congenital Rubella Syndrome (CRS)                  */
 /*  	                            			                           */
 /* Date Modified: 2021/9/17                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Remove 4 columns in output:  Keepcombo, Keepcombo_Val,  */
 /*          Comments, Spec_ID.                                      */
 /********************************************************************/

/*directory of the repeating model lookups*/
/*%let rmludir =\\cdc\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NMI\Dev\Source\Formats;*/
/*%let rmludir =\\cdc.gov\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\NMI\Dev\Docs\Metadata;*/
%let rmludir =\\cdc.gov\project\NIP_Project_Store1\surveillance\Surveillance_NCIRD_3\NMI\Test\Source\Formats;
%let outdir =\\cdc.gov\project\NIP_Project_Store1\Surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Q1_Q2_combo_Priority;


/* Import repeating model look ups into sas: Test Type */
proc import datafile="&rmludir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=LabTestType_Q1 replace;
	range = "M3_LabTestType_Q1$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;


/* Import repeating model look ups into sas: Specimen Type */
proc import datafile="&rmludir\Repeating Model Look Ups.xlsx"
	DBMS=EXCEL out=SpecimenType_Q2 replace;
	range = "M3_SpecimenType_Q2$";
	getnames=yes;
	mixed = yes;
	scantext = yes;
	usedate=yes;
run;
%macro q1q2_priority_generator(cond_code, cond_name);
/*Cartesian Join*/
proc sql;
create table q1q2_combo as
select a.Disease
,a.EventCode
,a.Code as Test_Type_Code
,a.Var_Name as Test_Type_Var_Name
,a.Keepcombo as Keepcombo_formula
,a.Comment
,b.Code as Secimen_Source_Code
,b.Var_Name as Specimen_source_Var_Name
,b.Spec_ID
,b.Value_Set
,b.cond_flag_&cond_code
from LabTestType_Q1 a,SpecimenType_Q2 b
where a.EventCode="&cond_code";
/*and b.cond_flag_11065="1";*/
quit;

/*Remove special characters ()""*/
data q1q2_combo2;
	set q1q2_combo;
	Keepcombo2=compress(Keepcombo_formula,"1234567890,","kis");
run;

/*separate text into different variables*/
data q1q2_combo3;
	set q1q2_combo2;
	array var(100);
	array varn(100) $30;
	i=1;
	do until (scan(Keepcombo2, i,",") eq "");
		var(i)=scan(Keepcombo2,i,",");
		if var(i) =1 then varn(i)="Blood";
		else if var(i)=2 then varn(i)="Body_Fluid";
		else if var(i)=3 then varn(i)="Bronc_wash";
		else if var(i)=4 then varn(i)="Buccal";
		else if var(i)=5 then varn(i)="Crust";
		else if var(i)=6 then varn(i)="CSF";
		else if var(i)=7 then varn(i)="DNA";
		else if var(i)=8 then varn(i)="Isolate";
		else if var(i)=9 then varn(i)="Lavage";
		else if var(i)=10 then varn(i)="Lesion";
		else if var(i)=11 then varn(i)="Lesion_swab";
		else if var(i)=12 then varn(i)="Mac_Scrape";
		else if var(i)=13 then varn(i)="Nasal_swab";
		else if var(i)=14 then varn(i)="Nose_swab";
		else if var(i)=15 then varn(i)="NP";
		else if var(i)=16 then varn(i)="NP_asp";
		else if var(i)=17 then varn(i)="NP_wash";
		else if var(i)=18 then varn(i)="NucleicAcid";
		else if var(i)=19 then varn(i)="Oralfluid";
		else if var(i)=20 then varn(i)="Oralswab";
		else if var(i)=21 then varn(i)="Oth";
		else if var(i)=22 then varn(i)="Plasma";
		else if var(i)=23 then varn(i)="RNA";
		else if var(i)=24 then varn(i)="Saliva";
		else if var(i)=25 then varn(i)="Scab";
		else if var(i)=26 then varn(i)="Serum";
		else if var(i)=27 then varn(i)="Stool";
		else if var(i)=28 then varn(i)="Swab";
		else if var(i)=29 then varn(i)="Tissue";
		else if var(i)=30 then varn(i)="TS";
		else if var(i)=31 then varn(i)="Unk";
		else if var(i)=32 then varn(i)="Urine";
		else if var(i)=33 then varn(i)="Vesc_fluid";
		else if var(i)=34 then varn(i)="Vesc_swab";
		else if var(i)=35 then varn(i)="im";
		else if var(i)=39 then varn(i)="Cataract";
		else if var(i)=64 then varn(i)="DBS";
		else if var(i)=65 then varn(i)="Resp";
		i+1;
	end;
run;

data q1q2_combo4;
	set q1q2_combo3;
	Keepcombo_Val=catx(",", of varn1-varn25);
run;

/*Calculate Var_Combo and Combo_Priority*/
proc sql;
create table q1q2_combo_priority_tool as
select Disease
/*,EventCode*/
,Test_Type_Code
,Test_Type_Var_Name
/*,Keepcombo_formula*/
/*,Keepcombo2 as Keepcombo*/
/*,Keepcombo_Val*/
/*,Comment*/
/*,case*/
/*when Comment ="Priority" then "Prioritized"*/
/*end as Comments*/
,Secimen_Source_Code
,Specimen_source_Var_Name
/*,Spec_ID*/
,Value_Set
,cond_flag_&cond_code
,cats(Test_Type_Var_Name,"_",Specimen_source_Var_Name) as Var_Combo
,case 
/*"Spec_ID" is included in "Keepcombo" AND "Comments" = "Priority" for the "Test Type"*/
	when input(Spec_ID,best.)=var1 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var2 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var3 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var4 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var5 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var6 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var7 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var8 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var9 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var10 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var11 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var12 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var13 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var14 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var15 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var16 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var17 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var18 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var19 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var20 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var21 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var22 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var23 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var24 and Comment="Priority" then "Y"
	when input(Spec_ID,best.)=var25 and Comment="Priority" then "Y"
/*the "Test Type" is "Invalid or missing" (im) AND "cond_flag_11065" = "1"; */
	when lower(Test_Type_Var_Name)="im" and cond_flag_&cond_code="1" then "Y"
/*the "Specimen Source" is "Invalid or missing " (im) AND "Comments" = "Priority" for the "Test Type"*/
	when lower(Specimen_source_Var_Name) ="im" and Comment="Priority" then "Y"
	else "N"
end as Combo_Priority
from q1q2_combo4 ;
quit;

/*Export data into excel*/
PROC EXPORT DATA= q1q2_combo_priority_tool
             OUTFILE= "&outdir\Test Type-Specimen Source(Q1Q2) Priority Tool run on &sysdate9..xlsx"
             DBMS=XLSX REPLACE;
      SHEET="&cond_name";
RUN;
%mend q1q2_priority_generator;


%q1q2_priority_generator(11065,COVID19);
%q1q2_priority_generator(10180,Mumps);
%q1q2_priority_generator(10190,Pertussis);
%q1q2_priority_generator(10030,Varicella);
%q1q2_priority_generator(10150,N_meningitidis);
%q1q2_priority_generator(10590,H_influenzae);
%q1q2_priority_generator(10490,Legionellosis);
%q1q2_priority_generator(10450,Psittacosis);
%q1q2_priority_generator(10140,Measles);
%q1q2_priority_generator(10200,Rubella);
%q1q2_priority_generator(11723,IPD);
%q1q2_priority_generator(10370,CRS);

