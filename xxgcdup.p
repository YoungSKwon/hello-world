/*******************************************************************************
* Vendor            : Comtec                                                   *
* Program Title     : 일반코드 복제(도메인)                                     *
* Program ID        : xxgcdup.p                                                *
* Description       : 소스 도메인에서 목표 도메인으로 일반코드 복제              *
* Include File      :                                                          *
*------------------------------------------------------------------------------*
* Rev. | LAST MODIFIED | Description                        |By     | Rev. ID  *
*      |  2021/02/22   | Initial Release                    |YSK    |          *
*******************************************************************************/
/* DISPLAY TITLE */
{mfdtitle.i "1+ "}

{qxi/maintainGeneralizedCode-ERP3_1.i}

/* ********** Begin Translatable Strings Definitions ********* */
&SCOPED-DEFINE DEBUG_LEVEL 1		/* 0 = Operation, 1 = Debug */
          
&SCOPED-DEFINE msg_summary_detail "Summary/Detail"

define variable viReturn as integer.
      
define variable cLicensedDomain as character no-undo 
	initial "820,821,823,824,825,826".
define variable i as integer no-undo.

define variable cSourceDomain	as character format "x(24)" no-undo label "소스 도메인"
	initial "820".
define variable cTargetDomain	as character format "x(24)" no-undo label "복사되는 도메인".
define variable lUpdate			   like mfc_logical label "Update".
define variable lSummary_only		like mfc_logical format {&msg_summary_detail} initial yes label "Reporting".              
define variable lError_only	   like mfc_logical label "Error only" init yes.

define variable iSourcPartCount as integer no-undo .
define variable iTargetPartCount as integer no-undo .
define variable iDiffPartCount as integer no-undo . 
define variable iSamePartCount as integer no-undo . 
define variable iCodeErrorCount as integer no-undo . 
define variable iProductLineErrorCount as integer no-undo . 
define variable iItemStatusErrorCount as integer no-undo . 
define variable iRecordCount as integer no-undo . 

define variable iNo as integer format ">>>,>>9" no-undo  label "NO".
define variable cItemNo as character format "x(18)" no-undo label "Part".
define variable cDesc as character format "x(24)"no-undo label "Description".
define variable cError as character format "x(24)"no-undo label "Error".
define variable lError as logical no-undo.
define variable lChedkError as logical no-undo.

define stream logs.

  	
define temp-table ttCode no-undo                                                                              
	field tField 		as character format "x(32)"  	label "필드명"	
	field tValue	   as character format "x(8)"  	label "값"	
	field tComment		as character format "x(40)"  	label "주석"	
	field tGroup		as character format "x(24)"  	label "그룹"	
	field tErr			as logical                    label "오류"	
	field tResult		as character format "x(8)" 	label "처리결과"
index ttCode_idx is primary unique    
  tField
  tValue.
                 	

/* DISPLAY SELECTION FORM */
form
   cSourceDomain      colon 25  
   cTargetDomain      colon 25 skip(1)
   lSummary_only  	colon 35
   lUpdate        	colon 35 skip(1)   
with frame a side-labels width 80.

/* SET EXTERNAL LABELS */
setFrameLabels(frame a:handle).

form 
	cItemNo  	no-label
	cDesc   		no-label
with frame c down width 132 no-attr-space.

/* SET EXTERNAL LABELS */
setFrameLabels(frame c:handle).
   
/* DISPLAY */

view frame a.

{wbrp01.i}

mainloop:
repeat :

	if c-application-mode <> 'web' then
		update cSourceDomain cTargetDomain lSummary_only lUpdate with frame a.

	{wbrp06.i &command = update &fields = " cSourceDomain cTargetDomain lSummary_only lUpdate  " &frm = "a"}
	
	if (c-application-mode <> 'web') or
	   (c-application-mode = 'web' and
	   (c-web-request begins 'data')) then do:
	
	   bcdparm = "".
	   {mfquoter.i cSourceDomain   }
	   {mfquoter.i cTargetDomain	 }
      {mfquoter.i lSummary_only}
      {mfquoter.i lUpdate}
      
	 	/* check domain */
	   find first dom_mstr 
	        where dom_mstr.dom_domain = cSourceDomain
	          and dom_active = yes
	          and dom_type <> 'SYSTEM' 
	         		no-lock no-error.		
	  	if not avail dom_mstr then do:

	      /* 도메인이 없습니다.  */
	      {pxmsg.i &MSGNUM=6135 &ERRORLEVEL=3}
	      next-prompt cSourceDomain with frame a.
	      undo mainloop, retry mainloop. 
	   end.
	   else do:
   	     		
	  		/* QXtend Licensed Domain	820,821,823,824,825 */
	  		if lookup(cSourceDomain, cLicensedDomain) = 0 then do:
		      /* QXTEND 사용 도메인이 아닙니다.  */					
		      /* {pxmsg.i &MSGNUM=6171 &ERRORLEVEL=3}	*/
		      message "QXTEND 사용 도메인이 아닙니다." skip(1).	
		      next-prompt cSourceDomain with frame a.
		      undo mainloop, retry mainloop. 	  			
	  		end.
  		
	  	end.

	   find first dom_mstr 
	        where dom_mstr.dom_domain = cTargetDomain
	          and dom_active = yes
	          and dom_type <> 'SYSTEM' 		 
	         		no-lock no-error.		
	  	if not avail dom_mstr then do:
	      /* 도메인이 없습니다.  */
	      {pxmsg.i &MSGNUM=6135 &ERRORLEVEL=3}
	      next-prompt cTargetDomain with frame a.
	      undo mainloop, retry mainloop. 
	  	end.
	  	else do:
	  		
	  		/* QXtend Licensed Domain	820,821,823,824,825 */
	  		if lookup(cTargetDomain, cLicensedDomain) = 0 then do:
		      /* QXTEND 사용 도메인이 아닙니다.  */
		      /* {pxmsg.i &MSGNUM=6171 &ERRORLEVEL=3}	*/
		      message "QXTEND 사용 도메인이 아닙니다." skip(1).
		      next-prompt cTargetDomain with frame a.
		      undo mainloop, retry mainloop. 	  			
	  		end.	  		

	  	end.      
            
 	end.

   /* OUTPUT DESTINATION SELECTION */
   {gpselout.i &printType = "printer"
               &printWidth = 132
               &pagedFlag = " "
               &stream = " "
               &appendToFile = " "
               &streamedOutputToTerminal = " "
               &withBatchOption = "yes"
               &displayStatementType = 1
               &withCancelMessage = "yes"
               &pageBottomMargin = 6
               &withEmail = "yes"
               &withWinprint = "yes"
               &defineVariables = "yes"}
/*   {mfphead.i} */
/*********************/
   lChedkError = no.
	/* Check generalized codes */
	empty temp-table ttCode.
	lError = no.
	
	run CreateCode( cSourceDomain, 'GENERALIZED_CODE', 'pt_part_type').
	run CreateCode( cSourceDomain, 'GENERALIZED_CODE', 'pt_group').
	run CreateCode( cSourceDomain, 'GENERALIZED_CODE', 'pt_promo').
	
	run IsThereCode( input cTargetDomain, input 'GENERALIZED_CODE', output lError ).

	run DisplayCheckResult( 'GENERALIZED_CODE', lError, lSummary_only ).	

	iDiffPartCount = 0.
	for each ttCode no-lock where ttCode.tErr = yes :
		iDiffPartCount = iDiffPartCount + 1.										  		
	end.  

	disp "복제할 일반코드 수 = "  			@ cItemNo
	     string(iDiffPartCount) 	    @ cDesc 
	     with frame c.
	down 1 with frame c.	   
		
	
	if not lUpdate then do:
		
		run DisplayGcList( lUpdate, lSummary_only ).			
    
   end.
   else do:

/****** sample data *
empty temp-table ttCode.

create ttCode.
assign
	ttCode.tField	 	= 'pt_group'
	ttCode.tValue 		= 'C00001'
	ttCode.tComment   = 'AP'
	ttCode.tGroup     = 'SYSTEM'
	ttCode.tErr = yes.
	
create ttCode.
assign
	ttCode.tField	 	= 'pt_group'
	ttCode.tValue 		= 'C00002'
	ttCode.tComment   = 'BACK UP'
	ttCode.tGroup     = 'SYSTEM'
	ttCode.tErr = yes.
	
create ttCode.
assign
	ttCode.tField	 	= 'pt_group'
	ttCode.tValue 		= 'C00003'
	ttCode.tComment   = 'Billing'
	ttCode.tGroup     = 'SYSTEM'
	ttCode.tErr = yes.		


******/


		iRecordCount = 0.
	
   	for each ttCode no-lock where ttCode.tErr = yes :
   		iRecordCount = iRecordCount + 1.
   			   
	      run qxi/maintainGeneralizedCode-ERP3_1.p persistent set vhProxyComponent.
	      
	      dataset dsGeneralizedCode:empty-dataset() no-error.
	   
	      create generalizedCode.
	      assign codeFldname = ttCode.tField
	             codeValue   = ttCode.tValue
	             codeCmmt    = ttCode.tComment
	             codeGroup   = ttCode.tGroup.
	             
	      run apiQXtendInbound in vhProxyComponent
	          (cTargetDomain,
	           dataset dsGeneralizedCode,
	           output dataset temp_err_msg,
	           output viReturn).
	   
	      delete procedure vhProxyComponent.   		
    		    	
		end.

	
		/* Verify qxtend */
   	for each ttCode no-lock where ttCode.tErr = yes :
   		ttCode.tResult	= 'Pass'.
   		find first code_mstr where code_domain = cTargetDomain
   		                     and code_fldname  = ttCode.tField
   		                     and code_value  	= ttCode.tValue 
   			no-lock no-error.
   		if not avail code_mstr then 
   			ttCode.tResult	= 'Fail'.
   	end.   	

		run DisplayGcList( lUpdate, lSummary_only ).		 
	   	
   end.
 
   
   /* REPORT TRAILER  */
   {mfrtrail.i}	
   
end.

{wbrp04.i &frame-spec = a}

procedure CreateCode:
/*------------------------------------------------------------------------------
* Purpose           : 코드                                                     *
* Parameters        :                                                          *
* Notes             :                                                          *
------------------------------------------------------------------------------*/
/* Passed Parameters */
define input parameter ipDomain as character   no-undo. 
define input parameter ipCodeType as character   no-undo. 
define input parameter ipCodeValue as character   no-undo. 


	if ipCodeType = 'GENERALIZED_CODE' then do:
	  	for each code_mstr no-lock 
	  		where code_domain = ipDomain
	  		  and code_fldname = ipCodeValue :
	  		
	  		find first ttCode 
	  			where ttCode.tField	 = code_fldname
	  			  and ttCode.tValue   = code_value
	  			  		no-lock no-error.
	  		if not avail ttCode then do:
	  			create ttCode.
	  			assign
	  				ttCode.tField	 	= code_fldname
	  				ttCode.tValue 		= code_value
	  				ttCode.tComment   = code_cmmt
	  				ttCode.tGroup     = code_group.
	  		end.
		end.
	end.	       
        
end procedure.	
		     

procedure IsThereCode:
/*------------------------------------------------------------------------------
* Purpose           : 코드                                                     *
* Parameters        :                                                          *
* Notes             :                                                          *
------------------------------------------------------------------------------*/
/* Passed Parameters */
define input parameter icDomain as character   no-undo. 
define input parameter icCodeType as character   no-undo. 
define output parameter olError as logical   no-undo. 


	if icCodeType = 'GENERALIZED_CODE' then do:
 		for each ttCode no-lock :
		  	find first code_mstr 
		  		where code_domain  = icDomain
		  		  and code_fldname = ttCode.tField 
		  		  and code_value 	 = ttCode.tValue 
		  		  no-lock no-error.
		  	if not avail code_mstr then do:
		  		olError = yes.
		  		ttCode.tErr = yes.
		  	end.
	  	end.
	end.
		
end procedure.	

PROCEDURE DisplayCheckResult:
/*------------------------------------------------------------------------------
* Purpose           : Display Check Result                                     *
* Parameters        :                                                          *
* Notes             :                                                          *
------------------------------------------------------------------------------*/
/* Passed Parameters */
define input parameter icCodeType 	as character   no-undo. 
define input parameter ilError		as logical   no-undo.
define input parameter olSummary		as logical   no-undo.
	
	if icCodeType = 'GENERALIZED_CODE' then do:
		
		if ilError then do:
			/* #을(를) 처리하는 동안 오류가 발생했습니다. */
			/* {pxmsg.i &MSGNUM=7596 &MSGARG1='일반코드' &ERRORLEVEL=3}		*/	
			/* message "** 복사되는 도메인에 일반코드가 정의되지 않았습니다." skip. */
	
			disp 
				"** 복사되는 도메인에 일반코드가 정의되지 않았습니다."  at 1
			with width 132.		
			/* down 1 with width 132. */
		end.
	end.

		   	
	if lSummary_only then do:
		.
	end.
	else do:
		for each ttCode no-lock where ttCode.tErr = yes :
			disp 
				ttCode.tField		format "x(32)" label "필드명"
				ttCode.tValue	   format "x(8)" label "값" 
				ttCode.tComment	format "x(40)" label "주석"
				ttCode.tErr		       label "오류"      
			with width 132.											  		
		end.  
	end.
	
end procedure.		
		
PROCEDURE DisplayGcList:
/*------------------------------------------------------------------------------
* Purpose           : Display GC lists                                         *
* Parameters        :                                                          *
* Notes             :                                                          *
------------------------------------------------------------------------------*/
/* Passed Parameters */
define input parameter ilUpdate		as logical   no-undo.
define input parameter olSummary		as logical   no-undo.

define variable iRecordCount as integer no-undo. 
define variable iPassCount as integer no-undo. 
define variable iFailCount as integer no-undo. 

	iRecordCount = 0.
		
	if not ilUpdate then do:
		
		if not lSummary_only then do:
			for each ttCode no-lock where ttCode.tErr = yes :
				iRecordCount = iRecordCount + 1.
				disp 
				   iRecordCount		format ">>>,>>9" label "NO"
					ttCode.tField		format "x(32)" label "필드명"
					ttCode.tValue		format "x(8)" label "값" 
					ttCode.tComment	format "x(40)" label "주석"  
				with width 132.			
						
				{mfrpchk.i}	
			end.	
		end.
	end.
	else do:
		iPassCount	 = 0.	
		iFailCount   = 0.

		for each ttCode no-lock where ttCode.tErr = yes :
			if ttCode.tResult = 'Pass' then
				iPassCount = iPassCount + 1.
			else 
				iFailCount = iFailCount + 1.
		end.	
		
		disp "복사 성공 품목 수 = "   @ cItemNo
			  string(iPassCount) 	@ cDesc 
			with frame c.
		down 1 with frame c.
		
		disp "복사 실패 품목 수 = "   @ cItemNo
			  string(iFailCount) 	@ cDesc 
			with frame c.
		down 1 with frame c.
			
		if not lSummary_only then do:
			iRecordCount = 0.
			for each ttCode no-lock where ttCode.tErr = yes :
				iRecordCount = iRecordCount + 1.
				disp 
				   iRecordCount		      format ">>>,>>9" label "NO"
					ttCode.tField		format "x(24)" label "필드명"
					ttCode.tValue		format "x(8)" label "값" 
					ttCode.tComment	format "x(40)" label "주석"    
					ttCode.tResult		format "x(8)" label "처리결과"
				with width 132.			

				{mfrpchk.i}	
			end.	
						
		end.
	end.
						
	
end procedure.		


		
