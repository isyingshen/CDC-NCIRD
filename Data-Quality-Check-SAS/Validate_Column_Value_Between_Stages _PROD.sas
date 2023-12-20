/*This is to validate the updated variables/columns between stages*/
/*Staging from Stage3-Stage4*/
/*Created by Ying Shen on 29Jun21*/


*This line connects to the NNAD PROD database; 
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;


/*Validate the Columns/variables*/
/*Stage3_NNDSScasesT3_61*/
proc sql;
select dfa_unk_1
,dfa_unk_2
,dfa_unk_3
,dfa_unk_addtl_flag
,dfa_unk_collct_dt_1
,dfa_unk_collct_dt_2
,dfa_unk_collct_dt_3
,dfa_unk_dt_sent_cdc_1
,dfa_unk_dt_sent_cdc_2
,dfa_unk_dt_sent_cdc_3
,dfa_unk_lab_type_1
,dfa_unk_lab_type_2
,dfa_unk_lab_type_3
,dfa_unk_qnt_rslt_1
,dfa_unk_qnt_rslt_2
,dfa_unk_qnt_rslt_3
,dfa_unk_unit_1
,dfa_unk_unit_2
,dfa_unk_unit_3
,igg_acu_im_spec_from_1
,igg_acu_im_spec_from_2
,igg_acu_im_spec_from_3
,igg_acu_serum_spec_from_1
,igg_acu_serum_spec_from_2
,igg_acu_serum_spec_from_3
,igg_con_im_spec_from_1
,igg_con_im_spec_from_2
,igg_con_im_spec_from_3
,igg_con_serum_spec_from_1
,igg_con_serum_spec_from_2
,igg_con_serum_spec_from_3

from NNAD.Stage3_NNDSScasesT3_61(obs=10);
quit;

/*Stage3_NNDSScasesT8*/
proc sql;
select cellulitis
,otitis_media
,pericarditis
,peritonitis
from NNAD.Stage3_NNDSScasesT8(obs=10);
quit;


/*Stage3_netss*/
proc sql;
select n_outbrel
,dfa_unk_1
/*,dfa_unk_2*/
/*,dfa_unk_3*/
/*,dfa_unk_addtl_flag*/
,dfa_unk_collct_dt_1
/*,dfa_unk_collct_dt_2*/
/*,dfa_unk_collct_dt_3*/
/*,dfa_unk_dt_sent_cdc_1*/
/*,dfa_unk_dt_sent_cdc_2*/
/*,dfa_unk_dt_sent_cdc_3*/
/*,dfa_unk_lab_type_1*/
/*,dfa_unk_lab_type_2*/
/*,dfa_unk_lab_type_3*/
/*,dfa_unk_qnt_rslt_1*/
/*,dfa_unk_qnt_rslt_2*/
/*,dfa_unk_qnt_rslt_3*/
/*,dfa_unk_unit_1*/
/*,dfa_unk_unit_2*/
/*,dfa_unk_unit_3*/
/*,igg_acu_im_spec_from_1*/
/*,igg_acu_im_spec_from_2*/
/*,igg_acu_im_spec_from_3*/
/*,igg_acu_serum_spec_from_1*/
/*,igg_acu_serum_spec_from_2*/
/*,igg_acu_serum_spec_from_3*/
/*,igg_con_im_spec_from_1*/
/*,igg_con_im_spec_from_2*/
/*,igg_con_im_spec_from_3*/
/*,igg_con_serum_spec_from_1*/
/*,igg_con_serum_spec_from_2*/
/*,igg_con_serum_spec_from_3*/
,cellulitis
,otitis_media
,pericarditis
,peritonitis
from NNAD.Stage3_netss (obs=10);
quit;


/*Stage4_NNDSScasesT3_61*/
proc sql;
select dfa_unk_1
,dfa_unk_2
,dfa_unk_3
,dfa_unk_addtl_flag
,dfa_unk_collct_dt_1
,dfa_unk_collct_dt_2
,dfa_unk_collct_dt_3
,dfa_unk_dt_sent_cdc_1
,dfa_unk_dt_sent_cdc_2
,dfa_unk_dt_sent_cdc_3
,dfa_unk_lab_type_1
,dfa_unk_lab_type_2
,dfa_unk_lab_type_3
,dfa_unk_qnt_rslt_1
,dfa_unk_qnt_rslt_2
,dfa_unk_qnt_rslt_3
,dfa_unk_unit_1
,dfa_unk_unit_2
,dfa_unk_unit_3
,igg_acu_im_spec_from_1
,igg_acu_im_spec_from_2
,igg_acu_im_spec_from_3
,igg_acu_serum_spec_from_1
,igg_acu_serum_spec_from_2
,igg_acu_serum_spec_from_3
,igg_con_im_spec_from_1
,igg_con_im_spec_from_2
,igg_con_im_spec_from_3
,igg_con_serum_spec_from_1
,igg_con_serum_spec_from_2
,igg_con_serum_spec_from_3

from NNAD.Stage4_NNDSScasesT3_61(obs=10);
quit;

/*Stage4_NNDSScasesT8*/
proc sql;
select cellulitis
,otitis_media
,pericarditis
,peritonitis
from NNAD.Stage4_NNDSScasesT8(obs=10);
quit;

/*Stage4_NNDSScasesT1*/
proc sql;
select n_outbrel
from NNAD.Stage4_NNDSScasesT1(obs=10);
quit;

/*End of Validating the Columns/variables*/


/*Start of validating values*/
%macro validate_value(column, table1,table2);
title "Validate &column in &table1 and &table2";
proc sql;
select a.local_record_id
,a.condition
,a.report_jurisdiction
,a.mmwr_year
,a.&column 
,b.&column 
,case when a.&column = b.&column then 0 else 1
end as compare
FROM nnad.&table1 as a
left join nnad.&table2 as b
on a.local_record_id=b.local_record_id 
and a.condition=b.condition 
and a.report_jurisdiction=b.report_jurisdiction 
and a.mmwr_year=b.mmwr_year 
/*and a.wsystem=b.wsystem */
and a.site=b.site
where a.&column is not null or b.&column is not null
having compare=1
order by compare desc;
quit;
%mend validate_value;

%validate_value(dfa_unk_1,stage3_netss,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_collct_dt_1,stage3_netss,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_addtl_flag,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_collct_dt_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_collct_dt_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_collct_dt_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_dt_sent_cdc_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_dt_sent_cdc_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_dt_sent_cdc_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_lab_type_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_lab_type_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_lab_type_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_qnt_rslt_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_qnt_rslt_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_qnt_rslt_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_unit_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_unit_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(dfa_unk_unit_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_acu_im_spec_from_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_acu_im_spec_from_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_acu_im_spec_from_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_acu_serum_spec_from_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_acu_serum_spec_from_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_acu_serum_spec_from_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_con_im_spec_from_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_con_im_spec_from_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_con_im_spec_from_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_con_serum_spec_from_1,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_con_serum_spec_from_2,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(igg_con_serum_spec_from_3,Stage3_NNDSScasesT3_61,Stage4_NNDSScasesT3_61);
%validate_value(cellulitis,Stage3_NNDSScasesT8,Stage3_NNDSScasesT8);
%validate_value(otitis_media,Stage3_NNDSScasesT8,Stage3_NNDSScasesT8);
%validate_value(pericarditis,Stage3_NNDSScasesT8,Stage3_NNDSScasesT8);
%validate_value(peritonitis,Stage3_NNDSScasesT8,Stage3_NNDSScasesT8);


proc sql;
select count(*) from NNAD.Stage4_NNDSScasesT3_61;
quit;

proc sql;
select count(*) from NNAD.Stage3_netss;
quit;


/*End of validating values*/
