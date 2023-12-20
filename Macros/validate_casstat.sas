/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Case Status variables from                 */
/*              master variable list and validate the result                                     */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_casstat;
proc sql noprint;
   select stg2netss, stg3netss
   into :stg2netss1-, :stg3netss1-
   from var_list
   where format_type = 'CASSTAT'
   ;
   %let total = &sqlobs;
quit;  
  
data mapping_validation;
   %do i=1 %to &total;
      length results_&&stg2netss&i.. $20;
   %end;
   set mapping_validation;
	
   %do i=1 %to &total;
      if (&&stg3netss&i = '#M') then
         results_&&stg2netss&i.. = '#M';
      else if (&&stg2netss&i = 1 and &&stg3netss&i = '410605003') then
         results_&&stg2netss&i.. = 'OK';
      else if (&&stg2netss&i = 2 and &&stg3netss&i = '2931005') then
         results_&&stg2netss&i.. = 'OK';
      else if (&&stg2netss&i = 3 and &&stg3netss&i = '415684004') then
         results_&&stg2netss&i.. = 'OK';
      else if (&&stg2netss&i = 9 and &&stg3netss&i = 'UNK') then
         results_&&stg2netss&i.. = 'OK';
      else if (&&stg2netss&i = . and &&stg3netss&i = '') then
         results_&&stg2netss&i.. = 'Both missing';
      else if (&&stg2netss&i = . and &&stg3netss&i NE '') then
         results_&&stg2netss&i.. = 'HL7 only';
      else if (&&stg2netss&i NE . and &&stg3netss&i = '') then
         results_&&stg2netss&i.. = 'NETSS only';
      else
         results_&&stg2netss&i.. = 'Check';
   %end;
run;

%do i=1 %to &total;
   %SYMDEL stg2netss&i;
   %SYMDEL stg3netss&i;
%end;

%mend validate_casstat;
