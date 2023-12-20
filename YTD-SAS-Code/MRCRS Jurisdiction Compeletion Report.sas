/*************************************************************************************************/
/* Description: HL7 Completetion Report for MRCRS                                                */
/*              This code creates a report to indicate the percent missing for HL7 variables     */
/*              for the MRCRS MMGs. (Based on Hannah's Implementation Spreadsheet).              */
/*                                                                                               */
/* Created by :   Chrissy Miner    10/24/2019                                                    */
/* Modified by:   Samatha Chindam  11/12/2019  -Standardized the code.                           */
/*                Samatha Chindam  12/12/2019  -Added the column to show total case count        */
/*                                              in the report                                    */
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

%let fipsn=41; /* For all jurisdictions, the state FIPS number needs to be changed here */

%let stabv=%sysfunc(fipnamel(&fipsn)); /* Converts FIPS number to state name */

libname nmi OLEDB
        provider="sqlncli11"
        properties = ( "data source"="&DBservName"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly; 

%macro epi;

   %do i=1 %to 6;

data t&i.;
   set nmi.stage4_NNDSScasesT&i.;
   if report_jurisdiction="&fipsn" and condition in ("10140", "10370", "10200");
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
   if report_jurisdiction="&fipsn" and trans_id ne . and condition in ("10140", "10370", "10200");
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

proc sql noprint ; /*pulls list of variable names*/

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

   select NAME into :adt separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and index(NAME, "_analyz_dt");

   select count(NAME) into :nadt separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and index(NAME, "_analyz_dt");

   select NAME into :gtyp separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_gentyp_");

   select count(NAME) into :ngtyp separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_gentyp_");
   
   select NAME into :stype separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_spec_type_");

   select count(NAME) into :nstype separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_spec_type_");
   
   select NAME into :vpdlid separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_vpdlab_id_");

   select count(NAME) into :nvpdlid separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_vpdlab_id_");
   
   select NAME into :vpdpid separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_vpdpt_id_");

   select count(NAME) into :nvpdpid separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_vpdpt_id_");

   select NAME into :vpdsid separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "vpdspec_id");

   select count(NAME) into :nvpdsid separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "vpdspec_id");

   select NAME into :specfr separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "spec_from_");

   select count(NAME) into :nspecfr separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "spec_from_");
quit;

data lab;
   set lab;

   array all{*} &sstt1 &sstt2 &sstt3 &ssttad;
   array qnum{*} &quant;
   array unit{*} &unit;
   array col{*} &coll;
   array sent{*} &sent;
   array labt{*} &labt;
   array anlyzdt{*} &adt;
   array gentyp{*} &gtyp;
   array vpdlbid{*} &vpdlid;
   array vpdptid{*} &vpdpid;
   array vpdspid{*} &vpdsid;
   array specfrm{*} &specfr;
   array spect{*} &stype;


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

   do o=1 to &nadt;
      if (anlyzdt{o} ne ' ') then
         analyze_dt=1;
   end;

   do p=1 to &ngtyp;
      if (gentyp{p} ne ' ') then
         geno_type=1;
   end;

   do q=1 to &nvpdlid;
      if (vpdlbid{q} ne ' ') then
         vpd_lab_id=1;
   end;

   do r=1 to &nvpdpid;
      if (vpdptid{r} ne ' ') then
         vpd_pt_id=1;
   end;

   do s=1 to &nvpdsid;
      if (vpdspid{s} ne ' ') then 
         vpd_spec_id=1;
   end;

   do x=1 to &nspecfr;
      if (specfrm{x} ne ' ') then
         specimen_from=1;
   end;

   do y=1 to &nstype;
      if (spect{y} ne ' ') then
         spec_type=1;
   end;

   keep local_record_id report_jurisdiction mmwr_year condition site wsystem test_type spec_source 
        test_result quant_res unit_comp col_date sent_date lab_type analyze_dt geno_type vpd_lab_id
        vpd_pt_id vpd_spec_id specimen_from spec_type;

run;
/*End lab data*/

data nnad;
   set nnad;

   where source_system in (5, 15);

   /*genv2 vars*/
   array race{10}      ak_n_ai asian black hi_n_pi race_no_info race_not_asked race_oth race_refused 
                       race_unk white;
   array expcity{5}    expcity1-expcity5;
   array expcountry{5} expcountry1-expcountry5;
   array expcounty{5}  expcounty1-expcounty5;
   array expstate{5}   expstateprov1-expstateprov5;
   /*general vars*/
   array binat{6}      binatl_case_contacts binatl_exp_by_res binatl_exp_in_country binatl_other_situations
                       binatl_product_exp binatl_res_of_country;
   array signs{30}     Fever Headache JawPain MusclePain  Parotit Sublingual_Swell Submand_Swell Fatigue 
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
   array ind2 {2}      industrytxt1-industrytxt2;
   array vaxdose{10}   vaxdose1-vaxdose10;
   array vaxexp {10}   vaxexpdt1-vaxexpdt10;
   array vaxlot{10}    vaxlot1-vaxlot10;
   array vaxmfr{10}    vaxmfr1-vaxmfr10;
   array vaxndc{10}    vaxndc1-vaxndc10;
   array vaxrecid{10}  vaxrecid1-vaxrecid10;
   array vaxtype{10}   vaxtype1-vaxtype10;
   array vaxage{10}    vaxage1-vaxage10; /* It is not in M, R and CRS, it is in HFLU, Mening and IPD  */
   array vaxageu{10}   vaxageunits1-vaxageunits10; /* It is not in M, R and CRS, it is in HFLU, Mening and IPD  */
   array vaxnm{10}     vaxname1-vaxname10; /* It is not in M, R and CRS, it is in Mening */
   array vaxinfsrc{10} vax_record_info_source1-vax_record_info_source10;

   /*pathogen specific vars*/
   array conf{5}       confirmation_epi_linked confirmation_lab_dx Confirmation_method_addtl_flag 
                       confirmation_no_info Confirmation_method_oth_txt;
   array trvl{5}       travel_destination1-travel_destination5;
   
   /*date arrays*/
   array trvlrdt{5}    travel_return_dt1-travel_return_dt5;
   array trvlddt{5}    travel_depart_dt1-travel_depart_dt5;
   array mombdt{5}     mom_prev_us_birth_dt1-mom_prev_us_birth_dt5;
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
   vxlotcombo=' ';
   vxmfcombo=' ';
   vxndccombo=' ';
   vxrecidcombo=' ';
   vxtypecombo=' ';
   vxinfsrcombo=' ';
   confmtdcombo=' ';
   trvdestcombo=' ';
   mombcombo=' ';
   trvlrdtcombo=' ';
   trvlddtcombo=' ';

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

   do i=1 to 5;
      if (expcity{i} ne ' ') then
         expctycombo='P';
      if (expcountry{i} ne ' ') then
         expcntrycombo='P';
      if (expstate{i} ne ' ') then
         expstatecombo='P';
      if (expcounty{i} ne ' ') then 
         expcntycombo='P';
      if (conf{i} ne ' ') then
         confmtdcombo='P';
      if (trvl{i} ne ' ') then
         trvdestcombo='P';
      if (trvlrdt{i} ne ' ') then
         trvlrdtcombo='P';
      if (trvlddt{i} ne ' ') then
         trvlddtcombo='P';      
   end;

   do i=1 to 6;
      if (binat{i} ne ' ') then 
         binatcombo='P';
   end;

   do i=1 to 10;
      if (race{i} ne ' ') then
         racecombo='P';
      if (vaxdose{i} ne ' ') then
         vxdosecombo='P';
      if (vaxexp{i} ne .) then
         vxexpcombo='P';
      if (vaxlot{i} ne ' ') then
         vxlotcombo='P';
      if (vaxmfr{i} ne ' ') then
         vxmfcombo='P';
      if (vaxndc{i} ne ' ') then
         vxndccombo='P';
      if (vaxrecid{i} ne ' ') then
         vxrecidcombo='P';
      if (vaxtype{i} ne ' ') then
         vxtypecombo='P';
      if (vxdate{i} ne .) then
         vxdtcombo='P';
      /*sam*/
      /*if (vaxage{i} ne ' ') then
         vaxagecombo='P';*/ 
      /*if (vaxageu{i} ne ' ') then 
         vaxageucombo='P';*/ 
      /*if (vaxnm{i} ne ' ') then
         vaxnmcombo='P';*/
      if (vaxinfsrc{i} ne ' ') then
         vxinfsrcombo='P';
   end;

   do i=1 to 30;
      if (signs{i} ne ' ') then
         signscombo='P';
   end;

   do i=1 to 44;
      if (comp{i} ne ' ') then
         compcombo='P';
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
   keep local_record_id report_jurisdiction mmwr_year condition site wsystem msh_id_disease 
        generalized_rash rash_onset_dt rash_duration rash_onset_age rash_onset_age_units highest_temp_fever
        temp_units fever_onset_dt xray_result res_city transmission_setting age_setting_verified 
        epi_link_confprob US_acquired trace_to_intl_import time_in_US time_in_US_units investigation_status
        detection_method hcp_onset import_status confirmation_dt lab_test_done lab_confirmed 
        spec_sent_to_cdc received_vax num_vax_doses_before_1st num_vax_doses_after_1st 
        num_vax_dose_prior_onset vax_dose_prior_onset_dt vax_per_acip_recs reason_not_vax_per_ACIP 
        vax_history_comment cause_of_death outbreak_of_3 expected_delivery_dt expected_delivery_locat 
        preg_weeks_gest preg_trimester immunity_test_done immunity_test_result immunity_test_year 
        immunity_test_age_years rubella_before prev_dx_by prev_disease_seroconf prev_disease_year 
        age_prev_dx age_prev_dx_units pregnancy_outcome fetus_age_weeks autopsy_done autopsy_result 
        prev_evaluation_dt cause_of_death_primary cause_of_death_second birth_state clinical_case_appraisal
        mom_rash mom_rash_onset_dt mom_rash_duration_days mom_fever mom_fever_onset_dt 
        mom_fever_duration_days mom_arthralgia_arthritis mom_lymphadenopathy mom_illness_oth gest_age_weeks
        age_dx age_dx_units birth_weight birth_weight_units mom_birth_country mom_time_in_US_years 
        mom_age_delivery mom_age_delivery_units mom_family_planning children_in_household 
        children_received_vax num_children_received_vax mom_res_country prenatal_care first_prenatal_care_dt
        prenatal_care_locat mom_serology_prior mom_serology_prior_dt mom_serology_prior_result 
        rubella_during_pregnancy sx_onset_month_pregnancy mom_lab_test_done mom_rubella_dx_physician 
        mom_rubella_dx_by mom_rubella_seroconf mom_know_where_exposed mom_intl_travel_1st_tri 
        mom_confirm_exposure mom_source_rel mom_exposure_dt mom_prev_US_birth num_prev_pregnancies 
        num_live_births num_live_births_US mom_received_vax mom_vax_info_source mom_num_vax_dose_prior_onset
        mom_vax_dose_prior_onset_dt mom_vax_per_acip_recs mom_reason_not_vax_per_ACIP racecombo expctycombo 
        expcntrycombo expcntycombo expstatecombo binatcombo signscombo compcombo occ1combo occ2combo 
        ind1combo ind2combo vxdtcombo vxdosecombo vxexpcombo vxinfsrcombo vxlotcombo vxmfcombo vxndccombo 
        vxrecidcombo vxtypecombo confmtdcombo trvdestcombo mombcombo trvlrdtcombo trvlddtcombo; /*144 or 142 vars */
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
   '10370'='CRS'
   '10140'='Measles'
   '10200'='Rubella'
   ;
run;

ods output onewayfreqs=genv2f;
proc freq data=genv2;
   tables _all_/missing;
   format _character_ $missing. _numeric_ missingnum.;
run;
ods output close;

proc sort data=nnad;
   by condition;
run;

ods output onewayfreqs=allvars;
proc freq data=nnad;
   tables _all_/missing;
   format mmwr_year-character-specimen_from $missing. _numeric_ missingnum.; /* Using Proc Contents, you will know that the last character variable is 'specimen_from' */
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
   sheet='MRCRS';
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
   drop=tranwrd(compress(condition||de_identifier), '0D0A'x, '');
run;

/*Implementation Spreadsheet*/
%macro isloop;

   %let name= CRS Measles Rubella;

   %do i=1 %to 3;
      %let pname=%scan(&name, &i);
proc import datafile="&projdir\source\inputs\&stabv. &pname. IS NCIRD Analysis.xlsx"
    DBMS=xlsx
    Out=IS&i. replace;
    sheet="Table 1 - Data Set WORK.ANALYSI";
    getnames=yes;
run;
      %if (&i=2 or &i=3) %then %do;
          data is&i.;
             set is&i.;
             if (condition='Generic v2') then
                 delete;
          run;
      %end;
   %end;

%mend;
%isloop;

data is;
   set is1-is3;
   if (condition='Generic v2') then
      condition='Gen V2';
   if (de_identifier='N/A:PID-11.3') then
      de_identifier='PID_11_3';
   if (de_identifier='N/A:NK1-4.6') then
      de_identifier='NK1_4_6';
run;

data is;
   set is;
   drop=compress(tranwrd((condition||de_identifier), '0D0A'x, ''));
   keep condition DE_Identifier PHA_Collected drop;
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
   merge is (in=a) priority (in=b);
   by drop;
   hl7_name=lowcase(hl7_name);
   drop2=compress(condition||hl7_name);
run;

proc sort data=priority_sent (drop=drop) nodupkey dupout=dups;
   by drop2;
run;

data allvars2;
   set allvars2;
   drop2=compress(condition||hl7_name);
run;

proc sort data=allvars2;
   by drop2;
run;

data all;
   merge allvars2 priority_sent (in=a);
   by drop2;
   if a;
run;

data all2;
   set all;
    
   length pha_collected $25.;

   /*removing signs and symptoms and type of complications indicator*/
   if (de_identifier in ('INV919', 'INV920', 'INV1046', 'N/A:OBR-31')) then
       delete;

   /*Formatting PHA Collected*/
   PHA__Collected=upcase(PHA_Collected);

   if (index(PHA__Collected, 'YES') or index(PHA__Collected, 'Y ')) then 
      pha_collected='Yes';
   if (index(PHA__Collected, 'NO')) then
      pha_collected='No';
   if (index(PHA__Collected, 'ONLY')) then
      pha_collected='Only certain conditions';

   drop pha__collected drop2;
run;

proc format;
   value per
   low-33.39='Red'
   33.4-66.59='Yellow'
   66.6-high='Green'
   ;
run;

options nobyline;
ods excel file="&projdir\Outputs\&stabv. MRCRS YTD Completeness Report.xlsx" options(start_at="2, 2"  sheet_name="Completion" embedded_titles='YES');

/*Report for each comment*/
proc report data=all2 spanrows nowd headline;
   title "Percent Completion Report for &stabv.";
   column condition DE_identifier Data_Element__DE__Name hl7_name ncird_priority PHA_Collected percent cumFrequency;
   define condition/group;
   define DE_identifier/ 'DE Identifier';
   define Data_Element__DE__Name/'DE Name';
   define hl7_name/'HL7 Variable Name';
   define PHA_Collected/"&stabv Submitting";   
   define ncird_priority/'NCIRD Priority';   
   define percent/'Percent Complete' style=[background= per.];
   define cumFrequency/'No. of Cases';
   compute PHA_collected;
      if (PHA_collected='No') then
         call define (_row_, "style", "style=[BACKGROUND=lightgrey]");
   endcomp;
run;

ods excel close;
libname _all_ clear;
