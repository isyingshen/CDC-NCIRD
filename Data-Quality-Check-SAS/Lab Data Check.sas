/*Lab Data Check*/
/*Compare the Q1Q2 Combos in Vertical Table(in BI report) and other T3 tables*/

/*Connect to NNAD DB*/

libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS 
                        access=readonly;

%macro lab_data_check(table_n, var_n);
title justify=l"Number of composites for &var_n at &table_n";
proc sql;
select COUNT(distinct (local_record_id)) as num_composites
  from NNAD.&table_n
  where &var_n is not null;
quit;
%mend lab_data_check;

%macro lab_data_check_mumps(table_n, var_n);
title justify=l"Number of composites for &var_n at &table_n";
proc sql;
select COUNT(distinct (local_record_id)) as num_composites
  from NNAD.&table_n
  where condition='10180' and
&var_n is not null;
quit;
%mend lab_data_check;

/*2020-12-29*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgG_unsp_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgG_unsp_Serum_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgG_unsp_Serum_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgM_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_11_vw,IgM_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_11_vw,IgM_Serum_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_11_vw,im_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_16_vw,im_Nose_swab_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_16_vw,im_Nose_swab_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_16_vw,im_Nose_swab_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_17_vw,im_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_17_vw,im_NP_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_17_vw,im_NP_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_20_vw,im_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_22_vw,im_Unk_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_22_vw,im_Unk_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_22_vw,im_Unk_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_interp_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Plasma_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Serum_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_40_vw,gene_N_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Blood_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Blood_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_rapid_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_rapid_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nasal_swab_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nasal_swab_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nasal_swab_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nose_swab_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nose_swab_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nose_swab_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_asp_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNA_Saliva_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNA_Saliva_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNA_Saliva_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNAnonprobe_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNAnonprobe_NP_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNAnonprobe_NP_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_9_vw,IgG_unsp_Blood_1);*/

/*2021-01-04*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nasal_swab_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNAnonprobe_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNA_Saliva_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNAnonprobe_NP_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNAnonprobe_NP_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nose_swab_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNA_Saliva_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_17_vw,im_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgG_unsp_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_46_vw,RNA_Saliva_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nasal_swab_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_22_vw,im_Unk_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_rapid_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_16_vw,im_Nose_swab_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_17_vw,im_NP_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_9_vw,IgG_unsp_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_16_vw,im_Nose_swab_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_22_vw,im_Unk_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nose_swab_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nasal_swab_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_17_vw,im_NP_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgG_unsp_Serum_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_22_vw,im_Unk_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_NP_asp_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Nose_swab_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgM_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_11_vw,IgM_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_16_vw,im_Nose_swab_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_interp_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_40_vw,gene_N_NP_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Blood_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_20_vw,im_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_11_vw,im_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Blood_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_rapid_Serum_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgG_unsp_Serum_3);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Serum_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_rapid_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_9_vw,IgG_unsp_Blood_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_41_vw,IgA_Blood_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_42_vw,IgG_IgM_Serum_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_11_vw,IgM_Serum_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_38_vw,Ab_pres_Plasma_1);*/
/*%lab_data_check(COVID19_NNDSScasesT3_10_vw,IgM_Blood_2);*/
/*%lab_data_check(COVID19_NNDSScasesT3_45_vw,RNA_Oralfluid_1);*/


/*2022-1-25*/
%lab_data_check_mumps(Stage4_NNDSScasesT3_6,Cult_Oth_1);
%lab_data_check_mumps(Stage4_NNDSScasesT3_7,Cult_Unk_1);
%lab_data_check_mumps(Stage4_NNDSScasesT3_9,igg_un_Blood_1);
%lab_data_check_mumps(Stage4_NNDSScasesT3_10,igg_un_Serum_1);
%lab_data_check_mumps(Stage4_NNDSScasesT3_10,igg_un_Serum_2);
%lab_data_check_mumps(Stage4_NNDSScasesT3_10,igg_un_Serum_3);
%lab_data_check_mumps(Stage4_NNDSScasesT3_10,IgM_Blood_1);
%lab_data_check_mumps(Stage4_NNDSScasesT3_11,IgM_Serum_1);
%lab_data_check_mumps(Stage4_NNDSScasesT3_11,IgM_Serum_2);
%lab_data_check_mumps(Stage4_NNDSScasesT3_11,IgM_Serum_3);
%lab_data_check_mumps(Stage4_NNDSScasesT3_31,PCR_Buccal_1);
%lab_data_check_mumps(Stage4_NNDSScasesT3_31,PCR_Buccal_2);
%lab_data_check_mumps(Stage4_NNDSScasesT3_34,PCR_Unk_1);


/*dm 'odsresults; clear';*/

/*Investigation Code*/
/*proc sql;*/
/*  select local_record_id*/
/*  ,trans_id*/
/*  ,igg_unsp_blood_1*/
/*    FROM [NCIRD_DVD_VPD].[NNDSS].[Stage3_NNDSScasesT3_9]*/
/*	where IgG_unsp_Blood_1 is not null;*/
/*quit;*/
/**/
/*proc sql;*/
/*SELECT [condition]*/
/*      ,[mmwr_year]*/
/*      ,[report_jurisdiction]*/
/*      ,[local_record_id]*/
/*      ,[site]*/
/*      ,[wsystem]*/
/*      ,[dup_SequenceID]*/
/*      ,[ContentID_str]*/
/*      ,[trans_id]*/
/*      ,[obx_id]*/
/*      ,[obx_4]*/
/*      ,[obj_seq_id]*/
/*      ,[obx_3_1]*/
/*      ,[obx_5]*/
/*      ,[obx_5_9]*/
/*      ,[repeat_prefix]*/
/*      ,[var_name]*/
/*      ,[contentv_name]*/
/*      ,[contentID]*/
/*  FROM [NCIRD_DVD_VPD].[NNDSS].[Stage3_NNDSSCasesT3_Vertical]*/
/*  where contentv_name like '%IgG_unsp_Blood_1%';*/
/*  quit;*/
