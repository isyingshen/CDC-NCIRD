/*************************************************************************************************/
/* Description: Frequency reports.  Part of                                                      */
/*              Covid19_Notification_Feedback_Report                                  				 */
/*                                                                                               */
/* Created by:  Anu Bhatta    07/08/2021                                                         */
/* Modified by: 								                                                          */
/*************************************************************************************************/

%macro Net_jur(juris, report_jurisdiction);
ods _all_ close; 
ods listing;
ods noproctitle;
ods word file="&output.\By jurisd\&report_jurisdiction (NETSS&NBS)- NNDSS COVID-19 Case Notification Feedback Report as of &SYSDATE9..docx" startpage=no;

proc freq data=shared.NETSS(keep = case_status mmwryear mmwrweek report_county_net dob age agetype sex_1
									 race_net ethnicity n_datet dis_aq outbreak report_jurisdiction);

   tables case_status mmwryear mmwrweek report_county_net dob age agetype sex_1 race_net ethnicity 
          n_datet /*onset_netss*/ dis_aq outbreak/nocol missing out=out;
   where report_jurisdiction = "&juris";

   title1 "&report_jurisdiction (NETSS/NBS): NNDSS COVID-19 Case Notification Feedback Report";
   title2 "Confirmed and Probable Cases as of &weekdate.";
run;
ods word close;

%mend Net_jur;