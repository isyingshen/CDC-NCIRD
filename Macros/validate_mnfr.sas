/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Manufacturer variables		                */
/*              from master variable list and validate the result only for 10190			          */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_mnfr;
   %if (&eventcode=10190) %then 
   %do;
      proc sql noprint;
         select stg2netss, stg3netss
         into :stg2netss1-, :stg3netss1-
         from var_list
         where format_type = 'MNFR'
         ;
         %let total = &sqlobs;
      quit;     
  
      data mapping_validation;
         %do i=1 %to &total;
            length &&stg2netss&i.._results $20;
         %end;
         set mapping_validation;    
  
         %do i=1 %to &total;
            if (&&stg3netss&i = '#M') then
               &&stg2netss&i.._results = '#M';
            else if (&&stg2netss&i = '' and &&stg3netss&i = '') then
               &&stg2netss&i.._results = 'Both missing';
            else if (&&stg2netss&i = 'L' and &&stg3netss&i = 'LED') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'C' and &&stg3netss&i = 'CON') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'M' and &&stg3netss&i = 'MA') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'I' and &&stg3netss&i = 'MI') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'S' and &&stg3netss&i = 'SKB') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'N' and &&stg3netss&i = 'NAV') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'P' and &&stg3netss&i = 'PMC') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'O' and &&stg3netss&i = 'OTH') then
               &&stg2netss&i.._results = 'OK';
            else if (&&stg2netss&i = 'U' and &&stg3netss&i = 'UNK') then
               &&stg2netss&i.._results = 'OK';
            else
               &&stg2netss&i.._results = 'Check';
         %end;
      run;

      %do i=1 %to &total;
         %SYMDEL stg2netss&i;
         %SYMDEL stg3netss&i;
      %end;
   %end;

%mend validate_mnfr;
