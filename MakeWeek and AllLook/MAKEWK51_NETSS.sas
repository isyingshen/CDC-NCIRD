
*---------------------------------------------------------------------*
|PROGRAM NAME:     MAKEWK51                                          |
|FUNCTION OF PROGRAM:  MUST BE RUN IN THE CORRECT  WEEK AT THE END    |
|                      OF THE YEAR!!!!!                               |
|      ** USE THIS TO READ EPO WEEK 52 NETSS DATASET AND WRITE        |
¦         THE DATA OUT TO A DATASET HERE AT NIP......
¦
¦      *** THIS IS IMPORTANT TO DO TO MAINTAIN AVAILABILITY OF
¦          WEEK 52 DATA INTO THE NEW YEAR, AFTER WHICH EPO
¦          CONTINUES TO UPDATE NETSS DATA UNTIL IT IS FINALIZED
¦           SOMETIME IN MIDYEAR.  THE WEEK 52 DATA IS NOT FROZEN
¦           AT EPO.
¦
¦
|                                                                     |
|PROGRAMMER:  S.ROUSH                                                 |
¦DATA SOURCES:  NETSS DATA SET                                        ¦
|DATE PROGRAM DOCUMENTED: 12-15-05                                    |
|PROGRAM RUN:  1/4/07                                               |
*---------------------------------------------------------------------*;

libname dat2 "\\cdc\csp_project\ncphi_disss_nndss_ncird\current" access=readonly ;
libname dat3 "\\cdc\csp_project\NCIRD_MB00\swr1\NETSS\WK5216" access=readonly ;
libname dat4 "\\cdc\csp_project\ncphi_disss_nndss_ncird\history" access=readonly ;


libname outdk "\\cdc\csp_project\NCIRD_MB00\swr1\NETSS\wk5219"  ;



DATA WEEk5219;
   SET DAT2.NCIRD;

IF YEAR = 2019;


DATA OUTDK.WEEk5219;
   SET WEEk5219;

run; 


/*--------------------------------------------------------------------------
If you need to delete the dataset that you just created, you can do it with
the following code.
--------------------------------------------------------------------------*/

*proc datasets lib=outdk ;
*delete WEEk5116testrun ;
*run ;
*quit ;


