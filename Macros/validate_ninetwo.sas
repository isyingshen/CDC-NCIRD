/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 variables value which are 99,999 		    */
/*              from master variable list and validate the result for 10180, 10190, 10200, 10370 */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_ninetwo;
   %if (&eventcode=10180 or &eventcode=10190 or &eventcode=10200 or &eventcode=10370) %then 
   %do;
      proc sql noprint;
         select stg2netss, stg3netss
         into :stg2netss1-, :stg3netss1-
         from var_list
         where format_type = 'NINETWO'
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
            else if (&&stg2netss&i = '' and &&stg3netss&i = '') then
               results_&&stg2netss&i.. = 'Both missing';
            else if (&&stg2netss&i = '99' and &&stg3netss&i = '999') then
               results_&&stg2netss&i.. = 'OK';
            else if (&&stg2netss&i = &&stg3netss&i) then
               results_&&stg2netss&i.. = 'OK';
            else
               results_&&stg2netss&i.. = 'Check';
         %end;
      run;

      %do i=1 %to &total;
         %SYMDEL stg2netss&i;
         %SYMDEL stg3netss&i;
      %end; 
   %end; /* if eventcode loop */

%mend validate_ninetwo;
