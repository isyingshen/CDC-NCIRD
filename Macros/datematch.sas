/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Date variables from master variable list   */
/*              and validate whether both dates has equal values or not                          */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro datematch;
   proc sql noprint;
      select stg2netss, stg3netss
      into :stg2netss1-, :stg3netss1-
      from var_list
      where format_type = 'DATE'
      ;
      %let total = &sqlobs;
   quit;  

   %do i=1 %to &total;
      data mapping_validation
         &&stg2netss&i.._M (keep = event year state caseid wsystem site &&stg2netss&i &&stg3netss&i 
                                   results_&&stg2netss&i..);
         set mapping_validation;
         output mapping_validation;
         if (results_&&stg2netss&i.. = 'Date_#M') then 
            output &&stg2netss&i.._M;
      run; 

      data mapping_validation;
         set mapping_validation;
         if (results_&&stg2netss&i..='Date_Both values') then 
         do;
            A = input(&&stg2netss&i, ??MMDDYY10.);
            B = input(&&stg3netss&i, ??YYMMDD8.);
            if (A = B) then 
            do;
               results_&&stg2netss&i..='Date_Equal values';
            end;
         else do;
            results_&&stg2netss&i..='Date_Nonequal values';
            end;
         end;
         output mapping_validation;
      run; 
   
   %end; /* end do loop */

%do i=1 %to &total;
   %SYMDEL stg2netss&i;
   %SYMDEL stg3netss&i;
%end;

%mend datematch;
