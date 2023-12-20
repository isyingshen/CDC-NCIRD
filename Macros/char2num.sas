/*************************************************************************************************/
/* Description: change format from character to number.  Part of                                 */
/*              Covid19_CovidMMG_Notification_Feedback_Report                                    */
/*                                                                                               */
/* Created by:  NNNNNNNNNN    mm/dd/yyyy                                                         */
/* Modified by: NNNNNNNNNN    mm/dd/yyyy                                                         */
/*************************************************************************************************/
%macro char2num(formn,charclm);
data &formn;
   set &formn;
   temp_column = input (&charclm, 2.);
   attrib temp_column format= 2. informat=2.;
   drop &charclm;
   rename temp_column=&charclm;
run;
%mend char2num;