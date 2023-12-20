/*Check NNAD Created Test Messages*/

/*%let jurs=34; *Jurisdiction FIPS code;*/
/*%let cond=11065; *5 digit event code;*/

/*MVPS database libname statement. Modify catalog for the following: */
/*For Test Messages and Limited Production Data, review MVPS_ONB*/
/*For Year-to-Date and Production data, review MVPS_PROD */

libname mvps OLEDB provider="sqlncli11"
     properties = ( "data source"="MVPSdata\QSRV1" "Integrated Security"="SSPI"
           "Initial Catalog"="MVPS_ONB" ) schema=hl7 access=readonly;

/*Sample code to confirm or review submitted messages from mvps message-meta_vw*/

data mvps;
      set mvps.message_meta_vw;
/*      where notifiable_condition_cd = "&cond" and national_reporting_jurisdiction_ = "&jurs" ;*/
		where local_record_id in ('5157671','5157672','Leg_NNDSS_TC_011','Leg_NNDSS_TC_011','Leg_NNDSS_TC_012',
'Leg_NNDSS_TC_013','Leg_NNDSS_TC_014','Leg_NNDSS_TC_015','Leg_NNDSS_TC_016','Leg_NNDSS_TC_017','Leg_NNDSS_TC_018',
'Leg_NNDSS_TC_019','Leg_NNDSS_TC_0110','Leg_NNDSS_TC_0111','Leg_NNDSS_TC_0112');
run;

proc print data=mvps;
var msg_transaction_id notifiable_condition_cd national_reporting_jurisdiction_ current_record_flag local_record_id mvps_datetime_updated gen_msg_guide condition_specific_msg_guide record_status msg_sequence_id;

run;
