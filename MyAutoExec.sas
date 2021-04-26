options validvarname=ANY;

%macro isBlank(param);
		%sysevalf(%superq(param)=, boolean) 
%mend isBlank;


%MACRO PRN(DSN,OBZ,WHR);
	
	%if %isblank(&WHR) %then
		%do;
		PROC PRINT DATA=&DSN(OBS=&OBZ);
		RUN;
		%end;
	%else
		%do;
			PROC PRINT DATA=&DSN(OBS=&OBZ);
			WHERE &WHR;
			RUN;
			%end;
%MEND PRN;

/* 	*CHECKS TO SEE IF MACRO VARIABLES IS BLANK.IF BLANK RETURNS TRUE; */
	%macro isBlank(param);
		%sysevalf(%superq(param)=, boolean) %mend isBlank;


/* code below will generate the Public and Casuser libraries (and others) on your behalf automatically when you open SAS Studio */
cas;
caslib _all_ assign;


DATA WORK.SOURCE_VARIABLES;
DoNotUse='Do Not Use';
run;


DATA WORK.PACKAGES;
DoNotUse='Do Not Use';
run;

DATA WORK.TARGETS;
DoNotUse='Do Not Use';
run;

filename myfile '/home/sasdemo/Auto2020Funcs/MetaData_in_TEXT.csv';
data WORK.PGM_Meta_Data    ;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile myfile delimiter = ',' MISSOVER DSD  firstobs=2 ;
 informat CallingPackage_Function $32. ;
informat InPutVariable $32. ;
informat User_Analyst $32. ;
informat Calling_Package $3. ;
informat Source_Package $3. ;
informat Entry_time_number DATETIME19. ;
informat Entry_time_text $19. ;
format CallingPackage_Function $32. ;
format InPutVariable $32. ;
format User_Analyst $32. ;
format Calling_Package $3. ;
format Source_Package $3. ;
format Entry_time_number DATETIME19. ;
format Entry_time_text $19. ;
input
CallingPackage_Function  $
InPutVariable  $
User_Analyst  $
Calling_Package  $
Source_Package  $
Entry_time_number
Entry_time_text $;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/* IC Create statement creates and integrity constraint, multiple choices of constraint type to use */
/*IC Create NOT NULL (variable) specifies that variable does not contain a SAS missing value, including special missing values.*/

proc datasets nolist;
	modify PGM_Meta_Data;
	ic create not null(CallingPackage_Function);
	ic create not null(InPutVariable);
	ic create not null(User_Analyst);
	ic create not null(Calling_Package);
	ic create not null(Source_Package);
	ic create not null(Entry_time_number);
	ic create not null(Entry_time_text);
quit;