/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Weeks Gestation variables from             */
/*              master variable list and validate the result for 10200, 10370, 10180             */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_gest;
%if (&eventcode =10200 or &eventcode =10370 or &eventcode =10180) %then 
%do;
   proc sql noprint;
      select stg2netss, stg3netss
      into :stg2netss1-, :stg3netss1-
      from var_list
      where format_type = 'GEST'
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
         else if (&&stg2netss&i in ('.','') and &&stg3netss&i = '') then
            results_&&stg2netss&i.. = 'Both missing';
         else if (upcase(&&stg2netss&i) = '1ST' and &&stg3netss&i = '255246003') then
            results_&&stg2netss&i.. = 'OK';
         else if (upcase(&&stg2netss&i) = '2ND' and &&stg3netss&i = '255247007') then
            results_&&stg2netss&i.. = 'OK';
         else if (upcase(&&stg2netss&i) = '3RD' and &&stg3netss&i = '255248002') then
            results_&&stg2netss&i.. = 'OK';
         else if (&&stg2netss&i = preg_weeks_gest) then
            results_&&stg2netss&i.. = 'OK';
         else 
            results_&&stg2netss&i.. = 'Check';
      %end;
   run;

   %do i=1 %to &total;
      %SYMDEL stg2netss&i;
      %SYMDEL stg3netss&i;
   %end;
%end;
  
%mend validate_gest;
