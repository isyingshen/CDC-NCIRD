 /********************************************************************/
 /* PROGRAM NAME: Production Row Count                               */
 /* VERSION: 1.0                                                     */
 /* CREATED: 2020/12/24                                              */
 /*                                                                  */
 /* BY:  Ying Shen                                                   */
 /*                                                                  */
 /* PURPOSE:  This is a code snippet that takes LabEpi data in       */
 /*                                                                  */
 /*                                                                  */ 
 /* Date Modified:                                                   */
 /* Modified by:                                                     */
 /* Changes:                                                         */
 /*                                                                  */
 /********************************************************************/


/*row counts*/

libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="dspv-infc-1601\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS 
                        access=readonly;

title justify=l"COVID Table Row Count in PRODUCTION";

/*macro to count the rows*/
%macro row_count(name_table);
proc sql;
   select count(*) as ct_&name_table
   from NNAD.&name_table
   where condition = "11065";
quit;
%mend row_rount;

/*tables*/
/*%row_count(Stage4_NNDSScasesT1);*/
/*%row_count(Stage4_NNDSScasesT2);*/
/*%row_count(Stage4_NNDSScasesT3);*/
/*%row_count(Stage4_NNDSScasesT4);*/
/*%row_count(Stage4_NNDSScasesT5);*/
/*%row_count(Stage4_NNDSScasesT6);*/
/*%row_count(Stage4_NNDSScasesT7);*/
/*%row_count(Stage4_NNDSScasesT3_1);*/
/*%row_count(Stage4_NNDSScasesT3_2);*/
/*%row_count(Stage4_NNDSScasesT3_3);*/
/*%row_count(Stage4_NNDSScasesT3_4);*/
/*%row_count(Stage4_NNDSScasesT3_5);*/
/*%row_count(Stage4_NNDSScasesT3_6);*/
/*%row_count(Stage4_NNDSScasesT3_7);*/
/*%row_count(Stage4_NNDSScasesT3_8);*/
/*%row_count(Stage4_NNDSScasesT3_9);*/
/*%row_count(Stage4_NNDSScasesT3_10);*/
/*%row_count(Stage4_NNDSScasesT3_11);*/
/*%row_count(Stage4_NNDSScasesT3_12);*/
/*%row_count(Stage4_NNDSScasesT3_13);*/
/*%row_count(Stage4_NNDSScasesT3_14);*/
/*%row_count(Stage4_NNDSScasesT3_15);*/
/*%row_count(Stage4_NNDSScasesT3_16);*/
/*%row_count(Stage4_NNDSScasesT3_17);*/
/*%row_count(Stage4_NNDSScasesT3_18);*/
/*%row_count(Stage4_NNDSScasesT3_19);*/
/*%row_count(Stage4_NNDSScasesT3_20);*/
/*%row_count(Stage4_NNDSScasesT3_21);*/
/*%row_count(Stage4_NNDSScasesT3_22);*/
/*%row_count(Stage4_NNDSScasesT3_23);*/
/*%row_count(Stage4_NNDSScasesT3_24);*/
/*%row_count(Stage4_NNDSScasesT3_25);*/
/*%row_count(Stage4_NNDSScasesT3_26);*/
/*%row_count(Stage4_NNDSScasesT3_27);*/
/*%row_count(Stage4_NNDSScasesT3_28);*/
/*%row_count(Stage4_NNDSScasesT3_29);*/
/*%row_count(Stage4_NNDSScasesT3_30);*/
/*%row_count(Stage4_NNDSScasesT3_31);*/
/*%row_count(Stage4_NNDSScasesT3_32);*/
/*%row_count(Stage4_NNDSScasesT3_33);*/
/*%row_count(Stage4_NNDSScasesT3_34);*/
/*%row_count(Stage4_NNDSScasesT3_35);*/
/*%row_count(Stage4_NNDSScasesT3_36);*/
/*%row_count(Stage4_NNDSScasesT3_37);*/
/*%row_count(Stage4_NNDSScasesT3_38);*/
/*%row_count(Stage4_NNDSScasesT3_39);*/
/*%row_count(Stage4_NNDSScasesT3_40);*/
/*%row_count(Stage4_NNDSScasesT3_41);*/
/*%row_count(Stage4_NNDSScasesT3_42);*/
/*%row_count(Stage4_NNDSScasesT3_43);*/
/*%row_count(Stage4_NNDSScasesT3_44);*/
/*%row_count(Stage4_NNDSScasesT3_45);*/
/*%row_count(Stage4_NNDSScasesT3_46);*/
/*%row_count(Stage4_11065);*/
/*%row_count(Stage3_NNDSSCasesT3_Vertical);*/


%row_count(COVID19_NNDSSCasesT1_vw);
%row_count(COVID19_NNDSSCasesT2_vw);
%row_count(COVID19_NNDSSCasesT3_9_vw);
%row_count(COVID19_NNDSSCasesT3_10_vw);
%row_count(COVID19_NNDSSCasesT3_11_vw);
%row_count(COVID19_NNDSSCasesT3_12_vw);
%row_count(COVID19_NNDSSCasesT3_13_vw);
%row_count(COVID19_NNDSSCasesT3_14_vw);
%row_count(COVID19_NNDSSCasesT3_15_vw);
%row_count(COVID19_NNDSSCasesT3_16_vw);
%row_count(COVID19_NNDSSCasesT3_17_vw);
%row_count(COVID19_NNDSSCasesT3_18_vw);
%row_count(COVID19_NNDSSCasesT3_19_vw);
%row_count(COVID19_NNDSSCasesT3_20_vw);
%row_count(COVID19_NNDSSCasesT3_21_vw);
%row_count(COVID19_NNDSSCasesT3_22_vw);
%row_count(COVID19_NNDSSCasesT3_23_vw);
%row_count(COVID19_NNDSSCasesT3_24_vw);
%row_count(COVID19_NNDSSCasesT3_25_vw);
%row_count(COVID19_NNDSSCasesT3_26_vw);
%row_count(COVID19_NNDSSCasesT3_27_vw);
%row_count(COVID19_NNDSSCasesT3_28_vw);
%row_count(COVID19_NNDSSCasesT3_29_vw);
%row_count(COVID19_NNDSSCasesT3_30_vw);
%row_count(COVID19_NNDSSCasesT3_31_vw);
%row_count(COVID19_NNDSSCasesT3_32_vw);
%row_count(COVID19_NNDSSCasesT3_33_vw);
%row_count(COVID19_NNDSSCasesT3_34_vw);
%row_count(COVID19_NNDSSCasesT3_35_vw);
%row_count(COVID19_NNDSSCasesT3_36_vw);
%row_count(COVID19_NNDSSCasesT3_37_vw);
%row_count(COVID19_NNDSSCasesT3_38_vw);
%row_count(COVID19_NNDSSCasesT3_39_vw);
%row_count(COVID19_NNDSSCasesT3_40_vw);
%row_count(COVID19_NNDSSCasesT3_41_vw);
%row_count(COVID19_NNDSSCasesT3_42_vw);
%row_count(COVID19_NNDSSCasesT3_43_vw);
%row_count(COVID19_NNDSSCasesT3_44_vw);
%row_count(COVID19_NNDSSCasesT3_45_vw);
%row_count(COVID19_NNDSSCasesT3_46_vw);
/*%row_count(COVID19_NNDSSCasesT3_Vertical_vw);*/
%row_count(COVID19_NNDSSCasesT4_vw);
%row_count(COVID19_NNDSSCasesT5_vw);
%row_count(COVID19_NNDSSCasesT7_vw);
%row_count(Stage4_11065_vw);



/*%row_count(COVID19_NNDSSCasesT3_Vertical_vw);*/
proc sql;
   select count(*) as ct_t3_vertical_vw
   from NNAD.COVID19_NNDSSCasesT3_Vertical_vw
   where condition = "11065";
quit;
