/*************************************************************************************************/
/* Description: Deduplicate case and remove none case.  Part of                                  */
/*              Covid19_CovidMMG_Notification_Feedback_Report                                    */
/*                                                                                               */
/* Created by:  NNNNNNNNNN    mm/dd/yyyy                                                         */
/* Modified by: NNNNNNNNNN    mm/dd/yyyy                                                         */
/*************************************************************************************************/
%macro dedup_case(formin,formout);
/* DEDUPLICATION AND DATA CLEANING FOR NNAD STAGE4 DATA*/
data formin_11065 error_nokey;
   set &formin;
   if (source_system in (5,15)) then 
      firstkey=cats(report_jurisdiction,compress(local_record_id)); /* For HL7 records, look at local_record_id */
   else if ((source_system=1) and (WSYSTEM=5)) then
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* For NETSS records created from MVPS, look at n_expandedcaseid */  
   else if ((source_system=1) and (WSYSTEM NE 5)) then
      firstkey=cats(report_jurisdiction,compress(local_record_id),site,mmwr_year); /* For other NETSS records, look at local_record_id (CASEID), site, mmwr_year */

   output formin_11065;

   if (firstkey = '') then
      output error_nokey;
run;
proc sort tagsort data=formin_11065;
   by firstkey descending source_system descending n_cdcdate; /* Prefer HL7 record over NETSS duplicate, newer NETSS record over older */
run;

/* Duplicates by match of local_record_id/n_expandedcaseid are removed */
data &&formout formin_remove;
   set formin_11065;
   by firstkey;

   if ((first.firstkey) and (result_status NE 'X') and (case_status NE 'PHC178')) then
      output &&formout;
   else 
      output formin_remove;
run;
%mend dedup_case;
