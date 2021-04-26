DATA TEST_CODE;
	MERGE  SASHELP.APPLIANC(OBS=156) 
		SASHELP.DEMOGRAPHICS(OBS=156) SASHELP.PRICEDATA(OBS=156 DROP=REGION);

	/* CODE GOES HERE */


                                                                                
/* Put Code Here*/                                                              
SUM2DEMVARS =sum(0, FemaleSchoolpct, MaleSchoolpct);                            
LABEL SUM2DEMVARS = 'Put label here';                                           
                                                                                
                                                                                
/* Put Code Here*/                                                              
                                                                                
SUMDEMAGAND2DEMVARS =sum(0, SUM2DEMVARS ,PopPovertyYear, PopPovertypct);    
LABEL SUMDEMAGAND2DEMVARS = 'Put label here';    


RUN;

%PRN(WORK.TEST_CODE, 200, );