/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 ReasonP variables from 			             */
/*              master variable list and validate the result for 10190 								    */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_reasonp;
	%if (&eventcode=10190) %then 
	%do;
		proc sql noprint;
		   select stg2netss, stg3netss
		   into :stg2netss1-, :stg3netss1-
		   from var_list
		   where format_type = 'REASONP'
		   ;
		   %let total = &sqlobs;
		quit;  

		data mapping_validation;
			%do i=1 %to &total;
    			length &&stg2netss&i.._results $20;
  			%end;
    		set mapping_validation;
			where event = '10190';
	
			%do i=1 %to &total;	
			   if (&&stg3netss&i = '#M') then
			      &&stg2netss&i.._results = '#M';
				else if (&&stg2netss&i = '' and &&stg3netss&i = '') then
			      &&stg2netss&i.._results = 'Both missing';
			   else if (&&stg2netss&i = '1' and &&stg3netss&i = 'PHC96') then
			      &&stg2netss&i.._results = 'OK';
				else if (&&stg2netss&i = '2' and &&stg3netss&i = '397745006') then
			      &&stg2netss&i.._results = 'OK';
				else if (&&stg2netss&i = '3' and &&stg3netss&i = 'PHC92') then
			      &&stg2netss&i.._results = 'OK';
				else if (&&stg2netss&i = '4' and &&stg3netss&i = 'PHC83') then
			      &&stg2netss&i.._results = 'OK';
				else if (&&stg2netss&i = '5' and &&stg3netss&i = 'PHC95') then
			      &&stg2netss&i.._results = 'OK';
				else if (&&stg2netss&i = '6' and &&stg3netss&i = 'PHC1312') then
			      &&stg2netss&i.._results = 'OK';
				else if (&&stg2netss&i = '7' and &&stg3netss&i = 'OTH') then
			      &&stg2netss&i.._results = 'OK';
				else if (&&stg2netss&i = '9' and &&stg3netss&i = 'UNK') then
			      &&stg2netss&i.._results = 'OK';
				else
			      &&stg2netss&i.._results = 'Check';
			%end;
		run;

		%do i=1 %to &total;
			%SYMDEL stg2netss&i;
		   %SYMDEL stg3netss&i;
		%end;
	%end; /* if eventcode loop */

%mend validate_reasonp;
