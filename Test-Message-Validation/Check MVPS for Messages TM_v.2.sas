 /********************************************************************/
 /* PROGRAM NAME: Check MVPS for Messages TM                         */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2021/7/3                                                */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to automate the process of             */
 /*           reviewing the limited prod messages in MVPS            */
 /*                                                                  */ 
 /* INPUT:    mvps database                                          */
 /*           juris code, condition code and mvps_datetime_updated   */ 
 /*                                                                  */ 
 /*                                                                  */ 
 /* OUTPUT:  a list of messages found in mvps                        */
 /*                                                                  */ 
 /* Date Modified:2022/1/4                                           */
 /* Modified by:Ying Shen                                            */
 /* Changes:  Added obr22 in the output                              */
 /* Date Modified: 5/2/2023                                          */
 /********************************************************************/


%let jurs=11; 
%let jurs=11; *Jurisdiction FIPS code;
%let cond=11065; *5 digit event code;

/*MVPS database libname statement. Modify catalog for the following: */
/*For Test Messages and Limited Production Data, review MVPS_ONB*/
/*For Year-to-Date and Production data, review MVPS_PROD */

libname mvps OLEDB provider="sqlncli11"
     properties = ( "data source"="MVPSdata,1201\QSRV1" "Integrated Security"="SSPI"
           "Initial Catalog"="MVPS_ONB" ) schema=hl7 access=readonly;

/*Sample code to confirm or review submitted messages from mvps message-meta_vw*/
data mvps;
      set mvps.message_meta_vw;
      where notifiable_condition_cd = "&cond" and national_reporting_jurisdiction_ = "&jurs" ;
/*		and local_record_id in('CAS10763089AK01','CAS10763052AK01','CAS10765232AK01','CAS10765231AK01','CAS10767106AK01','CAS10749670AK01');*/
/*and msg_received_dttm > '1OCT2021'd;*/
run;

proc print data=mvps;
var msg_transaction_id notifiable_condition_cd national_reporting_jurisdiction_ current_record_flag local_record_id msg_received_dttm mvps_datetime_updated electronic_case_notification_to0 gen_msg_guide condition_specific_msg_guide record_status msg_sequence_id;
/*by msg_received_dttm;*/
run;

/*proc contents data=mvps.message_meta_vw;*/
/*run;*/
