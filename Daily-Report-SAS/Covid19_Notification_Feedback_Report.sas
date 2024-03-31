/**********************************************************************************************************/
/* Description: Summarizes 11065 records in NNAD Stage4 Production and CSP NETSS.                         */
/**********************************************************************************************************/
/*** SAS grid connect setup section                                        ***/
%put SAS HOST %sysfunc(grdsvc_getname('')); /* name of the host handling the job */

%let rc=%sysfunc(grdsvc_enable(_all_, resource=SASApp)); 
*options sascmd="sas" autosignon;
options autosignon;
libname shared "%sysfunc(pathname(work))";  
/*****End SAS grid connect setup section ************************************/

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

options mprint mlogic symbolgen compress=yes
        sasautos = (sasautos,
                    "&rootdir\Source\Macros"
                    );

%DBserverByEnv(AppName=NNAD, Environment=&environment);  

/* Assign location of output */
%let output=&rootdir\QC\Outputs\DailyReports\COVID-19\COVID-19 Completeness Rpt;

/* Pull in Data: NNAD Production Environment and CSP NETSS */
libname NNAD OLEDB
        provider="sqlncli11"
        properties = ( "data source"="&DBservName"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;
                       
libname current "\\cdc\csp_project\NCPHI_DISSS_NNDSS_NCIRD\Current" access=readonly;

/* Bring in saved formats */

libname qcfmt XLSX "&rootdir\Source\Formats\QCNNADFormats.xlsx" access=readonly;

/* specify list of formats to be read from excel format file */
/* birthctr res_country is combined to bir_resctr as values are same, source is changed to repo_source as source already exists */
%ExlFmt(libn = qcfmt, SheetN= ethnicity case_status dis_aq bir_resctr repo_source 
									 	pre misy res_state sex race_gen nrace_net trans preg 
										outbreak race_us_var_name datet fipsprov);

/* release the excel file pointer */
libname qcfmt clear;

%let time=%sysfunc(time(),time8.0);
%let weekdate=%sysfunc(date(),weekdate29.);

options fullstimer compress=yes; /*This will allow us to troubleshoot which steps are taking a long time in the code*/

data AllUS;
      set NNAD.stage4_11065_vw;

	format birthctr $bir_resctr. mmwryear pre. mmwrweek pre. report_county pre. report_county_Gen pre. 
			 report_county_net pre. dob pre. age pre. agetype pre. sex_1 $sex. race_us_var_name race_us_var_name. 
			 race_gen $race_gen. nrace_net nrace_net. ethnicity $ethnicity. res_country $bir_resctr. 
			 res_state $res_state. res_county $res_state. zip $res_state. onset pre. dx_dt pre. end_dt pre. 
			 death_dt pre. illdur pre. preg preg. n_datet $datet. hosp preg. admit_date pre. dis_dt pre. 
			 hosp_dur pre.  die preg. importctr $res_state. import_country $res_state. importstate $res_state. 
			 importcounty $res_state. importcity $res_state. expcountry pre. expstateprov pre. expcounty pre. 
			 expcity pre. case_status $case_status. dis_aq $dis_aq. /*result_status $res_stat.*/
			 trans trans. outbreak $outbreak. outbreakname $res_state. invest_dt pre. phd_dt pre. county_dt pre. 
			 state_dt pre. phd_rpt pre. rpt_state pre. source $repo_source. comments pre. ;

	where case_status in ("410605003", "2931005");

   label case_status = "Case Status (Case Class Status Code (77990-0) in GenV2; CASE STATUS in NETSS) (case_status)";

   if (compress(birth_country) ="USA") then 
      birthctr='1';
   else 
      if (compress(birth_country) not in (".","", "UNK", "Unk", "unk", "UNKOWN", "Unknown", "unknown")) then 
         birthctr='2';
      else 
         if (compress(birth_country) in ("UNK")) then 
            birthctr='3';
         else 
            if (compress(birth_country) in ("", ".")) then 
               birthctr='4';
   label birthctr="Country of Birth (Country of Birth (78746-5); GenV2 only) (birth_country)";

   if (compress(mmwr_year) in ("", ".")) then 
      mmwryear =2;
   else 
      mmwryear=1;
   label mmwryear="MMWR Year (MMWR Year (77992-6) in GenV2; YEAR in NETSS) (mmwr_year)";

   if (compress(mmwr_week) in ("", ".")) then 
      mmwrweek =2;
   else
   mmwrweek=1;
   label mmwrweek="MMWR Week (MMWR Week (77991-8) in GenV2; WEEK in NETSS) (mmwr_week)";

   /*county for All US*/
   if (compress(reporting_county) not in (".", "") or compress(n_county) not in (".", "")) then 
      report_county=1;
   else 
      report_county=2;
   label report_county="Reporting County (Reporting County (77967-8) in GenV2; COUNTY in NETSS) (reporting_county; n_county)";

   /*county for Genv2*/
   if (compress(reporting_county) not in (".", "")) then 
      report_county_Gen=1;
   else 
      report_county_Gen=2;
   label report_county_Gen="Reporting County (Reporting County (77967-8) in GenV2) (reporting_county)";

   /*county for NETSS*/
   if (compress(n_county) not in (".", "")) then 
      report_county_net=1;
   else 
      report_county_net=2;
   label report_county_net="Reporting County (COUNTY) (n_county)";

   if (birth_dt = .) then 
      dob = 2;
   else 
      dob=1;
   label dob = "Date of Birth (Birth Date (PID-7) in GenV2; BIRTHDATE in NETSS) (birth_dt)" ;

   if (compress(age_invest) in ("", ".")) then 
      age = 2;
   else 
      age=1;
   label age = "Age at Case Investigation (Age at Case Investigation (77998-3) in GenV2; AGE in NETSS) (age_invest)" ;

   if (compress(age_invest_units) in ("", ".")) then 
      agetype = 2;
   else 
      agetype=1;
   label agetype = "Age Units (Age Unit at Case Investigation (OBX-6 for 77998-3) in GenV2; AGETYPE in NETSS) (age_invest_units)" ;

   if (compress(sex)="F") then 
      sex_1='1';
   else 
      if (compress(sex)="M") then 
         sex_1='2';
      else 
         if (compress(sex)="U") then 
            sex_1='3';
         else /*if compress(sex) in ("", ".") then*/ 
            sex_1='4'; /*Value "X" and "." are inlcuded in missing*/
   label sex_1 = "Sex (Subjects Sex (PID-8) in GenV2; SEX in NETSS) (sex)";

   /*Race for All US*/
   if (ak_n_ai='Y') then 
      race1=1;
   else 
      race1=0;
   if (asian='Y') then 
      race2=1;
   else 
      race2=0;
   if (black='Y') then 
      race3=1;
   else 
      race3=0;
   if (hi_n_pi='Y') then 
      race4=1;
   else 
      race4=0;
   if (white='Y') then 
      race5=1;
   else 
      race5=0;
   if (race_oth='Y') then 
      race6=1;
   else 
      race6=0;
   if (race_unk='Y' or race_asked_but_unk='Y' or race_no_info='Y' or race_not_asked='Y' or race_refused='Y') then 
      race7=1; /*Unknown*/
   else 
      race7=0;

   race_sum=race1 + race2 + race3 + race4 + race5 + race6;

   if ((race1=1 and race_sum=1) or nrace_net=1) then 
      race_us_var_name=1;
   else 
   if (((race2=1 or race4=1) and race_sum=1) or nrace_net=2) then 
      race_us_var_name=2;
   else 
   if ((race3=1 and race_sum=1) or nrace_net=3) then 
      race_us_var_name=3;
   else 
   if ((race5=1 and race_sum=1) or nrace_net=5) then 
      race_us_var_name=4;
   else 
   if (race_sum>=2) then 
      race_us_var_name=5;
   else 
   if ((race6=1 and race_sum=1) or nrace_net=8) then 
      race_us_var_name=6;
   else 
   if ((race7=1 and race_sum=1) or nrace_net=9) then 
      race_us_var_name=7;
   else 
   if ((race_sum=0) or nrace_net=10) then 
      race_us_var_name=8;
   label race_us_var_name="Race (Race Category (PID-10) in GenV2; RACE in NETSS)";

   /*Race for GenV2*/
   if (race1=1 and race_sum=1) then 
      race_gen='1';
   else 
   if (race2=1 and race_sum=1) then 
      race_gen='2';
   else 
   if (race3=1 and race_sum=1) then 
      race_gen='3';
   else 
   if (race4=1 and race_sum=1) then 
      race_gen='4';
   else 
   if (race5=1 and race_sum=1) then 
      race_gen='5';
   else 
   if (race_sum>=2) then 
      race_gen='6';
   else 
   if (race6=1 and race_sum=1) then 
      race_gen='7';
   else 
   if (race7=1 and race_sum=1) then 
      race_gen='8';
   else 
   if (race_sum=0) then 
      race_gen='9';

   /*Labeled in following NETSS dataset*/
   /*Race for NETSS*/
   if (compress(n_race) in ("", ".")) then 
      nrace_net=99;
   else if (compress(n_race) ='#M') then
      nrace_net = .M;
   else 
      nrace_net=n_race;

   /*Labeled in following NETSS dataset*/
   if (ethnicity='2135-2') then 
      ethnicity= '1';
   else 
   if (ethnicity='2186-5') then 
      ethnicity= '2';
   else 
   if (ethnicity='OTH') then 
      ethnicity='3';
   else 
   if (ethnicity in ('UNK','Unk')) then 
      ethnicity = '4';
   else 
   if (ethnicity =' ') then 
      ethnicity='5';
   label ethnicity="Ethnicity (Ethnic Group (PID-22) in GenV2; ETHNICITY in NETSS) (ethnicity)";

   if (compress(res_country) = "USA") then 
      res_country='1';
   else 
   if (compress(res_country) not in ("", ".", "UNK", "Unk", "unk", "Unkown", "UNKOWN", "unknown")) then 
      res_country='2';
   else 
   if (compress(res_country) in ("UNK", "Unk", "Unkown", "UNKOWN", "Unknown", "unknown")) then 
      res_country='3';
   else 
   if (compress(res_country) in ("", ".")) then 
      res_country='4';
   label res_country ="Country of Usual Residence (Country of Usual Residence (77983-5); GenV2 only) (res_country)";

   if (compress(res_state) not in ("", ".", "UNK", "Unk", "unk", "UNKOWN", "Unkown", "unknown")) then 
      res_state='1';
   else 
   if (compress(res_state) in ("UNK", "Unk", "Unkown", "UNKOWN", "Unkown", "unknown")) then 
      res_state='2';
   else 
   if (compress(res_state) in ("", ".")) then 
      res_state='3';
   label res_state="State of Residence (Subject Address State (PID-11.4); GenV2 only) (res_state)";

   if (compress(res_county) not in ("", ".", "UNK", "Unk", "unk", "UNKOWN", "Unkown", "unknown")) then 
      res_county='1';
   else 
   if (compress(res_county) in ("UNK", "Unk", "Unkown", "UNKOWN", "Unkown", "unknown")) then 
      res_county='2';
   else 
   if (compress(res_county) in ("", ".")) then 
      res_county='3';
   label res_county="County of Residence (Subject Address County (PID-11.9); GenV2 only) (res_county)";

   if (compress(res_zip) not in ("", ".", "UNK", "Unk", "Unkown", "UNKOWN", "Unkown", "unkown")) then 
      zip='1';
   else 
   if (compress(res_zip) in ("UNK", "Unk", "Unkown", "UNKOWN", "Unkown", "unkown")) then 
      zip='2';
   else 
   if (compress(res_zip) in ("", ".")) then 
      zip='3';
   label zip="Zip Code (Subject Address ZIP Code (PID-11.5); GenV2 only) (res_zip)";

   if (illness_onset_dt ne .) then 
      onset=1;
   else 
      onset=2;
   label onset="Onset Date (Date of Illness Onset (11368-8) in GenV2; EVENTDATE if DATETYPE = 1 in NETSS) (illness_onset_dt)";

   if (dx_dt =.) then 
      dx_dt=2;
   else 
      dx_dt=1;
   label dx_dt="Diagnosis Date (Diagnosis Date (77975-1) in GenV2; EVENTDATE if DATETYPE = 2 in NETSS) (dx_dt)";

   if (illness_end_dt = .) then 
      end_dt=2; /*enddt didn't work out, need further research. Use illness_end_dt for now*/
   else 
      end_dt=1;
   label end_dt="Illness End Date (Illness End Date (77976-9); GenV2 only) (illness_end_dt)";

   if (death_dt =.) then 
      death_dt=2;
   else 
      death_dt=1;
   label death_dt="Deceased Date Among Died Patients (Deceased Date (PID-29); GenV2 only) (death_dt)";

   if (compress(illness_duration) in ("", ".")) then 
      illdur=2;
   else 
      illdur=1;
   label illdur="Illness Duration (Illness Duration (77977-7); GenV2 only) (illness_duration)";

   if (compress(pregnant) ="Y") then 
      preg =1;
   else 
   if (compress(pregnant)="N") then 
      preg=2;
   else 
   if (compress(pregnant) in ("unk", "Unk", "UNK", "KNOWN", "Known", "unknown")) then 
      preg=3;
   else 
   if (compress(pregnant) in (" ", ".")) then 
      preg=4;
   label preg="Pregnant Among Females (Pregnancy Status (77996-7) if Subjects Sex (PID-8) = Female (F); GenV2 only) (pregnant)";


   if (n_datet='') then 
      n_datet='99';
   label n_datet="Type of Date for earliest date associated with this incidence (NETSS only; DATETYPE and EVENTDATE in NETSS) (n_datet)";

   if (compress(hospitalized)="Y") then 
      hosp=1;
   else 
   if (compress(hospitalized)="N") then 
      hosp=2;
   else 
   if (compress(hospitalized)="UNK") then 
      hosp=3;
   else 
   if (compress(hospitalized) in ("", ".")) then 
      hosp=4;
   label hosp="Hospitalized (Hospitalized (77974-4); GenV2 only) (hospitalized)";

   if (compress(days_in_hosp) in ("", ".")) then 
      hosp_dur =2;
   else 
      hosp_dur=1;
   label hosp_dur="Hospital Duration Among Hospitalized (Duration of Hospital Stay in Days (78033-8); GenV2 only) (days_in_hosp)";

   if (admit_dt = .) then 
      admit_date=2;
   else 
      admit_date=1;
   label admit_date = "Admission Date Among Hospitalized (Admission Date (8656-1); GenV2 only) (admit_dt)";

   if (discharge_dt = .) then 
      dis_dt=2;
   else 
      dis_dt=1;
   label dis_dt="Discharge Date Among Hospitalized (Discharge Date (8649-6); GenV2 only) (discharge_dt)";

   if (died="Y") then 
      die=1;
   else 
      if (died="N") then 
         die=2;
         else 
            if (died="UNK") then 
               die=3;
               else 
                  if (died=" ") then die=4;
   label die="Died (Subject Died (77978-5); GenV2 only) (died)";

   if (disease_acquired='PHC244') then 
      dis_aq='1';
   else 
      if (disease_acquired='C1512888') then 
         dis_aq='2';
      else 
         if (disease_acquired='PHC245') then 
            dis_aq='3';
         else 
            if (disease_acquired='PHC246') then 
               dis_aq='4';
            else 
               if (disease_acquired='PHC1274') then 
                  dis_aq='5';
                  else 
                     if (disease_acquired='UNK') then 
                        dis_aq='6';
                        else 
                           if (disease_acquired=' ') then 
                              dis_aq='7';
   label dis_aq="Where the disease was likely acquired (Case Disease Imported Code (77982-7) in GenV2; IMPORTED in NETSS) (disease_acquired)";

   if (compress(import_country) not in ("", ".", "Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importctr='1';
   else 
   if (compress(import_country) in ("Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importctr='2';
   else 
   if (compress(import_country) in ("", ".")) then 
      importctr='3';
   label importctr="Import Country (Imported Country (INV153); GenV2 only) (import_country)";
   /*label import_country="Import Country (Imported Country (INV153); GenV2 only) (import_country)";*/

   if (compress(import_state) not in ("", ".", "Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importstate='1';
   else 
   if (compress(import_state) in ("Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importstate='2';
   else 
   if (compress(import_state) in ("", ".")) then importstate='3';
   label importstate="Import State (Imported State (INV154); GenV2 only) (import_state)";

   if (compress(import_county) not in ("", ".", "Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importcounty='1';
   else 
   if (compress(import_county) in ("Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importcounty='2';
   else 
   if (compress(import_county) in ("", ".")) then 
      importcounty='3';
   label importcounty="Import County (Imported County (INV156); GenV2 only) (import_county)";

   if (compress(import_city) not in ("", ".", "Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importcity='1';
   else 
   if (compress(import_city) in ("Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      importcity='2';
   else 
   if (compress(import_city) in ("", ".")) then 
      importcity='3';
   label importcity="Import City (Imported City (INV155); GenV2 only) (import_city)";

   if (compress(expcountry1) not in ("", ".") or compress(expcountry2) not in ("", ".") or 
       compress(expcountry3) not in ("", ".") or compress(expcountry4) not in ("", ".") or
       compress(expcountry5) not in ("", ".") or compress(expcountry_oth_txt) not in ("", ".")) then 
         expcountry=1;
   else 
         expcountry=2;
   label expcountry="Exposure Country (Country of Exposure (77984-3); GenV2 only) (expcountry1  expcountry5) ";

   if (compress(expstateprov1) not in ("", ".") or compress(expstateprov2) not in ("", ".") or 
       compress(expstateprov3) not in ("", ".") or compress(expstateprov4) not in ("",".") or 
       compress(expstateprov5) not in ("", ".") or compress(expstateprov_oth_txt) not in ("", ".")) then 
         expstateprov=1;
   else 
         expstateprov=2;
   label expstateprov="Exposure State/Province (State or Province of Exposure (77985-0); GenV2 only) (expstateprov1  expstateprov5)";

   if (compress(expcounty1) not in ("", ".") or compress(expcounty2) not in ("", ".") or 
       compress(expcounty3) not in ("", ".") or compress(expcounty4) not in ("", ".") or
       compress(expcounty5) not in ("", ".") or compress(expcounty_oth_txt) not in ("", ".")) then 
         expcounty=1;
   else 
         expcounty=2;
   label expcounty="Exposure County (County of Exposure (77987-6); GenV2 only) (expcounty1 - expcounty5)";

   if (compress(expcity1) not in ("", ".") or compress(expcity2) not in ("", ".") or 
       compress(expcity3) not in ("", ".") or compress(expcity4) not in ("", ".") or
       compress(expcity5) not in ("", ".") or compress(expcity_oth_txt) not in ("", ".")) then 
         expcity=1;
   else 
         expcity=2;
   label expcity="Exposure City (City of Exposure (77986-8); GenV2 only) (expcity1 - expcity5)";

   /*Label result_status = "Result Status";*/ /*Removed*/
   if (compress(transmission) = "416380006") then 
      trans=1;
   else 
   if (compress(transmission) = "418375005") then 
      trans=2;
   else 
   if (compress(transmission) not in ("OTH", "Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown", "", ".")) then 
      trans=3;
   else 
   if (compress(transmission) = "OTH") then 
      trans=4;
   else 
   if (compress(transmission) in ("Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      trans=5;
   else 
   if (compress(transmission) in ("", ".")) then 
      trans=6;
   label trans="Mode of Transmission (Transmission Mode (77989-2); GenV2 only) (transmission)";

   if (compress(outbreak_assoc) = 'Y') then 
      outbreak='1';
   else 
   if (compress(outbreak_assoc) ='N') then 
      outbreak='2';
   else 
   if (compress(outbreak_assoc) in ('UNK', 'unk', 'Unk', "Unkown", "UNKOWN", "unknown"))  then 
      outbreak='3';
   else 
   if (compress(outbreak_assoc) in ("", ".")) then 
      outbreak='4';
   label outbreak="Outbreak Associated (Case Outbreak Indicator (77980-1) in GenV2; OUTBREAK in NETSS) (outbreak_assoc)";

   if (compress(outbreak_name) in (" ", ".")) then 
      outbreakname='3';
   else 
   if (compress(outbreak_name) in ("Unk", "unk", "UNK", "Unkown", "UNKOWN", "unknown")) then 
      outbreakname='2';
   else 
      outbreakname='1';
   label outbreakname="Outbreak Name Among Outbreak Associated (Case Outbreak Name (77981-9); GenV2 only) (outbreak_name)";

   if (compress(reporting_source) = "39350007") then 
      source='1';
   else 
   if (compress(reporting_source)= "PHC247") then 
      source='2';
   else 
   if (compress(reporting_source)= "PHC252") then 
      source='3';
   else 
   if (compress(reporting_source) not in ("UNK", "OTH", " ",".")) then 
      source='4';
   else 
   if (compress(reporting_source)= "OTH") then 
      source='5';
   else 
   if (compress(reporting_source)= "UNK") then 
      source='6';
   else 
   if (compress(reporting_source) in (" ",".")) then 
      source='7';
   label source="Type of Facility/Provider Reporting (Reporting Source Type Code (48766-0); GenV2 only) (reporting_source)";

   if (compress(case_inv_start_dt)=.) then 
      invest_dt=2;
   else 
      invest_dt=1;
   label invest_dt="Case Investigation Start Date (77979-3); GenV2 only (case_inv_start_dt)";

   if (first_PHD_suspect_dt=.) then 
      phd_dt=2;
   else 
      phd_dt=1;
   label phd_dt="Date Reported to PHD (Date Reported (77995-9); GenV2 only) (first_PHD_suspect_dt)";

   if (first_report_county_dt =.) then 
      county_dt=2;
   else 
      county_dt=1;
   label county_dt="Earliest Date Reported to County (Earliest Date Reported to County (77972-8) in GenV2; EVENTDATE if DATETYPE = 4 in NETSS) (first_report_county_dt)";

   if (first_report_state_dt =.) then 
      state_dt=2;
   else 
      state_dt=1;
   label state_dt="Earliest Date Reported to State (Earliest Date Reported to State (77973-6) in GenV2; EVENTDATE if DATETYPE = 5 in NETSS) (first_report_state_dt)";

   if (first_report_PHD_dt=.) then 
      phd_rpt=2;
   else 
      phd_rpt=1;
   label phd_rpt="Date First Reported to PHD (Date First Reported to PHD (77970-2); GenV2 only) (first_report_PHD_dt)";

   if (compress(reporting_state) in ("", ".")) then 
      rpt_state=2;
   else 
      rpt_state=1;
   label rpt_state="Reporting State (Reporting State (77966-0); GenV2 only) (reporting_state)";

   if (compress(comment) in ("",".")) then 
      comments=2;
   else 
      comments=1;
   label comments = "Comments (Comment (77999-1); GenV2 only) (comment)";

run; 

/*subsetting GenV2 jurisdictions*/

data GenV2;
	set AllUS;
	where report_jurisdiction in ("01", "02", "04", "08", "09", "10", "12", "13", "16", "17", "18",
											"19", "20", "21", "23", "25", "26", "27", "28", "30", "34", "36",
											"37", "975772", "41", "42", "44", "45", "46", "47", "49", "51", "55");

   label case_status="Case Status (Case Class Status Code (77990-0)) (case_status)";
   label mmwryear="MMWR Year (MMWR Year (77992-6)) (mmwr_year)";
   label mmwrweek="MMWR Week (MMWR Week (77991-8)) (mmwr_week)";
   label rpt_state="Reporting State (Reporting State (77966-0)) (reporting_state)";
   label report_county_Gen="Reporting County (Reporting County (77967-8)) (reporting_county)";
   label birthctr="Country of Birth (Country of Birth (78746-5)) (birth_country)";
   label dob="Date of Birth (Birth Date (PID-7)) (birth_dt)";
   label age="Age at Case Investigation (Age at Case Investigation (77998-3)) (age_invest)";
   label agetype="Age Units (Age Units at Case Investigation (OBX-6 for 77998-3)) (age_invest_units)";
   label sex_1="Sex (Subjects Sex (PID-8)) (sex)";
   label race_gen="Race (Race Category (PID-10))";
   label ethnicity="Ethnicity (Ethnic Group (PID-22)) (ethnicity)";
   label res_country="Country of Usual Residence (Country of Usual Residence (77983-5)) (res_country)";
   label res_state="State of Residence (Subject Address State (PID-11.4)) (res_state)";
   label res_county="County of Residence (Subject Address County (PID-11.9)) (res_county)";
   label zip="Zip Code (Subject Address ZIP Code (PID-11.5)) (res_zip)";
   label onset="Onset Date (Date of Illness Onset (11368-8)) (illness_onset_dt)";

   label n_datet="Type of Date for earliest date associated with this incidence (DATETYPE and EVENTDATE) (n_datet)";

   label end_dt="Illness End Date (Illness End Date (77976-9)) (illness_end_dt)";
   label death_dt="Deceased Date Among Died Patients (Deceased Date (PID-29)) (death_dt)";
   label illdur="Illness Duration (Illness Duration (77977-7)) (illness_duration)";
   label dx_dt="Diagnosis Date (Diagnosis Date (77975-1)) (dx_dt)";
   label hosp="Hospitalized (Hospitalized (77974-4)) (hospitalized)";
   label hosp_dur="Hospital Duration Among Hospitalized (Duration of Hospital Stay in Days (78033-8)) (days_in_hosp)";
   label admit_date="Admission Date Among Hospitalized (Admission Date (8656-1)) (admit_dt)";
   label dis_dt="Discharge Date Among Hospitalized (Discharge Date (8649-6)) (discharge_dt)";
   label die="Died (Subject Died (77978-5)) (died)";
   label import_country="Import Country (Imported Country (INV153)) (import_country)";
   label importstate="Import State (Imported State (INV154)) (import_state)";
   label importcounty="Import County (Imported County (INV156)) (import_county)";
   label importcity="Import City (Imported City (INV155)) (import_city)";
   label expcountry="Exposure Country (Country of Exposure (77984-3)) (expcountry1  expcountry5)";
   label expstateprov="Exposure State/Province (State or Province of Exposure (77985-0)) (expstateprov1  expstateprov5)";
   label expcounty="Exposure County (County of Exposure (77987-6)) (expcounty1 - expcounty5)";
   label expcity="Exposure City (City of Exposure (77986-8)) (expcity1 - expcity5)";
   label dis_aq="Where the disease was likely acquired (Case Disease Imported Code (77982-7)) (disease_acquired)";
   label trans="Mode of Transmission (Transmission Mode (77989-2)) (transmission)";
   label outbreak="Outbreak Associated (Case Outbreak Indicator (77980-1)) (outbreak_assoc)";
   label outbreakname="Outbreak Name Among Outbreak Associated(Case Outbreak Name (77981-9)) (outbreak_name)";
   label invest_dt="Date Investigation Started (Case Investigation Start Date (77979-3)) (case_inv_start_dt)";
   label phd_dt="Date Reported to PHD (Date Reported (77995-9)) (first_PHD_suspect_dt)";
   label county_dt="Earliest Date Reported to County (Earliest Date Reported to County (77972-8)) (first_report_county_dt)";
   label state_dt="Earliest Date Reported to State (Earliest Date Reported to State (77973-6))(first_report_state_dt)";
   label phd_rpt="Date First Reported to PHD (Date First Reported to PHD (77970-2)) (first_report_PHD_dt)";
   label source="Type of Facility/Provider Reporting (Reporting Source Type Code (48766-0)) (reporting_source)";
   label preg="Pregnant Among Females (Pregnancy Status (77996-7) if Subjects Sex (PID-8) = Female (F)) (pregnant)";

run; 

/*Subsetting NETSS jurisdictions*/

data NETSS;
   /*format onset_netss onset_net.;*/
	set AllUS; 
	where report_jurisdiction in ("05", "06", "15", "22", "24", "29", "31", "32", "33", 
											"35", "38", "39", "40", "48", "50", "53", "54", "56", 
											"60", "11", "66", "69", "70", "72", "78", "64", "68");

   /*If illness_onset_dt ne . then onset_netss=1;
   else if illness_onset_dt=. and n_datet in ('2','3','4','5') then onset_netss=2;
   else if illness_onset_dt=. then onset_netss=3;
   Label onset_netss="Onset Date";*/

   label case_status="Case Status (CASE STATUS) (case_status)";
   label mmwryear="MMWR Year (YEAR) (mmwr_year)";
   label mmwrweek="MMWR Week (WEEK) (mmwr_week)";
   label report_county_net="Reporting County (COUNTY) (n_county)";
   label dob="Date of Birth (BIRTHDATE) (birth_dt )";
   label age="Age at Case Investigation (AGE) (age_invest)";
   label agetype="Age Units (AGETYPE) (age_invest_units)";
   label sex_1="Sex (SEX) (sex)";
   label nrace_net="Race (RACE) (n_race)";
   label ethnicity="Ethnicity (ETHNICITY) (ethnicity)";
   label n_datet="Type of Date for earliest date asociated with this incidence (DATETYPE and EVENTDATE) (n_datet)";
   /*label onset_netss="Onset Date (EVENTDATE ifDATETYPE = 1) (illness_onset_dt)";*/

   label dis_aq="Where the disease was likely acquired (IMPORTED) (disease_acquired)";
   label outbreak="Outbreak Associated (OUTBREAK) (outbreak_assoc)";

run;


/* Create Excel Output for NNAD Team Review */

/*Output 1*/
/*The most recent date each jurisdiction sent data to CDC*/

proc sql noprint;
   create table jurisdiction_lastsent as
   select report_jurisdiction label='Report Jurisdiction', datepart(max(coalesce(electr_submitted_dt,n_cdcdate))) 
												 as recent_date label='Most Recent Submission Dates' format=mmddyy10. 
   from NNAD.Stage4_NNDSScasesT1
   where condition in ('10575','11065')
   group by report_jurisdiction
   order by report_jurisdiction
   ;
quit;

options nodate;
ods _all_ close; 
ods listing;
ods word file="&output.\Most recent submission dates by jurisdiction as of &SYSDATE9..docx";
   proc print data=jurisdiction_lastsent noobs label;
   format report_jurisdiction $fipsprov.;
   label report_jurisdiction="Report Jurisdiction";
   label recent_date="Most Recent Submission Dates";
   title "Most Recent Submission Dates of COVID-19 Data by Jurisdiction as of &weekdate.";
   footnote "Most recent submission dates selected from variable electr_submitted_dt and n_cdcdate";
run;
ods word close;

/*Output 2*/
/*COVID-19 Data Qulity Reports for All US jurisdiction*/
ods _all_ close; 
ods listing;
ods noproctitle;
ods word file="&output.\All US Jurisdictions - NNDSS COVID-19 Case Notification Feedback Report as of &SYSDATE9..docx" startpage=no;

proc freq data=allus(keep = case_status mmwryear mmwrweek rpt_state report_county birthctr dob age
									 agetype sex_1 race_us_var_name ethnicity res_country res_state res_county
									 zip n_datet dx_dt county_dt state_dt onset end_dt illdur hosp die importctr
									 importstate importcounty importcity expcountry expstateprov expcounty 
									 expcity dis_aq trans outbreak invest_dt phd_dt phd_rpt source comments);
									 
   tables case_status mmwryear mmwrweek rpt_state report_county birthctr dob age agetype sex_1 race_us_var_name
          ethnicity res_country res_state res_county zip n_datet dx_dt county_dt state_dt onset end_dt illdur 
          hosp die importctr importstate importcounty importcity expcountry expstateprov expcounty expcity 
          dis_aq trans outbreak invest_dt phd_dt phd_rpt source comments/nocol missing;  
   title1 "All US Jurisdictions - NNDSS COVID-19 Case Notification Feedback Report";
   title2 "Confirmed and Probable Cases as of &weekdate.";
   footnote;
run;

proc freq data=allus(keep = hosp_dur admit_date dis_dt hosp);
   tables hosp_dur admit_date dis_dt/nocol missing;
   where hosp=1; /*subet to hospitalized patients*/
run;

proc freq data=allus(keep = death_dt die);
   tables death_dt/nocol missing;
   where die=1;
run;

proc freq data=allus(keep = outbreakname outbreak);
   tables outbreakname /nocol missing;
   where outbreak='1';
run;

proc freq data=allus(keep = preg sex_1); 
   tables preg/nocol missing;
   where sex_1="1";
run;

ods word close;

/*Output 3*/
/*COVID-19 Data Quality Reports for All GenV2 jurisdictions*/
ods _all_ close; 
ods listing;

ods noproctitle;
ods word file="&output.\GenV2 Jurisdictions  NNDSS COVID-19 Case Notification Feedback Report as of &SYSDATE9..docx" startpage=no;

proc freq data=GenV2(keep = case_status mmwryear mmwrweek rpt_state report_county_Gen birthctr dob
									 age agetype sex_1 race_gen ethnicity res_country res_state res_county
									 zip dx_dt county_dt state_dt onset end_dt illdur hosp die importctr 
									 importstate importcounty importcity expcountry expstateprov expcounty
									 expcity dis_aq trans outbreak invest_dt phd_dt phd_rpt source comments);

   tables case_status mmwryear mmwrweek rpt_state report_county_Gen birthctr dob age agetype sex_1 race_gen
          ethnicity res_country res_state res_county zip dx_dt county_dt state_dt onset end_dt illdur hosp
          die importctr importstate importcounty importcity expcountry expstateprov expcounty expcity dis_aq 
          trans outbreak invest_dt phd_dt phd_rpt source comments/nocol missing;
           
   title1 "GenV2 Jurisdictions  NNDSS COVID-19 Case Notification Feedback Report";
   title2 "Confirmed and Probable Cases as of &weekdate.";
run;

proc freq data=GenV2(keep = hosp_dur admit_date dis_dt hosp);
   tables hosp_dur admit_date dis_dt /nocol missing;
   where hosp=1; /*subset to hospitalized patients*/
run;

proc freq data=GenV2(keep = death_dt die);
   tables death_dt/nocol missing;
   where die=1;
run;

proc freq data=GenV2(keep = outbreakname outbreak);
   tables outbreakname/nocol missing;
   where outbreak='1';
run;

proc freq data=GenV2(keep = preg sex_1); 
   tables preg/nocol missing;
   where sex_1="1";
run;

ods word close;

/*Output 4*/
/*COVID-19 Data Quality Reports for Each GenV2 jurisdiction*/

/* Gen_jur Begin */
   
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

   %Gen_Jur(01, Alabama);
	%Gen_Jur(04, Arizona);
	%Gen_Jur(08, Colorado);
   
endrsubmit; /*end task1;*/


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

	%Gen_Jur(09, Connecticut);
	%Gen_Jur(10, Delaware);
	%Gen_Jur(12, Florida);
   
endrsubmit; /*end task2;*/

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

	%Gen_Jur(13, Georgia);
	%Gen_Jur(17, Illinois);
	%Gen_Jur(19, Iowa);
   
endrsubmit; /*end task3;*/

signon task4;  
%syslput environment = %bquote(&environment) /remote=task4;  
%syslput rootdir = %bquote(&rootdir) /remote=task4;   
%syslput platform = %bquote(&platform) /remote=task4;                       
rsubmit task4 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=4; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Gen_Jur(21, Kentucky);
	%Gen_Jur(23, Maine);
	%Gen_Jur(25, Massachusetts);
   
endrsubmit; /*end task4;*/

signon task5;  
%syslput environment = %bquote(&environment) /remote=task5;  
%syslput rootdir = %bquote(&rootdir) /remote=task5;   
%syslput platform = %bquote(&platform) /remote=task5;                       
rsubmit task5 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=5; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Gen_Jur(26, Michigan);
	%Gen_Jur(27, Minnesota);
	%Gen_Jur(28, Mississippi);

endrsubmit; /*end task5;*/

signon task6;  
%syslput environment = %bquote(&environment) /remote=task6;  
%syslput rootdir = %bquote(&rootdir) /remote=task6;   
%syslput platform = %bquote(&platform) /remote=task6;                       
rsubmit task6 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=6; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Gen_Jur(30, Montana);
	%Gen_Jur(34, New Jersey);
	%Gen_Jur(36, New York);  
   
endrsubmit; /*end task6;*/

signon task7;  
%syslput environment = %bquote(&environment) /remote=task7;  
%syslput rootdir = %bquote(&rootdir) /remote=task7;   
%syslput platform = %bquote(&platform) /remote=task7;                       
rsubmit task7 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=7; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Gen_Jur(41, Oregon);
	%Gen_Jur(42, Pennsylvania);
	%Gen_Jur(44, Rhode Island);

endrsubmit; /*end task7;*/

signon task8;  
%syslput environment = %bquote(&environment) /remote=task8;  
%syslput rootdir = %bquote(&rootdir) /remote=task8;   
%syslput platform = %bquote(&platform) /remote=task8;                       
rsubmit task8 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=8; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Gen_Jur(45, South Carolina);
	%Gen_Jur(46, South Dakota);
	%Gen_Jur(47, Tennessee);
   
endrsubmit; /*end task8;*/

signon task9;  
%syslput environment = %bquote(&environment) /remote=task9;  
%syslput rootdir = %bquote(&rootdir) /remote=task9;   
%syslput platform = %bquote(&platform) /remote=task9;                       
rsubmit task9 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=9; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Gen_Jur(51    , Virginia);
	%Gen_Jur(55    , Wisconsin);
	%Gen_Jur(975772, New York City);
   
endrsubmit; /*end task9;*/

waitfor _all_ task1 task2 task3 task4 task5 task6 task7 task8 task9;

signoff task1;
signoff task2;
signoff task3;
signoff task4;
signoff task5;
signoff task6;
signoff task7;
signoff task8;
signoff task9;


/*Output 5*/
/*Output NETSS report*/
ods _all_ close; 
ods listing;
ods noproctitle;
ods word file="&output.\NETSS&NBS Jurisdictions - NNDSS COVID-19 Case Notification Feedback Report as of &SYSDATE9..docx" startpage=no;

proc freq data=NETSS(keep = case_status mmwryear mmwrweek report_county_net dob age agetype sex_1
									 nrace_net ethnicity n_datet dis_aq outbreak);

   tables case_status mmwryear mmwrweek report_county_net dob age agetype sex_1 nrace_net ethnicity
          n_datet /*onset_netss*/ dis_aq outbreak/nocol missing out=out;
          
   title1 "NETSS/NBS Jurisdictions - NNDSS COVID-19 Case Notification Feedback Report";
   title2 "Confirmed and Probable Cases as of &weekdate.";
run;

ods word close;


/*Output 6*/
/*Create reports by jurisdiction*/

/* Net_jur Begin */

signon task11;   
%syslput environment = %bquote(&environment) /remote=task11;
%syslput rootdir = %bquote(&rootdir) /remote=task11;
%syslput platform = %bquote(&platform) /remote=task11;
                    
rsubmit task11 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=11; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */

	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(02, Alaska);
	%Net_jur(05, Arkansas);
	%Net_jur(06, California);
   
endrsubmit; /*end task11;*/


signon task12;   
%syslput environment = %bquote(&environment) /remote=task12;
%syslput rootdir = %bquote(&rootdir) /remote=task12;
%syslput platform = %bquote(&platform) /remote=task12;
                    
rsubmit task12 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=12; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */

	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(11, District of Columbia);
	%Net_jur(15, Hawaii);
	%Net_jur(18, Indiana);
   
endrsubmit; /*end task12;*/

signon task13;  
%syslput environment = %bquote(&environment) /remote=task13;  
%syslput rootdir = %bquote(&rootdir) /remote=task13;   
%syslput platform = %bquote(&platform) /remote=task13;                       
rsubmit task13 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=13; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(22, Louisiana);
	%Net_jur(24, Maryland);
	%Net_jur(29, Missouri);
   
endrsubmit; /*end task13;*/

signon task14;  
%syslput environment = %bquote(&environment) /remote=task14;  
%syslput rootdir = %bquote(&rootdir) /remote=task14;   
%syslput platform = %bquote(&platform) /remote=task14;                       
rsubmit task14 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=14; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(31, Nebraska);
	%Net_jur(32, Nevada);
	%Net_jur(33, New Hampshire);
   
endrsubmit; /*end task14;*/

signon task15;  
%syslput environment = %bquote(&environment) /remote=task15;  
%syslput rootdir = %bquote(&rootdir) /remote=task15;   
%syslput platform = %bquote(&platform) /remote=task15;                       
rsubmit task15 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=15; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(35, New Mexico);
	%Net_jur(37, North Carolina);
	%Net_jur(38, North Dakota);

endrsubmit; /*end task15;*/

signon task16;  
%syslput environment = %bquote(&environment) /remote=task16;  
%syslput rootdir = %bquote(&rootdir) /remote=task16;   
%syslput platform = %bquote(&platform) /remote=task16;                       
rsubmit task16 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=16; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(39, Ohio);
	%Net_jur(40, Oklahoma);
	%Net_jur(48, Texas);  
   
endrsubmit; /*end task16;*/

signon task17;  
%syslput environment = %bquote(&environment) /remote=task17;  
%syslput rootdir = %bquote(&rootdir) /remote=task17;   
%syslput platform = %bquote(&platform) /remote=task17;                       
rsubmit task17 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=17; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(50, Vermont);
	%Net_jur(53, Washington);
	%Net_jur(54, West Virginia);
   
endrsubmit; /*end task17;*/

signon task18;  
%syslput environment = %bquote(&environment) /remote=task18;  
%syslput rootdir = %bquote(&rootdir) /remote=task18;   
%syslput platform = %bquote(&platform) /remote=task18;                       
rsubmit task18 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=18; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(56, Wyoming);
	%Net_jur(60, American Samoa);
	%Net_jur(64, Federated States of Micronesia);
   
endrsubmit; /*end task18;*/

signon task19;  
%syslput environment = %bquote(&environment) /remote=task19;  
%syslput rootdir = %bquote(&rootdir) /remote=task19;   
%syslput platform = %bquote(&platform) /remote=task19;                       
rsubmit task19 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=19; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(66, Guam); 
	%Net_jur(68, Republic of Marshall Islands );
	%Net_jur(69, Northern Marianas Islands);;
   
endrsubmit; /*end task19;*/

signon task20;  
%syslput environment = %bquote(&environment) /remote=task20;  
%syslput rootdir = %bquote(&rootdir) /remote=task20;   
%syslput platform = %bquote(&platform) /remote=task20;                       
rsubmit task20 wait=no inheritlib=(shared);

   %global environment platform rootdir SQLoad fmtdir DBservName;
   %let tasknumber=20; /* used to control the filename in the included header */
   %include "&rootdir\QC\source\Covid19_Feedback_header.sas"; /* include the configuration info */
	
	options threads mprint mlogic symbolgen noxwait xsync compress=yes
        sasautos = (sasautos,
                    "&rootdir\QC\Source\Macros"
                    );

	%Net_jur(70, Palau); 
	%Net_jur(72, Puerto Rico); 
	%Net_jur(78, Virgin Islands);
   
endrsubmit; /*end task20;*/
waitfor _all_ task11 task12 task13 task14 task15 task16 task17 task18 task19 task20;

signoff task11;
signoff task12;
signoff task13;
signoff task14;
signoff task15;
signoff task16;
signoff task17;
signoff task18;
signoff task19;
signoff task20;

