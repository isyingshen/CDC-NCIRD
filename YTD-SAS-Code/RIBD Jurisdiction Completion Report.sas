/*************************************************************************************************/
/* Description: HL7 Completetion Report for RIBD                                                 */
/*              This code creates a report to indicate the percent missing for HL7 variables     */
/*              for the RIBD MMGs. (Based on Hannah's Implementation Spreadsheet).               */
/*              Change the FIPS state number to the appropriate jurisdisction number for which   */
/*              you want the completeness report.                                                */
/*                                                                                               */
/* Created by :   Chrissy Miner    9/4/2019                                                      */
/* Modified by:   Samatha Chindam  11/12/2019  -Standardized the code                            */
/*															  -Added the column to show total case count        */
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
      %let rootdir = \\cdc\csp_project\NCIRD_MVPS\&environment\Source;
   %end;
%mend platform_path;
%platform_path;

options mprint mlogic symbolgen NOQUOTELENMAX
        sasautos = (sasautos,
                    "&projdir\Source\Macros",
                    "&rootdir\Macros"
                    );
                
%DBserverByEnv(AppName=NNAD, Environment=&environment);

%let fipsn=13; /* For all jurisdictions, the state FIPS number needs to be changed here */
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
   if report_jurisdiction="&fipsn" and condition in ("10590", "11723", "10490", "10150", "10450");
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

/* Lab data */
%macro loop;
   %do i=1 %to 37;

data t3_&i.;
   set nmi.stage4_NNDSScasesT3_&i.;
   if report_jurisdiction="&fipsn" and trans_id ne . and condition in ("10590", "11723", "10490", "10150", "10450");
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

proc sql noprint ; /* pulls list of variable names */
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

   select NAME into :species separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_species");

   select count(NAME) into :speciesn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_species");

   select NAME into :serot separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_serotype");

   select count(NAME) into :serotn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_serotype");

   select NAME into :serotmtd separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_srtyp_mthd");

   select count(NAME) into :serotmtdn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_srtyp_mthd");

   select NAME into :lbnm separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_lab_name");

   select count(NAME) into :lbnmn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_lab_name");

   select NAME into :tstmfr separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_test_mfr");

   select count(NAME) into :tstmfrn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_test_mfr");

   select NAME into :accnum separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_accsn_num");

   select count(NAME) into :accn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_accsn_num");

   select NAME into :titertype separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_titer_type");

   select count(NAME) into :ntitertyp separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_titer_type");

   select NAME into :titermtd separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_titer_mthd");

   select count(NAME) into :ntitermtd separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_titer_mthd");

   select NAME into :serog separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_serogroup");

   select count(NAME) into :serogn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_serogroup");

   select NAME into :serogmtd separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_srgp_mthd");

   select count(NAME) into :serogmtdn separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_srgp_mthd");

   select NAME into :tbrnd separated by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME, "_test_brand");

   select count(NAME) into :tbrndn separated  by ' '
   from dictionary.columns
   where libname='WORK' and memname='LAB' and type='char' and index(NAME,"_test_brand");

   select NAME into :tmtd separated by ' '
   from dictionary.columns
   where libname='WORK' and type='char' and (index(NAME, "_method_1") or index(NAME, "_method_2") or
         index(NAME, "_method_3"));

   select count(NAME) into :tmtdn separated  by ' '
   from dictionary.columns
   where libname='WORK' and type='char' and (index(NAME, "_method_1") or index(NAME, "_method_2") or
         index(NAME, "_method_3"));

quit;

data lab;
   set lab;

   array all{*} &sstt1 &sstt2 &sstt3 &ssttad;
   array qnum{*} &quant;
   array unit{*} &unit;
   array col{*} &coll;
   array sent{*} &sent;
   array labt{*} &labt;
   array spec{*} &species;
   array sero{*} &serot;
   array serom{*} &serotmtd;
   array labnm{*} &lbnm;
   array tsmfr{*} &tstmfr;
   array acc{*} &accnum;
   array ttype{*} &titertype;
   array tmtd{*} &titermtd;
   array serog{*} &serog;
   array serogmtd{*} &serogmtd;
   array tbrn{*} &tbrnd;
   array tmt{*} &tmtd;

   do i=1 to &nsstt.;
      if (all{i} ne ' ') then do;
         test_type=1;
         spec_source=1; /* spec_source is not part of RIBD in mmg auto, include spec_type instead as it is part of Lab epi group ? */
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

   do o=1 to &speciesn;
      if (spec{o} ne ' ') then 
         species=1;
   end;
   
   do p=1 to &serotn;
      if (sero{p} ne ' ') then
         serotyp_all=1;
   end;

   do q=1 to &serotmtdn.;
      if (serom{q} ne ' ') then
         seromtd_all=1;
   end;

   do r=1 to &lbnmn;
      if (labnm{r} ne ' ') then 
         lab_name=1;
   end;

   do t=1 to &tstmfrn;
      if (tsmfr{t} ne ' ') then
         test_manu=1;
   end;

   do u=1 to &accn;
      if (acc{u} ne ' ') then
         acc_num=1;
   end;

   do v=1 to &ntitertyp;
      if (ttype{v} ne ' ') then
         titer_type=1;
   end;

   do w=1 to &ntitermtd;
      if (tmtd{w} ne ' ') then
         titer_method=1;
   end;

   do x=1 to &serogn.;
      if (serog{x} ne ' ') then
         serogrp_all=1;
   end;

   do y=1 to &tbrndn.;
      if (tbrn{y} ne ' ') then
         test_brand=1;
   end;

   do z=1 to &serogmtdn;
      if (serogmtd{z} ne ' ') then
         serog_mtd=1;
   end;

   do a=1 to &tmtdn;
      if (tmt{z} ne ' ') then
         test_method=1;
   end;

   keep quant_res unit_comp col_date sent_date local_record_id report_jurisdiction mmwr_year 
        condition site wsystem test_type spec_source test_result species serotyp_all seromtd_all 
        lab_name lab_type test_manu acc_num titer_type titer_method serogrp_all test_brand serog_mtd 
        test_method;
run;
/* End lab data */

data nnad;
   set nnad;
   where source_system in (5, 15);

   /* genv2 vars */
   array race{10}    ak_n_ai asian black hi_n_pi race_no_info race_not_asked race_oth race_refused
                     race_unk white;
   array expcity{5}  expcity1-expcity5;
   array expcountry{5} expcountry1-expcountry5;
   array expcounty{5} expcounty1-expcounty5;
   array expstate{5} expstateprov1-expstateprov5;
   /* general vars */
   array binat{6}    binatl_case_contacts binatl_exp_by_res binatl_exp_in_country binatl_other_situations
                     binatl_product_exp binatl_res_of_country;  
   array signs{30}   Fever Headache JawPain MusclePain Parotit Sublingual_Swell Submand_Swell Fatigue 
                     Apnea Cough Cyanosis Paroxysm Post_tuss_vomit Whoop Sx_Unk Chills Diarrhea GI_illness
                     Nausea Photophobia Pneumonia Rash StiffNeck Vomit Coryza Conjunctivitis Arthralgia 
                     Arthritis Lymphadenopathy Symptoms_oth_txt;
   array comp{44}    Deafness Encephalitis Encephalitis Meningitis Orchitis Encephalopathy Seizures
                     Cereb_ataxia Dehydration Hemorrhagic skin_soft_tissue_inf Pneumonia 
                     Complications_oth_txt Comp_unk Mastitis Oophoritis Pancreatitis Otitis Diarrhea
                     Encephalitis Thrombocytopenia Croup Hepatitis Encephalitis Thrombocytopenia Cataract
                     Hearing_impairment congenital_heart_disease congenital_heart_disease_oth 
                     patent_ductus_arteriosus peripheral_pulmonic_stenosis Stenosis Congenital_glaucoma
                     pigmentary_retinopathy developmental_delay Meningoencephalitis Microencephaly Purpura
                     Enlarged_spleen Enlarged_liver Radiolucent_bone_disease Neonatal_jaundice Low_platelets
                     dermal_erythropoieses; /*Complications is not part of RIBD, Do we need this? */
   array occ2{2}     occupationcd1 occupationcd2;
   array occ{2}      occupationtxt1 occupationtxt2;
   array ind1{2}     industrycd1 industrycd2;
   array ind2 {2}     industrytxt1-industrytxt2;
   array vaxdose{10} vaxdose1-vaxdose10;
   array vaxexp {10} vaxexpdt1-vaxexpdt10;
   array vaxlot{10}  vaxlot1-vaxlot10;
   array vaxmfr{10}  vaxmfr1-vaxmfr10;
   array vaxndc{10}  vaxndc1-vaxndc10;
   array vaxrecid{10} vaxrecid1-vaxrecid10;
   array vaxtype{10} vaxtype1-vaxtype10;
   array vaxage{10}  vaxage1-vaxage10;
   array vaxageu{10} vaxageunits1-vaxageunits10;
   array vaxnm{10}   vaxname1-vaxname10;
   /* pathogen specific vars */
   array txdays{5}   txdurationdays1-txdurationdays5;
   array txrec{5}    txrcvd1-txrcvd5;
   array reashosp{7} hosp_var_complic hosp_IV_tx hosp_for_isolation hosp_non_var hosp_for_observation 
                     hosp_severe_var hosp_reason_unk; /*reason for hospitilization is part of varicella only, Do we need this for RIBD?*/
   array bacinf{26}  Sepsis_abortion Bacteremia_without_focus Septicemia_bacterial Chorioamnionitis 
                     Empyema Endometritis Epiglottitis Arthritis Meningitis Osteomyelitis 
                     BacterialInfection_oth_txt Pneumonia_oth_var Septicemia_puerperal Septic_shock 
                     BacterialInfection_unk Abscess  Bacteremia_asymptomatic Cellulitis Endocarditis HUS
                     Necro_fasciitis Otitis_media Pericarditis Peritonitis STSS conjunctivitis; 
   array undcon{57}  AIDS Alcohol_abuse Asthma Blood_cancer Cancer_treatment CSF_leak Resp_disease_chronic 
                     Hep_C_chronic Cirrhosis Cochlear_prosthesis Neuromuscular_disord Complement_deficiency
                     CHF Coronary_arteriosclerosis Corticosteroids Dialysis_chronic Deafness Dementia 
                     Diabetes Trouble_swallowing COPD Smoker_former Hodgkins_disease HIV Ig_deficiency
                     Immunosuppressive_therapy IVDU Kidney_disease Leukemia Cancer Myeloma 
                     Myocardial_infarction Nephrotic_syndrome No_underlying_conditions Obesity 
                     UnderylingConditions_oth_txt Premat_birth Renal_failure Sickle_cell Smoker_current 
                     organ_malignancy organ_transplant Missing_spleen Asplenia Lupus BMT 
                     UnderlyingConditions_unk Broken_skin CBV_accident Connect_tissue_disord 
                     Multiple_sclerosis Paralysis Parkinsons_disease Peptic_ulcer Peripheral_neuropathy
                     Peripheral_vascular_disease Seizures;
   array insur{5}    insurance1-insurance5;
   array hibc{7}     hib_contact_type1-hib_contact_type7;
   array nhib{7}     nonhib_contact_type1-nonhib_contact_type7;
   array sustype{10}  sustesttype1-sustesttype10;
   array susint{10}   sustestinterpret1-sustestinterpret10;
   array suslab{10}   SusTestLabType1-SusTestLabType10;
   array susmtd{10}   sustestmethod1-sustestmethod10;
   array susmic{10}   sustestmic1-sustestmic10;
   array susquan{10}  sustestresult1-sustestresult10;
   array vaxinf{10}  vaxinfosrce1-vaxinfosrce10;
   array txdose {5}  txdose1-txdose5;
   array txdoseunits{5} txdoseunits1-txdoseunits5;
   array txdur{5}    txdurationdays1-txdurationdays5;
   array contact{7}  contact_type1-contact_type7;
   array ppe{10}     Face_shield Gloves Goggles No_PPE PPE_oth_txt Overalls RespiratoryPE Protective_shoes 
                     Surgical_cap PPE_unk;
   array respppe{8}  Filter_piece_N95 Cartridge_95 Cartridge_99or100 No_respiratoryPE RespiratoryPE_oth_txt
                     Cartridge_oth Surgical_mask RespiratoryPE_unk;
   array glove{7}    Cloth Double_glove Leather No_gloves GloveMaterial_oth_txt Plastic GloveMaterial_unk;
   array brdtype{5}  birdtype1-birdtype5;
   array brdspec{5}  birdspecies1-birdspecies5;
   array brdquant{5} birdquantity1-birdquantity5;
   array brdhealth{5} birdhealthy1-birdhealthy5;
   array brdnhlth{5} birdnonhealthy1-birdnonhealthy5;
   array brdexpt{5}  birdexptype1-BirdExpType5;
   array brdexpn{5}  birdexpname1-birdexpname5;
   array brdexpad{5} birdexpaddr1-birdexpaddr5;
   array brdexset{5} birdexpsetting1-birdexpsetting5;
   array accname{10} accomname1-accomname10;
   array accaddr{10} accomaddr1-accomaddr10;
   array accst{10}   accomstate1-accomstate10;
   array acccity{10} accomcity1-accomcity10;
   array acccntry{10} accomcountry1-accomcountry10;
   array accroom{10} accomroom1-accomroom10;
   array acccom{10}  accomcomment1-accomcomment10;
   array accchkin{10} accomcheckindt1-accomcheckindt10;
   array accchkot{10} accomcheckoutdt1-accomcheckoutdt10;
   array acczip{10}  accomzip1-accomzip10;
   array hcset{11}   hcsetting1-hcsetting11;
   array hctyp{11}   hctype1-hctype11;
   array hcfnm{11}   hcfacname1-hcfacname11;
   array hctrns{11}  hctransplant1-hctransplant11;
   array hcreas{11}  hcreason1-hcreason11;
   array hcadd{11}   hcaddr1-hcaddr11;
   array hccit{11}   hccity1-hccity11;
   array hcst{11}    hcstate1-hcstate11;
   array hczip{11}   hczip1-hczip11;
   array hccom{11}   hccomment1-hccomment11;
   array hcw{11}     hcwmp1-hcwmp11;
   array fact{2}     factype1 factype2;
   array facexp{2}   facexp1 facexp2;
   array facnm{2}    facname1 facname2;
   array facad{2}    facaddr1 facaddr2;
   array facc{2}     faccity1 faccity2;
   array facst{2}    facstate1 facstate2;
   array faczip{2}   faczip1 faczip2;
   array faccom{2}   faccomments1 faccomments2;
   array facw{2}     facwmp1 facwmp2;
   array legexp{21}  exp_convention exp_near_construction exp_occ_construction exp_spa exp_fountain 
                     exp_mister exp_sprinkler exp_aerosol exp_oth_txt exp_waterpark  exp_shower_not_home
                     exp_truck_driver exp_respiratoryPE exp_bldg_cooling_tower exp_congregate_living 
                     exp_occ_kitchen exp_occ_waste_water exp_occ_industrial_plant exp_occ_custodial
                     exp_occ_water_leisure  exp_occ_device_maint;
   array water{6}    Bottled Distilled WaterType_oth_txt Sterile Tap WaterType_unk;
   array pcity{10}   portcity1-portcity10;
   array pcntry{10}  portcountry1-portcountry10;
   array pstate{10}  portstate1-portstate10;
   array portdt{10}  portdt1-portdt10;
  
   /* date arrays */
   array txstart{5} txstartdt1-txstartdt5;
   array vxdate{10} vaxdate1-vaxdate10;
   array txend{5}   txenddt1-txenddt5;
   array brdexpdt{5} birdexpdt1-birdexpdt5;
   array hcarrdt{11} hcarrivedt1-hcarrivedt11;
   array hcdpdt{11}  hcdepartdt1-hcdepartdt11;
   array facarr{11}  facarrivedt1-facarrivedt11;
   array facdep{11}  facdepartdt1-facdepartdt11;
  
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
   txdayscombo=' ';
   txreccombo=' ';
   hosprescombo=' ';
   txstrtdtcombo=' ';
   vxdtcombo=' ';
   
   bactinfcombo=' ';
   uncndcombo=' ';
   insurcombo=' ';
   hibcontcombo=' ';
   nhibcontcombo=' ';
   sustypecombo=' ';
   susinterpcombo=' ';
   suslabtypecombo=' ';
   sustmtdcombo=' ';
   susmiccombo=' ';
   sustestintcombo=' ';
   vaxinfocombo=' ';
   vaxagecombo=' ';
   vaxageucombo=' ';
   vaxnmcombo=' ';
   txdosecombo=' ';
   txdoseucombo=' ';
   txdurcombo=' ';
   conttypecombo=' ';
   ppecombo=' ';
   resppecombo=' ';
   glovecombo=' ';
   brdtcombo=' ';
   birdspeccombo=' ';
   birdqcombo=' ';
   birdhlthcombo=' ';
   brdnhlthcombo=' ';
   brdexptcombo=' ';
   brdexpncombo=' ';
   brdexpaddcombo=' ';
   brdexpsttcombo=' ';
   accnmcombo=' ';
   accaddcombo=' ';
   accstcombo=' ';
   acccitycombo=' ';
   accntrycombo=' ';
   accroomcombo=' ';
   acccomcombo=' ';
   acchkincombo=' ';
   accchkotcombo=' ';
   acczipcombo=' ';
   hcsetcombo=' ';
   hctypcombo=' ';
   hcfnmcombo=' ';
   hctrnscombo=' ';
   hcreascombo=' ';
   hcaddcombo=' ';
   hccitcombo=' ';
   hcstcombo=' ';
   hczipcombo=' ';
   hccomcomb=' ';
   hcwcombo=' ';
   factcombo=' ';
   facexpcombo=' ';
   facnmcombo=' ';
   facadcombo=' ';
   facccombo=' ';
   facstcombo=' ';
   faczipcombo=' ';
   faccomcombo=' ';
   facwcombo=' ';
   legexpcombo=' ';
   watercombo=' ';
   pcitycombo=' ';
   pcntrycombo=' ';
   pstatecombo=' ';
   portdtcombo=' ';
   txstrtdtcombo=' ';
   txendcombo=' ';
   brdexpdtcombo=' ';
   hcarrdtcombo=' ';
   hcdpdtcombo=' ';
   facarrcombo=' ';
   facdepcombo=' ';

   do i=1 to 2;
      if (occ{i} ne ' ') then
         occ1combo='P';
      if (occ2{i} ne ' ') then 
         occ2combo='P';
      if (ind1{i} ne ' ') then
         ind1combo='P';
      if (ind2{i} ne ' ') then 
         ind2combo='P';
      if (fact{i} ne ' ') then
         factcombo='P';
      if (facexp{i} ne ' ') then
         facexpcombo='P';
      if (facnm{i} ne ' ') then 
         facnmcombo='P';
      if (facad{i} ne ' ') then 
         facadcombo='P';
      if (facc{i} ne ' ') then
         faccombo='P';
      if (facst{i} ne ' ') then
         facstcombo='P';
      if (faczip{i} ne ' ') then
         faczipcombo='P';
      if (faccom{i} ne ' ') then
         faccomcombo='P';
      if (facw{i} ne ' ') then
         facwcombo='P';
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
      if (insur{i} ne ' ') then
         insurcombo='P';
      if (txdose{i} ne ' ') then
         txdosecombo='P';
      if (txdoseunits{i} ne ' ') then
         txdoseucombo='P';
      if (txdur{i} ne ' ') then
         txdurcombo='P';
      if (brdtype{i} ne ' ') then
         brdtcombo='P';
      if (brdspec{i} ne ' ') then 
         birdspeccombo='P';
      if (brdquant{i} ne ' ') then
         birdqcombo='P';
      if (brdhealth{i} ne ' ') then
         birdhlthcombo='P';
      if (brdnhlth{i} ne ' ') then
         brdnhlthcombo='P';
      if (brdexpt{i} ne ' ') then
         brdexptcombo='P';
      if (brdexpn{i} ne ' ') then
         brdexpncombo='P';
      if (brdexpad{i} ne ' ') then
         brdexpaddcombo='P';
      if (brdexset{i} ne ' ') then
        brdexpsttcombo='P';
      if (txdays{i} ne ' ') then
         txdayscombo='P';
      if (txrec{i} ne ' ') then 
         txreccombo='P';
      if (txstart{i} ne .) then
         txstrtdtcombo='P';
      if (txend{i} ne .) then
         txendcombo='P';
      if (insur{i} ne ' ') then
         insurcombo='P';
      if (brdexpdt{i} ne ' ') then
         brdexpdtcombo='P';
   end;
  
   do i=1 to 6;
      if (binat{i} ne ' ') then
         binatcombo='P';
      if (water{i} ne ' ') then
         watercombo='P';
   end;
  
   do i=1 to 8;
      if (respppe{i} ne ' ') then
        resppecombo='P';
   end;

   do i=1 to 7;
      if (reashosp{i} ne ' ') then
         hosprescombo='P';
      if (contact{i} ne ' ') then
         conttypecombo='P';
      if (glove{i} ne ' ') then
         glovecombo='P';
		if (hibc{i} ne ' ') then
         hibcontcombo='P';
		if (nhib{i} ne ' ') then
         nhibcontcombo='P';
   end;

   do i=1 to 10;
      if (race{i} ne ' ') then
         racecombo='P';		
		if (sustype{i} ne ' ') then
         sustypecombo='P';
		if (susint{i} ne ' ') then
         susinterpcombo='P';
		if (suslab{i} ne ' ') then
         suslabtypecombo='P';
		if (susmtd{i} ne ' ') then
         sustmtdcombo='P';
	   if (susmic{i} ne ' ') then
         susmiccombo='P';
		if (susquan{i} ne ' ') then
         sustestintcombo='P';
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
      if (vaxinf{i} ne ' ') then
         vaxinfocombo='P';
      if (vxdate{i} ne .) then
         vxdtcombo='P';
      if (vaxage{i} ne ' ') then
         vaxagecombo='P';
      if (vaxageu{i} ne ' ') then
         vaxageucombo='P';
      if (vaxnm{i} ne ' ') then
         vaxnmcombo='P';
      if (ppe{i} ne ' ') then
         ppecombo='P';
      if (accname{i} ne ' ') then 
         accnmcombo='P';
      if (accaddr{i} ne ' ') then
         accaddcombo='P';
      if (accst{i} ne ' ') then
         accstcombo='P';
      if (acccity{i} ne ' ') then
         acccitycombo='P';
      if (acccntry{i} ne ' ') then
         accntrycombo='P';
      if (accroom{i} ne ' ') then
         accroomcombo='P';
      if (acccom{i} ne ' ') then
         acccomcombo='P';
      if (accchkin{i} ne ' ') then
         acchkincombo='P';
      if (accchkot{i} ne ' ') then
         accchkotcombo='P';
      if (acczip{i} ne ' ') then
         acczipcombo='P';
      if (pcity{i} ne ' ') then
         pcitycombo='P';
      if (pcntry{i} ne ' ') then
         pcntrycombo='P';
      if (pstate{i} ne ' ') then
         pstatecombo='P';
      if (portdt{i} ne ' ') then
         portdtcombo='P';
   end;
  
   do i=1 to 11;
      if (hcset{i} ne ' ') then
         hcsetcombo='P';
      if (hctyp{i} ne ' ') then
         hctypcombo='P';
      if (hcfnm{i} ne ' ') then
         hcfnmcombo='P';
      if (hctrns{i} ne ' ') then
         hctrnscombo='P';
      if (hcreas{i} ne ' ') then
         hcreascombo='P';
      if (hcadd{i} ne ' ') then
         hcaddcombo='P';
      if (hccit{i} ne ' ') then
         hccitcombo='P';
      if (hcst{i} ne ' ') then
         hcstcombo='P';
      if (hczip{i} ne ' ') then
         hczipcombo='P';
      if (hccom{i} ne ' ') then
         hccomcomb='P';
      if (hcw{i} ne ' ') then 
         hcwcombo='P';
      if (hcarrdt{i} ne ' ') then
         hcarrdtcombo='P';
      if (hcdpdt{i} ne ' ') then
         hcdpdtcombo='P';
      if (facarr{i} ne ' ') then
         facarrcombo='P';
      if (facdep{i} ne ' ') then
         facdepcombo='P';
   end;

   do i=1 to 21;
      if (legexp{i} ne ' ') then
         legexpcombo='P';
   end;
  
   do i=1 to 26;
      if (bacinf{i} ne ' ') then
         bactinfcombo='P';
   end;

   do i=1 to 30;
      if (signs{i} ne ' ') then
         signscombo='P';
   end;

   do i=1 to 44;
      if (comp{i} ne ' ') then 
         compcombo='P';
   end;

   do i=1 to 57;
      if (undcon{i} ne ' ') then
         uncndcombo='P';
   end;

run;

/*Creating 2 datasets- one for GenV2 variables and one for condition specific variables*/
/* Samatha: Variables msh_id_notifiable and msh_id_disease are not included here that are part of generic list in mmgauto, include them or not? ask SANG */
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
 keep local_record_id report_jurisdiction mmwr_year condition site wsystem msh_id_disease weight 
      weight_units height height_units conditions_exist pregnant_at_culture pregnancy_outcome 
      gest_age_weeks birth_weight birth_weight_units hib_contact non_hib_contact day_care 
      long_term_care investigation_status recurrent_pathogen recurrent_prev_state_id CRF_status   
      res_city age_onset age_onset_units res_type premat_infant epi_link_labconf ABCs_state_id 
      lab_test_done lab_confirmed spec_sent_to_cdc received_vax vax_dose_prior_onset_dt 
      num_vax_dose_prior_onset vax_per_acip_recs reason_not_vax_per_ACIP vax_history_comment 
      sus_test_done VPD_RC_lab_id VPD_RC_patient_id VPD_RC_spec_id higher_ed_college school_grade
      college_liv_situation college_name secondary_case sex_with_male sex_with_female num_male_partners
      HIV_status homeless eculizumab hosp_icu epi_link_confprob oxacillin_disk_zone_size oxacillin_result
      highest_temp_fever temp_units antibiotics autopsy_spec_type autopsy_result autopsy_dt 
      autopsy_lab_name xray_result xray_dt occ_onset industry_onset occ_duties respirator_fit_test 
      legionella_dx hosp_name hosp_city hosp_state nights_away HC_exposure nosocomial liv_fac_exposure
      liv_fac_assoc humidifier cruise_travel cruiseline ship_name cruise_depart_city cruise_depart_state  
      cruise_depart_country cruise_depart_dt cruise_return_city cruise_return_state cruise_return_country
      cruise_return_dt cruise_cabin_num NORSID racecombo expctycombo expcntrycombo expcntycombo expstatecombo
      binatcombo signscombo compcombo occ1combo occ2combo ind1combo ind2combo vxdtcombo vxdosecombo 
      vxexpcombo vxlotcombo vxmfcombo vxndccombo vxrecidcombo vxtypecombo vaxinfocombo txdayscombo 
      txreccombo hosprescombo txstrtdtcombo vxdtcombo bactinfcombo uncndcombo insurcombo hibcontcombo 
      nhibcontcombo sustypecombo susinterpcombo suslabtypecombo sustmtdcombo susmiccombo sustestintcombo 
      vaxagecombo vaxageucombo vaxnmcombo txdosecombo txdoseucombo txdurcombo conttypecombo ppecombo  
      resppecombo glovecombo brdtcombo birdspeccombo birdqcombo brdhlthcombo brdnhlthcombo brdexpdtcombo
      brdexpncombo brdexpaddcombo brdexpsttcombo accnmcombo accaddcombo accstcombo acccitycombo accntrycombo
      accroomcombo acccomcombo acchkincombo accchkotcombo acczipcombo hcsetcombo hctypcombo hcfnmcombo
      hctrnscombo hcreascombo hcaddcombo hccitcombo hcstcombo hczipcombo hccomcomb hcwcombo factcombo 
      facexpcombo facnmcombo facadcombo facccombo facstcombo faczipcombo faccomcombo facwcombo legexpcombo
      watercombo pcitycombo pcntrycombo pstatecombo portdtcombo txstrtdtcombo txendcombo brdexpdtcombo 
      hcarrdtcombo hcdpdtcombo  facarrcombo facdepcombo birdhlthcombo brdexptcombo;
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
   '10590'='H. influenzae'
   '10490'='Legionella'
   '10150'='N. meningitidis'
   '10450'='Psittacosis'
   '11723'='IPD'
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
   format mmwr_year-character-facdepcombo $missing. _numeric_ missingnum.; /* Using Proc Contents, you will know that the last character variable is 'facdepcombo' */
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
   array var{&num}  F_:; /* All the column names that are starting with 'F_' are put together into array */

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
   sheet='RIBD';
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
proc import datafile="&projdir\source\inputs\&stabv. RIBD Implementation Spreadsheet NCIRD Analysis.xlsx"
   DBMS=xlsx
   Out=IS replace;
   sheet="Analysis";
   getnames=yes;
run;

data is;
   set is;
   where abcs ne 'Y';
   if (condition='Generic v2') then
      condition='Gen V2';
   if (condition='Legionellosis') then
      condition='Legionella';
   if (de_identifier='N/A:PID-11.3') then
      de_identifier='PID_11_3';
run;

data is;
   set is;
   drop=compress(tranwrd((condition||de_identifier), '0D0A'x, '')); /* there are hidden carriage returns in the excel file */
   keep condition DE_Identifier PHA__Collected drop;
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
    
   length pha_collected $25.;

   /*removing signs and symptoms and type of complications indicator*/
   if (de_identifier in ('INV919', 'INV920', 'INV1046', 'N/A:OBR-31')) then /* INV662, VAC156, INV1086 are indicators too, do we need to include them here? */
      delete;

   /*Formatting PHA Collected*/
   PHA__Collected=upcase(PHA__Collected);

   if (index(PHA__Collected, 'YES') or index(PHA__Collected, 'Y ')) then  /* using Y space to avoid the ones from Only */
      pha_collected='Yes';
   if (index(PHA__Collected, 'NO')) then
      pha_collected='No';
   if (index(PHA__Collected, 'ONLY')) then
      pha_collected='Only certain conditions';

   drop pha__collected;
run;

/* Testing purpose, just to check if everything is categorized in the implementation spreadsheet, can remove the code */
proc freq data=all2;
   tables PHA_Collected;
run;

proc format;
   value per
   low-33.33='Red'
   33.34-66.66='Yellow'
   66.67-high='Green'
   ;
run;

options nobyline;

ods excel file="&projdir\Outputs\&stabv. YTD Completeness Report.xlsx" options(start_at="2, 2"  sheet_name="Completion" embedded_titles='YES'); 

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

/*Testing purpose on how to validate;*/
/*proc freq data=nnad;
   tables lab_test_done*condition/missing list;
   by condition;
run; 
