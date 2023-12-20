/**********************************************************************************************************************/
/* Description: Summarizes 11065 records in NNAD Stage4 Production and CSP NETSS.                                     */
/*              Summarizes COVID stage4 data.                                                                         */
/*                                                                                                                    */
/* Created by : Ying Shen 01/06/2021 based on Xin Yue 03/17/2020                                                      */
/*                                                                                                                    */
/*              Ying Shen 01/06/2021 Added COVID MMG reports                                                          */
/*              Ying Shen 02/01/2021 Changed US to U.S., Capitalize Variable Values                                   */                         
/*              Ying Shen 02/01/2021 remove table first_PHD_suspect_dt                                         	    */
/*              Ying Shen 02/12/2021 updated labels,titles, layout, sequence according to Matt's review        		 */
/*				Ying Shen 02/16/2021  Added KS in Ln 2443 and UT in LN 2444											                */
/*				Anu Bhatta 06/01/2021 Added IDaho(ID) in Ln 2445											                         */
/*				Ying Shen 06/04/2021 Removed footnote for word report by adding footnote1;							             */
/*				Ying Shen 06/04/2021 Handled the () issue for vax lot							                                  */
/*				Ying Shen 06/08/2021 resolved the denominator issue for covidMMG reports		                            */
/*				Ying Shen 06/08/2021 Added note for diff denominators for the following covidMMG reports		             */
/*                               days_in_hosp,admit_dt, discharge_dt, death_dt, outbreak_name and pregnant            */
/*				Ying Shen 06/09/2021 Added n_expandedcaseId to the initial_table		                                     */
/*				Sang Kang 06/30/2021 Split code into Covid19_Feedback_header.sas and Macros - dedup_case and char2num		 */
/*				Anu Bhatta07/08/2021	gen_jur_CovidMMG, added Sasconnect to run each jurisdiction in parallel				 	 */
/**********************************************************************************************************************/
/*** SAS grid connect setup section                                        ***/
%put SAS HOST %sysfunc(grdsvc_getname('')); /* name of the host handling the job */

%let rc=%sysfunc(grdsvc_enable(_all_, resource=SASApp)); 
*options sascmd="sas" autosignon;
options autosignon;
libname shared "%sysfunc(pathname(work))";  
/*****End SAS grid connect setup section *************************************/

%global environment platform rootdir SQLoad fmtdir DBservName;
%let environment = PROD; /* DEV | TEST | STAGING | PROD environment code to control behaviour */
%let platform = DESKTOP; /* DESKTOP | CSP platform code to control file paths */

/* file path is declared based on the location the program is running under */
%macro platform_path;
   %if (&platform = DESKTOP) %then %do;
      %let rootdir = \\cdc\project\NIP_Project_Store1\Surveillance\Surveillance_NCIRD_3\NMI\&environment;
   %end;
   %else %do; /* assume the other platform is CSP */
      %let rootdir =\\cdc\csp_project\NCIRD_MVPS\&environment; 
   %end;
%mend platform_path;
%platform_path;

options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

/* Begin */    
signon task1;   
%syslput environment = %bquote(&environment) /remote=task1;
%syslput rootdir = %bquote(&rootdir) /remote=task1;
%syslput platform = %bquote(&platform) /remote=task1;
                    
rsubmit task1 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=1; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */

	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

   %Gen_Jur_CovidMMG(20,Kansas);
   
endrsubmit; /* end task1 */   

signon task2; 
%syslput environment = %bquote(&environment) /remote=task2;  
%syslput rootdir = %bquote(&rootdir) /remote=task2;   
%syslput platform = %bquote(&platform) /remote=task2;                          
rsubmit task2 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=2; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

   %Gen_Jur_CovidMMG(49,Utah);
   
endrsubmit; /* end task2 */   

signon task3;  
%syslput environment = %bquote(&environment) /remote=task3;  
%syslput rootdir = %bquote(&rootdir) /remote=task3;   
%syslput platform = %bquote(&platform) /remote=task3;                       
rsubmit task3 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=3; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

   %Gen_Jur_CovidMMG(16,Idaho);
   
endrsubmit; /* end task3 */


waitfor _all_ task1 task2 task3;

signoff task1;
signoff task2;
signoff task3;
