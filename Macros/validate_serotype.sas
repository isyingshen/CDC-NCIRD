/*************************************************************************************************/
/* Description: This macro extracts Stage2 and Stage3 serotype variables from 		             */
/*              master variable list and validate the result for 10590, 11723, 11717, 11720	    */
/*                                                                                               */
/* Created by:  Hannah Fast   10/08/2019                                                         */
/* Modified by: Anu Bhatta    11/13/2019  -Standardized the code.                                */
/*************************************************************************************************/

%macro validate_serotype;
	%if (&eventcode =10590) %then 
	%do;

		proc sql noprint;
		   select stg2netss, stg3netss
		   into :stg2netss1-, :stg3netss1-
		   from var_list
		   where format_type = 'STYPE'
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
			   else if (&&stg2netss&i = '1' and &&stg3netss&i = '277452004') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '2' and &&stg3netss&i = 'PHC1610') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '8' and &&stg3netss&i = 'OTHNOTB') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '9' and &&stg3netss&i = 'NT_UNK') then
			      results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i in ('','.') and &&stg3netss&i = '') then
			      results_&&stg2netss&i.. = 'Both missing';
				else if (&&stg2netss&i in ('','.') and &&stg3netss&i NE '') then
			      results_&&stg2netss&i.. = 'HL7 only';
				else if (&&stg2netss&i in ('','.') and &&stg3netss&i = '') then
			      results_&&stg2netss&i.. = 'NETSS only';
				else
			      results_&&stg2netss&i.. = 'Check';
  			%end;
		run;

		%do i=1 %to &total;
    		%SYMDEL stg2netss&i;
    		%SYMDEL stg3netss&i;
  		%end;
	%end; /* if 10590 loop */

	%if (&eventcode = 11723 or &eventcode = 11717 or &eventcode = 11720) %then 
	%do;
		data _NULL_;
			set var_list end=lastrec;
			where format_type = 'STYPE';
			if lastrec then do; 
				call symput('total',_n_); end;
		run;

  		%do n=1 %to &total;
    		%global stg2netss&n stg3netss&n;
			data _null_;
  				set var_list;
    			where format_type = 'STYPE';
  				if &n=_n_;
    				call symputx("stg2netss&n", stg2netss);
    				call symputx("stg3netss&n", stg3netss);
			run;
  		%end; /* do n loop */

		data mapping_validation;
  			%do i=1 %to &total;
    			length results_&&stg2netss&i.. $20;
  			%end;
    		set mapping_validation;

  			%do i=1 %to &total;	
    			if (&&stg3netss&i = '#M') then 
    				results_&&stg2netss&i.. = '#M';
    			else if (&&stg2netss&i = '1' and &&stg3netss&i = 'PCV7_13') then 
    				results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '2' and &&stg3netss&i = 'PPSV23') then 
					results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '8' and &&stg3netss&i = 'OTH') then 
					results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i = '9' and &&stg3netss&i = 'UNK') then 
					results_&&stg2netss&i.. = 'OK';
				else if (&&stg2netss&i in ('','.') and &&stg3netss&i = '') then 
					results_&&stg2netss&i.. = 'Both missing';
				else if (&&stg2netss&i in ('','.') and &&stg3netss&i NE '') then 
					results_&&stg2netss&i.. = 'HL7 only';
				else if (&&stg2netss&i in ('','.') and &&stg3netss&i = '') then 
					results_&&stg2netss&i.. = 'NETSS only';
				else results_&&stg2netss&i.. = 'Check';
  			%end;
		run;

		%do i=1 %to &total;
	  		%SYMDEL stg2netss&i;
	   	%SYMDEL stg3netss&i;
	  	%end;
	%end; /* if eventcode loop */

%mend validate_serotype;
