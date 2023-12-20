/*Connect to NNAD DB*/

libname NNAD OLEDB
        provider="sqloledb"
        properties = ( "data source"="dspv-infc-1601\qsrv1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="NCIRD_DVD_VPD" ) schema=NNDSS 
                        access=readonly;


/*Connect to MVPS DB*/
libname MVPS OLEDB
        provider="sqloledb"
        properties = ( "data source"="DSPV-INFC-1604\QSRV1"
                       "Integrated Security"="SSPI"
                       "Initial Catalog"="MVPS_PROD" ) schema=hl7 
                        access=readonly;

/*Count row of NNAD COVID*/
proc sql;
   select count(*) as ct_t1_vw_NNAD
   from NNAD.COVID19_NNDSSCasesT1_vw
   where condition = "11065";
quit;

/*Count row of MVPS COVID*/
proc sql;
   select count(*) as ct_message_meta_vw_MVPS
   from MVPS.message_meta_vw
   where condition_code = "11065";
quit;

proc sql;
	select msg_transaction_id
	from MVPS.message_meta_vw
	where msg_transaction_id not in
	(select trans_id from NNAD.COVID19_NNDSSCasesT1_vw );
quit;
