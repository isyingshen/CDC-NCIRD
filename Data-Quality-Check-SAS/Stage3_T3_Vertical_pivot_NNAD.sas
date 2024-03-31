 /********************************************************************/
 /* PROGRAM NAME: Stage3_T3_Vertical_pivot_NNAD                      */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2020/12/22                                              */
 /*                                                                  */
 /* PURPOSE:  This is a code snippet that takes LabEpi data in       */
 /*           vertical form into horizontal                          */
 /*                                                                  */ 
 /* Date Modified: 2020/12/23                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: Add 10-example output for 3 tables                      */
 /*          Add 3 proc exports                                      */
 /*          Add local record id                                     */
 /*                                                                  */ 
 /* Date Modified: 2022/06/14                                        */
 /* Modified by: Ying Shen                                           */
 /* Changes: Added staging connection                      */
 /*                                                                  */
 /********************************************************************/


/*!!!! Change the outputdir to your output folder location*/
%let outputdir = \\cdc.gov\project\NIP_Project_Store1\Surveillance\NNDSS_Modernization_Initiative\MMG_Implementation\Stage3_T3_Vertical_pivot\Output;

/*NNAD secondary staging connection*/
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="dssv-infc-1601,53831\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD_COVIDTF" ) schema=NNDSS access=readonly;

/*NNAD staging connection*/
libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSSV-INFC-1601\QSRV1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS access=readonly;


/* Extract vertically structured LabEpi data */
proc sql noprint;
   create table T3_vertical as
   select trans_id, local_record_id, var_name, ContentV_Name, obx_4, OBX_5
   from NNAD.COVID19_NNDSSCasesT3_Vertical_vw
   where condition = "11065"
   order by trans_id, obx_4   
   ;
quit;

/**********************************************************/
/* This section pivots the data at Stage4 level variable. */
/* In other word, it is pivoted at the message (case).    */     
/**********************************************************/                  
/* Note, the let option in transpose will generate error when data collide */
/* Repeat prefix Q1 and Q2 do not yield ContentV_Name thus it is NULL.     */
proc transpose data=T3_vertical out=transposed3G_msg(drop=_name_ _label_) let;
   by trans_id local_record_id;
   id ContentV_Name;
   var OBX_5;
run;

/**********************************************************/
/* This section pivots the data at OBX4 level variable.   */
/* In other word, it is pivoted at the group level.       */     
/**********************************************************/                  
/* Note, the let option in transpose will generate error when data collide */
proc transpose data=T3_vertical out=transposed3G_grp(drop=_name_ _label_) let;
   by trans_id local_record_id obx_4;
   id var_name;
   var OBX_5;
run;

/*Output 10 examples from T3_Vertical, transposed3G_msg and transposed3G_grp*/
proc sql;
select * 
from T3_vertical (obs=10);
quit;
proc sql;
select * 
from transposed3G_msg (obs=10);
quit;
proc sql;
select * 
from transposed3G_grp (obs=10);
quit;


/*Export T3_Vertical, transposed3G_msg and transposed3G_grp into excel*/
PROC EXPORT DATA= T3_vertical
			OUTFILE= "&outputdir\T3_vertical.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="T3_vertical";
RUN;

PROC EXPORT DATA= transposed3G_msg
			OUTFILE= "&outputdir\transposed3G_msg.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="transposed3G_msg";
RUN;

PROC EXPORT DATA= transposed3G_grp
			OUTFILE= "&outputdir\transposed3G_grp.xlsx"
             DBMS=XLSX REPLACE;
      SHEET="transposed3G_grp";
RUN;







