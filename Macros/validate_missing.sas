/*************************************************************************************************/
/* Description: This macro is to check to get overall missing / non-missing counts               */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_missing;
   %do i=1 %to &total;
      data &&stg2netss&i.._missM (keep = event year state caseid wsystem site &&stg2netss&i &&stg3netss&i)
         &&stg2netss&i.._nonmissM (keep = event year state caseid wsystem site &&stg2netss&i &&stg3netss&i)
         &&stg2netss&i.._missP (keep = event year state caseid wsystem site &&stg2netss&i &&stg3netss&i)
         &&stg2netss&i.._nonmissP (keep = event year state caseid wsystem site &&stg2netss&i &&stg3netss&i)
         ;
         set combined;
         if (&&stg2netss&i = ' ' and event = '10180') then 
            output &&stg2netss&i.._missM;
         else if (&&stg2netss&i NE ' ' and event = '10180') then 
            output &&stg2netss&i.._nonmissM;
         else if (&&stg2netss&i = ' ' and event = '10190') then 
            output &&stg2netss&i.._missP;
         else if (&&stg2netss&i NE ' ' and event = '10190') then 
            output &&stg2netss&i.._nonmissP;
      run;
   %end;

%do i=1 %to &total;
   %SYMDEL stg2netss&i;
   %SYMDEL stg3netss&i;
%end;
%mend validate_missing;
