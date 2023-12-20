/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Species variables from 			             */
/*              master variable list and validate the result for 10150,10590,11723,11720,11717   */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_species;
%if (&eventcode =10150 or &eventcode =10590 or &eventcode =11723 or &eventcode =11720
 	  or &eventcode =11717) %then 
%do;
	proc sql noprint;
	   select stg2netss, stg3netss
	   into :stg2netss1-, :stg3netss1-
	   from var_list
	   where format_type = 'SPECIES'
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
	   	else if (&&stg2netss&i in ('1 ',' 1','01') and &&stg3netss&i = '17872004') then 
	   		results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('2 ',' 2','02') and &&stg3netss&i = '44470000') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('3 ',' 3','03') and &&stg3netss&i = '42518002') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('4 ',' 4','04') and &&stg3netss&i = '36094007') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('5 ',' 5','05') and &&stg3netss&i = '9861002') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('6 ',' 6','06') and &&stg3netss&i = '112283007') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('7 ',' 7','07') and &&stg3netss&i = '3092008') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('8 ',' 8','08') and &&stg3netss&i = '60875001') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('9 ',' 9','09') and &&stg3netss&i = '131269001') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '10' and &&stg3netss&i = '131263000') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '11' and &&stg3netss&i = '116497004') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '12' and &&stg3netss&i = '413857000') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '13' and &&stg3netss&i = '67297007') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '14' and &&stg3netss&i = '55547008') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '15' and &&stg3netss&i = '58800005') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '16' and &&stg3netss&i = 'OTH') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '99' and &&stg3netss&i = 'UNK') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('','.') and &&stg3netss&i = '') then 
				results_&&stg2netss&i.. = 'Both missing';
			else if (&&stg2netss&i in ('','.') and &&stg3netss&i NE '') then 
				results_&&stg2netss&i.. = 'HL7 only';
			else if (&&stg2netss&i not in ('','.') and &&stg3netss&i = '') then 
				results_&&stg2netss&i.. = 'NETSS only';
			else results_&&stg2netss&i.. = 'Check';
		%end;
	run;

  	%do i=1 %to &total;
  		%SYMDEL stg2netss&i;
   	%SYMDEL stg3netss&i;
  	%end;
%end; /* if eventcode loop */

%mend validate_species;
