 /********************************************************************/
 /* PROGRAM NAME: Check MVPS for Messages LPM                        */
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
 /* Changes:  Added obr22 in the output                     		 */
 /*																	 */
 /* Date Modified:2023/10/25                                         */
 /* Modified by:Jheri GOdfrey                                         */
 /* Changes:  Added port number 1201 to MVPS server name  			  */													
 /********************************************************************/



%let jurs=02; *Jurisdiction FIPS code;
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
      where notifiable_condition_cd = "&cond" and national_reporting_jurisdiction_ = "&jurs" 
and mvps_datetime_updated > '09Feb2022'd;
/*and local_record_id in('CAS11411123AK01'*/
/*,'CAS11411143AK01'*/
/*,'CAS11411160AK01'*/
/*,'CAS11411180AK01'*/
/*,'CAS11411198AK01'*/
/*,'CAS11411222AK01'*/
/*,'CAS11411106AK01'*/
/*,'CAS11411128AK01'*/
/*,'CAS11411147AK01'*/
/*,'CAS11411165AK01'*/
/*,'CAS11411184AK01'*/
/*,'CAS11411201AK01'*/
/*,'CAS11411225AK01'*/
/*,'CAS11411120AK01'*/
/*,'CAS11411138AK01'*/
/*,'CAS11411157AK01'*/
/*,'CAS11411177AK01'*/
/*,'CAS11411193AK01'*/
/*,'CAS11411218AK01'*/
/*,'CAS11411118AK01'*/
/*,'CAS11411135AK01'*/
/*,'CAS11411155AK01'*/
/*,'CAS11411175AK01'*/
/*,'CAS11411191AK01'*/
/*,'CAS11411215AK01'*/
/*,'CAS11411103AK01'*/
/*,'CAS11411125AK01'*/
/*,'CAS11411146AK01'*/
/*,'CAS11411162AK01'*/
/*,'CAS11411182AK01'*/
/*,'CAS11411200AK01'*/
/*,'CAS11411223AK01'*/
/*,'CAS11411110AK01'*/
/*,'CAS11411131AK01'*/
/*,'CAS11411151AK01'*/
/*,'CAS11411170AK01'*/
/*,'CAS11411187AK01'*/
/*,'CAS11411207AK01'*/
/*,'CAS11411116AK01'*/
/*,'CAS11411134AK01'*/
/*,'CAS11411154AK01'*/
/*,'CAS11411174AK01'*/
/*,'CAS11411190AK01'*/
/*,'CAS11411212AK01'*/
/*,'CAS11411108AK01'*/
/*,'CAS11411130AK01'*/
/*,'CAS11411149AK01'*/
/*,'CAS11411169AK01'*/
/*,'CAS11411186AK01'*/
/*,'CAS11411206AK01'*/
/*,'CAS11411121AK01'*/
/*,'CAS11411139AK01'*/
/*,'CAS11411158AK01'*/
/*,'CAS11411178AK01'*/
/*,'CAS11411194AK01'*/
/*,'CAS11411219AK01'*/
/*,'CAS11411124AK01'*/
/*,'CAS11411144AK01'*/
/*,'CAS11411161AK01'*/
/*,'CAS11411181AK01'*/
/*,'CAS11411199AK01'*/
/*,'CAS11411220AK01'*/
/*,'CAS11411119AK01'*/
/*,'CAS11411136AK01'*/
/*,'CAS11411156AK01'*/
/*,'CAS11411176AK01'*/
/*,'CAS11411192AK01'*/
/*,'CAS11411217AK01'*/
/*,'CAS11411122AK01'*/
/*,'CAS11411140AK01'*/
/*,'CAS11411159AK01'*/
/*,'CAS11411179AK01'*/
/*,'CAS11411172AK01'*/
/*,'CAS11411221AK01'*/
/*,'CAS11411104AK01'*/
/*,'CAS11411129AK01'*/
/*,'CAS11411150AK01'*/
/*,'CAS11411168AK01'*/
/*,'CAS11411185AK01'*/
/*,'CAS11411204AK01'*/
/*,'CAS11411226AK01'*/
/*,'CAS11411114AK01'*/
/*,'CAS11411132AK01'*/
/*,'CAS11411152AK01'*/
/*,'CAS11411167AK01'*/
/*,'CAS11411188AK01'*/
/*,'CAS11411202AK01'*/
/*,'CAS11411105AK01'*/
/*,'CAS11411127AK01'*/
/*,'CAS11411145AK01'*/
/*,'CAS11411163AK01'*/
/*,'CAS11411183AK01'*/
/*,'CAS11411197AK01'*/
/*,'CAS11411224AK01'*/
/*,'CAS11411115AK01'*/
/*,'CAS11411133AK01'*/
/*,'CAS11411153AK01'*/
/*,'CAS11411173AK01'*/
/*,'CAS11411189AK01'*/
/*,'CAS11411208AK01'*/
/*);*/
run;

proc print data=mvps;
var msg_transaction_id notifiable_condition_cd national_reporting_jurisdiction_ current_record_flag local_record_id msg_received_dttm mvps_datetime_updated electronic_case_notification_to0 gen_msg_guide condition_specific_msg_guide record_status msg_sequence_id;
run;
