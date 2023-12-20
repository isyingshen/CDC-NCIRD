/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Labtest variables from                     */
/*              master variable list and validate the result for 10180, 10140, 10200, 10370      */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_mlab;
   %if (&eventcode=10180 or &eventcode=10140 or &eventcode=10200 or &eventcode=10370) %then 
   %do;
      proc sql noprint;
         select stg2netss, stg3netss
         into :stg2netss1-, :stg3netss1-
         from var_list
         where format_type = 'MLAB'
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
            else if (&&stg2netss&i = 'P' and &&stg3netss&i = '10828004') then
               results_&&stg2netss&i.. = 'OK';
            else if (&&stg2netss&i = 'N' and &&stg3netss&i = '260385009') then
               results_&&stg2netss&i.. = 'OK';
            else if (&&stg2netss&i = 'I' and &&stg3netss&i = '82334004') then
               results_&&stg2netss&i.. = 'OK';
            else if (&&stg2netss&i = 'E' and &&stg3netss&i = 'I') then
               results_&&stg2netss&i.. = 'OK';
            else if (&&stg2netss&i = 'X' and &&stg3netss&i = '385660001') then
               results_&&stg2netss&i.. = 'OK';
            else if (&&stg2netss&i = 'U' and &&stg3netss&i = 'UNK') then
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

%mend validate_mlab;
