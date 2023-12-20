/*****************************************************************************************************************/
/* Description: Summarizes 11065 records in NNAD Stage4 Production and CSP NETSS.                 					  */
/*                                                                                               				 	  */
/* Created by : Hannah Fast      3/10/2020                                                        				 	  */
/* Modified by:                                                                                   				 	  */
/* Matt Lerick	3/13/2020 -%Include formats pathway renamed                                        				 	  */
/* Matt Lerick	3/13/2020 -Upcase SITE for merge between CSP and NNAD                              				 	  */
/* Matt Lerick	3/17/2020 -Redirected output to SAS code sets folder                               				 	  */
/* Matt Lerick	3/19/2020 -Removed constraint for NNAD records to have mmwr_year>2018              				 	  */
/* Hannah Fast  3/31/2020 -Made v4                                                               				  	  */
/* Hannah Fast  4/7/2020  -Added duplicate sort by n_CDCDATE                                      				 	  */
/* Hannah Fast  4/13/2020 -Added duplicate report output                                          				 	  */
/* Hannah Fast  5/1/2020  -Restructured, added second dup_flag                                    				 	  */
/* Hannah Fast  5/13/2020 -Restructured, modified duplicates tab                                  				 	  */
/* Hannah Fast  5/18/2020 -Changed NETSS dedup key to 4 variables                                 				 	  */
/* Hannah Fast  6/11/2020 -Added timer                                                            				 	  */
/* Hannah Fast  6/15/2020 -Optimized to improve time and limit memory                             				 	  */
/* Hannah Fast  7/6/2020  -Added limit on printing of duplicate report                            				 	  */
/* Sang Kang    7/27/2020 -Changed the output file path to Informatics environment folder.        				 	  */
/* Anu Bhatta	8/05/2020 -As QC folder changed path for Projdir modified					     		  				 	  */
/* Hannah Fast  8/12/2020 -Added 5 changes from email                                             				 	  */
/* Anu Bhatta	8/21/2020 -Implemented changes to Listing 3b, Table 5a, 5b, 6b,6c,6d	    	 		  				 	  */
/* Hannah Fast	9/09/2020 -Changes to table 6a (report and dataset) and added MVPS prod libname    				 	  */
/* Anu Bhatta	10/05/2020 -Added column for difference between previous NNAD and CSP Netss	to	  				 	  */
/*						    		table 5a and storing dataset to bring in 14 days prior into a column 		  		 	  */
/* Anu Bhatta	11/02/2020 -Standardized the code and added ExlFmt macro for QCNNADFormats		 		 			 	  */
/* Anu Bhatta	11/06/2020 -Added new tab for Table 7 for Alaska Duplicates						 						 	  */
/* Hannah Fast	04/13/2021 -Adjusted for NNDSS Redesign								             						 	  */
/* Ying Shen	05/19/2021 -Removed the 2nd labname NNADs 								         			  			 	  */
/* Ying Shen	05/20/2021 -Used the secondary staging NNAD								         						 	  */
/* Ying Shen	05/20/2021 -Change var.sum to sum(var)                                           				 	  */
/* Ying Shen   05/24/2021 -Bring in Jurisdiction FIPS Code                                      				 	  */
/* Ying Shen   05/24/2021 -Added a tab8 to output the mismatch caseID and State                 				 	  */
/* Ying Shen   05/27/2021 -Limited tab8 to COVID only                                           				 	  */
/*                         -only output wsystem not equal to 5                                   				 	  */
/*                         -Indicate the Source of the Data on the top of the report             				 	  */
/* Anu Bhatta	05/27/2021 -Limited Table7 Listing 7b to 5000 observations												 	  */
/*									-Saving dataset dup_flag2_format to folder using formats									 	  */ 
/* Ying Shen   06/04/2021 -Comment out filters in data datasets.duplicate_pairs									 	 	  */
/* Ying Shen   06/04/2021 -Added title2 to the table 7b																	 	     */
/* Ying Shen   06/04/2021 -Added "delete dup_flag2_&prior_15;" to the proc datasets library=datasets nolist;     */
/* Anu Bhatta  06/07/2021 -Modified title1 and 2 to the Table 7a																  */
/* Anu Bhatta  08/24/2021 -Changed from CSP_NETSS to MPVS spinoff NETSS_VW to retrieve data for Netss 		     */
/*								  -retrieve and modified variables CSP_NETSS to NETSS_VW, CSPNETSSonly to netssvwonly 	  */
/*								   to avoid confusion and are saved datasets in folder for prior 15 days datasets		  */
/* Anu Bhatta	11/02/2021 -Limited Line Listing 4b and save NETSSduplicate_pairs dataset to folder					  */
/* Anu Bhatta  01/07/2022 -Table 5 has been removed																				  */
/* Anu Bhatta  01/10/2022 -Table 6b, 6c, 6d and 6e has been removed															  */
/*****************************************************************************************************************/

%put SAS HOST %sysfunc(grdsvc_getname('')); /* name of the host handling the job */
ods listing close;

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

options mprint mlogic symbolgen
        sasautos = (sasautos,
                    "&rootdir\Source\Macros"
                    );

%DBserverByEnv(AppName=NNAD, Environment=&environment);

/* Assign location of output */
%let output=&rootdir\QC\Outputs\DailyReports\COVID-19;

/* Pull in Data: NNAD Production Environment and MVPS Production */
libname NNAD OLEDB
        provider="sqlncli11"
        properties = ( "data source"="&DBservName"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;

libname MVPS OLEDB
        provider="sqlncli11"
        properties = ( "data source"="mvpsdata,1201\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="MVPS_PROD" ) schema=HL7 access=readonly;

libname MVPSN OLEDB
        provider="sqlncli11"
        properties = ( "data source"="mvpsdata,1201\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="MVPS_PROD" ) schema=NETSS access=readonly;

																																  
libname output "&rootdir\QC\Outputs\DailyReports\COVID-19";
libname datasets "&rootdir\QC\Outputs\DailyReports\COVID-19\Datasets";

filename nnadteam "&output.\&SYSDATE. COVID-19 NNAD Report_Internal.xlsx";
filename duprpt "&output.\&SYSDATE. COVID-19 NNAD Report_Duplicates.xlsx";
filename pdfrptCP "&output.\&SYSDATE. COVID-19 NNAD Report Confirmed and Probable.pdf";
																			
filename pdfrptA "&output.\&SYSDATE. COVID-19 NNAD Report All Case Status.pdf";

/* Bring in formats */
libname qcfmt XLSX "&rootdir\Source\Formats\QCNNADFormats.xlsx" access=readonly;

/*Bring in Jurisdiction FIPS Code*/
libname fips xlsx "&rootdir\Source\Formats\Jurisdiction_FIPS_Code.xlsx";

/* specify list of formats to be read from excel format file */;
%ExlFmt(libn = qcfmt, SheetN = fipsprov case_status event source dup db category casstat merge casflag);

/* release the excel file pointer */
libname qcfmt clear;


%let time=%sysfunc(time(),time8.0);
%let weekdate=%sysfunc(date(),weekdate29.);
%let date=%sysfunc(date(),mmddyyd8.); /* change to yymmdd10.*/
options fullstimer compress=yes;
/* report should follow label of column 1 - "Both "today's date"" column 2 - "Both "previous report's date"", etc. */

/* DEDUPLICATION AND DATA CLEANING FOR NNAD STAGE4 DATA*/
data stage4_11065 stage4_10575;
   set NNAD.Stage4_NNDSSCasesT1 (keep= trans_id condition mmwr_year report_jurisdiction local_record_id site 
   												wsystem age_invest age_invest_units birth_dt case_status sex
                                       ak_n_ai asian black hi_n_pi white race_asked_but_unk race_no_info 
                                       race_not_asked race_oth race_oth_txt race_refused race_unk n_race 
                                       ethnicity  first_electr_submit_dt electr_submitted_dt first_report_county_dt
                                       first_report_phd_dt first_report_state_dt n_datet illness_onset_dt dx_dt 
                                       n_labtestdate n_unkeventd mmwr_week comment jurisdiction legacy_case_id  
                                       n_cdcdate n_count n_county  n_expandedcaseid n_rectype 
                                       result_status  source_system state_case_id);
   where condition in ('10575','11065');

   /* Key Variables */
   expanded_id_merge=trim(left(local_record_id));
   case_id_merge=trim(left(local_record_id));
   isite=upcase(site);
   iwsystem=input(wsystem, 3.);
   event=input(condition, 5.);
   year=input(mmwr_year, 4.);

   /* Date Variables */
   ifirst_electr_submit_dt=datepart(first_electr_submit_dt);
   in_cdcdate=datepart(n_cdcdate);
   ielectr_submitted_dt=datepart(electr_submitted_dt);
   ibirth_dt=datepart(birth_dt);

   drop wsystem first_electr_submit_dt n_cdcdate electr_submitted_dt site birth_dt;
   rename iwsystem=wsystem ifirst_electr_submit_dt=first_electr_submit_dt in_cdcdate=n_cdcdate 
   		 ielectr_submitted_dt=electr_submitted_dt isite=site ibirth_dt=birth_dt;
   database=2;

   if wsystem=2 then do;
      expanded_id_length=length(n_expandedcaseid);
      if find(n_expandedcaseid, 'CAS')>=1 then CAS_flag=1;
      else CAS_flag=0;
   end;

   if (source_system in (5,15)) then do;
      firstkey=cats(report_jurisdiction,compress(local_record_id)); /* For HL7 records, look at local_record_id */
   	secondkey=cats(report_jurisdiction,compress(local_record_id));
	end;
   else if (source_system=1) and (WSYSTEM=5) then do;
      firstkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* For NETSS records created from MVPS, look at n_expandedcaseid */  
   	secondkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* This step is for data investigation purposes only */
	end;
   else if (source_system=1) and (WSYSTEM NE 5) then do;
      firstkey=cats(report_jurisdiction,compress(local_record_id),site,mmwr_year); /* For other NETSS records, look at local_record_id (CASEID), site, mmwr_year */
      secondkey=cats(report_jurisdiction,compress(n_expandedcaseid)); /* This step is for data investigation purposes only */
   end;

   if condition='11065' then output stage4_11065;
   else output stage4_10575;
run;

proc sort tagsort data=stage4_11065;
   by firstkey descending source_system descending n_cdcdate; /* Prefer HL7 record over NETSS duplicate, newer NETSS record over older */
run;

/* Duplicates by match of local_record_id/n_expandedcaseid are flagged */
data NNAD_COVID_2 (drop= isite iwsystem icase_status ibirth_dt iage isex /* in_race */ 
								 iillness_onset_dt isource_system)
     dup_list     (keep= firstkey electr_submitted_dt site_flag wsystem_flag case_status_flag
     							 birth_dt_flag age_invest_flag sex_flag illness_onset_dt_flag source_system_flag);
   set stage4_11065;
   by firstkey;
   retain isite iwsystem icase_status ibirth_dt iage isex /* in_race */ iillness_onset_dt isource_system;
      /* Assign duplicate flag */
         if missing(firstkey) then dup_flag=0;
         else if not missing(firstkey) then do;
            if first.firstkey then do;
            dup_flag=-1;
               isite=site;
			   iwsystem=wsystem;
               icase_status=case_status;
               ibirth_dt=birth_dt;
               iage=age_invest;
		       isex=sex;
               /* in_race=n_race; */
			   iillness_onset_dt=illness_onset_dt;
			   isource_system=source_system;
            end;
	        dup_flag+1;
            /* Compare values for case information */
		       if site NE isite then site_flag=1;
		       if wsystem NE iwsystem then wsystem_flag=1;
               if case_status NE icase_status then case_status_flag=1;
               if birth_dt NE ibirth_dt then birth_dt_flag=1;
	           if age_invest NE iage then age_invest_flag=1;
	           if sex NE isex then sex_flag=1;
	           /* if n_race NE in_race then n_race_flag=1; */
               if illness_onset_dt NE iillness_onset_dt then illness_onset_dt_flag=1;
			   if source_system=isource_system then source_system_flag=1;
         end;

      output NNAD_COVID_2;
      if dup_flag NE 0 then output dup_list;
run;

proc sort tagsort data=NNAD_COVID_2;
   by secondkey descending source_system descending n_cdcdate;
run;

/* secondkey added for HL7 records, look at local_record_id and
for NETSS records created from MVPS, look at n_expandedcaseid*/

/* Duplicates by match of local_record_id/n_expandedcaseid are removed */
data stage4_dupflag2 (keep= secondkey electr_submitted_dt site_flag wsystem_flag case_status_flag
										  birth_dt_flag age_invest_flag sex_flag n_race_flag illness_onset_dt_flag
										  source_system_flag)
duplist;
   set NNAD_COVID_2;
   by secondkey;
   retain iwsystem isource_system;
   if (first.secondkey) then do;
      dup_flag2=-1;
	  iwsystem=wsystem;
	  isource_system=source_system;
   end;

   dup_flag2+1;

   if wsystem NE iwsystem then wsystem_flag=1;
   if source_system=isource_system then source_system_flag=1;
   
   output stage4_dupflag2;

   if dup_flag=0 and dup_flag2 NE 0 then output duplist;
run;

/* NETSS "duplicates" by match of local_record_id/caseid are flagged. These are not considered 
	true duplicates as they do not match on 4 key variables but need investigation */

data NNAD_COVID_3        (drop= isite iwsystem icase_status ibirth_dt iage isex in_race 
										  iillness_onset_dt isource_system)
     NNAD_COVID_3_limvar (keep= database electr_submitted_dt dup_flag dup_flag2 source_system
										  report_jurisdiction event mmwr_year local_record_id n_expandedcaseid 
										  site wsystem n_CDCDATE result_status case_status firstkey secondkey
										  birth_dt age_invest age_invest_units sex n_race illness_onset_dt)
     NETSSdup_list       (keep= secondkey electr_submitted_dt site_flag wsystem_flag case_status_flag
										  birth_dt_flag age_invest_flag sex_flag n_race_flag illness_onset_dt_flag
										  source_system_flag);
   set NNAD_COVID_2;
   by secondkey;
   retain isite iwsystem icase_status ibirth_dt iage isex in_race iillness_onset_dt isource_system;
      /* Assign second duplicate flag */
      if missing(secondkey) then dup_flag2=0;
      else 
			if not missing(secondkey) then do;
         	if first.secondkey then do;
         		dup_flag2=-1;
            	isite=site;
					iwsystem=wsystem;
            	icase_status=case_status;
            	ibirth_dt=birth_dt;
            	iage=age_invest;
		    		isex=sex;
            	in_race=n_race;
					iillness_onset_dt=illness_onset_dt;
					isource_system=source_system;
		end;
	   dup_flag2+1;
      /* Compare values for case information */
	   if site NE isite then 
			site_flag=1;
		if wsystem NE iwsystem then 
			wsystem_flag=1;
		if case_status NE icase_status then 
			case_status_flag=1;
      if birth_dt NE ibirth_dt then 
			birth_dt_flag=1;
	   if age_invest NE iage then 
			age_invest_flag=1;
	   if sex NE isex then 
			sex_flag=1;
	   if n_race NE in_race then 
			n_race_flag=1;
      if illness_onset_dt NE iillness_onset_dt then 
			illness_onset_dt_flag=1;
		if source_system=isource_system then 
			source_system_flag=1;
	  end;

     	output NNAD_COVID_3;
	  	output NNAD_COVID_3_limvar;
     	if dup_flag=0 and dup_flag2 NE 0 then 
			output NETSSdup_list;
run;

/* Create clean dataset - remove duplicates and records that are not a case  */
data stage4_clean stage4_remove;
   set NNAD_COVID_3;
   if (dup_flag=0) and (result_status NE 'X') and (case_status NE 'PHC178') then 
      output stage4_clean;
   else 
		output stage4_remove;
run;

/* Delete datasets not used further on */
proc datasets library=work;
   delete stage4_remove;
   delete NNAD_COVID_2;
run;
quit;

/* THESE STEPS ARE FOR GENERATING THE REPORT */

/* Create dataset with duplicate pairs */
proc sql noprint;
create table duplicate_pairs as
   select a.*, b.site_flag, b.wsystem_flag, b.case_status_flag, b.birth_dt_flag, b.age_invest_flag,
			 b.sex_flag, b.illness_onset_dt_flag, b.source_system_flag
   from NNAD_COVID_3_limvar as a inner join dup_list as b 
   on a.firstkey=b.firstkey;

/* secondkey duplicate */
create table dup_flag2 as
   select a.*, b.wsystem_flag, b.source_system_flag
   from NNAD_COVID_3_limvar as a inner join duplist as b 
   on a.secondkey=b.secondkey;

create table NETSSduplicate_pairs as
   select a.*, b.site_flag, b.wsystem_flag, b.case_status_flag, b.birth_dt_flag, b.age_invest_flag,
			 b.sex_flag, b.n_race_flag, b.illness_onset_dt_flag, b.source_system_flag
   from NNAD_COVID_3_limvar as a inner join NETSSdup_list as b
   on a.secondkey=b.secondkey;
quit;

proc sort tagsort data=duplicate_pairs;
   by firstkey;
run;

proc sort tagsort data=NETSSduplicate_pairs (obs=2000) out=duplicatereport ;
   by secondkey dup_flag2;
run;

/* Create stored dataset for investigating differences in duplicates */
data datasets.duplicate_pairs;
   set duplicate_pairs;
/*   where site_flag=1 or wsystem_flag=1 or case_status_flag=1 or birth_dt_flag=1 or age_invest_flag=1*/
/*			or sex_flag=1 or illness_onset_dt_flag=1 or source_system_flag=1;*/
run;		

%macro dup_pairs (varname=, dupflag=);
	data &varname;
		set duplicate_pairs;
			by report_jurisdiction;
				if &dupflag = 1 then
					output &varname;
	run;
%mend dup_pairs;

%dup_pairs(varname=site_fl, dupflag=site_flag);
%dup_pairs(varname=wsystem_fl, dupflag=wsystem_flag);
%dup_pairs(varname=case_status_fl, dupflag=case_status_flag);
%dup_pairs(varname=birth_dt_fl, dupflag=birth_dt_flag);
%dup_pairs(varname=age_invest_fl, dupflag=age_invest_flag);
%dup_pairs(varname=sex_fl, dupflag=sex_flag);
%dup_pairs(varname=illness_onset_dt_fl, dupflag=illness_onset_dt_flag);
%dup_pairs(varname=source_system_fl, dupflag=source_system_flag);

/* 1. Final Counts */ 
/* 2. Data Cleaning */

proc freq data=NNAD_COVID_3 noprint;
   tables report_jurisdiction*case_status / out=nnad_total_freq; /* Total records before cleaning */
run;

proc freq data=NNAD_COVID_3 noprint;
   where (dup_flag NE 0);
   tables report_jurisdiction*case_status / out=dups_freq; /* Duplicates */
run;

proc freq data=NNAD_COVID_3 noprint;
   where (dup_flag2 NE 0);
   tables report_jurisdiction*case_status / out=dups_freq2; /* NETSS duplicates with different SITE */
run;

proc freq data=NNAD_COVID_3 noprint;
   where (case_status='PHC178');
   tables report_jurisdiction*case_status / out=nocase_freq; /* Records with case status "Not a Case" */
run;

proc freq data=NNAD_COVID_3 noprint;
   where (result_status='X');
   tables report_jurisdiction*case_status / out=resultX_freq; /* Records with result_status='X' */
run;

proc freq data=stage4_clean noprint;
   tables report_jurisdiction*case_status / out=nnad_nodups_freq; /* Cleaned dataset */
run;

data tab2;
  set nnad_total_freq   (in=in1)
      dups_freq         (in=in2)
	   nocase_freq       (in=in3)
	   resultX_freq      (in=in4)
	   nnad_nodups_freq  (in=in5);
	if in1 then 
		total=count;
  	if in2 then 
		dups=count;
  	if in3 then 
		nocase=count;
  	if in4 then 
		resultx=count;
  	if in5 then 
		nodups=count;
run;

/* 3. Duplicates */
/* Summarize duplicate records */

%macro dupfreq (varname=, dupflag=, tab=);
proc freq data=NNAD_COVID_3 noprint;
   where (&dupflag NE 0) and (&varname._flag=1);
   tables report_jurisdiction*&varname._flag / out=dup_&varname._freq&tab.;
run;
%mend dupfreq;

%dupfreq (varname=site, dupflag=dup_flag, tab=3);
%dupfreq (varname=wsystem, dupflag=dup_flag, tab=3);
%dupfreq (varname=case_status, dupflag=dup_flag, tab=3);
%dupfreq (varname=birth_dt, dupflag=dup_flag, tab=3);
%dupfreq (varname=age_invest, dupflag=dup_flag, tab=3);
%dupfreq (varname=sex, dupflag=dup_flag, tab=3);
%dupfreq (varname=illness_onset_dt, dupflag=dup_flag, tab=3);

data table3b;
  set dups_freq (in=in1) 
      dup_site_freq3 (in=in2)
      dup_wsystem_freq3 (in=in3) 
      dup_case_status_freq3 (in=in4)
      dup_birth_dt_freq3 (in=in5)
      dup_age_invest_freq3 (in=in6)
      dup_sex_freq3 (in=in7)
      dup_illness_onset_dt_freq3 (in=in8);
	if in1 then 
		numtotal=count;
  	if in2 then 
		numsite=count;
  	if in3 then 
		numwsys=count;
  	if in4 then 
		numcasstat=count;
  	if in5 then 
		numbirthd=count;
  	if in6 then 
		numage=count;
  	if in7 then 
		numsex=count;
  	if in8 then 
		numillness=count;
run;

proc freq data=NNAD_COVID_3 noprint;
   where dup_flag NE 0 and source_system in (5, 15);
   tables report_jurisdiction*case_status / out=MVPSdup_freq;
run;

proc freq data=NNAD_COVID_3 noprint;
   where dup_flag NE 0 and source_system=1 and wsystem=5;
   tables report_jurisdiction*case_status / out=MVPSNETSSdup_freq;
run;

proc freq data=NNAD_COVID_3 noprint;
   where dup_flag NE 0 and source_system=1 and wsystem NE 5;
   tables report_jurisdiction*case_status / out=NETSSdup_freq;
run;

proc freq data=NNAD_COVID_3 noprint;
   where dup_flag=0 and dup_flag2 NE 0;
   tables report_jurisdiction*case_status / out=NETSSsitedup_freq;
run;

data dedup;
   set MVPSdup_freq (in=in1) MVPSNETSSdup_freq (in=in2) NETSSdup_freq (in=in3)  NETSSsitedup_freq (in=in4);
   if in1 then 
		MVPSdup_freq=count;
   if in2 then 
		MVPSNETSSdup_freq=count;
   if in3 then 
		NETSSdup_freq=count;
   if in4 then 
		NETSSsitedup_freq=count;
   where report_jurisdiction not in ("06", "6"); /*Remove CA duplicates, Added by Xin on 07/13/2020*/ 
run;

/* 4. NETSS "Duplicates" */
%dupfreq (varname=site, dupflag=dup_flag2, tab=4);
%dupfreq (varname=wsystem, dupflag=dup_flag2, tab=4);
%dupfreq (varname=case_status, dupflag=dup_flag2, tab=4);
%dupfreq (varname=birth_dt, dupflag=dup_flag2, tab=4);
%dupfreq (varname=age_invest, dupflag=dup_flag2, tab=4);
%dupfreq (varname=sex, dupflag=dup_flag2, tab=4);
%dupfreq (varname=n_race, dupflag=dup_flag2, tab=4);
%dupfreq (varname=illness_onset_dt, dupflag=dup_flag2, tab=4);

data table4a;
  set dups_freq2 (in=in1) 
      dup_site_freq4 (in=in2)
      dup_wsystem_freq4 (in=in3) 
	   dup_case_status_freq4 (in=in4)
      dup_birth_dt_freq4 (in=in5)
      dup_age_invest_freq4 (in=in6)
      dup_sex_freq4 (in=in7)
	   dup_n_race_freq4 (in=in8)
	   dup_illness_onset_dt_freq4 (in=in9);
  	if in1 then 
		numtotal=count;
  	if in2 then 
		numsite=count;
  	if in3 then 
		numwsys=count;
  	if in4 then 
		numcasstat=count;
  	if in5 then 
		numbirthd=count;
  	if in6 then 
		numage=count;
  	if in7 then 
		numsex=count;
  	if in8 then 
		numrace=count;
  	if in9 then 
		numillness=count;
run;

/* added prefix to save dataset daily */
data _null_;
   now = datetime();
   loaddate = put(datepart(now), mmddyyn6.);
   call symput("loaddate", loaddate);
run;
%put &loaddate;


/* Table 6a. SARS-CoV cases (10575) */
proc sql noprint;
create table NNAD_10575 as
   select a.*, b.current_record_flag
   from stage4_10575 as a left join MVPS.message_meta_vw as b 
   on a.trans_id=b.msg_transaction_id;
quit;

proc sort data=NNAD_10575;
by report_jurisdiction;
run;


/*Report 8*/
proc sql;
create table spinoff_vw_data1 as
select event
,state
,year
,caseID
,site
,wsystem
,expanded_caseID
from MVPSN.NetssCaseSASSpinOff_vw
where event=11065;
quit;

proc sql;
create table spinoff_vw_state as
select a.*
,b.FIPS_Code
,b.code
from spinoff_vw_data1 as a
left join fips.sheet1 as b
on a.state=b.FIPS_Code;
quit;

/*change caseID from numeric to character*/
data spinoff_vw_state_c;
	set spinoff_vw_state;
	c_caseID=vvalue(caseID);
	drop caseID;
	rename c_caseID=caseID;
run;


/*create state_match and caseID_match variables*/
data spinoff_vw_state_cf;
	set spinoff_vw_state_c;
	state_match=find(lowcase(compress(expanded_caseID)),lowcase(compress(Code)));
	caseID_match=find(lowcase(compress(expanded_caseID)),lowcase(compress(caseID)));
run;


/*report 8a*/
proc sql;
create table report_8a as
select event
,state
,year
,caseID
,site
,wsystem
,expanded_caseID
,Code
,state_match
from spinoff_vw_state_cf(obs=5000)
where state_match =0
and wsystem not in (5);
quit;

/*report 8b*/
proc sql;
create table report_8b as
select event
,state
,year
,caseID
,site
,wsystem
,expanded_caseID
,Code
,caseID_match
from spinoff_vw_state_cf(obs=5000)
where caseID_match =0
and wsystem not in (5);
quit;

/*report 8c*/
proc sql;
create table report_8c as
select event
,state
,year
,caseID
,site
,wsystem
,expanded_caseID
,Code
,state_match
,caseID_match
from spinoff_vw_state_cf(obs=5000)
where (state_match =0 and caseID_match =0)
and wsystem not in (5);
quit;


/* CREATE OUTPUT */
/* Filenames can be edited at the top of the code */


/* Create Excel Output for NNAD Team Review */
/* Sheet 1: Frequency Counts */
ods excel file=nnadteam                               
   options (sheet_interval="none" sheet_name="1. Final Count" start_at="1, 2" embedded_titles="YES");

/* NNDSS: All case statuses */
title1 color=black justify=left h=3.5 "Table 1a. Reports of COVID-19 with Notification through NNDSS";
title2 color=black justify=left h=2 "All Case Status: Confirmed, Probable, Suspect, and Unknown";
title3 color=black justify=left h=2 "Exclusion Criteria: NNAD Stage4 duplicates, case status='PHC178' (Not a Case), and result_status='X' for the most recent record.";
proc report data=nnad_nodups_freq spanrows;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS.;
   label report_jurisdiction='Reporting Jurisdiction' case_status='Case Status';
   where case_status in ('410605003','2931005','415684004','UNK');
   columns report_jurisdiction case_status count;
       define report_jurisdiction / group style=[width=2in];
       define case_status / group style=[width=2in];
	   define count /  style=[width=2in];
          /* Calculate Total */
          rbreak after / summarize style=[fontweight=bold background=gainsboro];
          compute after;
             report_jurisdiction='Total';
          endcomp;
          /* Add header and footnotes */
          compute before _page_ / style=[fontweight=bold];
             line "&weekdate.";  
          endcomp;
          compute after _page_/ style=[just=left fontsize=1];
             line "Provisional data as of &weekdate. &time..";
          endcomp;
run;

/* NNDSS: Confirmed and Probable Only */
title1 color=black justify=left h=3.5 "Table 1b. Reports of COVID-19 with Notification through NNDSS";
title2 color=black justify=left h=2 "Confirmed and Probable Case Status";
title3 color=black justify=left h=2 "Exclusion Criteria: NNAD Stage4 duplicates, all records with case status other than '410605003' (Confirmed), and result_status='X' for the most recent record.";
proc report data=nnad_nodups_freq spanrows;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS.;
   label report_jurisdiction='Reporting Jurisdiction' case_status='Case Status';
   where case_status in ('410605003','2931005');
   columns report_jurisdiction case_status count;
      define report_jurisdiction / group style=[width=2in];
      define case_status / group style=[width=2in];
      define count /  style=[width=2in];
	     /* Calculate Total */
         rbreak after / summarize style=[fontweight=bold background=gainsboro];
         compute after;
            report_jurisdiction='Total';
         endcomp;
		 /* Add header and footnotes */
	     compute before _page_/ style=[fontweight=bold];
            line "&weekdate.";
         endcomp;
         compute after _page_/ style=[just=left fontsize=1];
            line "Provisional data as of &weekdate. &time..";
         endcomp;
run;


/* Sheet 2: Data Cleaning and NNAD Validation Report */
ods excel options (sheet_interval="proc" sheet_name="2. Data Cleaning");

title1 color=black justify=left h=3.5 "Table 2. NNAD Stage4 Data Summary for Deduplication and Removal of Non-Cases";
title2 color=black justify=left h=2 "The 'Final Total' column contains the final case counts for Table 1a and 1b after deduplication of Stage4 records and removal of non-cases.";
proc report data=tab2 spanrows nowd;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS.;
   label report_jurisdiction='Reporting Jurisdiction' case_status='Case Status' total='Total Records' 
         dups='NNAD Duplicate' nocase='Case Status=PHC178' resultx='Result Status=X' nodups='Final Total';
   columns report_jurisdiction case_status total dups nocase resultx nodups;
   define report_jurisdiction / group style=[width=1.5in];
	define case_status / group style=[width=1.2in];
	define total / style=[width=1in];
	define dups / style=[width=1.4in];
	define nocase / style=[width=1.5in];
	define resultx / style=[width=1.2in];
	define nodups / style=[width=1.7in];
   rbreak after / summarize style=[fontweight=bold background=gainsboro];
   compute after ;
      report_jurisdiction='Total';
   endcomp;
	compute before _page_/ style=[fontweight=bold];
            line "&weekdate.";
   endcomp;
	compute after _page_/ style=[just=left fontsize=1];
      line "The 'Total Records' count represents the complete number of records in Stage4 NNAD with condition code=11065.";
      line "Duplicate records are removed. See the 'Duplicates' sheet for a definition of what constitutes a duplicate record.";
      line "Records with a case_status of 'Not a case' (PHC178) and those with result_status='X' are removed.";
	   line "The columns are not mutually exclusive; 1 record may meet more than one criteria for exclusion.";
   endcomp;
run;


/* Sheet 3: Duplicate Reports */

ods excel options (sheet_interval="proc" sheet_name="3. Duplicates");

title1 color=black justify=left h=3.5 "Table 3a. Summary of the Daily Report Deduplication Process";
title2 color=black justify=left h=2 "Column A. If the record is from MVPS (source_system=5 or 15), the deduplication key is assigned as report_jurisdiction and local_record_id.";
title3 color=black justify=left h=2 "Column B. If the record is from NETSS and is MVPS source (source_system=1 and wsystem=5), the deduplication key is assigned as report_jurisdiction and n_expandedcaseid.";
title4 color=black justify=left h=2 "Column C. If the record is from NETSS and is NOT MVPS source (source_system=1 and wsystem=1, 2 or 3), the deduplication key is assigned as STATE (report_jurisdiction), CASEID (local_record_id), YEAR (mmwr_year), and SITE.";
title5 color=black justify=left h=2 "Column D. This column shows NETSS records with a duplicate local_record_id, but were not deduped because of a difference in SITE.";
title6 color=black justify=left h=2 "CA Duplicates excluded from this sheet"; /*Added by Xin on 07/13/2020*/
proc report data=dedup;
   format report_jurisdiction $FIPSPROV.;
   label report_jurisdiction='Reporting Jurisdiction' mvpsdup_freq='A. Duplicate MVPS Records' MVPSNETSSdup_freq='B. Duplicate NETSS Records (MVPS-source)'
         NETSSdup_freq='C. Duplicate NETSS records (non-MVPS-source)' NETSSsitedup_freq='D. NETSS records with same local_record_id but NOT Deduped';
   column report_jurisdiction mvpsdup_freq MVPSNETSSdup_freq NETSSdup_freq NETSSsitedup_freq;
   define report_jurisdiction / group;
   rbreak after / summarize style=[fontweight=bold background=gainsboro];
   compute after;
      report_jurisdiction='Total';
   endcomp;
run;

ods excel options (sheet_interval="none");

title1 color=black justify=left h=3.5 "Table 3b. Counts of Duplicates with Differences in Case Information";
proc report data=table3b;
   format report_jurisdiction $FIPSPROV.;
   label report_jurisdiction='Reporting Jurisdiction' numtotal='All Duplicate Records' numsite='Subset: Different Site' numwsys='Subset: Different WSYSTEM'  
      numcasstat='Subset: Different Case Status' numbirthd='Subset: Different Birth Date' numage='Subset: Different Age' numsex='Subset: Different Sex' 
      numillness='Subset: Different Illness Onset Date';
   column report_jurisdiction numtotal numsite numwsys numcasstat numbirthd numage numsex numillness;
   define report_jurisdiction / group;
   rbreak after / summarize style=[fontweight=bold background=gainsboro];
	compute after _page_/ style=[just=left fontsize=1];
	   line "The columns are not mutually exclusive; 1 record may be included in more than subset.";
   endcomp;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in site. Output is limited to 20 records per jurisdiction."; 
proc report data=site_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt site_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in wsystem. Output is limited to 20 records per jurisdiction."; 
proc report data=wsystem_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt wsystem_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in case_status. Output is limited to 20 records per jurisdiction."; 
proc report data=case_status_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt case_status_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in birth_dt. Output is limited to 20 records per jurisdiction."; 
proc report data=birth_dt_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt birth_dt_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in age_invest. Output is limited to 20 records per jurisdiction."; 
proc report data=age_invest_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt age_invest age_invest_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in sex. Output is limited to 20 records per jurisdiction."; 
proc report data=sex_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt sex sex_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in illness_onset_dt. Output is limited to 20 records per jurisdiction."; 
proc report data=illness_onset_dt_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt illness_onset_dt illness_onset_dt_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

title1 color=black justify=left h=3.5 "Line Listing 3b. Listing of Records with Differences in Case Information";
title2 color=black justify=left h=2 "Records marked 'Duplicate' were removed from the final count."; 
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in source_system. Output is limited to 20 records per jurisdiction."; 
proc report data=source_system_fl(obs=20);
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt source_system_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

/* Sheet 4: NETSS "Duplicates" Report - For Investigation */
ods excel options (sheet_interval="proc" sheet_name="4. NETSS Site Diff");

title1 color=black justify=left h=3.5 "Table 3a. Summary of the Daily Report Deduplication Process";
title2 color=black justify=left h=2 "Column A. If the record is from MVPS (source_system=5 or 15), the deduplication key is assigned as report_jurisdiction and local_record_id.";
title3 color=black justify=left h=2 "Column B. If the record is from NETSS and is MVPS source (source_system=1 and wsystem=5), the deduplication key is assigned as report_jurisdiction and n_expandedcaseid.";
title4 color=black justify=left h=2 "Column C. If the record is from NETSS and is NOT MVPS source (source_system=1 and wsystem=1, 2 or 3), the deduplication key is assigned as STATE (report_jurisdiction), CASEID (local_record_id), YEAR (mmwr_year), and SITE.";
title5 color=black justify=left h=2 "Column D. This column shows NETSS records with a duplicate local_record_id, but were not deduped because of a difference in SITE.";
proc report data=dedup;
   format report_jurisdiction $FIPSPROV.;
   label report_jurisdiction='Reporting Jurisdiction' mvpsdup_freq='A. Duplicate MVPS Records' MVPSNETSSdup_freq='B. Duplicate NETSS Records (MVPS-source)'
         NETSSdup_freq='C. Duplicate NETSS records (non-MVPS-source)' NETSSsitedup_freq='D. NETSS records with same local_record_id but NOT Deduped';
   column report_jurisdiction mvpsdup_freq MVPSNETSSdup_freq NETSSdup_freq NETSSsitedup_freq;
   define report_jurisdiction / group;
run;


ods excel options (sheet_interval="none");

title1 color=black justify=left h=3.5 "Table 4a. Counts of NETSS Records with Same Local_Record_ID but Differences in Case Information";
proc report data=table4a;
   format report_jurisdiction $FIPSPROV.;
   label report_jurisdiction='Reporting Jurisdiction' numtotal='All Duplicate Records' numsite='Subset: Different Site' numwsys='Subset: Different WSYSTEM'  
         numcasstat='Subset: Different Case Status' numbirthd='Subset: Different Birth Date' numage='Subset: Different Age' numsex='Subset: Different Sex' 
         numrace='Subset: Different Race' numillness='Subset: Different Illness Onset Date';
   column report_jurisdiction numtotal numsite numwsys numcasstat numbirthd numage numsex numrace numillness;;
   define report_jurisdiction / group;
   rbreak after / summarize style=[fontweight=bold background=gainsboro];
	compute after _page_/ style=[just=left fontsize=1];
   line "The columns are not mutually exclusive; 1 record may be included in more than subset.";
   endcomp;
run;

/* Save dataset into folder as Report is not outputting all the observations */
data datasets.NETSSduplicate_pairs_&loaddate.;
   set NETSSduplicate_pairs;
run;
quit;

title1 color=black justify=left h=3.5 "Line Listing 4b. Listing of NETSS Records with same CASEID, but differences in SITE and MMWR YEAR";
title3 color=black justify=left h=2 "Duplicate pairs shown below contain a difference in site and were not deduped according to the 4 NETSS keys.";
title4 color=black justify=left h=2 "This report only outputs 2000 rows. For the complete list, please see 'NETSSduplicate_pairs_&loaddate..sas7bdat'"; 
proc report data=NETSSduplicate_pairs (obs=2000);
   where birth_dt_flag NE 1 and n_race_flag NE 1 and sex_flag NE 1 and illness_onset_dt_flag NE 1;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag dup_flag2 DUP. database DB. birth_dt n_CDCDATE MMDDYY8.;
   column database dup_flag dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE result_status sex age_invest age_invest_units n_race illness_onset_dt;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

/* Delete datasets not used further on */
proc datasets library=work;
   delete NETSSduplicate_pairs;
run;
quit;

/* Sheet 6: Other Analysis */
ods excel options (sheet_interval="proc" sheet_name="6. Other Analysis");

title1 color=black justify=left h=3.5 "Table 6a. Condition Code Verification";
title2 color=black justify=left h=2 "This table shows records in Stage4 with condition code = 10575 (SARS-CoV).";
title3 color=black justify=left h=2 "Records with case_status='PHC178' (Not a Case) and result_status='X' (Results not available) are excluded.";
proc report data=nnad_10575 spanrows;
where (case_status NE 'PHC178') and (result_status NE 'X');
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. source_system SOURCE. /*condition $condition.*/ electr_submitted_dt n_cdcdate MMDDYY8.;
   label report_jurisdiction='Reporting Jurisdiction' condition='Condition' source_system='Source System' local_record_id='Local Record ID' mmwr_year='MMWR Year' case_status='Case Status' 
         result_status='Result Status' current_record_flag='MVPS Current Record Flag';
   columns report_jurisdiction condition source_system local_record_id mmwr_year case_status result_status electr_submitted_dt n_cdcdate current_record_flag;
   compute before _page_/ style=[fontweight=bold];
       line "&weekdate.";
    endcomp;
   compute after _page_/ style=[just=left fontsize=1];
      line "MVPS current_record_flag is taken from message_meta_vw in MVPS Prod. NETSS-source records will not have a current_record_flag.";
   endcomp;
run;

ods excel options (sheet_interval="none" sheet_name="6. Other Analysis");

title1 color=black justify=left h=3.5 "Table 6f. NBS records in NETSS with EXPANDED_CASEID populated but do not contain 'CAS' (CAS_Flag=0)";
title2 color=black justify=left h=2 "MVPS began populating EXPANDED_CASEID for NBS-source NETSS records on 4/26/2020. It would be an error if a record received after that date is not populated with 'CAS'.";
title3 color=black justify=left h=2 "Note: This process can cause deduplication of records.";
proc freq data=stage4_11065;
   where wsystem=2 and CAS_flag=0;
   format report_jurisdiction $FIPSPROV. n_CDCDATE MMDDYY8.;
   tables report_jurisdiction*n_CDCDATE / list;
run;

/* Delete datasets not used further on */
proc datasets library=work;
	delete stage4_clean;
   delete stage4_11065;
run;
quit;

ods excel options (sheet_interval="proc" sheet_name="7. Sent to HL7 and NETSS");
title1 color=black justify=left h=3.5 "Table 7a. Counts of Potential Duplicate Records by Matching Local_Record_ID/N_Expandedcaseid but Differences for WSYSTEM";
title2 color=black justify=left h=2 "Records matching by local_record_id or n_expandedcaseid or combination of local_record_id, site and mmwr_year with differences in Source_System and WSYSTEM indicate they were sent separately to different systems";


proc report data=table4a;
where wsystem_flag=1;
   format report_jurisdiction $FIPSPROV.;
   label report_jurisdiction='Reporting Jurisdiction' numwsys='Subset: Different WSYSTEM';  
   column report_jurisdiction numwsys;
   define report_jurisdiction / group;
   rbreak after / summarize style=[fontweight=bold background=gainsboro];
   endcomp;
run;

ods excel options (sheet_interval="none" sheet_name="7. Sent to HL7 and NETSS");

title1 color=black justify=left h=3.5 "Line Listing 7b. Listing of Records with Differences in WSYSTEM";
title2 color=black justify=left h=2 "This table only outputs 5000 obs. The complete list is in dataset dup_flag2_<date>";
proc report data=dup_flag2(obs=5000);
where wsystem_flag=1;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. /*dup_flag2 DUP.*/ database DB. birth_dt n_CDCDATE electr_submitted_dt MMDDYY8.;
   column database dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid site case_status wsystem n_CDCDATE electr_submitted_dt result_status birth_dt wsystem_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag2 / style=[width=1in textalign=left];
   define n_expandedcaseid / width=97;
run;

ods excel options (sheet_interval="proc" sheet_name="8. Mis-Match");
proc report data=report_8a;
title1 color=black justify=left h=3.5 "Table 8a. The substring of the Expanded CaseID doesnt match the State Name (Report_Jurisdiction)";
title2 color=black justify=left h=2 "This report only outputs 5000 obs for review.";
title3 color=black justify=left h=2 "0: Not Match; 1: Match at the 1st position; 2: Match at the 2nd position...";
label caseID='CASEID' Code='STATE NAME' STATE='STATE ID' EXPANDED_CASEID='EXPANDED CASEID' state_match='DOES STATE NAME MATCH EXPANDED CASEID?';
run;


ods excel options (sheet_interval="none" sheet_name="8. Mis-Match");

proc report data=report_8b;
title1 color=black justify=left h=3.5 "Table 8b. The substring of the Expanded_caseID doesnt match the Case ID";
title2 color=black justify=left h=2 "This report only outputs 5000 obs for review.";
title3 color=black justify=left h=2 "0: Not Match; 1: Match at the 1st position; 2: Match at the 2nd position...";
label caseID='CASEID' Code='STATE NAME' STATE='STATE ID' EXPANDED_CASEID='EXPANDED CASEID' caseID_match='DOES CASEID MATCH EXPANDED CASEID?';
run;


ods excel options (sheet_interval="none" sheet_name="8. Mis-Match");

proc report data=report_8c;
title1 color=black justify=left h=3.5 "Table 8c. The substring of the Expanded_caseID doesnt match both State and Case ID";
title2 color=black justify=left h=2 "This report only outputs 5000 obs for review.";
title3 color=black justify=left h=2 "0: Not Match; 1: Match at the 1st position; 2: Match at the 2nd position...";
label caseID='CASEID' Code='STATE NAME' STATE='STATE ID' EXPANDED_CASEID='EXPANDED CASEID' state_match='DOES STATE NAME MATCH EXPANDED CASEID?' caseID_match='DOES CASEID MATCH EXPANDED CASEID?';
run;

/*Max Length of Expanded Case ID*/
data spinoff_vw_state_cf2;
	set spinoff_vw_state_cf;
	ExpnID_length=length(compress(expanded_caseID));
run;

/*use proc sql instead of proc sort and proc freq*/
proc sql;
title1 justify=l"Number of Case by the Length of the Expanded CaseID";
select ExpnID_length
,count(caseID) as num_caseID
from spinoff_vw_state_cf2
group by ExpnID_length;
quit;

%macro printEX(len=);
proc sql;
title1 justify=l"expnID_length=&len";
select *
from spinoff_vw_state_cf2(obs=10)
where expnID_length=&len;
quit;
%mend printEX;

%printEX(len=1);
%printEX(len=6);
%printEX(len=7);
%printEX(len=8);
%printEX(len=9);
%printEX(len=10);
%printEX(len=11);
%printEX(len=12);
%printEX(len=14);
%printEX(len=15);
%printEX(len=16);
%printEX(len=25);
%printEX(len=26);
%printEX(len=27);
%printEX(len=28);
%printEX(len=29);

/*use proc sql instead of proc sort and proc freq*/
proc sql;
title1 justify=l"Table 8a Summary: Number of Case by the Length of the Expanded CaseID and States";
select ExpnID_length
,code as State_name
,count(caseID) as Num_caseID
from spinoff_vw_state_cf2
where state_match =0
group by ExpnID_length,code;
quit;

/*use proc sql instead of proc sort and proc freq*/
proc sql;
title1 justify=l"Table 8b Summary: Number of Case by the Length of the Expanded CaseID and States";
select ExpnID_length
,code as State_name
,count(caseID) as Num_caseID
from spinoff_vw_state_cf2
where caseID_match =0
group by ExpnID_length,code;
quit;

/*use proc sql instead of proc sort and proc freq*/
proc sql;
title1 justify=l"Table 8c Summary: Number of Case by the Length of the Expanded CaseID and States";
select ExpnID_length
,code as State_name
,count(caseID) as Num_caseID
from spinoff_vw_state_cf2
where (state_match =0 and caseID_match =0)
group by ExpnID_length,code;
quit;

ods excel close;

/* Duplicate Report - this is a seperate spreadsheet */
ods excel file=duprpt                              
   options (sheet_interval="bygroup" sheet_name="#ByVal1" start_at="1, 2" embedded_titles="YES");

title1 color=black justify=left h=3.5 "Records Identified as Duplicates";
title2 color=black justify=left h=2 "1) Additional matches between local_record_id and expanded_caseid not captured by the Stage4 merge by key variables";
title3 color=black justify=left h=2 "2) Accomodating non-matching values for SITE";
title4 color=black justify=left h=2 "This subset is indicating duplicates by source_system.";
title5 color=black justify=left h=2 "CA Duplicates not included"; /*added by Xin on 07/13/2020*/
proc report data=duplicatereport;
   where report_jurisdiction not in ("06", "6"); /*added by Xin on 07/13/2020*/
   *where source_system_flag=1;
   by report_jurisdiction;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS. event EVENT. source_system SOURCE. dup_flag2 DUP. database DB. n_CDCDATE MMDDYY8. /*source_system_flag SSFLAG.*/;
   column database dup_flag2 report_jurisdiction event source_system local_record_id n_expandedcaseid n_CDCDATE result_status site wsystem case_status age_invest age_invest_units sex n_race illness_onset_dt 
          site_flag wsystem_flag case_status_flag birth_dt_flag age_invest_flag sex_flag n_race_flag illness_onset_dt_flag;
   define database / style=[width=1in textalign=left];
   define event / style=[width=1in textalign=left];
   define dup_flag / style=[width=1in textalign=left];
   define n_expandedcaseid / WIDTH=97;
run;

ods excel close;

/* PDF Report */

/* PDF: NNDSS Case Reports (All Case Status) */
ods pdf file=pdfrptA style=htmlblue;
   options nodate nonumber topmargin="0.5in";

title1 color=black h=3.5 "Reports of COVID-19 with Notification through NNDSS";
title2 color=black h=2 "All Case Statuses: Confirmed, Probable, Suspect, and Unknown";
proc report data=nnad_nodups_freq spanrows;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS.;
   label report_jurisdiction='Reporting Jurisdiction' case_status='Case Status';
   where case_status in ('410605003','2931005','415684004','UNK');
   columns report_jurisdiction case_status count;
       define report_jurisdiction / group style=[width=2in fontsize=1];
       define case_status / group style=[width=2in fontsize=1];
	   define count /  style=[width=2in fontsize=1];
          /* Calculate Total */
          rbreak after / summarize style=[fontweight=bold background=gainsboro];
          compute after;
             report_jurisdiction='Total';
          endcomp;
          /* Add header and footnotes */
          compute before _page_ / style=[fontweight=bold];
             line "&weekdate.";  
          endcomp;
          compute after _page_/ style=[just=left fontsize=1];
             line "Provisional data as of &weekdate. &time..";
          endcomp;
run;

ods pdf close;

/* PDF: NNDSS Case Reports (Confirmed and Probable) */
ods pdf file=pdfrptCP style=htmlblue;
   options nodate nonumber topmargin="0.5in";

title1 color=black h=3.5 "Reports of COVID-19 with Notification through NNDSS";
title2 color=black h=2 "Confirmed and Probable Case Status";
proc report data=nnad_nodups_freq spanrows;
   format report_jurisdiction $FIPSPROV. case_status $CASE_STATUS.;
   label report_jurisdiction='Reporting Jurisdiction' case_status='Case Status';
   where case_status in ('410605003','2931005');
   columns report_jurisdiction case_status count;
      define report_jurisdiction / group style=[width=2in fontsize=1];
      define case_status / group style=[width=2in fontsize=1];
      define count /  style=[width=2in fontsize=1];
	     /* Calculate Total */
         rbreak after / summarize style=[fontweight=bold background=gainsboro];
         compute after;
            report_jurisdiction='Total';
         endcomp;
		 /* Add header and footnotes */
	     compute before _page_/ style=[fontweight=bold];
            line "&weekdate.";
         endcomp;
         compute after _page_/ style=[just=left fontsize=1];
            line "Provisional data as of &weekdate. &time..";
         endcomp;
run;

ods pdf close;


/* saving dataset to folder using formats */

data datasets.dup_flag2_&loaddate(keep = _database dup_flag2 _report_jurisdiction _event _source_system 
                                         local_record_id n_expandedcaseid site _case_status wsystem 
                                         _n_CDCDATE _electr_submitted_dt result_status _birth_dt wsystem_flag
                                  rename = (_report_jurisdiction = report_jurisdiction
                                            _case_status = case_status
                                            _event = event
                                            _source_system = source_system
                                            _database = database
                                            _birth_dt = birth_dt
                                            _n_CDCDATE = n_CDCDATE
                                            _electr_submitted_dt = electr_submitted_dtg
                                            )
                                  );
	length  _database _report_jurisdiction _event _source_system _case_status _birth_dt _n_CDCDATE _electr_submitted_dt $50;          
	retain _database dup_flag2 _report_jurisdiction _event _source_system local_record_id n_expandedcaseid 
          site _case_status wsystem _n_CDCDATE _electr_submitted_dt result_status _birth_dt wsystem_flag;
          
set dup_flag2;
where wsystem_flag=1;   
   _report_jurisdiction = put(report_jurisdiction,$FIPSPROV.);
   _case_status=put(case_status,$CASE_STATUS.);
   _event =put(event,EVENT.);
   _source_system=put(source_system,SOURCE.);
   _database =put(database,DB.);
   _birth_dt=put(birth_dt,MMDDYY8.);
   _n_CDCDATE=put(n_CDCDATE,MMDDYY8.);
   _electr_submitted_dt=put(electr_submitted_dt,MMDDYY8.);   
run;

%put &prior;

/* delete dataset from 15 days prior */
%let prior_15 = %sysfunc(intnx(day,%sysfunc(today()),-15), mmddyyn6.); /* prior 15 days */
%put &prior_15;

proc datasets library=datasets nolist;
	delete dup_flag2_&prior_15;
	delete NETSSduplicate_pairs_&prior_15;
quit;

libname _all_ clear;
