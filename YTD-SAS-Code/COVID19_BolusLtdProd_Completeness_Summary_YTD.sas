/*************************************************************************************************/
/* Description: HL7 Completetion Report for COVID                                                */
/*              This code creates a report to indicate the percent missing for HL7 variables     */
/*              for the COVID MMGs. (Based on Hannah's Implementation Spreadsheet).              */
/*              Change the FIPS state number to the appropriate jurisdisction number             */
/*              for which you want the completeness report.                                      */
/*                                                                                               */
/* Created by :   Chrissy Miner    8/15/2018                                                     */
/* Modified by:   Samatha Chindam  11/12/2019  -Standardized the code.                           */
/*                Samatha Chindam  01/24/2020  -Modified the code to make the report work        */
/*                Anu Bhatta       08/05/2020  -As QC folder changed path for Projdir modified   */
/*                Samatha Chindam  09/20/2020  -Modified the code to include condition in genv2  */
/*                                              Used a global variable for implementation sheet  */
/*                                              Modified to read from row 4 to avoid the headers */
/*                Samatha Chindam  09/23/2020  -Included variables ending with 'oth_ynu' and     */
/*                                              Made sure the lookup variables match the current */
/*                                              RMLU & are only Covid flagged variables          */
/*                Samatha Chindam  11/03/2020  -Modified the code to change the font color for   */
/*                                              the variables that are not submitted and their   */
/*                                              percent not equal to 0                           */
/*                Samatha Chindam  09/09/2021  -Removed the 8 lab data elements as per email     */
/*                                              and added prev_infected covid variable           */
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
      %let rootdir = \\cdc\csp_project\NCIRD_MVPS\&environment\Source;
   %end;
%mend platform_path;
%platform_path;

options threads noxwait xsync mprint mlogic symbolgen NOQUOTELENMAX fullstimer compress=yes
        sasautos = (sasautos,
                    "&projdir\Source\Macros",
                    "&rootdir\Macros"
                    );
                
%DBserverByEnv(AppName=NNAD, Environment=&environment);

%let fipsn=46; /* For all jurisdictions, the state FIPS number needs to be changed here */

/*%let stabv=%sysfunc(fipnamel(&fipsn)); /* Converts FIPS number to state name */

/* use this for 2 word state name */
%let stabv=%sysfunc(fipstate(&fipsn)); /* Converts FIPS number to state Postal code */

%let date=%sysfunc(date(),mmddyyd8.);

%let ISfilename = SD COVID-19 Implementation Spreadsheet NCIRD Review_Appended_10.25.2023.xlsx; /* Implementation Spreadsheet document name */                                                                                                                                                                                                                                                                  

libname intrans XLSX "&projdir\source\inputs\SD Trans_IDs-11.22.23.xlsx"; /* list of trans_id */

libname nmi OLEDB
        provider = "sqlncli11"
        properties = ( "data source"="&DBservName"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=nndss access=readonly;

/* read in user specified trans_ids / convert msg_trans_id as trans_id */
proc sql noprint;
   create table input_transid as
   select distinct trans_id
   from intrans.'Sheet1'n
   order by trans_id
   ;
quit;

/*************************************************************/
/* There was discrepancy between count if ran with trans_id, so running using local_record_id */

/*proc sql noprint;*/
/*   create table input_local_record_id as*/
/*   select distinct local_record_id*/
/*   from intrans.'Sheet1'n*/
/*   order by local_record_id*/
/*   ;*/
/*quit;*/
/**/
/*%macro epi;*/
/*/* read only epi tables.  Note, there is no table 3 so skip. */*/
/*proc sql noprint;*/
/*   %do i=1 %to 7;*/
/**/
/*      %if (&i ^= 3) %then %do;*/
/*         create table t&i. as*/
/*         select a.**/
/*         from nmi.stage4_NNDSScasesT&i. a inner join input_local_record_id b*/
/*			on a.local_record_id = b.local_record_id*/
/*         where report_jurisdiction="&fipsn" and condition in ("11065")*/
/*         order by local_record_id, report_jurisdiction, mmwr_year, condition, site, wsystem, dup_SequenceID*/
/*         ;*/
/*      %end;*/
/**/
/*   %end; /* end do 1 to 7 */*/
/*quit;*/
/*%mend;*/
/*%epi;

/*************************************************************/

%macro epi;
/* read only epi tables.  Note, there is no table 3 so skip. */
proc sql noprint;
   %do i=1 %to 7;

      %if (&i ^= 3) %then %do;
         create table t&i. as
         select a.*
         from nmi.stage4_NNDSScasesT&i. a inner join input_transid b
			on a.trans_id = b.trans_id
         where report_jurisdiction="&fipsn" and condition in ("11065")
         order by local_record_id, report_jurisdiction, mmwr_year, condition, site, wsystem, dup_SequenceID
         ;
      %end;

   %end; /* end do 1 to 7 */
quit;
%mend;
%epi;

data nnad;
   merge t1 t2 t4 t5 t6 t7;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem dup_SequenceID;
run;

proc delete data= t1-t7; /* clean work space */
run;

/* Read only Lab data */
%macro labloop;

/* read only epi tables. Note, there is no table 3 so skip. */
/* SangN: we should limit the variable list to COVID. Use new dictionary with flag */
/* used the tables that has only covid variables, is this a good solution? */
proc sql noprint;
   %do i=38 %to 46;

      create table t3_&i. as
      select *
      from nmi.stage4_NNDSScasesT3_&i. a inner join input_transid b
		on a.trans_id = b.trans_id                            
      where report_jurisdiction="&fipsn" and a.trans_id ne . and condition in ("11065")
      order by local_record_id, report_jurisdiction, mmwr_year, condition, site, wsystem, dup_SequenceID
      ;

   %end; /* end do 1 to 46 */
quit;

%mend labloop;
%labloop;

data lab;
   merge t3_38-t3_46;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem dup_SequenceID;
run;

proc delete data= t3_38-t3_46; /* clean work space */
run;

proc sql noprint; /*pulls list of variable names*/

   select NAME
   into :sstt1 separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and 
         NAME ne 'site' and NAME ne 'wsystem' and NAME ne 'dup_SequenceID' and index(NAME, '_1');

   %let sst1cnt = &sqlobs;

   select NAME
   into :sstt2 separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and
         NAME ne 'site' and NAME ne 'wsystem' and NAME ne 'dup_SequenceID' and index(NAME, '_2');

   %let sst2cnt = &sqlobs;
   
   select NAME
   into :sstt3 separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and
         NAME ne 'site' and NAME ne 'wsystem' and NAME ne 'dup_SequenceID' and index(NAME, '_3');

   %let sstt3cnt = &sqlobs;

   select NAME
   into :ssttad separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_")<1 and 
         index(NAME, 'unit')<1 and index(NAME, 'lab_type_')<1 and NAME ne 'condition' and
         NAME ne 'mmwr_year' and NAME ne 'report_jurisdiction' and NAME ne 'local_record_id' and
         NAME ne 'site' and NAME ne 'wsystem' and NAME ne 'dup_SequenceID' and index(NAME, '_addtl_flag');

   %let ssttadcnt = &sqlobs;

   select NAME
   into :quant separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_qnt_rslt_");

   select count(NAME)
   into :qnum separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"qnt_rslt");

   select NAME
   into :unit separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "unit");

   select count(NAME)
   into :unum separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"unit");

   select NAME
   into :coll separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='num' and index(NAME, "_collct_dt_") and 
         format='DATETIME22.3';

   select count(NAME)
   into :ncol separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='num' and index(NAME, "_collct_dt_") and 
         format='DATETIME22.3';

   select NAME
   into :spec separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_spec_id_");

   select count(NAME)
   into :nspec separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_spec_id_");

   select NAME
   into :labt separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_lab_type_");

   select count(NAME)
   into :nlabt separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_lab_type_");

quit;

data lab;
   set lab;

   array all{*} &sstt1 &sstt2 &sstt3 &ssttad;
   array qnum{*} &quant;
   array unit{*} &unit;
   array col{*} &coll;
   array spec{*} &spec;
   array labt{*} &labt;

   %let allcnt = %eval(&sst1cnt + &sst2cnt + &sstt3cnt + &ssttadcnt);

   /* assign indicator when value submitted */
   do i=1 to &allcnt;
      if (all{i} ne ' ') then do;
         test_type=1;
         spec_source=1;
         test_result=1;
      end;
   end;

   do j=1 to &qnum.;
      if (qnum{j} ne ' ') then
         test_result_quant=1;
   end;

   do k=1 to &unum.;
      if (unit{k} ne ' ') then
         test_result_quant_units=1;
   end;

   do l=1 to &ncol;
      if (col{l} ne ' ') then
         spec_collection_dt=1;
   end;

   do m=1 to &nspec;
      if (spec{m} ne ' ') then
         specimen_id=1;
   end;

   do n=1 to &nlabt;
      if (labt{n} ne ' ') then
         lab_type=1;
   end;

   keep test_result_quant test_result_quant_units spec_collection_dt specimen_id lab_type local_record_id 
        report_jurisdiction mmwr_year condition site wsystem dup_SequenceID test_type spec_source test_result;

run;
/*End lab data*/

data nnad;
   set nnad;

   where source_system in (5, 15);

   /* Generic repeating fields */
   array race{12}      ak_n_ai asian black hi_n_pi race_no_info race_not_asked race_oth race_refused 
                       race_unk white Race_oth_txt Race_asked_but_unk;
   array expcountry{5} expcountry1-expcountry5;
   array expstate{5}   expstateprov1-expstateprov5;
   array expcity{5}    expcity1-expcity5;
   array expcounty{5}  expcounty1-expcounty5;
   array binat{8}      binatl_case_contacts binatl_exp_by_res binatl_exp_in_country binatl_other_situations 
                       binatl_product_exp binatl_res_of_country binationalreport_oth_txt binationalreport_oth_ynu;

   /* Condition specific repeating fields */
   array detect{5}     detection_method1-detection_method5;
   array tribn{4}      tribal_name1-tribal_name4;
   array tribnenrol{4} tribal_name_enrolled1-tribal_name_enrolled4;
   array occ2{2}       occupationcd1 occupationcd2;
   array occ{2}        occupationtxt1 occupationtxt2;
   array ind1{2}       industrytxt1-industrytxt2;
   array ind2{2}       industrycd1 industrycd2;
   array covexp{15}    child_care_facility airport infected_animal congregate_living_facility contact_with_case
                       domestic_travel international_travel mass_gathering correctional_facility
                       cruise_ship school exp_unk workplace exp_oth_txt exp_oth_ynu;
   array ship{2}       ship_name1-ship_name2;
   array work{2}       critical_work_setting1-critical_work_setting2;
   array animal{2}     animal_type1-animal_type2;
   array contact{6}    community_acquired healthcare_contact household_contact contact_type_oth_txt
                       contact_type_unk contact_type_oth_ynu;
   array contactid{3}  contact_us_case_id1-contact_us_case_id3;
   array trvl{5}       travel_destination1-travel_destination5;
   array trvlst{5}     Travel_State1-Travel_State5;
   array clinif{3}     clinical_info_source1-clinical_info_source3;
   array secdig{2}     secondary_diagnosis_type1-secondary_diagnosis_type2;
   array clincf{7}     ARDS abnormal_ekg clinical_finding_oth_txt pneumonia abnormal_xray
                       clinicalfinding_unk clinical_finding_oth_ynu;
   array intvt{5}      intervention_type1-intervention_type5;
   array intvdur{5}    intervention_duration_days1-intervention_duration_days5;
   array signs{24}     abdominal_pain chest_pain Chills Cough Diarrhea difficulty_breathing dyspnea Fatigue
                       fever_gt_100_4f Headache MusclePain Nausea new_olfactory_disorder new_taste_disorder
                       Pneumonia rhinorrhea rigors sore_throat subjective_fever Sx_Unk Symptoms_oth_txt 
                       Symptoms_oth_ynu Vomit wheezing;
   array risk{18}      autoimmune_condition cardiovascular_disease chronic_liver_disease chronic_lung_disease
                       chronic_renal_disease diabetes disability Smoker_former hypertension
                       immunosuppressive_condition psych_condition substance_misuse RiskFactors_oth_txt
                       severe_obesity Smoker_current riskfactors_unk other_chronic_disease riskfactors_oth_ynu;
   array disbly{2}     disability_type1-disability_type2;
   array mntlcond{2}   mental_condition_type1-mental_condition_type2;
   array reason{5}     reason_for_testing1-reason_for_testing5;
   array vaxtype{10}   vaxtype1-vaxtype10;
   array vaxdose{10}   vaxdose1-vaxdose10;
   array vaxmfr{10}    vaxmfr1-vaxmfr10;
   array vaxlot{10}    vaxlot1-vaxlot10;
   array vaxndc{10}    vaxndc1-vaxndc10;
   array vaxrecid{10}  vaxrecid1-vaxrecid10;
   array vaxinfo{10}   vaxinfosrce1-vaxinfosrce10;

   /*date arrays*/
   array trvlrdt{5}    travel_return_dt1-travel_return_dt5;
   array trvlddt{5}    travel_depart_dt1-travel_depart_dt5;
   array vxdate{10}    vaxdate1-vaxdate10;
   array vaxexp{10}    vaxexpdt1-vaxexpdt10;

   array prevstnum{5}    prev_st_case_num1-prev_st_case_num4 prev_st_case_num_oth_txt;
   
   racecombo=' ';
   expctycombo=' ';
   expcntrycombo=' ';
   expcntycombo=' ';
   expstatecombo=' ';
   binatcombo=' ';
   signscombo=' ';  
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
   detectcombo=' ';
   tribncombo=' ';
   tribnenrolcombo=' ';
   covexpcombo=' ';
   shipcombo=' ';
   workcombo=' ';
   animalcombo=' ';
   contactcombo=' ';
   contactidcombo=' ';
   trvlcombo=' ';
   trvlstcombo=' ';
   clinifcombo=' ';
   secdigcombo=' ';
   clincfcombo=' ';
   intvtcombo=' ';
   intvdurcombo=' ';
   riskcombo=' ';
   disblycombo=' ';
   mntlcondcombo=' ';
   reasoncombo=' ';
   trvlrdtcombo=' ';
   trvlddtcombo=' ';
   prevstnumcombo=' ';

   /* Summary variable to hold data existence in the array */
   do i=1 to 2;
      if (occ{i} ne ' ') then
         occ1combo='P';
      if (occ2{i} ne ' ') then
         occ2combo='P';
      if (ind1{i} ne ' ') then
         ind1combo='P';
      if (ind2{i} ne ' ') then
         ind2combo='P';
      if (ship{i} ne ' ') then
         shipcombo='P';
      if (work{i} ne ' ') then
         workcombo='P';
      if (animal{i} ne ' ') then
         animalcombo='P';
      if (secdig{i} ne ' ') then
         secdigcombo='P';
      if (disbly{i} ne ' ') then
         disblycombo='P';
      if (mntlcond{i} ne ' ') then
         mntlcondcombo='P';
   end;

   do i=1 to 3;
      if (contactid{i} ne ' ') then
         contactidcombo='P';
      if (clinif{i} ne ' ') then
         clinifcombo='P';
   end;

   do i=1 to 4;
      if (tribn{i} ne ' ') then
         tribncombo='P';
      if (tribnenrol{i} ne ' ') then
         tribnenrolcombo='P';
   end;

   do i=1 to 5;
      if (expcity{i} ne ' ') then
         expctycombo='P';
      if (expcountry{i} ne ' ') then
         expcntrycombo='P';
      if (expcounty{i} ne ' ') then
         expcntycombo='P';
      if (expstate{i} ne ' ') then
         expstatecombo='P';
      if (detect{i} ne ' ') then
         detectcombo='P';
      if (trvl{i} ne ' ') then
         trvlcombo='P';
      if (trvlst{i} ne ' ') then
         trvlstcombo='P';
      if (intvt{i} ne ' ') then
         intvtcombo='P';
      if (intvdur{i} ne ' ') then
         intvdurcombo='P';
      if (reason{i} ne ' ') then
         reasoncombo='P';
      if (trvlrdt{i} ne ' ') then
         trvlrdtcombo='P';
      if (trvlddt{i} ne ' ') then
         trvlddtcombo='P';
      if (prevstnum{i} ne ' ') then
		   prevstnumcombo='P';
   end;

   do i=1 to 6;
      if (contact{i} ne ' ') then
         contactcombo='P';
   end;

   do i=1 to 7;
      if (clincf{i} ne ' ') then
         clincfcombo='P';
   end;

   do i=1 to 8;
      if (binat{i} ne ' ') then
         binatcombo='P';
   end;

   do i=1 to 10;
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

   do i=1 to 12;
      if (race{i} ne ' ') then
         racecombo='P';
   end;

   do i=1 to 15;
      if (covexp{i} ne ' ') then
         covexpcombo='P';
   end;

   do i=1 to 18;
      if (risk{i} ne ' ') then
         riskcombo='P';
   end;

   do i=1 to 24;
      if (signs{i} ne ' ') then
         signscombo='P';
   end;

run;

/*Creating 2 datasets- one for GenV2 variables and one for condition specific variables*/
/*SangN: we can get this from dictionary. */
data genv2;
   set nnad;
   keep msh_id_generic local_subject_id condition birth_dt sex racecombo res_state res_zip res_county ethnicity
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
   keep local_record_id report_jurisdiction mmwr_year condition site wsystem dup_SequenceID msh_id_disease
        cdc_ncov2019_id reason_probable dgmq_id translator hosp_icu icu_admit_dt icu_discharge_dt primary_language
        tribal_affiliation res_type hcp_onset hcp_occupation hcp_work_setting preg_weeks_gest preg_trimester
        critical_workplace contact_us_case symptomatic symptom_resolved secondary_diagnosis conditions_exist
        first_pos_specimen_dt received_vax num_vax_dose_prior_onset vax_dose_prior_onset_dt vax_per_acip_recs
        reason_not_vax_per_ACIP vax_history_comment signscombo occ1combo occ2combo ind1combo ind2combo vxdosecombo
        vxexpcombo vxinfocombo vxlotcombo vxmfrcombo vxndccombo vxrecidcombo vxtypecombo vxdtcombo detectcombo
        tribncombo tribnenrolcombo covexpcombo shipcombo workcombo animalcombo contactcombo contactidcombo
        trvlcombo trvlstcombo clinifcombo secdigcombo clincfcombo intvtcombo intvdurcombo riskcombo disblycombo
        mntlcondcombo reasoncombo trvlrdtcombo trvlddtcombo prev_infected prevstnumcombo;
run;

proc sort data=lab;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem dup_SequenceID;
run;

proc sort data=nnad;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem dup_SequenceID;
run;

/*Merging condition specific w/ lab data*/
data nnad;
   merge nnad (in=a) lab;
   if a;
   by local_record_id report_jurisdiction mmwr_year condition site wsystem dup_SequenceID;
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
   '11065'='COVID-19'
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
   format _character_ $missing. _numeric_ missingnum.; /*Need to check if the last character variable is 'vxinfocombo' using proc Contents*/
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
   array var{&num} F_:;

   do i=1 to &num;
      if (percent ne 100 and var{i}='Missing') then
         delete;
      if (percent = 100 and var{i}='Missing') then
         percent=0;
   end;

   keep condition table percent cumFrequency;
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
   sheet='Covid';
run;

data priority;
   set priority;
   rename Data_Element__DE__Identifier=DE_Identifier Data_Element__DE__Name=de_name;
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
proc import datafile="&projdir\source\inputs\&ISfilename"
   DBMS=xlsx
   Out=IS replace;
   range="NCIRD Review$A4:0"; /* specific range to read, starting from row to end of data */
   getnames=yes;
run;

data is;
   set is;
   keep DE_Name PHA_Collection DE_Identifier Condition Priority;
   rename DE_Identifier=de_id DE_Name=de_name PHA_Collection=&stabv._sending;
run;

data is;
   set is;
   if (condition='Generic v2') then
      condition='Gen V2';
run;

data is;
   set is;
   drop=compress(tranwrd((Condition||de_id), '0D0A'x, '')); /* there are hidden carriage returns in the excel file */   
   keep Condition de_id DE_Name &stabv._sending Priority drop;
run;

proc sort data=priority;
   by drop de_name;
run;

proc sort data=is;
   by drop de_name;
run;

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
   /* removing signs and symptoms and type of complications indicator */
   /* removed the below 8 data elements as per email on 9/7/2021 */
   /* lab_type, spec_collection_dt, spec_source, specimen_id, test_result, test_result_quant, test_result_quant_units, test_type */
   if (de_id in ('INV1086', 'INV1313', 'INV1314', 'INV919', 'INV1118', 
                 'INV290', '31208-2', 'INV291', 'LAB628', 'LAB115', '68963-8', 'LAB202', '82771-7')) then
      delete;
run;

proc sort data = all2;
   by condition;
run;

proc format;
   value per
   low-33.33='Red'
   33.34-66.66='Yellow'
   66.67-high='Green'
   ;
run;

options nobyline;
ods excel file="&projdir\Outputs\&stabv. COVID-19 YTD Completeness Summary &date..xlsx" options(start_at="2, 2"  sheet_name="Completion" embedded_titles='YES');

/*Report for each comment*/
proc report data=all2 nowd headline;
   title "Percent Completion Report for &stabv.";
   column condition DE_identifier de_name hl7_name Priority &stabv._sending percent cumFrequency made_new;
   define DE_identifier/ 'DE Identifier';
   define de_name/'DE Name';
   define hl7_name/'NCIRD Variable Name';
   define &stabv._sending/ display "&stabv Submitting";
   define Priority/ 'Priority';
   define percent/ display 'Percent Complete' style=[background= per.];
   define cumFrequency/'No. of Cases';
   define made_new/computed noprint;
   compute made_new;
      if (&stabv._sending='No' and percent = 0) then
         call define (_row_, "style", "style=[BACKGROUND=lightgrey]");
      else if (&stabv._sending='No' and percent ne 0) then
         call define (_row_, "style", "style=[BACKGROUND=lightgrey Foreground=red]");
   endcomp;
run;

ods excel close;
libname _all_ clear;
