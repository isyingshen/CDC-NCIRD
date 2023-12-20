/*************************************************************************************************/
/* Description: Frequency reports.  Part of                                                      */
/*              Covid19_CovidMMG_Notification_Feedback_Report                                    */
/*                                                                                               */
/* Created by:  Sang Kang	   06/30/2021                                                         */
/* Modified by: Anu Bhatta    07/08/2021                                                         */
/* 				 Anu Bhatta 	10/21/2021 - Limited vax_detail report and saved dataset to folder */
/*													  - deleted prior 15 days dataset							    */
/*************************************************************************************************/
%macro Gen_jur_CovidMMG(juris, report_jurisdiction);

data AllUS;
   set NNAD.stage4_11065_vw (where = (report_jurisdiction in ("&juris") and 
                                      case_status in ("410605003", "2931005")
                                      )
                             ); /* filter on the server */

   format birthctr $bir_resctr. mmwryear pre. mmwrweek pre. report_county pre. report_county_Gen pre. 
          report_county_net pre. dob pre. age pre. agetype pre. sex_1 $sex. race_us_var_name race_us_var_name. 
          race_gen $race_gen. race_net race_net. ethnicity $ethnicity. res_country $bir_resctr. 
          res_state $res_state. res_county $res_state. zip $res_state. onset pre. dx_dt pre. end_dt pre. 
          death_dt pre. illdur pre. preg preg. n_datet $datet. hosp preg. admit_date pre. dis_dt pre. 
          hosp_dur pre.  die preg. importctr $res_state. import_country $res_state. importstate $res_state. 
          importcounty $res_state. importcity $res_state. expcountry pre. expstateprov pre. expcounty pre. 
          expcity pre. case_status $case_status. dis_aq $dis_aq. /*result_status $res_stat.*/
          trans trans. outbreak $outbreak. outbreakname $res_state. invest_dt pre. phd_dt pre. county_dt pre. 
          state_dt pre. phd_rpt pre. rpt_state pre. source $repo_source. comments pre. ;


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
   label sex_1 = "Sex (Subject’s Sex (PID-8) in GenV2; SEX in NETSS) (sex)";

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

   if ((race1=1 and race_sum=1) or race_net=1) then 
      race_us_var_name=1;
   else 
   if (((race2=1 or race4=1) and race_sum=1) or race_net=2) then 
      race_us_var_name=2;
   else 
   if ((race3=1 and race_sum=1) or race_net=3) then 
      race_us_var_name=3;
   else 
   if ((race5=1 and race_sum=1) or race_net=5) then 
      race_us_var_name=4;
   else 
   if (race_sum>=2) then 
      race_us_var_name=5;
   else 
   if ((race6=1 and race_sum=1) or race_net=8) then 
      race_us_var_name=6;
   else 
   if ((race7=1 and race_sum=1) or race_net=9) then 
      race_us_var_name=7;
   else 
   if ((race_sum=0) or race_net=10) then 
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
      race_net=99;
   else if (compress(n_race) ='#M') then
      race_net = .M;
   else 
      race_net=n_race;

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
   label preg="Pregnant Among Females (Pregnancy Status (77996-7) if Subject’s Sex (PID-8) = Female (F); GenV2 only) (pregnant)";


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
   label admit_date = "Admission Date Among Hospitalized (Admission Date (8656-1); GenV2 only) (admit_dt) (among hospitalized cases)";

   if (discharge_dt = .) then 
      dis_dt=2;
   else 
      dis_dt=1;
   label dis_dt="Discharge Date Among Hospitalized (Discharge Date (8649-6); GenV2 only) (discharge_dt) (among hospitalized cases)";

   if (died="Y") then 
      die=1;
   else 
      if (died="N") then 
         die=2;
      else 
         if (died="UNK") then 
            die=3;
         else 
            if (died=" ") then
               die=4;
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
   label importctr="Imported Country (PHINQUESTION:INV153) (import_country)";
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
   label expcountry="Exposure Country (Country of Exposure (77984-3); GenV2 only) (expcountry1 – expcountry5) ";

   if (compress(expstateprov1) not in ("", ".") or compress(expstateprov2) not in ("", ".") or 
       compress(expstateprov3) not in ("", ".") or compress(expstateprov4) not in ("",".") or 
       compress(expstateprov5) not in ("", ".") or compress(expstateprov_oth_txt) not in ("", ".")) then 
         expstateprov=1;
   else 
         expstateprov=2;
   label expstateprov="Exposure State/Province (State or Province of Exposure (77985-0); GenV2 only) (expstateprov1 – expstateprov5)";

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

   label case_status="Case Class Status Code (LN:77990-0) (case_status)";
   label mmwryear="MMWR Year (LN:77992-6) (mmwr_year)";
   label mmwrweek="MMWR Week (LN:77991-8) (mmwr_week)";
   label rpt_state="Reporting State (LN:77966-0) (reporting_state)";
   label report_county_Gen="Reporting County (LN:77967-8) (reporting_county)";
   label birthctr="Country of Birth (LN:78746-5) (birth_country)";
   label dob="Birth Date (PID-7) (birth_dt)";
   label age="Age at Case Investigation (LN:77998-3) (age_invest)";
   label agetype="Age Units at Case Investigation (OBX-6 for 77998-3) (age_invest_units)";
   label sex_1="Subject’s Sex (PID-8) (sex)";
   label race_gen="Race Category (PID-10) (race)";
   label ethnicity="Ethnic Group (PID-22) (ethnicity)";
   label res_country="Country of Usual Residence (LN:77983-5) (res_country)";
   label res_state="Subject Address State (PID-11.4) (res_state)";
   label res_county="Subject Address County (PID-11.9) (res_county)";
   label zip="Subject Address ZIP Code (PID-11.5) (res_zip)";
   label onset="Date of Illness Onset (LN:11368-8) (illness_onset_dt)";
   label end_dt="Illness End Date (LN:77976-9) (illness_end_dt)";
   label death_dt="Deceased Date (PID-29) (death_dt) (among cases who died)";
   label illdur="Illness Duration (LN:77977-7) (illness_duration)";
   label dx_dt="Diagnosis Date (LN:77975-1) (dx_dt)";
   label hosp="Hospitalized (LN:77974-4) (hospitalized)";
   label hosp_dur="Duration of Hospital Stay in Days (LN:78033-8) (days_in_hosp) (among hospitalized cases)";
   label admit_date="Admission Date (LN:8656-1) (admit_dt)";
   label dis_dt="Discharge Date (LN:8649-6) (discharge_dt)";
   label die="Subject Died (LN:77978-5) (died)";
   label import_country="Imported Country (PHINQUESTION:INV153) (import_country)";
   label importstate="Imported State (PHINQUESTION:INV154) (import_state)";
   label importcounty="Imported County (PHINQUESTION:INV156) (import_county)";
   label importcity="Imported City (LN:INV155) (import_city)";
   label expcountry="Country of Exposure (LN:77984-3) (expcountry1 – expcountry5)";
   label expstateprov="State or Province of Exposure (LN:77985-0) (expstateprov1 – expstateprov5)";
   label expcounty="County of Exposure (LN:77987-6) (expcounty1 - expcounty5)";
   label expcity="City of Exposure (LN:77986-8) (expcity1 - expcity5)";
   label dis_aq="Case Disease Imported Code (LN:77982-7) (disease_acquired)";
   label trans="Transmission Mode (LN:77989-2) (transmission)";
   label outbreak="Case Outbreak Indicator (LN:77980-1) (outbreak_assoc)";
   label outbreakname="Case Outbreak Name (LN:77981-9) (outbreak_name) (among outbreak-related cases)";
   label invest_dt="Case Investigation Start Date (LN:77979-3) (case_inv_start_dt)";
   label phd_dt="Date Reported (LN:77995-9) (first_PHD_suspect_dt)";
   label county_dt="Earliest Date Reported to County (LN:77972-8) (first_report_county_dt)";
   label state_dt="Earliest Date Reported to State (LN:77973-6) (first_report_state_dt)";
   label phd_rpt="Date First Reported to PHD (LN:77970-2) (first_report_PHD_dt)";
   label source="Reporting Source Type Code (LN:48766-0) (reporting_source)";
   label preg="Pregnancy Status (LN:77996-7) (pregnant) (among female)";
run; 


options orientation=landscape;
ods _all_ close; 
ods listing;
ods noproctitle;
ods word file="&output\&report_jurisdiction (GenV2 and COVID-19 MMG) - NCIRD NNDSS COVID-19 Case Notification Feedback Report as of &SYSDATE9..docx" ;
/*startpage=no*/

proc template;
   delete Base.Freq.OneWayList;
run; 

ods path reset;
ods path(prepend) work.templat(update);
ods path show;
ods path SASHELP.TMPLBASE(READ);

proc template;                                                           
   edit Base.Freq.OneWayList;                                                                                
      edit FVariable;                                                       
         just=varjust;
         style=rowheader;
         id;
         generic;
         header=" ";
      end;
   end;                                    
run;

proc freq data=GenV2(keep = case_status mmwryear mmwrweek rpt_state report_county_Gen birthctr dob
                            age agetype sex_1 race_gen ethnicity res_country res_state res_county
                            zip dx_dt county_dt state_dt onset end_dt report_jurisdiction);
   tables case_status mmwryear mmwrweek rpt_state report_county_Gen birthctr dob age agetype sex_1 race_gen
          ethnicity res_country res_state res_county zip dx_dt county_dt state_dt onset end_dt/nocol missing; 
   where report_jurisdiction="&juris";
   title1 "&report_jurisdiction (GenV2 and COVID-19 MMG) - NCIRD NNDSS COVID-19 Case Notification Feedback Report";
   title2 "Confirmed and Probable Cases as of &weekdate.";
   footnote1;
run;

proc freq data=GenV2(keep = illdur hosp report_jurisdiction);
   tables illdur hosp/nocol missing;
   where report_jurisdiction="&juris";
run;

proc freq data=GenV2(keep = hosp_dur admit_date dis_dt hosp report_jurisdiction);
   tables hosp_dur admit_date dis_dt /nocol missing;
   where hosp=1 and report_jurisdiction="&juris"; /*subet to hospitalized patients*/
run;

proc freq data=GenV2(keep = die report_jurisdiction);
   tables die/nocol missing;
   where report_jurisdiction="&juris";
run;

proc freq data=GenV2(keep = death_dt die report_jurisdiction);
   tables death_dt/nocol missing;
   where die=1 and report_jurisdiction="&juris";
run;

proc freq data=GenV2(keep = importctr importstate importcounty importcity expcountry expstateprov
                            expcounty expcity dis_aq trans outbreak report_jurisdiction);
                            
   tables importctr importstate importcounty importcity expcountry expstateprov expcounty expcity 
          dis_aq trans outbreak/nocol missing;
   where report_jurisdiction="&juris";
run;

proc freq data=GenV2(keep = outbreakname outbreak report_jurisdiction);
   tables outbreakname/nocol missing;
   where outbreak='1' and report_jurisdiction="&juris";
run;

proc freq data=GenV2(keep = invest_dt phd_dt phd_rpt source comments report_jurisdiction);
   tables invest_dt phd_rpt source comments/nocol missing;

   where report_jurisdiction="&juris";
run;

proc freq data=GenV2(keep = preg sex_1 report_jurisdiction); 
   tables preg/nocol missing;
   where sex_1="1" and report_jurisdiction="&juris";
run;


/*COVID REPORTS*/
/*Add filter of one Jurisdiction and only keep the variables needed for deduplication*/
proc sql;
create table initial_table as
   select local_record_id, trans_id ,source_system, report_jurisdiction, wsystem
          , site, mmwr_year, result_status, case_status, N_CDCDATE, n_expandedcaseid
   from NNAD.COVID19_NNDSScasesT1_vw
   where report_jurisdiction="&juris";
quit;


/*Use Macro to remove duplicates and none cases*/
/*source_stystem, result_status and case_status only appear in T1, so other tables will need to merge with T1 to get the cleaned data*/
%dedup_case(initial_table, t_vw_clean);

/*cdc_ncov2019_id*/ 
/*Get the variables needed*/
proc sql;
   create table cdc_ncov2019_id_0 as
   select local_record_id
   ,trans_id
   ,cdc_ncov2019_id
   from  NNAD.COVID19_NNDSScasesT7_vw 
   where report_jurisdiction="&juris"
   and trans_id in (select trans_id
                    from t_vw_clean
 where report_jurisdiction="&juris");
quit;

/*Prepare the table for proc freq*/
proc sql;
create table cdc_ncov2019_id as
   select cdc_ncov2019_id
   ,case 
      when cdc_ncov2019_id is null then "Missing"
      when cdc_ncov2019_id is not null then "Present"
   end as cdc_ncov2019_id_status
   from cdc_ncov2019_id_0;
quit;

proc sort data=cdc_ncov2019_id;
   by desending cdc_ncov2019_id_status;
run;

ods noproctitle;
proc freq data=cdc_ncov2019_id order=data;
   tables cdc_ncov2019_id_status/nocol missing;
   title3 " ";
   title4 " ";
   title5 "Completeness of CDC 2019-nCoV ID Included in NNDSS Case Notifications";
   footnote1;
   label cdc_ncov2019_id_status="CDC 2019-nCoV ID (LN: 94659-0) (cdc_ncov2019_id)";
run;

/*detection_method*/
/*Get the variables needed*/
proc sql;
   create table detection_method_0 as
   select local_record_id
         ,trans_id
         ,detection_method1
         ,detection_method2
         ,detection_method3
         ,detection_method4
         ,detection_method5
         ,detection_method_addtl_flag
         ,detection_method_oth_txt
   from  NNAD.COVID19_NNDSScasesT7_vw 
   where report_jurisdiction="&juris"
         and local_record_id in (select local_record_id
                                 from t_vw_clean where report_jurisdiction="&juris");
quit;


/*Detection report 1 starts*/
/*Get the 5 detection methods*/
proc sql;
   create table dm1 as 
   select local_record_id
         ,trans_id
         ,detection_method1 as detection_method
   from detection_method_0
   where  detection_method1 is not null;

   create table dm2 as 
   select local_record_id
         ,trans_id
         ,detection_method2 as detection_method
   from detection_method_0
   where detection_method2 is not null;

   create table dm3 as 
   select local_record_id
         ,trans_id
         ,detection_method3 as detection_method
   from detection_method_0
   where detection_method3 is not null;

   create table dm4 as 
   select local_record_id
         ,trans_id
         ,detection_method4 as detection_method
   from detection_method_0
   where detection_method4 is not null;

   create table dm5 as 
   select local_record_id
         ,trans_id
         ,detection_method5 as detection_method
   from detection_method_0
   where detection_method5 is not null;

   create table addt_flag as 
   select local_record_id
         ,trans_id
         ,detection_method_addtl_flag as detection_method
   from detection_method_0
   where detection_method_addtl_flag ="Y";
quit;

/*append 5 detection methods*/
proc append base=dm1 data=dm2;
run;
proc append base=dm1 data=dm3;
run;
proc append base=dm1 data=dm4;
run;
proc append base=dm1 data=dm5;
run;


proc sql;
   create table dm_rn as
   select local_record_id
   ,trans_id
   ,case
      when detection_method ='OTH' then "Other"
      when detection_method ='PHC2112' then "Laboratory_reported"
      when detection_method ='C0004398' then "Prenatal_testing"
      when detection_method ='C4084924' then "Clinical_evaluation"
      when detection_method ='PHC2262' then "Contact_tracing"
      when detection_method ='PHC2264' then "EpiX_notification_of_traveler"
      when detection_method ='PHC241' then "Provider_reported"
      when detection_method ='PHC243' then "Routine_physical_examination"
      when detection_method ='PHC2263' then "Routine_surveillance"
      when detection_method ='UNK' then "Unknown"
   end as detection_method 
   from dm1;
quit;

proc sort data=dm_rn;
   by detection_method;
run;

proc freq data=dm_rn order=data;
   title1 "&report_jurisdiction (GenV2 and COVID-19 MMG) - NCIRD NNDSS COVID-19 Case Notification Feedback Report";
   title2 "Confirmed and Probable Cases as of &weekdate.";
   title3 " ";
   title4 " ";
   title5 "Frequency of Detection Methods (DM) Among the First 5 Responses for Each Case";
   title6 height=2"Each Case May Have Multiple DMs";
   footnote1;
   label detection_method="Detection Method (PHINQUESTION: INV159) (detection_method1-5)";
   table detection_method;
run;

/*Detection report 1 ends*/
/*Detection report 2 starts*/
proc sql;
   create table dm_rn_report2 as
   select local_record_id
   ,trans_id
   ,case
      when detection_method1 ='OTH' then '1DM Selected - "Other"'
      when detection_method1 ='PHC2112' then '1DM Selected - "Laboratory_reported"'
      when detection_method1 ='C0004398' then '1DM Selected - "Prenatal_testing"'
      when detection_method1 ='C4084924' then '1DM Selected - "Clinical_evaluation"'
      when detection_method1 ='PHC2262' then '1DM Selected - "Contact_tracing"'
      when detection_method1 ='PHC2264' then '1DM Selected - "EpiX_notification_of_traveler"'
      when detection_method1 ='PHC241' then '1DM Selected - "Provider_reported"'
      when detection_method1 ='PHC243' then '1DM Selected - "Routine_physical_examination"'
      when detection_method1 ='PHC2263' then '1DM Selected - "Routine_surveillance"'
      when detection_method1 ='UNK' then '1DM Selected - "Unknown"'
      end as detection_method1
      ,case
      when detection_method2 ='OTH' then '1DM Selected - "Other"'
      when detection_method2 ='PHC2112' then '1DM Selected - "Laboratory_reported"'
      when detection_method2 ='C0004398' then '1DM Selected - "Prenatal_testing"'
      when detection_method2 ='C4084924' then '1DM Selected - "Clinical_evaluation"'
      when detection_method2 ='PHC2262' then '1DM Selected - "Contact_tracing"'
      when detection_method2 ='PHC2264' then '1DM Selected - "EpiX_notification_of_traveler"'
      when detection_method2 ='PHC241' then '1DM Selected - "Provider_reported"'
      when detection_method2 ='PHC243' then '1DM Selected - "Routine_physical_examination"'
      when detection_method2 ='PHC2263' then '1DM Selected - "Routine_surveillance"'
      when detection_method2 ='UNK' then '1DM Selected - "Unknown"'
   end as detection_method2
   ,case
      when detection_method_addtl_flag ='Y' then "Other"
   end as detection_method3
   ,case
      when detection_method4 ='OTH' then '1DM Selected - "Other"'
      when detection_method4 ='PHC2112' then '1DM Selected - "Laboratory_reported"'
      when detection_method4 ='C0004398' then '1DM Selected - "Prenatal_testing"'
      when detection_method4 ='C4084924' then '1DM Selected - "Clinical_evaluation"'
      when detection_method4 ='PHC2262' then '1DM Selected - "Contact_tracing"'
      when detection_method4 ='PHC2264' then '1DM Selected - "EpiX_notification_of_traveler"'
      when detection_method4 ='PHC241' then '1DM Selected - "Provider_reported"'
      when detection_method4 ='PHC243' then '1DM Selected - "Routine_physical_examination"'
      when detection_method4 ='PHC2263' then '1DM Selected - "Routine_surveillance"'
      when detection_method4 ='UNK' then '1DM Selected - "Unknown"'
      end as detection_method4
      ,case
      when detection_method5 ='OTH' then '1DM Selected - "Other"'
      when detection_method5 ='PHC2112' then '1DM Selected - "Laboratory_reported"'
      when detection_method5 ='C0004398' then '1DM Selected - "Prenatal_testing"'
      when detection_method5 ='C4084924' then '1DM Selected - "Clinical_evaluation"'
      when detection_method5 ='PHC2262' then '1DM Selected - "Contact_tracing"'
      when detection_method5 ='PHC2264' then '1DM Selected - "EpiX_notification_of_traveler"'
      when detection_method5 ='PHC241' then '1DM Selected - "Provider_reported"'
      when detection_method5 ='PHC243' then '1DM Selected - "Routine_physical_examination"'
      when detection_method5 ='PHC2263' then '1DM Selected - "Routine_surveillance"'
      when detection_method5 ='UNK' then '1DM Selected - "Unknown"'
   end as detection_method5
   ,case
      when detection_method_addtl_flag ='Y' then "Additional_Flag"
   end as detection_method_addtl_flag
   
   /* Get the number of dm*/
   ,case
      when (detection_method1 is null and detection_method2 is null and detection_method3 is null and detection_method4 is null and detection_method5 is null) then 9
      when (detection_method1 is not null and detection_method2 is null and detection_method3 is null and detection_method4 is null and detection_method5 is null) then 1
      when (detection_method1 is not null and detection_method2 is not null and detection_method3 is null and detection_method4 is null and detection_method5 is null) then 2
      when (detection_method1 is not null and detection_method2 is not null and detection_method3 is not null and detection_method4 is null and detection_method5 is null) then 3
      when (detection_method1 is not null and detection_method2 is not null and detection_method3 is not null and detection_method4 is not null and detection_method5 is null) then 4
      when (detection_method1 is not null and detection_method2 is not null and detection_method3 is not null and detection_method4 is not null and detection_method5 is not null and detection_method_addtl_flag is null) then 5
      when (detection_method1 is not null and detection_method2 is not null and detection_method3 is not null and detection_method4 is not null and detection_method5 is not null and detection_method_addtl_flag is not null) then 6
   end as num_dm
   from detection_method_0;


   create table dm_rn_report2_add as
   select *
   ,case
      when num_dm=1 then detection_method1
      when num_dm=2 then "2 Detection Methods"
      when num_dm=3 then "3 Detection Methods"
      when num_dm=4 then "4 Detection Methods"
      when num_dm=5 then "5 Detection Methods"
      when num_dm=6 then "6 or More Detection Methods"
      when num_dm=9 then "No Detection Methods Selected"
   end as detection_method
   from dm_rn_report2; 
quit;

proc sort data=dm_rn_report2_add;
   by detection_method;
run;

proc freq data=dm_rn_report2_add order=data;
title1 "&report_jurisdiction (GenV2 and COVID-19 MMG) - NCIRD NNDSS COVID-19 Case Notification Feedback Report";
title2 "Confirmed and Probable Cases as of &weekdate.";
title3 " ";
title4 " ";
title5 "COVID-19 Cases By Detection Methods (DM) Included in NNDSS Case Notifications";
footnote1;
   label detection_method="Detection Method (PHINQUESTION: INV159) (detection_method)";
   table detection_method;
run;
/*Detection report 2 Ends*/


/*COVID19_NNDSScasesT5_vw   hosp_icu  */
/*COVID19_NNDSScasesT7_vw  icu_admit_dt*/
/*COVID19_NNDSScasesT7_vw  icu_discharge_dt*/

/*Get the variables needed*/
proc sql;
   create table t7_icu as
   select local_record_id
      ,trans_id
      ,icu_admit_dt
      ,icu_discharge_dt
   from NNAD.COVID19_NNDSScasesT7_vw
   where report_jurisdiction="&juris";

   create table t5_icu as
   select local_record_id
      ,trans_id
      ,hosp_icu
   from NNAD.COVID19_NNDSScasesT5_vw
   where report_jurisdiction="&juris";

   create table hosp_icu_0 as
   select t5.local_record_id
      ,t5.trans_id
      ,t5.hosp_icu
      ,t7.icu_admit_dt
      ,t7.icu_discharge_dt
   from t5_icu as t5
   left join t7_icu as t7
   on (t5.local_record_id = t7.local_record_id and t5.trans_id=t7.trans_id)
   and t5.trans_id in (select trans_id
                       from t_vw_clean
 where report_jurisdiction="&juris");
quit;

proc sql;
   create table hosp_icu as 
   select local_record_id
   ,trans_id
   ,hosp_icu
   ,icu_admit_dt
   ,icu_discharge_dt
   ,case 
      when icu_admit_dt is null then "Missing"
      when icu_admit_dt is not null then "Present"
   end as icu_admit_dt_status
   ,case 
      when icu_discharge_dt is null then "Missing"
      when icu_discharge_dt is not null then "Present"
   end as icu_discharge_dt_status
   ,case 
      when hosp_icu ="Y" then 1
      when hosp_icu ="N" then 2
      when hosp_icu ="UNK" then 3
   else 4
   end as hosp_icu_sort
   from hosp_icu_0;
quit;

/*If we want to delete the template, use the following*/
proc template;
   delete base.freq.crosstabfreqs;
run; 

proc template;
define crosstabs Base.Freq.CrossTabFreqs / store=work.templat;

define header ControllingFor;
   dynamic StratNum StrataVariableNames StrataVariableLabels;
   text "Table" StratNum 10. ": " StrataVariableLabels / StratNum>0;
end;

define header TableOf;
   dynamic StratNum NoTitle;
   text "Table " StratNum 10. ": " _ROW_NAME_ " by " _COL_NAME_ /
   (NoTitle=0) and (StratNum>0);
   text "Table of " _ROW_NAME_ " by " _COL_NAME_ / NoTitle=0;
end; 
define ControllingFor;
   dynamic StratNum StrataVariableNames StrataVariableLabels;
   text "Controlling for" StrataVariableNames / StratNum>0;
end;
define header rowsheader;
/* text _row_label_ / _row_label_ ^= ' ';*/
/* text _row_name_;*/
   text _row_label_;
end; 

   define header colsheader;
/* text _col_label_ / _col_label_ ^= ' ';*/
   text _col_label_;
end; 
   cols_header=colsheader;
   rows_header=rowsheader;
   header ControllingFor; 

end;
run; 

proc sort data=hosp_icu;
   by hosp_icu_sort desending icu_admit_dt_status desending icu_discharge_dt_status;
run;
ods noproctitle;
proc freq data=hosp_icu order=data;
   title3 " ";
   title4 " ";
   title5 "Completeness of Hospital ICU, ICU Admission Date and ICU Discharge Date Included in NNDSS Case Notifications";
   title6 height=2"Hospital ICU (SCT: 309904001) (hosp_icu); ICU Admission Date (LN: 95367-9) (icu_admit_dt); ICU Discharge Date (LN: 95368-7) (icu_discharge_dt)";
	footnote1;
label icu_admit_dt_status='icu_admit_dt';
   label icu_discharge_dt_status='icu_discharge_dt';
   table hosp_icu*icu_admit_dt_status*icu_discharge_dt_status /nocol norow;
run;

/*tribal_affiliation starts*/
/*tribal_affiliation COVID19_NNDSScasesT7_vw*/

/*Get the variables needed*/
proc sql;
create table tribal_0 as
   select local_record_id
   ,trans_id
   ,tribal_affiliation
   ,tribal_name1
   ,tribal_name2
   ,tribal_name3
   ,tribal_name4
   ,tribalname_addtl_flag
   ,tribal_name_oth_txt
   from  NNAD.COVID19_NNDSScasesT7_vw 
   where report_jurisdiction="&juris"
         and trans_id in (select trans_id
                          from t_vw_clean
 where report_jurisdiction="&juris");
quit;

proc sql;
   create table tribal as
   select local_record_id
   ,trans_id
   ,case
      when tribal_affiliation ='Y' then 'Yes'
      when tribal_affiliation ='N' then 'No'
      when tribal_affiliation ='UNK' then 'Unknown'
      when tribal_affiliation is null then 'Missing'
   end as tribal_affiliation
   ,case 
      when (tribal_name1 is null and tribal_name2 is null and tribal_name3 is null and tribal_name4 is null) then "Missing"
      when (tribal_name1 ='UNK' or tribal_name2 ='UNK' or tribal_name3 ='UNK' or tribal_name4 ='UNK') then "Present-Unknown"
   else "Present-Known"
   end as tribal_name
   ,case
      when tribal_affiliation is null then 'Missing'
   else tribal_affiliation
   end as tribal_affiliation
   from tribal_0;

   create table tribal2 as
   select *
   ,case
      when tribal_affiliation ='Yes' then 1
      when tribal_affiliation ='No' then 2
      when tribal_affiliation ='Unknown' then 3
      when tribal_affiliation ='Missing' then 4
   end as tribal_sort
   ,case
      when tribal_name ='Present-Known' then 1
      when tribal_name ='Present-Unknown' then 2
      when tribal_name ='Missing' then 3
   end as tribal_sort2
   from tribal;
quit;


/*If we want to delete the template, use the following*/
proc template;
   delete base.freq.crosstabfreqs;
run; 
proc template;
   define crosstabs Base.Freq.CrossTabFreqs / store=work.templat;

define header ControllingFor;
   dynamic StratNum StrataVariableNames StrataVariableLabels;
   text "Table" StratNum 10. ": " StrataVariableLabels / StratNum>0;
end;

define header TableOf;
   text "Table: Tribal Affiliation (LN: 95369-5) (tribal_affiliation) by Tribal Name (LN: 95370-3) (tribal_name)" ;
end; 
define ControllingFor;
   dynamic StratNum StrataVariableNames StrataVariableLabels;
   text "Controlling for" StrataVariableNames / StratNum>0;
end;
define header rowsheader;
/* text _row_label_ / _row_label_ ^= ' ';*/
/* text _row_name_;*/
   text _row_label_;
end; 

   define header colsheader;
/* text _col_label_ / _col_label_ ^= ' ';*/
   text _col_label_;
end; 
   cols_header=colsheader;
   rows_header=rowsheader;
   header TableOf; 

end;
run;
proc sort data=tribal2;
   by tribal_sort tribal_sort2; 
run;

ods noproctitle;
proc freq data=tribal2 order=data;
title3 " ";
title4 " ";
title5 "COVID-19 Cases By Tribal Affiliation and Tribal Name Included in NNDSS Case Notifications";
footnote1;
label tribal_affiliation="tribal_affiliation"; 
label tribal_name="tribal_name";
   table tribal_affiliation*tribal_name/nocol norow missprint missing;
run;

/*tribal_affiliation ends*/

/*COVID19_NNDSScasesT4_vw  hcp_onset*/
/*Get the variables needed*/
proc sql;
   create table hcp_onset_0 as
   select local_record_id
   ,trans_id
   ,hcp_onset
   from  NNAD.COVID19_NNDSScasesT4_vw 
   where report_jurisdiction="&juris"
         and trans_id in (select trans_id
                          from t_vw_clean where report_jurisdiction="&juris");
quit;

/*Get data and have a new var hcp_onset_sort*/
proc sql;
   create table hcp_onset as
   select 
   case
      when hcp_onset ='Y' then 'Yes'
      when hcp_onset ='N' then 'No'
      when hcp_onset ='UNK' then 'Unknown'
      when hcp_onset is null then 'Missing'
   end as hcp_onset
   from hcp_onset_0;

   create table hcp_onset2 as
   select *
   ,case
      when hcp_onset ='Yes' then 1
      when hcp_onset ='No' then 2
      when hcp_onset ='Unknown' then 3
      when hcp_onset ='Missing' then 4
   end as hcp_onset_sort
   from hcp_onset;
quit;

/*Sort according to Y, N, UNK*/
proc sort data=hcp_onset2;
   by hcp_onset_sort;
run;

/*Output the freq table*/
proc freq data=hcp_onset2 order=data;
   title3 " ";
   title4 " ";
   title5 "COVID-19 Cases By Healthcare Worker Status Included in NNDSS Case Notifications";
   footnote1;
   table hcp_onset/missing;
   label hcp_onset='Case Patient a Healthcare Worker (SCT: 223366009) (hcp_onset)';
run;

/*Current Occupation OccupationTxt*/
/*Current Occupation Standardized   OccupationCd*/
/*Current Industry   IndustryTxt*/
/*Current Industry Standardized  IndustryCd*/
/*COVID19_NNDSScasesT2_vw  occupationcd1*/

/*Get the variables needed*/
proc sql;
   create table occupation_0 as
   select local_record_id
   ,trans_id
   ,occupationtxt_oth_txt
   ,occupationtxt1
   ,occupationtxt2
   from  NNAD.COVID19_NNDSScasesT2_vw 
   where report_jurisdiction="&juris"
         and trans_id in (select trans_id
                          from t_vw_clean where report_jurisdiction="&juris");
quit;

proc sql;
   create table occupation as
   select local_record_id
   ,trans_id
   ,occupationtxt_oth_txt
   ,occupationtxt1
   ,occupationtxt2
   ,case 
      when (occupationtxt1 is null and occupationtxt2 is null and occupationtxt_oth_txt is null) then "No Occupation Provided"
      when (occupationtxt1 is not null or occupationtxt2 is not null or occupationtxt_oth_txt is not null) then "One and More Occupations"
   end as Occupation_Status
   from occupation_0;
quit;

proc freq data=occupation;
   title3 " ";
   title4 " ";
   title5 "COVID-19 Cases By Current Occupation Included in NNDSS Case Notifications ";
   footnote1;
   label Occupation_Status="Current Occupation (LN:85658-3) (current_occ_txt)";
   table Occupation_Status/missing ;
run;


/*Get the variables needed*/
proc sql;
   create table exposure_0 as
   select t7.local_record_id
   ,t7.trans_id
   ,t7.child_care_facility
   ,t7.airport
   ,t7.infected_animal
   ,t7.congregate_living_facility
   ,t7.contact_with_case
   ,t7.domestic_travel
   ,t7.international_travel
   ,t7.mass_gathering
   ,t7.correctional_facility
   ,t7.cruise_ship
   ,t7.school
   ,t7.exp_unk
   ,t7.workplace
   ,t4.exp_oth_txt
   from  NNAD.COVID19_NNDSScasesT7_vw as t7
   left join NNAD.COVID19_NNDSScasesT4_vw as t4
   on (t7.local_record_id=t4.local_record_id and t7.trans_id=t4.trans_id)
   where t7.report_jurisdiction="&juris"
         and t4.report_jurisdiction="&juris"
         and t7.trans_id in (select trans_id
                             from t_vw_clean where report_jurisdiction="&juris");
quit;

proc sql;
   create table exposure_1 as
   select local_record_id
   ,trans_id
   /* Get the name of exposure instead of Y or N*/
   ,case 
   when child_care_facility="Y" then "Child_care_facility"
   end as child_care_facility
   ,case 
   when airport="Y" then "Airport"
   end as airport
   ,case 
   when infected_animal="Y" then "Infected_animal"
   end as infected_animal
   ,case 
   when congregate_living_facility="Y" then "Congregate_living_facility"
   end as congregate_living_facility
   ,case 
   when contact_with_case="Y" then "Contact_with_case"
   end as contact_with_case
   ,case 
   when domestic_travel="Y" then "Domestic_travel"
   end as domestic_travel
   ,case 
   when mass_gathering="Y" then "Mass_gathering"
   end as mass_gathering
   ,case 
   when correctional_facility="Y" then "Correctional_facility"
   end as correctional_facility
   ,case 
   when cruise_ship="Y" then "Cruise_ship"
   end as cruise_ship
   ,case 
   when school="Y" then "School"
   end as school
   ,case 
   when exp_unk="Y" then "Unknown"
   end as exp_unk
   ,case 
   when workplace="Y" then "Workplace"
   end as workplace
   ,case 
   when international_travel="Y" then "International_travel"
   end as international_travel
   ,exp_oth_txt

   /*Get the 1 or 0 of exposure instead of Y or N*/
   ,case 
   when child_care_facility ="Y" then 1
   else 0
   end as child_care_facility_n
   ,case 
   when airport ="Y" then 1
   else 0
   end as airport_n
   ,case 
   when infected_animal ="Y" then 1
   else 0
   end as infected_animal_n
   ,case 
   when congregate_living_facility ="Y" then 1
   else 0
   end as congregate_living_facility_n
   ,case 
   when contact_with_case ="Y" then 1
   else 0
   end as contact_with_case_n
   ,case 
   when domestic_travel ="Y" then 1
   else 0
   end as domestic_travel_n
   ,case 
   when international_travel ="Y" then 1
   else 0
   end as international_travel_n
   ,case 
   when mass_gathering ="Y" then 1
   else 0
   end as mass_gathering_n
   ,case 
   when correctional_facility ="Y" then 1
   else 0
   end as correctional_facility_n
   ,case 
   when cruise_ship ="Y" then 1
   else 0
   end as cruise_ship_n
   ,case 
   when school ="Y" then 1
   else 0
   end as school_n
   ,case 
   when workplace ="Y" then 1
   else 0
   end as workplace_n
   ,case 
   when exp_unk ="Y" then 1
   else 0
   end as exp_unk_n
   ,case 
   when exp_oth_txt is not null then 1
   else 0
   end as exp_oth_txt_n

   from exposure_0;
quit;

/*Exposure report1 starts*/

proc sql;
   /*child_care_facility*/
   create table child_care_facility as 
   select local_record_id
   ,trans_id
   ,child_care_facility as exposure
   from exposure_1
   where child_care_facility is not null;
   /* airport*/
   create table airport as 
   select local_record_id
   ,trans_id
   ,airport as exposure
   from exposure_1
   where airport is not null;

   /* infected_animal*/
   create table infected_animal as 
   select local_record_id
   ,trans_id
   ,infected_animal as exposure
   from exposure_1
   where infected_animal is not null;

   /* congregate_living_facility*/
   create table congregate_living_facility as 
   select local_record_id
   ,trans_id
   ,congregate_living_facility as exposure
   from exposure_1
   where congregate_living_facility is not null;

   /* contact_with_case*/
   create table contact_with_case as 
   select local_record_id
   ,trans_id
   ,contact_with_case as exposure
   from exposure_1
   where contact_with_case is not null;

   /* domestic_travel*/
   create table domestic_travel as 
   select local_record_id
   ,trans_id
   ,domestic_travel as exposure
   from exposure_1
   where domestic_travel is not null;

   /* international_travel*/
   create table international_travel as 
   select local_record_id
   ,trans_id
   ,international_travel as exposure
   from exposure_1
   where international_travel is not null;

   /* mass_gathering*/
   create table mass_gathering as 
   select local_record_id
   ,trans_id
   ,mass_gathering as exposure
   from exposure_1
   where mass_gathering is not null;

   /* correctional_facility*/
   create table correctional_facility as 
   select local_record_id
   ,trans_id
   ,correctional_facility as exposure
   from exposure_1
   where correctional_facility is not null;

   /* cruise_ship*/
   create table cruise_ship as 
   select local_record_id
   ,trans_id
   ,cruise_ship as exposure
   from exposure_1
   where cruise_ship is not null;

   /* school*/
   create table school as 
   select local_record_id
   ,trans_id
   ,school as exposure
   from exposure_1
   where school is not null;

   /* exp_unk*/
   create table exp_unk as 
   select local_record_id
   ,trans_id
   ,exp_unk as exposure
   from exposure_1
   where exp_unk is not null;

   /* workplace*/
   create table workplace as 
   select local_record_id
   ,trans_id
   ,workplace as exposure
   from exposure_1
   where child_care_facility is not null;
quit;

proc append base =congregate_living_facility data=airport force;
run;
proc append base =congregate_living_facility data=infected_animal force;
run;
proc append base =congregate_living_facility data=child_care_facility force;
run;
proc append base =congregate_living_facility data=contact_with_case force;
run;
proc append base =congregate_living_facility data=domestic_travel force;
run;
proc append base =congregate_living_facility data=international_travel force;
run;
proc append base =congregate_living_facility data=mass_gathering force;
run;
proc append base =congregate_living_facility data=correctional_facility force;
run;
proc append base =congregate_living_facility data=cruise_ship force;
run;
proc append base =congregate_living_facility data=school force;
run;
proc append base =congregate_living_facility data=exp_unk force;
run;
proc append base =congregate_living_facility data=workplace force;
run;

proc sort data=congregate_living_facility;
   by exposure;
run;

proc freq data=congregate_living_facility;
   title3 " ";
   title4 " ";
   title5 "Summary of Exposure Category Included in NNDSS Case Notifications";
   title6 height=2"Each Case May Have Multiple Exposure Categories Entered";
   footnote1;
   label exposure="Exposure (PHINQUESTION:INV1085) and Exposure Indicator (PHINQUESTION:INV1086)";
   table exposure;
run;
/*Exposure report1 ends*/


/*Exposure report2 starts*/
proc sql;
   create table exposure_2 as
   select local_record_id
   ,trans_id
   ,child_care_facility
   ,airport
   ,infected_animal
   ,congregate_living_facility
   ,contact_with_case
   ,domestic_travel
   ,international_travel
   ,mass_gathering
   ,correctional_facility
   ,cruise_ship
   ,school
   ,exp_unk
   ,workplace
   ,exp_oth_txt
   /* get the total number of exposure*/
   ,child_care_facility_n + airport_n + infected_animal_n + congregate_living_facility_n + contact_with_case_n + domestic_travel_n + 
   international_travel_n + mass_gathering_n + correctional_facility_n + cruise_ship_n + school_n + exp_unk_n +  
   workplace_n  as num_exposure
   from exposure_1;

      
   create table exposure_3 as
   select local_record_id
   ,trans_id
   ,num_exposure
   ,case
   when num_exposure =2 then "2 Exposures Selected"
   when num_exposure =3 then "3 Exposures Selected"
   when num_exposure =4 then "4 Exposures Selected"
   when num_exposure =5 then "5 Exposures Selected"
   when num_exposure >5 then "6 or More Exposures Selected"
   when (num_exposure =0 and exp_oth_txt is not null) then 'No Exposure Selected – Text Provided to Specify'
   when (num_exposure =0 and exp_oth_txt is null) then 'Missing'
   /* child_care_facility*/
   when (num_exposure=1 and child_care_facility is not null) then '1 Exposure Selected - "Child_care_facility"'
   /* airport*/
   when (num_exposure=1 and airport is not null) then '1 Exposure Selected - "Airport"'
   /* ,infected_animal*/
   when (num_exposure=1 and infected_animal is not null) then '1 Exposure Selected - "Infected_animal"'
   /* congregate_living_facility*/
   when (num_exposure=1 and congregate_living_facility is not null) then '1 Exposure Selected - "Congregate_living_facility"'
   /* contact_with_case*/
   when (num_exposure=1 and contact_with_case is not null) then '1 Exposure Selected - "Contact_with_case"'
   /* domestic_travel*/
   when (num_exposure=1 and domestic_travel is not null) then '1 Exposure Selected - "Domestic_travel"'
   /* international_travel*/
   when (num_exposure=1 and international_travel is not null) then '1 Exposure Selected - "International_travel"'
   /* mass_gathering*/
   when (num_exposure=1 and mass_gathering is not null) then '1 Exposure Selected - "Mass_gathering"'
   /* correctional_facility*/
   when (num_exposure=1 and correctional_facility is not null) then '1 Exposure Selected - "Correctional_facility"'
   /* cruise_ship*/
   when (num_exposure=1 and cruise_ship is not null) then '1 Exposure Selected - "Cruise_ship"'
   /* school*/
   when (num_exposure=1 and school is not null) then '1 Exposure Selected - "School"'
   /* exp_unk*/
   when (num_exposure=1 and exp_unk is not null) then '1 Exposure Selected - "Unknown"'
   /* workplace*/
   when (num_exposure=1 and workplace is not null) then '1 Exposure Selected - "Workplace"'
   end as exposure
   ,case 
   when (num_exposure =0 and exp_oth_txt is not null) then 98
   when (num_exposure =0 and exp_oth_txt is null) then 99
   else num_exposure
   end as num_exposure_sort
   from exposure_2;
quit;

proc sort data=exposure_3;
   by num_exposure_sort exposure;
run;

proc freq data=exposure_3 order=data;
   title3 " ";
   title4 " ";
   title5 "COVID-19 Cases By Exposure Category Included in NNDSS Case Notifications";
   footnote1;
   label exposure="Exposure (PHINQUESTION:INV1085) and Exposure Indicator (PHINQUESTION:INV1086)";
   table exposure;
run;
/*Exposure report2 ends*/


/*COVID19_NNDSScasesT2_vw  vaxtype10*/
/*Get the variables needed: vaxtype, vaxdose, voxmfr,,,,*/
proc sql;
   create table vax_0 as
   select local_record_id
   ,trans_id
   ,vaxtype1,vaxtype2,vaxtype3,vaxtype4,vaxtype5,vaxtype6,vaxtype7,vaxtype8,vaxtype9,vaxtype10,vaxtype_oth_txt
   ,vaxdose1 ,vaxdose2 ,vaxdose3,vaxdose4,vaxdose5,vaxdose6,vaxdose7,vaxdose8,vaxdose9,vaxdose10
   ,case 
      when vaxdose1 is null then "Missing"
      else vaxdose1
   end as vaxdose1_c
   ,case 
      when vaxdose2 is null then "Missing"
      else vaxdose2
   end as vaxdose2_c
   ,case 
      when vaxdose3 is null then "Missing"
      else vaxdose3
   end as vaxdose3_c
   
   ,vaxmfr1,vaxmfr2,vaxmfr3,vaxmfr4,vaxmfr5,vaxmfr6,vaxmfr7,vaxmfr8,vaxmfr9,vaxmfr10
   ,case 
      when vaxmfr1 is null then "Missing"
      else vaxmfr1
   end as vaxmfr1_c
   ,case 
      when vaxmfr2 is null then "Missing"
      else vaxmfr2
   end as vaxmfr2_c
   ,case 
      when vaxmfr3 is null then "Missing"
      else vaxmfr3
   end as vaxmfr3_c
   
   ,vaxdate1 as vaxdate1_ 
   ,vaxdate2 as vaxdate2_ 
   ,vaxdate3 as vaxdate3_ 
   ,case 
      when vaxdate1 is null then "Missing"
      else "Present"
   end as vaxdate1
   ,case 
      when vaxdate2 is null then "Missing"
      else "Present"
   end as vaxdate2
   ,case 
      when vaxdate3 is null then "Missing"
      else "Present"
   end as vaxdate3
   ,vaxlot1 as vaxlot1_
   ,vaxlot2 as vaxlot2_
   ,vaxlot3 as vaxlot3_
   ,case 
      when vaxlot1 is null then "Missing"
      else "Present"
   end as vaxlot1
   ,case 
      when vaxlot2 is null then "Missing"
      else "Present"
   end as vaxlot2
   ,case 
      when vaxlot3 is null then "Missing"
      else "Present"
   end as vaxlot3
   ,vaxexpdt1 as vaxexpdt1_
   ,vaxexpdt2 as vaxexpdt2_
   ,vaxexpdt3 as vaxexpdt3_
   ,case 
      when vaxexpdt1 is null then "Missing"
      else "Present"
   end as vaxexpdt1
   ,case 
      when vaxexpdt2 is null then "Missing"
      else "Present"
   end as vaxexpdt2
   ,case 
      when vaxexpdt3 is null then "Missing"
      else "Present"
   end as vaxexpdt3
   ,vaxndc1 as vaxndc1_
   ,vaxndc2 as vaxndc2_
   ,vaxndc3 as vaxndc3_
   ,case 
      when vaxndc1 is null then "Missing"
      else "Present"
   end as vaxndc1
   ,case 
      when vaxndc2 is null then "Missing"
      else "Present"
   end as vaxndc2
   ,case 
      when vaxndc3 is null then "Missing"
      else "Present"
   end as vaxndc3

   ,vaxrecid1 as vaxrecid1_
   ,vaxrecid2 as vaxrecid2_
   ,vaxrecid3 as vaxrecid3_
   ,case 
      when vaxrecid1 is null then "Missing"
      else "Present"
   end as vaxrecid1
   ,case 
      when vaxrecid2 is null then "Missing"
      else "Present"
   end as vaxrecid2
   ,case 
      when vaxrecid3 is null then "Missing"
      else "Present"
   end as vaxrecid3
   ,vaxinfosrce1 as vaxinfosrce1_
   ,vaxinfosrce2 as vaxinfosrce2_
   ,vaxinfosrce3 as vaxinfosrce3_
   ,case 
      when vaxinfosrce1 is null then "Missing"
      else "Present"
   end as vaxinfosrce1
   ,case 
      when vaxinfosrce2 is null then "Missing"
      else "Present"
   end as vaxinfosrce2
   ,case 
      when vaxinfosrce3 is null then "Missing"
      else "Present"
   end as vaxinfosrce3
   from  NNAD.COVID19_NNDSScasesT2_vw 
   where report_jurisdiction="&juris"
         and trans_id in (select trans_id
                          from t_vw_clean where report_jurisdiction="&juris");
quit;

/*Get the variables needed from table1*/
proc sql;
   create table t1_0 as
   select local_record_id
   ,trans_id
   ,mmwr_year, site, age_invest,illness_onset_dt
   ,case
   when age_invest_units="a" then "Year"
   when age_invest_units="d" then "Day"
   when age_invest_units="h" then "Hour"
   when age_invest_units="min" then "Minute"
   when age_invest_units="s" then "Second"
   when age_invest_units="mo" then "Month"
   when age_invest_units="wk" then "Week"
   else age_invest_units
   end as age_invest_units
    ,birth_dt,sex, ak_n_ai,asian,black, white,ethnicity,birth_country,n_race,result_status,case_status

   from  NNAD.COVID19_NNDSScasesT1_vw 
   where report_jurisdiction="&juris"
         and local_record_id in (select local_record_id
                                 from t_vw_clean where report_jurisdiction="&juris");
quit;

/*get the vaccine data*/
proc sql;
create table vax as
   select *
   ,case 
   when vaxtype1 is null then 0
   else 1
   end as vaxtype1n
   ,case 
   when vaxtype2 is null then 0
   else 1
   end as vaxtype2n
   ,case 
   when vaxtype3 is null then 0
   else 1
   end as vaxtype3n
   ,case 
   when vaxtype4 is null then 0
   else 1
   end as vaxtype4n
   ,case 
   when vaxtype5 is null then 0
   else 1
   end as vaxtype5n
   ,case 
   when vaxtype6 is null then 0
   else 1
   end as vaxtype6n
   ,case 
   when vaxtype7 is null then 0
   else 1
   end as vaxtype7n
   ,case 
   when vaxtype8 is null then 0
   else 1
   end as vaxtype8n
   ,case 
   when vaxtype9 is null then 0
   else 1
   end as vaxtype9n
   ,case 
   when vaxtype10 is null then 0
   else 1
   end as vaxtype10n
   ,case 
   when vaxtype_oth_txt is null then 0
   else 1
   end as vaxtype_oth_txtn
/* vax dose*/
   ,case 
   when vaxdose1 is null then 0
   else 1
   end as vaxdose1n
   ,case 
   when vaxdose2 is null then 0
   else 1
   end as vaxdose2n
   ,case 
   when vaxdose3 is null then 0
   else 1
   end as vaxdose3n
   ,case 
   when vaxdose4 is null then 0
   else 1
   end as vaxdose4n
   ,case 
   when vaxdose5 is null then 0
   else 1
   end as vaxdose5n
   ,case 
   when vaxdose6 is null then 0
   else 1
   end as vaxdose6n
   ,case 
   when vaxdose7 is null then 0
   else 1
   end as vaxdose7n
   ,case 
   when vaxdose8 is null then 0
   else 1
   end as vaxdose8n
   ,case 
   when vaxdose9 is null then 0
   else 1
   end as vaxdose9n
   ,case 
   when vaxdose10 is null then 0
   else 1
   end as vaxdose10n
   /* vax mfr*/
   ,case 
   when vaxmfr1 is null then 0
   else 1
   end as vaxmfr1n
   ,case 
   when vaxmfr2 is null then 0
   else 1
   end as vaxmfr2n
   ,case 
   when vaxmfr3 is null then 0
   else 1
   end as vaxmfr3n
   ,case 
   when vaxmfr4 is null then 0
   else 1
   end as vaxmfr4n
   ,case 
   when vaxmfr5 is null then 0
   else 1
   end as vaxmfr5n
   ,case 
   when vaxmfr6 is null then 0
   else 1
   end as vaxmfr6n
   ,case 
   when vaxmfr7 is null then 0
   else 1
   end as vaxmfr7n
   ,case 
   when vaxmfr8 is null then 0
   else 1
   end as vaxmfr8n
   ,case 
   when vaxmfr9 is null then 0
   else 1
   end as vaxmfr9n
   ,case 
   when vaxmfr10 is null then 0
   else 1
   end as vaxmfr10n
   ,case 
   when (vaxmfr1 ='PFR' or vaxmfr2 ='PFR' or vaxmfr3 ='PFR' or vaxmfr4 ='PFR' or vaxmfr5 ='PFR' or vaxmfr6 ='PFR' or vaxmfr7 ='PFR' or vaxmfr8 ='PFR' or vaxmfr9 ='PFR' or vaxmfr10 ='PFR') then 1
   else 0
   end as PFR
   ,case 
   when (vaxmfr1 ='SKB' or vaxmfr2 ='SKB' or vaxmfr3 ='SKB' or vaxmfr4 ='SKB' or vaxmfr5 ='SKB' or vaxmfr6 ='PSKB' or vaxmfr7 ='SKB' or vaxmfr8 ='SKB' or vaxmfr9 ='SKB' or vaxmfr10 ='SKB') then 1
   else 0
   end as SKB
   ,case 
   when (vaxmfr1 ='MOD' or vaxmfr2 ='MOD' or vaxmfr3 ='MOD' or vaxmfr4 ='MOD' or vaxmfr5 ='MOD' or vaxmfr6 ='MOD' or vaxmfr7 ='MOD' or vaxmfr8 ='MOD' or vaxmfr9 ='MOD' or vaxmfr10 ='MOD') then 1
   else 0
   end as MOD
   from vax_0;
quit;

/*Add total num of vax type, total num of dose and num of vax type category*/
proc sql;
   create table vax_num as
   select *
   ,vaxtype1n+vaxtype2n+vaxtype3n as num_vax_type
   ,vaxdose1n+vaxdose2n+vaxdose3n as num_dose
   ,vaxmfr1n+vaxmfr2n+vaxmfr3n as num_mfr
   from vax;

   create table vax_num123 as
   select *
   ,case 
   when num_vax_type =0 then "0"
   when num_vax_type =1 then "1"
   when num_vax_type =2 then "2"
   when num_vax_type =3 then "3"
   else "3+"
   end as num_vax_type_category

   ,case
   when num_vax_type =0 then "Missing"
   else cats(vaxtype1," ",vaxtype2," ",vaxtype3)
   end as vax_type_val
   ,case 
   when (vaxmfr1 is null and vaxmfr2 is null and vaxmfr3 is null) then "0-Missing"
   when (vaxmfr1 ='PFR' or vaxmfr2 ='PFR' or vaxmfr3 ='PFR') and num_mfr=1 then "1DosePFR"
   when (vaxmfr1 ='MOD' or vaxmfr2 ='MOD' or vaxmfr3 ='MOD') and num_mfr=1 then "1DoseMOD"
   when (vaxmfr1 ='UNK' or vaxmfr2 ='UNK' or vaxmfr3 ='UNK') and num_mfr=1 then "Unknown"
   when (vaxmfr1 ='PFR' or vaxmfr2 ='PFR' or vaxmfr3 ='PFR') and num_mfr=2 then "2DosesPFR"
   when (vaxmfr1 ='MOD' or vaxmfr2 ='MOD' or vaxmfr3 ='MOD') and num_mfr=2 then "2DosesMOD"
   when (vaxmfr1 ='PFR' or vaxmfr2 ='PFR' or vaxmfr3 ='PFR') and num_mfr=3 then "3DosesPFR"
   when (vaxmfr1 ='MOD' or vaxmfr2 ='MOD' or vaxmfr3 ='MOD') and num_mfr=3 then "3DosesMOD"
   when (vaxmfr1 in ('MOD','PFR') or vaxmfr2 in ('MOD','PFR') or vaxmfr3 in ('MOD','PFR')) and num_mfr=2 then "1DoseMOD&1DosePFR"
   when (vaxmfr1 is not null or vaxmfr2 is not null or vaxmfr3 is not null) then "Other"
   end as manufacturer
   from vax_num;
quit;

/*Report1 is moved to the end*/
/*Report2 starts: Onset date and Vax date*/
proc sql;
   create table onset_vaxdate as
   select t1.local_record_id
   ,t1.trans_id
   ,case
      when t1.illness_onset_dt is not null then "Present"
      else "Missing"
   end as illness_onset_dt
   ,case
      when (t2.vaxtype1 is not null and t2.vaxdate1 is not null and t2.vaxtype1 is not null and t2.vaxdate2 is not null) then "Present_for_all_doses_received"
      when (t2.vaxtype1 is not null and t2.vaxdate1 is not null and t2.vaxtype1 is null and t2.vaxdate2 is null) then "Present_for_all_doses_received"
      else "Missing_for_1_or_more_doses"
   end as vaxdate
   ,case
      when t1.illness_onset_dt is not null then 1
      else 2
   end as illness_onset_dt_sort
   ,case
      when (t2.vaxtype1 is not null and t2.vaxdate1 is not null and t2.vaxtype1 is not null and t2.vaxdate2 is not null) then 1
      when (t2.vaxtype1 is not null and t2.vaxdate1 is not null and t2.vaxtype1 is null and t2.vaxdate2 is null) then 1
      else 2
   end as vaxdate_sort
   from NNAD.COVID19_NNDSScasesT1_vw as t1
   left join NNAD.COVID19_NNDSScasesT2_vw as t2
   on (t1.local_record_id=t2.local_record_id and t1.trans_id=t2.trans_id)
   where t1.report_jurisdiction="&juris"
         and t2.report_jurisdiction="&juris"
         and t2.vaxtype1 is not null
         and t1.trans_id in (select trans_id
                             from t_vw_clean where report_jurisdiction="&juris");
quit;

proc sort data=onset_vaxdate;
by illness_onset_dt_sort vaxdate_sort;
run;

ods path reset;
ods path show;
ods path(prepend) work.templat(update);
proc template;
delete base.freq.crosstabfreqs;
run; 
proc template;
   define crosstabs base.freq.crosstabfreqs / store=work.templat;
   define header tableof;
   text "Table: Onset Date (illness_onset_dt) by Vaccine Date (vaxdate1-2)";
   end;

   define header rowsheader;
/* text _row_label_ / _row_label_ ^= ' ';*/
   text _row_name_;
/* text _row_label_;*/
   end; 

   define header colsheader;
/* text _col_label_ / _col_label_ ^= ' ';*/
   text _col_name_;
   end; 
   cols_header=colsheader;
   rows_header=rowsheader;
   header tableof; 
   end;
run; 

proc freq data=onset_vaxdate order=data;
title5 "Vaccine Data Included in NNDSS COVID-19 Case Notifications";
title6 height=2"Total Equals Number of Cases With Any Vaccine Doses Administered";
footnote1;
table illness_onset_dt*vaxdate/norow nocol;
run;

/*If we want to delete the template, use the following*/
proc template;
delete base.freq.crosstabfreqs;
run; 

/*Report2 ends: Onset date and Vax date*/

/*Report 3 starts*/
/*case based report*/
/*ods path show;*/
/*ods path(prepend) work.tmplbase(update);*/
proc template;
delete base.freq.crosstabfreqs;
run; 
proc template;
   define crosstabs base.freq.crosstabfreqs / store=work.templat;
   define header tableof;
   text "Table: Number of Doses (Vax Type) Administered by Vaccine Manufacturer";
   end;

   define header rowsheader;
/* text _row_label_ / _row_label_ ^= ' ';*/
/* text _row_name_;*/
   text _row_label_;
   end; 

   define header colsheader;
/* text _col_label_ / _col_label_ ^= ' ';*/
   text _col_label_;
   end; 
   cols_header=colsheader;
   rows_header=rowsheader;
   header tableof; 
   end;
run; 

proc freq data=vax_num123 (rename=(num_vax_type_category='NumVax'n manufacturer='VarMfr'n));
title3 " ";
title4 " ";
title5 "Vaccine Data Included in NNDSS COVID-19 Case Notifications";
title6 height=2"Total Equals Number of Cases";
footnote1;
label NumVax="DosesAdmin";
label VarMfr="VaxMfr";
table NumVax*VarMfr/nocol norow;
run;
/*If we want to delete the template, use the following*/
proc template;
delete base.freq.crosstabfreqs;
run; 
/*Report 3 ends*/

/*Report 4 starts*/

/*Get the vax type 1-3 and append them*/
proc sql;
   create table vaxtype_ins1 as
   select local_record_id
   ,trans_id
   ,vaxtype1 as vaxtype
   ,vaxdate1 as vaxdate
   ,vaxdose1_c as vaxdose
   ,vaxmfr1_c as vaxmfr
   ,vaxlot1 as vaxlot
   ,vaxexpdt1 as vaxexpdt
   ,vaxndc1 as vaxndc
   ,vaxrecid1 as vaxrecid
   ,vaxinfosrce1 as vaxinfosrce
   from vax_num123 
   where vaxtype1 is not null;
quit;
proc sql;
   create table vaxtype_ins2 as
   select local_record_id
   ,trans_id
   ,vaxtype2 as vaxtype
   ,vaxdate2 as vaxdate
   ,vaxdose2_c as vaxdose
   ,vaxmfr2_c as vaxmfr
   ,vaxlot2 as vaxlot
   ,vaxexpdt2 as vaxexpdt
   ,vaxndc2 as vaxndc
   ,vaxrecid2 as vaxrecid
   ,vaxinfosrce2 as vaxinfosrce
   from vax_num123 
   where vaxtype2 is not null;
quit;
proc sql;
   create table vaxtype_ins3 as
   select local_record_id
   ,trans_id
   ,vaxtype3 as vaxtype
   ,vaxdate3 as vaxdate
   ,vaxdose3_c as vaxdose
   ,vaxmfr3_c as vaxmfr
   ,vaxlot3 as vaxlot
   ,vaxexpdt3 as vaxexpdt
   ,vaxndc3 as vaxndc
   ,vaxrecid3 as vaxrecid
   ,vaxinfosrce3 as vaxinfosrce
   from vax_num123 
   where vaxtype3 is not null;
quit;

/*append three instances*/
proc append base=vaxtype_ins1 data=vaxtype_ins2;
run;
proc append base=vaxtype_ins1 data=vaxtype_ins3;
run;

proc sql;
create table vaxtype_ins as
select local_record_id
   ,trans_id
   ,case
      when vaxtype="213" then "SARS-COV-2 (COVID-19) vaccine, UNSPECIFIED"
      when vaxtype="207" then "COVID-19, mRNA, LNP-S, PF, 100 mcg/0.5 mL dose"
      when vaxtype="208" then "COVID-19, mRNA, LNP-S, PF, 30 mcg/0.3 mL dose"
      when vaxtype="210" then "SARS-COV-2 (COVID-19) vaccine, vector non-replicating, recombinant spike protein-ChAdOx1, preservative free, 0.5 mL"
      when vaxtype="999" then "Unknown"
      when vaxtype="OTH" then "Other"
      when vaxtype="UNK" then "Unknown"
   end as vaxtype
   ,vaxdate
   ,vaxdose
   ,vaxmfr
   ,vaxlot
   ,vaxexpdt
   ,vaxndc
   ,vaxrecid
   ,vaxinfosrce
   from vaxtype_ins1;
quit;


proc sort data=vaxtype_ins;
by vaxtype descending VaxDate VaxDose descending VaxMfr descending VaxMfr descending VaxExpDt descending VaxNDC descending VaxRecID descending VaxInfoSrce;
run;

/*Get the proc freq for vax type*/
ods noproctitle;
proc freq data=vaxtype_ins order=data;
title3 " ";
title4 " ";
title5 "Summary of COVID-19 Vaccine Data Included in NNDSS Case Notifications";
title6 height=2"Cumulative Frequency May Include Multiple Responses Per Case with Vaccine Type Entered ";
footnote1;
label vaxtype="Vaccine Type (LN: 30956-7) (VaxType1-3)";
label VaxDate="Vaccine Administered Date (LN: 30952-6) (VaxDate1-3)";
label VaxDose="Vaccine Dose Number (LN: 30973-2) (VaxDose1-3)";
label VaxMfr="Vaccine Manufacturer (LN: 30957-5) (VaxMfr1-3)";
label VaxLot="Vaccine Lot Number (LN: 30956-7) (VaxLot1-3)";
label VaxExpDt="Vaccine Expiration Date (PHINQUESTION: VAC109) (VaxExpDt1-3)";
label VaxNDC="National Drug Code (NDC) (PHINQUESTION: VAC153) (VaxNDC1-3)";
label VaxRecID="Vaccination Record Identifier (PHINQUESTION: VAC102) (VaxRecID1-3)";
label VaxInfoSrce="Vaccine Event Information Source (PHINQUESTION:VAC14) (VaxInfoSrce1-3)";
table vaxtype vaxdate vaxdose vaxmfr vaxlot vaxexpdt vaxndc vaxrecid vaxinfosrce;
run;

/*Report 4 ends*/

ods word close;

options orientation=landscape;
/*ods word;*/
/*Report5: Detailed cases*/
proc sql;
create table vax_detail as
   select a.local_record_id as Local_Record_ID,
   a.trans_id as Trans_ID
   ,a.age_invest as Age_at_Case_Investigation
   ,a.age_invest_units as Age_Unit_at_Case_Investigation
   ,b.vaxtype1 as Vaccine_Type1
   ,b.vaxtype2 as Vaccine_Type2
   ,b.vaxtype3 as Vaccine_Type3
   ,b.vaxmfr1 as Vaccine_Manufacturer1
   ,b.vaxmfr2 as Vaccine_Manufacturer2
   ,b.vaxmfr3 as Vaccine_Manufacturer3
   ,datepart(a.illness_onset_dt) as Illness_End_Date format=mmddyy10.
   ,datepart(b.vaxdate1_) as Vaccine_Date1 format=mmddyy10.
   ,datepart(b.vaxdate2_) as Vaccine_Date2 format=mmddyy10.
   ,datepart(b.vaxdate3_) as Vaccine_Date3 format=mmddyy10.
   ,intck('day', datepart(b.vaxdate1_), datepart(a.illness_onset_dt)) as Onsetdate_minus_Vaxdate1_in_Days
   ,intck('day', datepart(b.vaxdate2_), datepart(a.illness_onset_dt)) as Onsetdate_minus_Vaxdate2_in_Days
   ,intck('day', datepart(b.vaxdate3_), datepart(a.illness_onset_dt)) as Onsetdate_minus_Vaxdate3_in_Days
   ,vaxlot1_ as Vaccine_Lot1
   ,vaxlot2_ as Vaccine_Lot2
   ,vaxlot3_ as Vaccine_Lot3
   ,datepart(vaxexpdt1_) as Vaccine_Expiration_Date1 format=mmddyy10.
   ,datepart(vaxexpdt2_) as Vaccine_Expiration_Date2 format=mmddyy10.
   ,datepart(vaxexpdt3_) as Vaccine_Expiration_Date3 format=mmddyy10.
   ,vaxndc1_ as National_Drug_Code1 
   ,vaxndc2_ as National_Drug_Code2 
   ,vaxndc3_ as National_Drug_Code3
   ,vaxrecid1_ as Vaccination_Record_Identifier1
   ,vaxrecid2_ as Vaccination_Record_Identifier2
   ,vaxrecid3_ as Vaccination_Record_Identifier3
   ,case 
      when vaxinfosrce1_ ="PHC1435" then "Patient/Parents Recall"
      when vaxinfosrce1_ ="PHC1436" then "Patient/Parents Written Record"
      when vaxinfosrce1_ ="PHC1936" then "IIS"
      when vaxinfosrce1_ ="184225006" then "Medical record"
      when vaxinfosrce1_ ="06" then "Historical information - from birth certificate"
      when vaxinfosrce1_ ="02" then "Historical information - from other provider"
      when vaxinfosrce1_ ="05" then "Historical information - from other registry"
      when vaxinfosrce1_ ="08" then "Historical information - from public agency"
      when vaxinfosrce1_ ="07" then "Historical information - from school record"
      when vaxinfosrce1_ ="01" then "Historical information - source unspecified"
      when vaxinfosrce1_ ="00" then "New immunization record"
      when vaxinfosrce1_ ="OTH" then "Other"
      when vaxinfosrce1_ ="PP" then "Primary Care Provider"
      else vaxinfosrce1_
   end as Vaccine_Event_Info_Source1
   ,case 
      when vaxinfosrce2_ ="PHC1435" then "Patient/Parents Recall"
      when vaxinfosrce2_ ="PHC1436" then "Patient/Parents Written Record"
      when vaxinfosrce2_ ="PHC1936" then "IIS"
      when vaxinfosrce2_ ="184225006" then "Medical record"
      when vaxinfosrce2_ ="06" then "Historical information - from birth certificate"
      when vaxinfosrce2_ ="02" then "Historical information - from other provider"
      when vaxinfosrce2_ ="05" then "Historical information - from other registry"
      when vaxinfosrce2_ ="08" then "Historical information - from public agency"
      when vaxinfosrce2_ ="07" then "Historical information - from school record"
      when vaxinfosrce2_ ="01" then "Historical information - source unspecified"
      when vaxinfosrce2_ ="00" then "New immunization record"
      when vaxinfosrce2_ ="OTH" then "Other"
      when vaxinfosrce2_ ="PP" then "Primary Care Provider"
      else vaxinfosrce2_
   end as Vaccine_Event_Info_Source2
   ,case 
      when vaxinfosrce3_ ="PHC1435" then "Patient/Parents Recall"
      when vaxinfosrce3_ ="PHC1436" then "Patient/Parents Written Record"
      when vaxinfosrce3_ ="PHC1936" then "IIS"
      when vaxinfosrce3_ ="184225006" then "Medical record"
      when vaxinfosrce3_ ="06" then "Historical information - from birth certificate"
      when vaxinfosrce3_ ="02" then "Historical information - from other provider"
      when vaxinfosrce3_ ="05" then "Historical information - from other registry"
      when vaxinfosrce3_ ="08" then "Historical information - from public agency"
      when vaxinfosrce3_ ="07" then "Historical information - from school record"
      when vaxinfosrce3_ ="01" then "Historical information - source unspecified"
      when vaxinfosrce3_ ="00" then "New immunization record"
      when vaxinfosrce3_ ="OTH" then "Other"
      when vaxinfosrce3_ ="PP" then "Primary Care Provider"
      else vaxinfosrce3_
   end as Vaccine_Event_Info_Source3

   from t1_0 as a
   left join vax_num123 as b
   on (a.local_record_id=b.local_record_id and a.trans_id =b.trans_id)
   where num_vax_type>0;
quit;

/* Create stored dataset for all the observations of report_jurisdiction */
%let loaddate = %sysfunc(intnx(day,%sysfunc(today()),0), mmddyyn6.);
%put &loaddate;

data datasets.vax_detail_&report_jurisdiction&loaddate;
   set vax_detail;
run;

/* delete dataset from 16 days prior */
%let prior_16 = %sysfunc(intnx(day,%sysfunc(today()),-16), mmddyyn6.); /* prior 16 days */
%put &prior_16;

proc datasets library=datasets nolist;
	delete vax_detail_&report_jurisdiction&prior_16;
quit;

/*Report5 ends: Detailed cases*/
/*Output the Report 5 into Excel*/
ods excel file="&output\&report_jurisdiction Detailed Vaccine History Data as of &SYSDATE9..xlsx" 
options (sheet_name='Vax_detail' embedded_titles='yes' embedded_footnotes='yes');

options missing='';
proc print data=vax_detail(obs=2000);
   title1 justify=l"&report_jurisdiction (GenV2 and COVID-19 MMG) - NCIRD NNDSS COVID-19 Case Notification Feedback Report";
   title2 justify=l"Confirmed and Probable Cases as of &weekdate.";
   title3 " ";
   title4 " ";
   title5 justify=l"Vaccine History Data Included in NNDSS for COVID-19 Cases With Any Vaccine Doses Administered";
   ods escapechar="^";
   title6 justify=l"This report only outputs 2000 rows. For the complete list, please see 'vax_detail_&report_jurisdiction&loaddate..sas7bdat'";
   footnote1 justify=l"Vax Type: ^{newline}
   207 = COVID-19, mRNA, LNP-S, PF, 100 mcg/0.5 mL dose ^{newline}
   208 = COVID-19, mRNA, LNP-S, PF, 30 mcg/0.3 mL dose ^{newline}
   210 = SARS-COV-2 (COVID-19) vaccine, vector non-replicating, recombinant spike protein-ChAdOx1, preservative free, 0.5 mL^{newline}
   213 = SARS-COV-2 (COVID-19) vaccine, UNSPECIFIED ^{newline}
   999 = unknown; OTH = other; UNK = unknown";
run;

ods excel close;

%mend Gen_jur_CovidMMG;
