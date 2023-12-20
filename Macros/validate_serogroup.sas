/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 serogrp variables from 			             */
/*              master variable list and validate the result for 10150  							    */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_serogroup;
	%if (&eventcode =10150) %then 
	%do;
		proc sql noprint;
		   select stg2netss, stg3netss
		   into :stg2netss1-, :stg3netss1-
		   from var_list
		   where format_type = 'SGRP'
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
			   else if (&&stg2netss&i = '1' and strip(&&stg3netss&i) = '103479006') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '2' and strip(&&stg3netss&i) = '103480009') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '3' and strip(&&stg3netss&i) = '103481008') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '4' and strip(&&stg3netss&i) = '103482001') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '5' and strip(&&stg3netss&i) = '103483006') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '6' and strip(&&stg3netss&i) = 'PHC1120') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '8' and strip(&&stg3netss&i) = 'OTH') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '9' and strip(&&stg3netss&i) = 'UNK') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i in ('','.') and strip(&&stg3netss&i) = '') then
			      results_&&stg2netss&i.. = 'Both missing';
				else if (&&stg2netss&i in ('','.') and strip(&&stg3netss&i) NE '') then
			      results_&&stg2netss&i.. = 'HL7 only';
				else if (&&stg2netss&i in ('','.') and strip(&&stg3netss&i) = '') then
			      results_&&stg2netss&i.. = 'NETSS only';
				else
			      results_&&stg2netss&i.. = 'Check';
  			%end;
		run;

		%do i=1 %to &total;
			%SYMDEL stg2netss&i;
			%SYMDEL stg3netss&i;
		%end; 
	%end; /* if eventcode loop */

%mend validate_serogroup;
