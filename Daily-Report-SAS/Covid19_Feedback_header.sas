/*************************************************************************************************/
/* Description: Header for the code Covid19_CovidMMG_Notification_Feedback_Report                */
/*                                                                                               */
/* Created by:  Sang Kang	   06/30/2021                                                         */
/* Modified by: Anu Bhatta    07/08/2021                                                         */
/*************************************************************************************************/

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
                    "&rootdir\Source\Macros"
                    );

%DBserverByEnv(AppName=NNAD, Environment=&environment);  

/* Assign location of output */
%let output=&rootdir\QC\Outputs\DailyReports\COVID-19\COVID-19 Completeness Rpt;
libname datasets "&rootdir\QC\Outputs\DailyReports\COVID-19\COVID-19 Completeness Rpt\datasets_MMG";

/* Pull in Data: NNAD Production Environment and CSP NETSS */
libname NNAD OLEDB
        provider="sqlncli11"
        properties = ( "data source"="&DBservName"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;
                       
libname current "\\cdc\csp_project\NCPHI_DISSS_NNDSS_NCIRD\Current" access=readonly;

/* Bring in saved formats */
X "Copy ""&rootdir\Source\Formats\QCNNADFormats.xlsx"" ""&rootdir\Source\Formats\QCNNADFormats&tasknumber..xlsx"" ";
libname qcfmt XLSX "&rootdir\Source\Formats\QCNNADFormats&tasknumber..xlsx" access=readonly;

/* specify list of formats to be read from excel format file */
/* birthctr res_country is combined to bir_resctr as values are same, source is changed to repo_source as source already exists */
%ExlFmt(libn = qcfmt, SheetN= ethnicity case_status dis_aq bir_resctr repo_source 
                              pre misy res_state sex race_gen nrace_net trans preg 
                              outbreak race_us_var_name datet fipsprov);

/* release the excel file pointer */
libname qcfmt clear;
X "Del ""&rootdir\Source\Formats\QCNNADFormats&tasknumber..xlsx"" ";

%let time=%sysfunc(time(),time8.0);
%let weekdate=%sysfunc(date(),weekdate29.);

options fullstimer compress=yes; /*This will allow us to troubleshoot which steps are taking a long time in the code*/
