/*************************************************************************************************/
/* Description: HL7 Completetion Report for MPV                                                  */
/*              This code creates a report to indicate the percent missing for HL7 variables     */
/*              for the MPV MMGs. (Based on Hannah's Implementation Spreadsheet).                */
/*              Change the FIPS state number to the appropriate jurisdisction number             */
/*              for which you want the completeness report.                                      */
/*                                                                                               */
/* Created by :   Chrissy Miner    8/15/2018                                                     */
/* Modified by:   Samatha Chindam  11/12/2019  -Standardized the code.                           */
/*                Samatha Chindam  01/24/2020  -Modified the code to make the report work        */
/* 					Anu Bhatta		  08/05/2020  -As QC folder changed path for Projdir modified	 */
/*************************************************************************************************/
%global environment platform rootdir projdir DBservName;
%let environment = PROD; /* DEV | TEST | STAGING | PROD environment code to control behaviour */
%let platform = DESKTOP; /* DESKTOP | CSP platform code to control file paths */

/* file path is declared based on the location the program is running under */
%macro platform_path;
   %if (&platform = DESKTOP) %then %do;
      %let projdir = \\cdc\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NMI\&environment\QC;
	   %let rootdir = \\cdc\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NMI\&environment\Source;
   %end;
   %else %do; /* assume the other platform is CSP */
      %let projdir = \\cdc\csp_project\NCIRD_MVPS\&environment\QC;   
      %let rootdir =\\cdc\csp_project\NCIRD_MVPS\&environment\Source;
   %end;
%mend platform_path;
%platform_path;

options mprint mlogic symbolgen NOQUOTELENMAX
        sasautos = (sasautos,
                    "&projdir\Source\Macros",
                    "&rootdir\Macros"
                    );
                
%DBserverByEnv(AppName=NNAD, Environment=&environment);

%let fipsn=49; /* For all jurisdictions, the state FIPS number needs to be changed here */

%let stabv=%sysfunc(fipnamel(&fipsn)); /* Converts FIPS number to state name */

libname nmi OLEDB 
        provider="sqlncli11"
        properties = ( "data source"="&DBservName"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=nndss access=readonly;

%macro epi;

   %do i=1 %to 6;

data t&i.;
   set nmi.stage4_NNDSScasesT&i.;
   if report_jurisdiction="&fipsn" and condition in ("10180", "10190", "10030");
run;

proc sort data=t&i.;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem;
run;

   %end;
%mend;
%epi;

data nnad;
   merge t1 t2 t4 t5 t6;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem;
run;

/*Lab data*/
%macro loop;

   %do i=1 %to 37;

data t3_&i.;
   set nmi.stage4_NNDSScasesT3_&i.;
   if report_jurisdiction="&fipsn" and trans_id ne . and condition in ("10180", "10190", "10030"); /* use trans_id because source_system not in all tables */
run;

proc sort data=t3_&i.;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem;
run;

   %end;

%mend loop;
%loop;

data lab;
   merge t3_1-t3_37;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem;
run;

proc sql noprint; /*pulls list of variable names*/

   select NAME into :sstt1 separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and 
         NAME ne 'site' and NAME ne 'wsystem' and index(NAME, '_1');

   select NAME into :sstt2 separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and
         NAME ne 'site' and NAME ne 'wsystem' and index(NAME, '_2');

   select NAME into :sstt3 separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and
         NAME ne 'site' and NAME ne 'wsystem' and index(NAME, '_3');

   select NAME into :ssttad separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and
         NAME ne 'site' and NAME ne 'wsystem' and index(NAME, '_addtl_flag');

   select count(NAME) into :nsstt separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and 
         NAME ne 'site' and NAME ne 'wsystem';

   select NAME into :quant separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_");

	select count(NAME) into :qnum separated  by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='char' and index(NAME,"qnt_rslt");

	select NAME into :unit separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='char' and index(NAME, "unit");

	select count(NAME) into :unum separated  by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='char' and index(NAME,"unit");

	select NAME into :coll separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='num' and index(NAME, "_collct_dt_") and 
         format='DATETIME22.3';

	select count(NAME) into :ncol separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='num' and index(NAME, "_collct_dt_") and 
         format='DATETIME22.3';

	select NAME into :sent separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='num' and index(NAME, "_dt_sent_") and 
         format='DATETIME22.3';

	select count(NAME) into :nsent separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='num' and index(NAME, "_dt_sent_") and 
         format='DATETIME22.3';

	select NAME into :labt separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_lab_type_");

	select count(NAME) into :nlabt separated by ' '
	from dictionary.columns
	where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_lab_type_");

quit;

data lab;
   set lab;

	array all{*} &sstt1 &sstt2 &sstt3 &ssttad;
	array qnum{*} &quant;
	array unit{*} &unit;
	array col{*} &coll;
	array sent{*} &sent;
	array labt{*} &labt;

   do i=1 to &nsstt.;
      if (all{i} ne ' ') then do;
         test_type=1;
			spec_source=1;
			test_result=1;
      end;
   end;

   do j=1 to &qnum.;
		if (qnum{j} ne ' ') then
         quant_res=1;
	end;

	do k=1 to &unum.;
		if (unit{k} ne ' ') then
         unit_comp=1;
	end;

	do l=1 to &ncol;
		if (col{l} ne ' ') then
         col_date=1;
	end;

	do m=1 to &nsent;
		if (sent{m} ne ' ') then 
         sent_date=1;
	end;

	do n=1 to &nlabt;
		if (labt{n} ne ' ') then
         lab_type=1;
	end;

	keep quant_res unit_comp col_date sent_date lab_type local_record_id report_jurisdiction mmwr_year
        condition site wsystem test_type spec_source test_result;
run;
/*End lab data*/

data nnad;
   set nnad;

	where source_system in (5, 15);

	array race{10}      ak_n_ai asian black hi_n_pi race_no_info race_not_asked race_oth race_refused 
                       race_unk white;
   array expcity{5}    expcity1-expcity5;
   array expcountry{5} expcountry1-expcountry5;
   array expcounty{5}  expcounty1-expcounty5;
   array expstate{5}   expstateprov1-expstateprov5;
   array binat{6}      binatl_case_contacts binatl_exp_by_res binatl_exp_in_country binatl_other_situations 
                       binatl_product_exp binatl_res_of_country;
   array signs{30}     Fever Headache JawPain MusclePain Parotit Sublingual_Swell Submand_Swell Fatigue 
                       Apnea Cough Cyanosis Paroxysm Post_tuss_vomit Whoop Sx_Unk Chills Diarrhea 
                       GI_illness Nausea Photophobia Pneumonia Rash StiffNeck Vomit Coryza Conjunctivitis
                       Arthralgia Arthritis Lymphadenopathy Symptoms_oth_txt;
   array comp{44}      Deafness Encephalitis Encephalitis Meningitis Orchitis Encephalopathy Seizures 
                       Cereb_ataxia Dehydration Hemorrhagic skin_soft_tissue_inf Pneumonia 
                       Complications_oth_txt Comp_unk Mastitis Oophoritis Pancreatitis Otitis Diarrhea 
                       Encephalitis Thrombocytopenia Croup Hepatitis Encephalitis Thrombocytopenia Cataract
                       Hearing_impairment congenital_heart_disease congenital_heart_disease_oth 
                       patent_ductus_arteriosus peripheral_pulmonic_stenosis Stenosis Congenital_glaucoma
                       pigmentary_retinopathy developmental_delay Meningoencephalitis Microencephaly 
                       Purpura Enlarged_spleen Enlarged_liver Radiolucent_bone_disease Neonatal_jaundice 
                       Low_platelets dermal_erythropoieses;    
   array occ2{2}       occupationcd1 occupationcd2;
   array occ{2}        occupationtxt1 occupationtxt2;
   array ind1{2}       industrycd1 industrycd2;
   array ind2{2}       industrytxt1-industrytxt2;
   array vaxdose{10}   vaxdose1-vaxdose10;
   array vaxexp{10}    vaxexpdt1-vaxexpdt10;
   array vaxinfo{10}   vaxinfosrce1-vaxinfosrce10;
   array vaxlot{10}    vaxlot1-vaxlot10;
   array vaxmfr{10}    vaxmfr1-vaxmfr10;
   array vaxndc{10}    vaxndc1-vaxndc10;
   array vaxrecid{10}  vaxrecid1-vaxrecid10;
   array vaxtype{10}   vaxtype1-vaxtype10;
   array srcage{5}     sourceage1-sourceage5;
   array srcageut{5}   sourceageunit1-sourceageunit5;
   array srcrel{5}     sourcerel1-sourcerel5;
   array srcsex{5}     sourcesex1-sourcesex5;
   array sons{5}       sourceonset1-sourceonset5;
   array txdays{5}     txdurationdays1-txdurationdays5;
   array txrec{5}      txrcvd1-txrcvd5;
   array reashosp{8}   hosp_var_complic hosp_IV_tx hosp_for_isolation hosp_non_var hosp_for_observation 
                       hosp_severe_var reasonhosp_oth_txt hosp_reason_unk;
   array rcnttrvl{5}   recent_travel_dest1-recent_travel_dest5;
   array body{9}       arm_hand_torso_back head_face_eye head_face_no_eye leg neck_shoulder 
                       pelvis_groin_buttocks_hip upper_mid_abdomen_flank rash_region_unk rashregion_oth_txt;
							  /* 'rashregion_oth_txt' is not in the repeating model excel file but it is in the data dictionary */

   /*date arrays*/
   array txstart{5}    txstartdt1-txstartdt5;
   array vxdate{10}    vaxdate1-vaxdate10;

   racecombo=' ';
   expctycombo=' ';
   expcntrycombo=' ';
   expcntycombo=' ';
   expstatecombo=' ';
   binatcombo=' ';
   signscombo=' ';
   compcombo=' ';
   occ1combo=' ';
   occ2combo=' ';
   ind1combo=' ';
   ind2combo=' ';
   vxdtcombo=' ';
   vxdosecombo=' ';
   vxexpcombo=' ';
   vxinfocombo=' ';
   vxlotcombo=' ';
   vxmfrcombo=' ';
   vxndccombo=' ';
   vxrecidcombo=' ';
   vxtypecombo=' ';
   srceagecombo=' ';
   srcageutcombo=' ';
   srcrelcombo=' ';
   srcsexcombo=' ';
	sonscombo=' ';
   txdayscombo=' ';
   txreccombo=' ';
   hosprescombo=' ';
   rcnttrvlcombo=' ';
   txstrtdtcombo=' ';
   bodycombo=' ';   

   do i=1 to 5;
      if (expcity{i} ne ' ') then
         expctycombo='P';
      if (expcountry{i} ne ' ') then
         expcntrycombo='P';
      if (expcounty{i} ne ' ') then
         expcntycombo='P';
      if (expstate{i} ne ' ') then
         expstatecombo='P';
      if (srcage{i} ne ' ') then
         srceagecombo='P';
      if (srcageut{i} ne ' ') then
         srcageutcombo='P';
      if (srcrel{i} ne ' ') then
         srcrelcombo='P';
      if (srcsex{i} ne ' ') then
         srcsexcombo='P';
      if (txdays{i} ne ' ') then
         txdayscombo='P';
      if (txrec{i} ne ' ') then
         txreccombo='P';
      if (txstart{i} ne .) then
         txstrtdtcombo='P';
      if (rcnttrvl{i} ne ' ') then
         rcnttrvlcombo='P';
      if (sons{i} ne ' ') then
         sonscombo=' ';
   end;

   do i=1 to 6;
      if (binat{i} ne ' ') then
         binatcombo='P';
   end;

   do i=1 to 15;
      if (signs{i} ne ' ') then
         signscombo='P';
   end;

   do i=1 to 13;
      if (comp{i} ne ' ') then 
         compcombo='P';
   end;

   do i=1 to 2;
      if (occ{i} ne ' ') then
         occ1combo='P';
      if (occ2{i} ne ' ') then
         occ2combo='P';
      if (ind1{i} ne ' ') then
         ind1combo='P';
      if (ind2{i} ne ' ') then
         ind2combo='P';
   end;

   do i=1 to 10;
      if (race{i} ne ' ') then
         racecombo='P';
      if (vaxdose{i} ne ' ') then
         vxdosecombo='P';
      if (vaxexp{i} ne .) then
         vxexpcombo='P';
      if (vaxinfo{i} ne ' ') then
         vxinfocombo='P';
      if (vaxlot{i} ne ' ') then
         vxlotcombo='P';
      if (vaxmfr{i} ne ' ') then		   
         vxmfrcombo='P';
      if (vaxndc{i} ne ' ') then
         vxndccombo='P';
      if (vaxrecid{i} ne ' ') then
         vxrecidcombo='P';
      if (vaxtype{i} ne ' ') then 
         vxtypecombo='P';      
      if (vxdate{i} ne .) then 
         vxdtcombo='P';
   end;

   do i=1 to 8;
      if (reashosp{i} ne ' ') then 
         hosprescombo='P';
   end;

   do i=1 to 9;
      if (body{i} ne ' ') then
         bodycombo='P';
   end;
run;

/*Creating 2 datasets- one for GenV2 variables and one for condition specific variables*/
data genv2;
   set nnad;
   keep msh_id_generic local_subject_id birth_dt sex racecombo res_state res_zip res_county ethnicity
        death_dt local_record_id first_electr_submit_dt electr_submitted_dt result_status race_oth_txt
        birth_country birthplace_other res_country illness_onset_dt illness_end_dt illness_duration 
        illness_duration_units pregnant dx_dt hospitalized admit_dt discharge_dt days_in_hosp died 
        state_case_id legacy_case_id age_invest age_invest_units disease_acquired import_country 
        import_state import_city import_county expcntrycombo expstatecombo expctycombo expcntycombo
        transmission case_status immediate_nnc_criteria outbreak_assoc outbreak_name jurisdiction 
        reporting_source reporting_zip binatcombo reporter_name reporter_phone reporter_email 
        case_inv_start_dt first_report_phd_dt first_report_county_dt first_report_state_dt mmwr_week
        mmwr_year cdc_verbal_notify_dt first_PHD_suspect_dt reporting_state reporting_county 
        report_jurisdiction comment;
run;

data nnad;
   set nnad;
   keep local_record_id report_jurisdiction mmwr_year condition site wsystem msh_id_disease msh_id_notifiable
        parotitis_laterality swelling_onset_dt swelling_duration highest_temp_fever temp_units
        fever_onset_dt deafness_type time_in_US time_in_US_units import_status US_acquired res_city
        investigation_status detection_method transmission_setting age_setting_verified epi_link_labconf
        epi_link_confprob lab_test_done lab_confirmed spec_sent_to_cdc VPD_RC_lab_id VPD_RC_patient_id 
        VPD_RC_spec_id received_vax num_vax_doses_after_1st vax_dose_prior_onset_dt num_vax_dose_prior_onset 
        vax_per_acip_recs reason_not_vax_per_ACIP vax_history_comment interview_dt cough_interview
        cough_dt cough_duration_days cough_age cough_age_units xray_result antibiotics hcp_pert
        mom_age_years gest_age_weeks birth_weight birth_weight_units setting_of_spread num_rec_anti
        mom_tdap trimester_tdap mom_tdap_dt source_suspect source_num num_lesions num_lesions_specify
        rash_onset_dt generalized_rash character_lesions hemo_lesions itchy_lesions crops_waves
        crusted_lesions rash_duration fever fever_duration immunocomp immunocomp_cond visit_hcp
        antiviral varicella_before age_prev_dx age_prev_dx_units prev_dx_by epi_link_case_type HCP_var
        preg_weeks_gest preg_trimester racecombo expctycombo expcntycombo expcntrycombo expstatecombo 
        binatcombo signscombo occ1combo occ2combo ind1combo ind2combo vxdosecombo vxexpcombo vxinfocombo 
        vxlotcombo vxmfrcombo vxndccombo vxrecidcombo vxtypecombo srceagecombo srcageutcombo srcrelcombo 
        srcsexcombo txdayscombo txreccombo hosprescombo rcnttrvlcombo txstrtdtcombo vxdtcombo expstatecombo
        bodycombo sonscombo compcombo travel_return_dt;
run;

proc sort data=lab;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem;
run;

proc sort data=nnad;
	by local_record_id report_jurisdiction mmwr_year condition site wsystem;
run;

/*Merging condition specific w/ lab data*/
data nnad;
	merge nnad (in=a) lab;
	if a;
	by local_record_id report_jurisdiction mmwr_year condition site wsystem;
run;

proc format;
   value $missing
   ' '='Missing'
   other='Populated'
   ;
   value missingnum
   .='Missing'
   other='Populated'
   ;
   value $condition
   '10180'='Mumps'
   '10190'='Pertussis'
   '10030'='Varicella'
   ;
run;

ods listing close;
ods output onewayfreqs=genv2f;
proc freq data=genv2;
   tables _all_/missing;
   format _character_ $missing. _numeric_ missingnum.;
run;
ods output close;
dm 'odsresults; clear';

proc sort data=nnad;
   by condition;
run;

ods listing close;
ods output onewayfreqs=allvars;
proc freq data=nnad;
   tables _all_/missing;
	format mmwr_year-character-bodycombo $missing. _numeric_ missingnum.; /*Need to check if the last character variable is 'vxinfocombo' using proc Contents*/
   by condition;
run;
ods output close;
dm 'odsresults; clear';

data allvars2;
	length condition $50.;
	format condition $50.;
	set allvars;
	condition=put(condition, $condition.);
run;

data genv2f;
	set genv2f;
	condition='Gen V2';
run;

/*Combine GenV2 and condition specific variables back together*/
data allvars2;
   set allvars2 genv2f;
   table=substr(table, 7, 50);
run;

proc sql noprint; 
	select count(NAME) into :num separated by " "
	from dictionary.columns
	where libname='WORK' and memname="ALLVARS2" and NAME contains "F_";
quit;
run;

data allvars2;
	set allvars2;
	array var{&num}  F_:;

   do i=1 to &num;
	   if (percent ne 100 and var{i}='Missing') then
         delete;
	   if (percent = 100 and var{i}='Missing') then
        percent=0;
	end;

 	keep condition table percent mmg cumFrequency;
 	rename table=hl7_name;
run;

proc sort data=allvars2;
   by hl7_name;
run;

/*Getting Priority lists*/
proc import datafile="&projdir\source\inputs\Priority Lists by MMG.xlsx"
	DBMS=xlsx
	Out=Priority replace;
	getnames=yes;
	sheet='MPV';
run;

data priority;
   set priority;
   rename Data_Element__DE__Identifier=DE_Identifier;
run;

data priority;
   set priority;
   length icondition $20.;
   format icondition $20.;
   informat icondition $20.;
   icondition=left(condition);
   drop condition;
   rename icondition=condition;
   drop=tranwrd(compress(condition||de_identifier), '0D0A'x, ''); /* there are hidden carriage returns in the excel file */
run;

/*Implementation Spreadsheet*/
proc import datafile="&projdir\source\inputs\NMI_implementation_spreadsheet_20181107_UT.xlsx"
   DBMS=xlsx
   Out=IS replace;
   sheet="All Other Conditions";
   getnames=yes;
run;

data is;
	set is;
	keep mmg HL7_Message_Context Data_Element__DE__Name PHA_Collected__Yes_Only_Certain var31 phin_variable section Data_Element_Identifier
        data_element_category;
	where mmg in ('Gen V2', 'Mumps', 'Pertussis', 'Varicella') and section not in ('Gen V2 Data Elements', 'Mumps', 'Pertussis', 'Varicella') and
         index(data_element_category, 'LABORATORY INFORMATION')<1;
	rename Data_Element_Identifier=de_id Data_Element__DE__Name=de_name mmg=condition_c 
			 PHA_Collected__Yes_Only_Certain=&stabv._sending var31=&stabv._comment;
run;

data is;
   set is;
	drop data_element_category;
	drop=compress(tranwrd((condition_c||de_id), '0D0A'x, '')); /* there are hidden carriage returns in the excel file */	
	keep condition_c de_id &stabv._sending drop;
run;

proc sort data=priority;
   by drop;
run;

proc sort data=is;
	by drop;
run;

/*Testing purpose to see if there are any variables missing with the merge*/
/*data priority_sent notMergedList isOnly priorityOnly;
   merge is(in = a) priority(in = b);
   by drop;
	if (a and b) then
		output priority_sent;
	else if (a and not b) then
		output isOnly;
	else if(b and not a) then
		output priorityOnly;
	else
		output notMergedList;
   hl7_name=lowcase(hl7_name);
run;*/

data priority_sent;
   merge is priority;
   by drop;
   hl7_name=lowcase(hl7_name);
run;

proc sort data=priority_sent (drop=drop) nodupkey dupout=dups;
   by hl7_name condition;
run;

proc sort data=allvars2;
	by hl7_name condition;
run;

data all;
   merge allvars2 priority_sent (in=a);
   by hl7_name condition;
   if a;
run;

data all2;
   set all;	
	/*removing signs and symptoms and type of complications indicator*/
	if (de_id in ('INV919', 'INV920')) then
      delete;
run;

proc format;
   value per
	low-33.33='Red'
	33.34-66.66='Yellow'
	66.67-high='Green'
	;
run;

options nobyline;
ods excel file="&projdir\Outputs\&stabv. MPV YTD Completeness Report.xlsx" options(start_at="2, 2"  sheet_name="Completion" embedded_titles='YES');

/*Report for each comment*/
proc report data=all2 spanrows nowd headline;
   title "Percent Completion Report for &stabv.";
   column condition DE_identifier Data_Element__DE__Name hl7_name ncird_priority &stabv._sending percent cumFrequency;
	define condition/group;
	define DE_identifier/ 'DE Identifier';
	define Data_Element__DE__Name/'DE Name';
	define hl7_name/'HL7 Variable Name';
	define &stabv._sending/"&stabv Submitting"; 	
	define ncird_priority/'NCIRD Priority';
	define percent/'Percent Complete' style=[background= per.];
	define cumFrequency/'No. of Cases';
	compute &stabv._sending;
		if (&stabv._sending='No') then 
         call define (_row_, "style", "style=[BACKGROUND=lightgrey]");
	endcomp;
run;

ods excel close;
libname _all_ clear;
