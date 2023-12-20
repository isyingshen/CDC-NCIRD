/*************************************************************************************************/
/* Description: Frequency reports.  Part of                                                      */
/*              Covid19_Notification_Feedback_Report                                  				 */
/*                                                                                               */
/* Created by:  Anu Bhatta    07/08/2021                                                         */
/* Modified by: 								                                                          */
/*************************************************************************************************/

%macro Gen_jur(juris, report_jurisdiction);
ods _all_ close; 
   ods listing;
   ods noproctitle;
   ods word file="&output.\By Jurisd\&report_jurisdiction (GenV2)-NNDSS COVID-19 Case Notification Feedback Report as of &SYSDATE9..docx" startpage=no;

proc freq data=shared.GenV2(keep = case_status mmwryear mmwrweek rpt_state report_county_Gen birthctr dob
									 age agetype sex_1 race_gen ethnicity res_country res_state res_county
									 zip dx_dt county_dt state_dt onset end_dt report_jurisdiction);
   tables case_status mmwryear mmwrweek rpt_state report_county_Gen birthctr dob age agetype sex_1 race_gen
          ethnicity res_country res_state res_county zip dx_dt county_dt state_dt onset end_dt/nocol missing; 
   where report_jurisdiction="&juris";
   title1 "&report_jurisdiction (GenV2) - NNDSS COVID-19 Case Notification Feedback Report";
   title2 "Confirmed and Probable Cases as of &weekdate.";
run;

proc freq data=shared.GenV2(keep = illdur hosp report_jurisdiction);
   tables illdur hosp/nocol missing;
   where report_jurisdiction="&juris";
run;

proc freq data=shared.GenV2(keep = hosp_dur admit_date dis_dt hosp report_jurisdiction);
   tables hosp_dur admit_date dis_dt /nocol missing;
   where hosp=1 and report_jurisdiction="&juris"; /*subet to hospitalized patients*/
run;

proc freq data=shared.GenV2(keep = die report_jurisdiction);
   tables die/nocol missing;
   where report_jurisdiction="&juris";
run;

proc freq data=shared.GenV2(keep = death_dt die report_jurisdiction);
   tables death_dt/nocol missing;
   where die=1 and report_jurisdiction="&juris";
run;

proc freq data=shared.GenV2(keep = importctr importstate importcounty importcity expcountry expstateprov
									 expcounty expcity dis_aq trans outbreak report_jurisdiction);
									 
   tables importctr importstate importcounty importcity expcountry expstateprov expcounty expcity 
          dis_aq trans outbreak/nocol missing;
   where report_jurisdiction="&juris";
run;

proc freq data=shared.GenV2(keep = outbreakname outbreak report_jurisdiction);
   tables outbreakname/nocol missing;
   where outbreak='1' and report_jurisdiction="&juris";
run;

proc freq data=shared.GenV2(keep = invest_dt phd_dt phd_rpt source comments report_jurisdiction);
   tables invest_dt phd_dt phd_rpt source comments report_jurisdiction/nocol missing;
   where report_jurisdiction="&juris";
run;

proc freq data=shared.GenV2(keep = preg sex_1 report_jurisdiction); 
   tables preg/nocol missing;
   where sex_1="1" and report_jurisdiction="&juris";
run;
ods word close;

%mend Gen_jur;