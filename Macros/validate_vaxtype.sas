/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 VaxType variables from 			             */
/*              master variable list and validate the result for 10190								    */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_vaxtype;
%if (&eventcode=10190) %then 
%do;

	proc sql noprint;
	   select stg2netss, stg3netss
	   into :stg2netss1-, :stg3netss1-
	   from var_list
	   where format_type = 'TYPE'
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
		   else if (&&stg2netss&i = 'W' and &&stg3netss&i = '01') then 
		   	&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'A' and &&stg3netss&i = '20') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'D' and &&stg3netss&i = 'DT') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'T' and &&stg3netss&i = '22') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'P' and &&stg3netss&i = '11') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'H' and &&stg3netss&i = '50') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'V' and &&stg3netss&i = '110') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'N' and &&stg3netss&i = '120') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'K' and &&stg3netss&i = '130') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'X' and &&stg3netss&i = '115') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'O' and &&stg3netss&i = 'OTH') then 
				&&stg2netss&i.._results = 'OK';
			else if (&&stg2netss&i = 'U' and &&stg3netss&i = '999') then 
				&&stg2netss&i.._results = 'OK';
			else &&stg2netss&i.._results = 'Check';
  		%end;
	run;

	%do i=1 %to &total;
    	%SYMDEL stg2netss&i;
    	%SYMDEL stg3netss&i;
  	%end;
%end; /* if eventcode loop */

%mend validate_vaxtype;
