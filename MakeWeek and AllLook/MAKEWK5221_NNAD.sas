/*********************************************************************************/
/*PROGRAM NAME:     MAKEWK31_NNAD                                                */
/*VERSION: 1.0                                                                   */
/*CREATED: 2021/8/6                                                              */
/*                                                                               */
/*BY: Ying Shen based on MAKEWK51 netss program SANDY ROUSH (8/2005)             */
/*FUNCTION OF PROGRAM:  MUST BE RUN IN THE CORRECT  WEEK AT THE END              */
/*                      OF THE YEAR!!!!!                                         */
/*     ** USE THIS TO READ EPO WEEK 52 NNAD DATASET AND WRITE                    */
/*         THE DATA OUT TO A DATASET HERE AT NIP......                           */
/*                                                                               */
/*      *** THIS IS IMPORTANT TO DO TO MAINTAIN AVAILABILITY OF                  */
/*          WEEK 52 DATA INTO THE NEW YEAR, AFTER WHICH EPO                      */
/*          CONTINUES TO UPDATE DATA UNTIL IT IS FINALIZED                       */
/*           SOMETIME IN MIDYEAR.  THE WEEK 52 DATA IS NOT FROZEN                */
/*           AT EPO.                                                             */
/*                                                                               */
/*DATA SOURCES:  NETSS DATA SET                                                  */
/* INPUT:  NNAD DATABASE - ALLVPD                                                */
/*                                                                               */
/* OUTPUT: different spreadsheets by pathogens   		                         */
/*                                                                               */
/* Date Modified: 2022-1-3                                                       */
/* Modified by: Ying Shen                                                        */
/* Changes: Change to wk52 from wk31                                             */
/*          use proc sql instead of data step to be more efficient               */
/*                                                                               */
/*********************************************************************************/

/*libname dat2 "\\cdc\csp_project\ncphi_disss_nndss_ncird\current" access=readonly ;*/
/*libname dat3 "\\cdc\csp_project\NCIRD_MB00\swr1\NETSS\WK5216" access=readonly ;*/
/*libname dat4 "\\cdc\csp_project\ncphi_disss_nndss_ncird\history" access=readonly ;*/

/*This is to connect to the NNAD database; */
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-VPDN-1601,59308\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;


libname outdk "\\cdc.gov\csp_project\NCIRD_MB00\SWR1\NNAD\WK5221";


/*DATA WEEk5221;*/
/*   SET NNAD.Stage4_NNDSScasesT1;*/
/**/
/*IF mmwr_year = 2021;*/
/*IF condition ne 11065;*/


proc sql;
create table Week5221 as
select *
from NNAD.Stage4_NNDSScasesT1
where mmwr_year='2021'
and condition not in ("11065");
quit;


DATA OUTDK.Week5221_nnad_noncovid;
   SET Week5221;
run; 

