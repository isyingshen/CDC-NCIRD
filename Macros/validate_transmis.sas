/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 Transmis variables from 			          */
/*              master variable list and validate the result for 10180,10190,10140,10200,10370   */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_transmis;
%if (&eventcode=10180 or &eventcode=10190 or &eventcode=10140 or &eventcode=10200 
	  or &eventcode=10370) %then 
%do;
	proc sql noprint;
	   select stg2netss, stg3netss
	   into :stg2netss1-, :stg3netss1-
	   from var_list
	   where format_type = 'TRANSMIS'
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
   		else if (&&stg2netss&i in ('1 ',' 1','01') and &&stg3netss&i = '1348009') then 
   			results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('2 ',' 2','02') and &&stg3netss&i = '257698009') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('3 ',' 3','03') and &&stg3netss&i = '83891005') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('4 ',' 4','04') and &&stg3netss&i = '225746001') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('5 ',' 5','05') and &&stg3netss&i = 'ER') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('6 ',' 6','06') and &&stg3netss&i = 'C0029916') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('7 ',' 7','07') and &&stg3netss&i = '264362003') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i in ('8 ',' 8','08') and &&stg3netss&i = '285141008') then 
				results_&&stg2netss&i.. = 'OK';
   		else if (&&stg2netss&i in ('9 ',' 9','09','99') and &&stg3netss&i = 'UNK') then 
   			results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '10' and &&stg3netss&i = '224864007') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '11' and &&stg3netss&i = 'PHC64') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '12' and &&stg3netss&i = '257656006') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '13' and &&stg3netss&i = '257659004') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '14' and &&stg3netss&i = 'PHC179') then 
				results_&&stg2netss&i.. = 'OK';
			else if (&&stg2netss&i = '15' and &&stg3netss&i = 'OTH') then 
				results_&&stg2netss&i.. = 'OK';
			else results_&&stg2netss&i.. = 'Check';
 		%end;
	run;

  	%do i=1 %to &total;
   	%SYMDEL stg2netss&i;
   	%SYMDEL stg3netss&i;
  	%end;
%end; /* if eventcode loop */

%mend validate_transmis;
