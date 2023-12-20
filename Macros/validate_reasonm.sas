/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 ReasonM variables from 			             */
/*              master variable list and validate the result for 10180, 10140, 10200, 10370      */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_reasonm;
	%if (&eventcode=10180 or &eventcode=10140 or &eventcode=10200 or &eventcode=10370) %then 
	%do;
		proc sql noprint;
		   select stg2netss, stg3netss
		   into :stg2netss1-, :stg3netss1-
		   from var_list
		   where format_type = 'REASONM'
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
			   else if (&&stg2netss&i = '1' and &&stg3netss&i = 'PHC96') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '2' and &&stg3netss&i = '397745006') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '3' and &&stg3netss&i = 'PHC92') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '4' and &&stg3netss&i = 'PHC82') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '5' and &&stg3netss&i = 'PHC83') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '6' and &&stg3netss&i = 'PHC1312') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '7' and &&stg3netss&i = 'PHC95') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '8' and &&stg3netss&i = 'OTH') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '9' and &&stg3netss&i = 'UNK') then
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

%mend validate_reasonm;
