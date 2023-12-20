libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="dspv-infc-1601\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS 
                        access=readonly;

%macro complete_check(table_n, col_n);
title justify=l"Number of &table_n, &col_n";
	proc sql;
	select count(*) as null_&col_n
	from NNAD.&table_n
	where &col_n is null;

	select count(*) as not_null_&col_n
	from NNAD.&table_n
	where &col_n is not null;
	quit;
%mend complete_check; 


/*COVID19_NNDSSCasesT3_Vertical_vw*/
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,obx_3_1);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,condition);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,mmwr_year);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,report_jurisdiction);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,local_record_id);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,site);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,wsystem);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,dup_SequenceID);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,ContentID_str);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,trans_id);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,obx_id);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,obx_4);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,obj_seq_id);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,obx_3_1);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,obx_5);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,obx_5_9);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,repeat_prefix);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,var_name);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,contentv_name);
%complete_check(COVID19_NNDSSCasesT3_Vertical_vw,contentID);

/*COVID19_NNDSSCasesT1_vw*/
%complete_check(COVID19_NNDSSCasesT1_vw,local_record_id);
%complete_check(COVID19_NNDSSCasesT1_vw,condition);
%complete_check(COVID19_NNDSSCasesT1_vw,mmwr_year);
%complete_check(COVID19_NNDSSCasesT1_vw,report_jurisdiction);
%complete_check(COVID19_NNDSSCasesT1_vw,source_system);
%complete_check(COVID19_NNDSSCasesT1_vw,trans_id);
%complete_check(COVID19_NNDSSCasesT1_vw,dup_SequenceID);
%complete_check(COVID19_NNDSSCasesT1_vw,wsystem);
%complete_check(COVID19_NNDSSCasesT1_vw,site);
%complete_check(COVID19_NNDSSCasesT1_vw,admit_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,age_invest);
%complete_check(COVID19_NNDSSCasesT1_vw,age_invest_units);
%complete_check(COVID19_NNDSSCasesT1_vw,ak_n_ai);
%complete_check(COVID19_NNDSSCasesT1_vw,asian);
%complete_check(COVID19_NNDSSCasesT1_vw,binationalreport_addtl_flag);
%complete_check(COVID19_NNDSSCasesT1_vw,binationalreport_oth_txt);
%complete_check(COVID19_NNDSSCasesT1_vw,binationalreport_oth_ynu);
%complete_check(COVID19_NNDSSCasesT1_vw,binatl_case_contacts);
%complete_check(COVID19_NNDSSCasesT1_vw,binatl_exp_by_res);
%complete_check(COVID19_NNDSSCasesT1_vw,binatl_exp_in_country);
%complete_check(COVID19_NNDSSCasesT1_vw,binatl_other_situations);
%complete_check(COVID19_NNDSSCasesT1_vw,binatl_product_exp);
%complete_check(COVID19_NNDSSCasesT1_vw,binatl_res_of_country);
%complete_check(COVID19_NNDSSCasesT1_vw,birth_country);
%complete_check(COVID19_NNDSSCasesT1_vw,birth_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,birthplace_other);
%complete_check(COVID19_NNDSSCasesT1_vw,black);
%complete_check(COVID19_NNDSSCasesT1_vw,case_inv_start_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,case_status);
%complete_check(COVID19_NNDSSCasesT1_vw,cdc_verbal_notify_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,comment);
%complete_check(COVID19_NNDSSCasesT1_vw,days_in_hosp);
%complete_check(COVID19_NNDSSCasesT1_vw,death_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,died);
%complete_check(COVID19_NNDSSCasesT1_vw,discharge_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,disease_acquired);
%complete_check(COVID19_NNDSSCasesT1_vw,dx_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,electr_submitted_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,ethnicity);
%complete_check(COVID19_NNDSSCasesT1_vw,expcity1);
%complete_check(COVID19_NNDSSCasesT1_vw,expcity2);
%complete_check(COVID19_NNDSSCasesT1_vw,expcity3);
%complete_check(COVID19_NNDSSCasesT1_vw,expcity4);
%complete_check(COVID19_NNDSSCasesT1_vw,expcity5);
%complete_check(COVID19_NNDSSCasesT1_vw,expcity_oth_txt);
%complete_check(COVID19_NNDSSCasesT1_vw,expcountry1);
%complete_check(COVID19_NNDSSCasesT1_vw,expcountry2);
%complete_check(COVID19_NNDSSCasesT1_vw,expcountry3);
%complete_check(COVID19_NNDSSCasesT1_vw,expcountry4);
%complete_check(COVID19_NNDSSCasesT1_vw,expcountry5);
%complete_check(COVID19_NNDSSCasesT1_vw,expcountry_oth_txt);
%complete_check(COVID19_NNDSSCasesT1_vw,expcounty1);
%complete_check(COVID19_NNDSSCasesT1_vw,expcounty2);
%complete_check(COVID19_NNDSSCasesT1_vw,expcounty3);
%complete_check(COVID19_NNDSSCasesT1_vw,expcounty4);
%complete_check(COVID19_NNDSSCasesT1_vw,expcounty5);
%complete_check(COVID19_NNDSSCasesT1_vw,expcounty_oth_txt);
%complete_check(COVID19_NNDSSCasesT1_vw,exposure_addtl_flag);
%complete_check(COVID19_NNDSSCasesT1_vw,expstateprov1);
%complete_check(COVID19_NNDSSCasesT1_vw,expstateprov2);
%complete_check(COVID19_NNDSSCasesT1_vw,expstateprov3);
%complete_check(COVID19_NNDSSCasesT1_vw,expstateprov4);
%complete_check(COVID19_NNDSSCasesT1_vw,expstateprov5);
%complete_check(COVID19_NNDSSCasesT1_vw,expstateprov_oth_txt);
%complete_check(COVID19_NNDSSCasesT1_vw,first_electr_submit_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,first_phd_suspect_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,first_report_county_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,first_report_phd_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,first_report_state_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,hi_n_pi);
%complete_check(COVID19_NNDSSCasesT1_vw,hospitalized);
%complete_check(COVID19_NNDSSCasesT1_vw,illness_duration);
%complete_check(COVID19_NNDSSCasesT1_vw,illness_duration_units);
%complete_check(COVID19_NNDSSCasesT1_vw,illness_end_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,illness_onset_dt);
%complete_check(COVID19_NNDSSCasesT1_vw,immediate_nnc_criteria);
%complete_check(COVID19_NNDSSCasesT1_vw,import_city);
%complete_check(COVID19_NNDSSCasesT1_vw,import_country);
%complete_check(COVID19_NNDSSCasesT1_vw,import_county);
%complete_check(COVID19_NNDSSCasesT1_vw,import_state);
%complete_check(COVID19_NNDSSCasesT1_vw,jurisdiction);
%complete_check(COVID19_NNDSSCasesT1_vw,legacy_case_id);
%complete_check(COVID19_NNDSSCasesT1_vw,local_subject_id);
%complete_check(COVID19_NNDSSCasesT1_vw,mmwr_week);
%complete_check(COVID19_NNDSSCasesT1_vw,msh_id_disease);
%complete_check(COVID19_NNDSSCasesT1_vw,msh_id_generic);
%complete_check(COVID19_NNDSSCasesT1_vw,msh_id_notifiable);
%complete_check(COVID19_NNDSSCasesT1_vw,n_cdcdate);
%complete_check(COVID19_NNDSSCasesT1_vw,n_count);
%complete_check(COVID19_NNDSSCasesT1_vw,n_county);
%complete_check(COVID19_NNDSSCasesT1_vw,n_datet);
%complete_check(COVID19_NNDSSCasesT1_vw,n_expandedcaseid);
%complete_check(COVID19_NNDSSCasesT1_vw,n_int_date);
%complete_check(COVID19_NNDSSCasesT1_vw,n_labtestdate);
%complete_check(COVID19_NNDSSCasesT1_vw,n_printed);
%complete_check(COVID19_NNDSSCasesT1_vw,n_race);
%complete_check(COVID19_NNDSSCasesT1_vw,n_rectype);
%complete_check(COVID19_NNDSSCasesT1_vw,n_unkeventd);
%complete_check(COVID19_NNDSSCasesT1_vw,n_update);
%complete_check(COVID19_NNDSSCasesT1_vw,outbreak_assoc);
%complete_check(COVID19_NNDSSCasesT1_vw,outbreak_name);
%complete_check(COVID19_NNDSSCasesT1_vw,pregnant);
%complete_check(COVID19_NNDSSCasesT1_vw,race_asked_but_unk);
%complete_check(COVID19_NNDSSCasesT1_vw,race_no_info);
%complete_check(COVID19_NNDSSCasesT1_vw,race_not_asked);
%complete_check(COVID19_NNDSSCasesT1_vw,race_oth);
%complete_check(COVID19_NNDSSCasesT1_vw,race_oth_txt);
%complete_check(COVID19_NNDSSCasesT1_vw,race_refused);
%complete_check(COVID19_NNDSSCasesT1_vw,race_unk);
%complete_check(COVID19_NNDSSCasesT1_vw,reporter_email);
%complete_check(COVID19_NNDSSCasesT1_vw,reporter_name);
%complete_check(COVID19_NNDSSCasesT1_vw,reporter_phone);
%complete_check(COVID19_NNDSSCasesT1_vw,reporting_county);
%complete_check(COVID19_NNDSSCasesT1_vw,reporting_source);
%complete_check(COVID19_NNDSSCasesT1_vw,reporting_state);
%complete_check(COVID19_NNDSSCasesT1_vw,reporting_zip);
%complete_check(COVID19_NNDSSCasesT1_vw,res_country);
%complete_check(COVID19_NNDSSCasesT1_vw,res_county);
%complete_check(COVID19_NNDSSCasesT1_vw,res_state);
%complete_check(COVID19_NNDSSCasesT1_vw,res_zip);
%complete_check(COVID19_NNDSSCasesT1_vw,result_status);
%complete_check(COVID19_NNDSSCasesT1_vw,sex);
%complete_check(COVID19_NNDSSCasesT1_vw,state_case_id);
%complete_check(COVID19_NNDSSCasesT1_vw,transmission);
%complete_check(COVID19_NNDSSCasesT1_vw,white);





/*  proc sql;*/
/*	create table test as*/
/*	select site, local_record_id*/
/*	from NNAD.COVID19_NNDSSCasesT2_vw;*/
/*  quit;*/
/**/
/*  proc freq data=test;*/
/*  run;*/
