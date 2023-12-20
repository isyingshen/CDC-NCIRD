 /********************************************************************/
 /* PROGRAM NAME: Confirm YTD data transmission finished             */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2021/12/3                                               */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This program is to confirm the YTD data transmission   */
 /*           is finished by looking at msg_received_dttm and        */
 /*           mvps_datetime_created.                                 */
 /*                                                                  */ 
 /* INPUT:   mvps database                                           */
 /*                                                                  */ 
 /* OUTPUT:  see the SAS result viewer                               */
 /*                                                                  */ 
 /* Date Modified: 2023-11-3                                         */
 /* Modified by: Ying Shen                                           */
 /* Changes: Added port number 1201 to the server name               */
 /********************************************************************/


/*Connect MVPS production db*/
libname mvps OLEDB provider="sqlncli11"
     properties = ( "data source"="MVPSdata ,1201\QSRV1" "Integrated Security"="SSPI"
           "Initial Catalog"="MVPS_PROD" ) schema=hl7 access=readonly;


/*sql query*/
proc sql;
Select * 
  FROM mvps.message_meta_vw (obs=10)
  where reporting_state_cd='12'
  and condition_specific_msg_guide like '%COVID%'
  order by mvps_datetime_updated desc;
quit;
