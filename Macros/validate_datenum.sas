/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Datenum variables 								 */
/*              from master variable list and validate the result                                */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_datenum;
proc sql noprint;
   select stg2netss, stg3netss
   into :stg2netss1-, :stg3netss1-
   from var_list
   where format_type = 'DATENUM'
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
         results_&&stg2netss&i.. = 'Date - #M';
      else if (&&stg3netss&i in ('99999999','99/99/99')) then
         results_&&stg2netss&i.. = 'Date - Unknown';
      else if (&&stg2netss&i = . and &&stg3netss&i = '') then
         results_&&stg2netss&i.. = 'Date - Both missing';
      else if (&&stg2netss&i NE . and &&stg3netss&i = '') then
         results_&&stg2netss&i.. = 'Date - NETSS only';
      else if (&&stg2netss&i = . and &&stg3netss&i NE '') then
         results_&&stg2netss&i.. = 'Date - HL7 only';
      else
         results_&&stg2netss&i.. = 'Date - Check values';
   %end;
run;

%mend validate_datenum;
