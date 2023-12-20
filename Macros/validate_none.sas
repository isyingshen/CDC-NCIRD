/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 variables value which are blank 				 */
/*              from master variable list and validate the result                                */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_none;
proc sql noprint;
   select stg2netss, stg3netss
   into :stg2netss1-, :stg3netss1-
   from var_list
   where format_type = 'NONE'
   ;
   %let total = &sqlobs;
quit;  

data mapping_validation;
	%do i=1 %to &total;
   	length results_&&stg2netss&i.. $20;
  	%end;
   set mapping_validation;

  	%do i=1 %to &total;
   	if (compress(&&stg2netss&i) = '' and compress(&&stg3netss&i = '')) then
      	results_&&stg2netss&i.. = 'Both missing';
		else if (compress(&&stg2netss&i) = '' and compress(&&stg3netss&i) NE '') then
      	results_&&stg2netss&i.. = 'HL7 only';
		else if (compress(&&stg2netss&i) NE '' and compress(&&stg3netss&i) = '') then
      	results_&&stg2netss&i.. = 'NETSS only';
   	else if (compress(&&stg2netss&i) = compress(&&stg3netss&i)) then
      	results_&&stg2netss&i.. = 'OK';
	else
      results_&&stg2netss&i.. = 'Check';
  %end;
run;

%do i=1 %to &total;
	%SYMDEL stg2netss&i;
 	%SYMDEL stg3netss&i;
%end;

%mend validate_none;


