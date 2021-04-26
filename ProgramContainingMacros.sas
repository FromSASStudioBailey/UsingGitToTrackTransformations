/* Below is where your log will be stored when running task B create transformations */
%LET MyLog =/home/sasdemo/Auto2020Funcs/mylog.log;

/* below is the main folder where the Git Repositories will be stored */
%LET GitLocation = /home/sasdemo/AutoLiability_Pricing_2020/;

/* when you create transformation code, below is the location of the code */
%LET MySASCode =/home/sasdemo/AutoLiability_Pricing_2020/ALL_CODE_SEGMENTS.SAS;

/* BELOW IS THE LIBRARY THAT CONTAINS THE TABLE HOLDING THE FCMP FUNCTIONS (THAT HOLD OUR TRANSFORMATION CODE ) */
libname AUTO2020 '/home/sasdemo/Auto2020Funcs/FCMP_Table';

/* BELOW IS OUR TABLE HOLDING THE FCMP FUNCTIONS (THAT HOLD OUR TRANSFORMATION CODE ) */
%LET FILE_CABINET=AUTO2020.TRNSFRMS;

/**************   MACRO TROUBLE SHOOTING OPTIONS TURNING ON AND OFF. TROUBLE SHOOTING OPTIONS DEFAULT = OFF   ********/
/* BELOW WILL TURN ON ALL THE MACRO TROUBLE SHOOTING TOOLS. TO TURN THEM ON, SIMPLY UNCOMMENT AND RUN LINE OF CODE BELOW */
/* OPTIONS MERROR SYMBOLGEN MLOGIC MPRINT SOURCE SOURCE2; */
/* BELOW WILL TURN OFF ALL THE MACRO TROUBLE SHOOTING TOOLS. TO TURN THEM OFF, SIMPLY UNCOMMENT AND RUN LINE OF CODE BELOW */
/* OPTIONS NOMERROR NOSYMBOLGEN NOMLOGIC NOMPRINT NOSOURCE NOSOURCE2; */
/* THE MACRO CREATE_FUNCTION_INFORMATION SHOWN BELOW WILL CREATE A TABLE SIMILAR TO THE TABLE SHOWN BELOW */
/* THE TABLE IS CREATED BELOW IS CREATED BY PULL INFORMATION OUT OF TABLE HOLDING FCMP FUNCTIONS */
/* InPutVariable			CallingPackage_Function			Calling_Package		Source_Package */
/* APP.UNITS_1				APP.VAR1_SUM1_2					APP					APP */
/* APP.UNITS_2				APP.VAR1_SUM1_2					APP					APP */
/* APP.UNITS_3				APP.VAR2_SUM3_4					APP					APP */
/* APP.UNITS_4				APP.VAR2_SUM3_4					APP					APP */
/* APP.UNITS_6				APP.VAR3_SUM6_34_12				APP					APP */
/* APP.VAR2_SUM3_4			APP.VAR3_SUM6_34_12				APP					APP */
/* APP.VAR1_SUM1_2			APP.VAR3_SUM6_34_12				APP					APP */
/* DEM.POP					DEM.POP_PLUS5					DEM					DEM */
/* DEM.ISO					DEM.ISO_PLUS_POPPLUS5			DEM					DEM */
/* DEM.POP_PLUS5			DEM.ISO_PLUS_POPPLUS5			DEM					DEM */
/* DEM.ID					DEM.VAR3_SUMDEM_APP				DEM					DEM */
/* DEM.ISO_PLUS_POPPLUS5	DEM.VAR3_SUMDEM_APP				DEM					DEM */
/* APP.VAR3_SUM6_34_12		DEM.VAR3_SUMDEM_APP				DEM					APP */
%MACRO CREATE_FUNCTION_INFORMATION;
	/* START OF MACRO */
	DATA WORK.Package_Functions_Ins_Outs;
		SET &FILE_CABINET.;
		LENGTH InPutVariable CallingPackage_Function Calling_Package Source_Package 
			TEMP_FUNC0 TEMP_FUNC1 TEMP_FUNC2 TEMP_FUNC_USE $65.;

		IF NValue=65;
		TEMP_FUNC0=trim(scan(_key_, 2, '.'));
		TEMP_FUNC1=trim(scan(_key_, 3, '.'));
		TEMP_FUNC2=trim(scan(_key_, 4, '.'));
		TEMP_FUNC_USE=TEMP_FUNC1;

		IF TRIM(TEMP_FUNC0)=TRIM(TEMP_FUNC1) THEN
			TEMP_FUNC_USE=TEMP_FUNC2;
/* 		Calling_Package=trim(scan(_key_, 2, '.')); */
Calling_Package=upcase(trim(scan(_key_, 2, '.')));
		CallingPackage_Function=CATS(Calling_Package, '.', TEMP_FUNC_USE);
		LENGTH TEMP_VALUE $1000.;
		TEMP_VALUE=COMPRESS(VALUE);
		EvalIn_and_outs=substr(TEMP_VALUE, 1, 200);
		count=2;

		do until(InPutVariable=' ');
			count+1;
/* 			InPutVariable=scan(EvalIn_and_outs, count, "(,);"); */
InPutVariable=upcase(scan(EvalIn_and_outs, count, "(,);"));
			Source_Package=Calling_Package;

			if length(InPutVariable) > 1 then
				do;

					if countw(InPutVariable, '.') > 1 then
/* 						Source_Package=scan(InputVariable, 1, "."); */
Source_Package=upcase(scan(InputVariable, 1, "."));
					else
						InPutVariable=cats(Source_Package, '.', InPutVariable);
					output;
				end;
		end;
		KEEP InPutVariable CallingPackage_Function Calling_Package Source_Package;
	run;

%MEND CREATE_FUNCTION_INFORMATION;

/* END OF MACRO */
%MACRO BUILD_PACKAGE_DROP_DOWNS;
	/* START OF MACRO */

/* %CREATE_FUNCTION_INFORMATION   CALLING ANOTHER MACRO */
	PROC SQL;
	SELECT COUNT(DISTINCT(Calling_Package)) INTO :PACKAGE_COUNT FROM 
		/* WORK.PACKAGE_FUNCTIONS_INS_OUTS;*/
		WORK.PGM_META_DATA;
	SELECT DISTINCT(TRIM(Calling_Package)) 
		INTO :PACKAGE1-:PACKAGE%TRIM(%LEFT(&PACKAGE_COUNT.)) FROM 
	/*	WORK.PACKAGE_FUNCTIONS_INS_OUTS; */
		WORK.PGM_META_DATA;
	QUIT;

	/* The dataset WORK.PACKAGES below will list out all packages that exist in the table that houses all our fcmp functions */
	/* IF 50 PACKAGES EXIST, ALL 50 WILL BE LISTED AND THE USER WILL SELECT THE PACKAGE THEY WANT TO WORK WITH */
	/* THE TABLE OF SELECTIONS THAT WILL BE LOADED LOOKS LIKE THIS, ASSUMING YOU HAD THESE FOUR MODELS\PACKAGES */
	/* THE VALUES OF APP, CAR,DEM AND PRC WILL BE LOADED IN THE TASK DROP DOWN. THE VALUES "DUMMY" WILL NOT BE LOADED, ONLY THE COLUMN NAMES */
	/* APP		CAR		DEM		PRC */
	/* DUMMY	DUMMY	DUMMY	DUMMY */
	DATA WORK.PACKAGES;
		%DO I=1 %TO &PACKAGE_COUNT.;
			%QUOTE(&&PACKAGE&I.)='DUMMY';
		%END;
	RUN;

%MEND BUILD_PACKAGE_DROP_DOWNS;

/* END OF MACRO */

%BUILD_PACKAGE_DROP_DOWNS /* EXECUTE THE MACRO WE JUST BUILT */

/* IN OUR PROCESS WE CREATE MACRO VARIABLES, BELOW WILL DELETE THESE VARIABLES. WE DO THIS SO WE DON'T HAVE "OLD" VALUES LOADED INTO MACROS */
/* BOTH MACROS DELVARS AND DELETETARGETS CLEAN OUT ALL MACRO VARIABLES THAT BEGIN WITH "VARS_FROM_OTHER_SEGMENTS" OR "TARGETVARS"   */
%macro delvars;
	data vars;
		set sashelp.vmacro;
	run;

	data _null_;
		set vars;
		temp=lag(name);

		if substr(name, 1, 24)='VARS_FROM_OTHER_SEGMENTS' then
			call execute('%symdel '||trim(left(name))||'/ NOWARN;');
	run;

%mend delvars;

%macro deleteTargets;
	data vars;
		set sashelp.vmacro;
	run;

	data _null_;
		set vars;
		temp=lag(name);

		if substr(name, 1, 10)='TARGETVARS' then
			call execute('%symdel '||trim(left(name))||'/ NOWARN;');
	run;

%mend deleteTargets;

%MACRO BUILD_VAR_DROP_DOWNS;
	/* START OF MACRO */
%LET CP_COUNT=0;
	%CREATE_FUNCTION_INFORMATION   /* CALL ANOTHER MACRO */

	/* BELOW WILL DELETE ANY MACRO VARIABLES THAT ARE NAMED IN THIS FORMAT: "VARS_FROM_OTHER_SEGMENTS" , WE DO THIS SO THAT ERRANT MACRO VARIABLES ARE */
	/* NOT FLOATING AROUND. BY DELETING EVERY RUN WE VERIFY THAT NO VARIABLES ARE CARRIED OVER FROM THE PREVIOUS RUN*/

%delvars

	/* Below go grab the variables from the models LIKE: LTV.PRODUCTS OR CRD.DEFAULTS  AND ADD THEM TO VARIABLES  DROP DOWN LIST */
	/* THE MACRO VARIABLE PACKAGES_TO_INCLUDE IS CREATED IN OUR TASK A_GettingStarted. THIS MACRO &PACKAGES_TO_INCLUDE.  WILL HOLD A VALUE SOMETHING LIKE 'DEM','CRD','APP','PRC' */
	/* BELOW COUNTS THE NUMBER OF CALLING PACKAGE FUNCTIONS THAT WE SHOULD ADD IN THE DROP DOWN IN ADDITION TO VARIABLES FROM OUR SOURCE(MODEL) TABLE */
	PROC SQL;
	SELECT COUNT(DISTINCT(CallingPackage_Function)) INTO :CP_COUNT FROM 
		WORK.PACKAGE_FUNCTIONS_INS_OUTS where inputVariable 
		NOT=trim(CALLING_PACKAGE)||".DUMMY" and TRIM(CALLING_PACKAGE) 
		in (&PACKAGES_TO_INCLUDE.);

	/* IF COUNT IS GREATER THAN 1 THEN CREATE MULTIPLE VARIABLES THIS WAY: VARS_FROM_OTHER_SEGMENTS1-:VARS_FROM_OTHER_SEGMENTS%TRIM(%LEFT(&CP_COUNT.)) */

	%if &CP_COUNT. > 1 %then
		%do;
			SELECT DISTINCT("'"||TRIM(CallingPackage_Function)||"'n") INTO :VARS_FROM_OTHER_SEGMENTS1-:VARS_FROM_OTHER_SEGMENTS%TRIM(%LEFT(&CP_COUNT.)) 
				FROM WORK.PACKAGE_FUNCTIONS_INS_OUTS where inputVariable 
				NOT=trim(CALLING_PACKAGE)||".DUMMY" and TRIM(CALLING_PACKAGE) 
				in (&PACKAGES_TO_INCLUDE.);
		%end;

	/* IF COUNT = 1 THEN CREATE ONE VARIABLE CALLED VARS_FROM_OTHER_SEGMENTS1 */

	%if &CP_COUNT.=1 %then
		%do;
			SELECT DISTINCT("'"||TRIM(CallingPackage_Function)||"'n") 
				INTO :VARS_FROM_OTHER_SEGMENTS1 FROM WORK.PACKAGE_FUNCTIONS_INS_OUTS where 
				inputVariable NOT=trim(CALLING_PACKAGE)||".DUMMY" and TRIM(CALLING_PACKAGE) 
				in (&PACKAGES_TO_INCLUDE.);
		%end;
	quit;

	/* The table WORK.SOURCE_VARIABLES is created to support a drop down for the user to select variables they would like to include in their transfromation*/
	/* If user has elected to allow other model variables in, the table could look something like this */
	/***********                  The table  WORK.SOURCE_VARIABLES could create a drop down that looks something like below                                   ****************** /
	/* sale (From SASHelp.PriceData) */
	/* price (From SASHelp.PriceData) */
	/* discount (From SASHelp.PriceData) */
	/* cost (From SASHelp.PriceData) */
	/* price1 (From SASHelp.PriceData) */
	/* price2 (From SASHelp.PriceData) */
	/* price3 (From SASHelp.PriceData) */
	/* APP.VAR1_SUM1_2 (From APP Package\model) */
	/* CAR.VIDEO_VAR1_FOR_CAR (From CAR Package\model) */
	/* DEM.ISO_PLUS_POPPLUS5 (From DEM Package\model)	 */
	/* PRC.PRC_VIDEO_VARA (From PRC Package\model) */
	DATA WORK.SOURCE_VARIABLES;
		SET  &MySource_Table. (obs=1);

		/* source table is the table the user selected as teh table to be used to build their transformations from. Using our example */
		/* the value of &MySource_Table. would equal SASHelp.PriceData */

		%if &CP_COUNT. > 0 %then
			%do;

				%DO I=1 %TO &CP_COUNT.;
					%QUOTE(&&VARS_FROM_OTHER_SEGMENTS&I.)='DUMMY';
				%END;
			%end;
	RUN;

%MEND BUILD_VAR_DROP_DOWNS;

/* END OF MACRO */
%MACRO SELECTED_PACKAGE_DROP_DOWN;
	/* START OF MACRO */
	/* THE PURPOSE OF THIS MACRO IS TO CREATE A TABLE TO HOLD THE NAME OF THE MODEL THE ANALYST IS WORKING ON */
	/* USING OUR EXAMPLE ABOVE THE VALUE OF &WORKING_ON_MODEL. = PRC */
	DATA WORK.PACKAGE_SELECTED;
		&WORKING_ON_MODEL.='Model we are working on';
	RUN;

%MEND SELECTED_PACKAGE_DROP_DOWN;

/* END OF MACRO */


%macro deleteTblLibs;
	data vars;
		set sashelp.vmacro;
	run;

	data _null_;
		set vars;
		temp=lag(name);

		if substr(name, 1, 15)='LIBS_AND_TABLES' then
			call execute('%symdel '||trim(left(name))||'/ NOWARN;');
	run;

%mend deleteTblLibs;


%macro CreateListLibs_Tbl;

%deleteTblLibs;

proc sql;
 create table work.tmpTable_A as
select libname, memname, memtype from dictionary.tables;
quit;

DATA WORK.TBL_LIB_FOR_TESTING_ONLY;
SET work.tmpTable_A;
where (upcase(libname) not in ('MAPS','MAPSSAS','MAPSGFK')  AND MEMTYPE='DATA'); 

if (upcase(libname) = 'SASHELP' and upcase(memname) not in ('DEMOGRAPHICS','APPLIANC','PRICEDATA')) THEN DELETE; 

keep libname memname;
run;
			
				
proc sql;
 select COUNT(*) INTO :TBL_LIBS_COUNT from WORK.TBL_LIB_FOR_TESTING_ONLY;
 select ("'"||TRIM(libname)||"."||TRIM(MEMNAME)||"'n") INTO :LIBS_AND_TABLES1-:LIBS_AND_TABLES%TRIM(%LEFT(&TBL_LIBS_COUNT.))  from WORK.TBL_LIB_FOR_TESTING_ONLY; 
QUIT;


DATA WORK.DROP_DOWN_LIBS_TBLS;

			%DO I=1 %TO &TBL_LIBS_COUNT.;
				%QUOTE(&&LIBS_AND_TABLES&I.)='DUMMY';
			%END;

RUN;

%mend CreateListLibs_Tbl;

/* The macro below will create drop down variables for a specific package (model)  */
%MACRO BUILD_VAR_DROP_DOWNS_USING_PGM;
	/* START OF MACRO */
%LET CP_COUNT=0;
 /* 	%CREATE_FUNCTION_INFORMATION  CALL ANOTHER MACRO */

	/* BELOW WILL DELETE ANY MACRO VARIABLES THAT ARE NAMED IN THIS FORMAT: "VARS_FROM_OTHER_SEGMENTS" , WE DO THIS SO THAT ERRANT MACRO VARIABLES ARE */
	/* NOT FLOATING AROUND. BY DELETING EVERY RUN WE VERIFY THAT NO VARIABLES ARE CARRIED OVER FROM THE PREVIOUS RUN*/

%delvars

	/* Below go grab the variables from the models LIKE: LTV.PRODUCTS OR CRD.DEFAULTS  AND ADD THEM TO VARIABLES  DROP DOWN LIST */
	/* THE MACRO VARIABLE PACKAGES_TO_INCLUDE IS CREATED IN OUR TASK A_GettingStarted. THIS MACRO &PACKAGES_TO_INCLUDE.  WILL HOLD A VALUE SOMETHING LIKE 'DEM','CRD','APP','PRC' */
	/* BELOW COUNTS THE NUMBER OF CALLING PACKAGE FUNCTIONS THAT WE SHOULD ADD IN THE DROP DOWN IN ADDITION TO VARIABLES FROM OUR SOURCE(MODEL) TABLE */
	PROC SQL;
	SELECT COUNT(DISTINCT(CallingPackage_Function)) INTO :CP_COUNT FROM 
		WORK.PGM_Meta_Data where inputVariable 
		NOT=trim(CALLING_PACKAGE)||".DUMMY" and TRIM(CALLING_PACKAGE) 
		in (&PACKAGES_TO_INCLUDE.);

	/* IF COUNT IS GREATER THAN 1 THEN CREATE MULTIPLE VARIABLES THIS WAY: VARS_FROM_OTHER_SEGMENTS1-:VARS_FROM_OTHER_SEGMENTS%TRIM(%LEFT(&CP_COUNT.)) */

	%if &CP_COUNT. > 1 %then
		%do;
			SELECT DISTINCT("'"||TRIM(CallingPackage_Function)||"'n") INTO :VARS_FROM_OTHER_SEGMENTS1-:VARS_FROM_OTHER_SEGMENTS%TRIM(%LEFT(&CP_COUNT.)) 
				FROM WORK.PGM_Meta_Data where inputVariable 
				NOT=trim(CALLING_PACKAGE)||".DUMMY" and TRIM(CALLING_PACKAGE) 
				in (&PACKAGES_TO_INCLUDE.);
		%end;

	/* IF COUNT = 1 THEN CREATE ONE VARIABLE CALLED VARS_FROM_OTHER_SEGMENTS1 */

	%if &CP_COUNT.=1 %then
		%do;
			SELECT DISTINCT("'"||TRIM(CallingPackage_Function)||"'n") 
				INTO :VARS_FROM_OTHER_SEGMENTS1 FROM WORK.PGM_Meta_Data where 
				inputVariable NOT=trim(CALLING_PACKAGE)||".DUMMY" and TRIM(CALLING_PACKAGE) 
				in (&PACKAGES_TO_INCLUDE.);
		%end;
	quit;

	/* The table WORK.SOURCE_VARIABLES is created to support a drop down for the user to select variables they would like to include in their transfromation*/
	/* If user has elected to allow other model variables in, the table could look something like this */
	/***********                  The table  WORK.SOURCE_VARIABLES could create a drop down that looks something like below                                   ****************** /
	/* sale (From SASHelp.PriceData) */
	/* price (From SASHelp.PriceData) */
	/* discount (From SASHelp.PriceData) */
	/* cost (From SASHelp.PriceData) */
	/* price1 (From SASHelp.PriceData) */
	/* price2 (From SASHelp.PriceData) */
	/* price3 (From SASHelp.PriceData) */
	/* APP.VAR1_SUM1_2 (From APP Package\model) */
	/* CAR.VIDEO_VAR1_FOR_CAR (From CAR Package\model) */
	/* DEM.ISO_PLUS_POPPLUS5 (From DEM Package\model)	 */
	/* PRC.PRC_VIDEO_VARA (From PRC Package\model) */
	DATA WORK.SOURCE_VARIABLES;
		SET  &MySource_Table. (obs=1);

		/* source table is the table the user selected as teh table to be used to build their transformations from. Using our example */
		/* the value of &MySource_Table. would equal SASHelp.PriceData */

		%if &CP_COUNT. > 0 %then
			%do;

				%DO I=1 %TO &CP_COUNT.;
					%QUOTE(&&VARS_FROM_OTHER_SEGMENTS&I.)='DUMMY';
				%END;
			%end;
	RUN;

%MEND BUILD_VAR_DROP_DOWNS_USING_PGM;


%macro append_check;

/* if we have transforms (&rec_count >0) and that variable transformation does not already exist then do the following */
/* 1. Append new transform to metadata */
/* 2. Export metadata to csv file */
/* 3. Create copy of metadata table before we re-import table. We do this for the option of rolling back */
/* 4. Delete metadata before re-importing metadata table (csv created in the proc export step) */
/* 5. Re-import metadata table (csv)  */
/* 6. Create constraints on our metadata table that does not allow missing values for key columns */
/* 7. Check record count of metadata table to verify the table was imported properly */
/* 8. Print statemetn to log based of record count test for metadata table and check to see if transform variable already exists */
/* 9. If our metadata table is good (via record check) then delete our back table called work.PGM_Meta_data_temp */

%if (&rec_count. > 0 and &does_transform_exist. = 0) %then
%do;
PROC APPEND BASE=WORK.PGM_Meta_Data DATA=work.one_transform_B;QUIT;

PROC EXPORT DBMS=CSV DATA=WORK.PGM_Meta_Data replace
  OUTFILE="/home/sasdemo/Auto2020Funcs/MetaData_in_TEXT.csv";
RUN;


/* Below will save a copy of our Metadata before we delete it prior to re-importing it */
Data work.PGM_Meta_data_temp;set WORK.PGM_Meta_Data;run; 
proc delete data=WORK.PGM_Meta_Data;run;

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

/* %prn(WORK.PGM_Meta_Data,100,); */
Proc sql;
select count(*) into :check_good_table from PGM_Meta_Data;
quit;

	%if &check_good_table. > 0 %then %do;
	
		proc delete data=work.PGM_Meta_data_temp;run;
		proc delete data=work.one_transform_B;
		proc delete data=work.one_transform_A;

		data _null_;
			file print ods;
			text="Succesfully created and added transformation";
			put text;
		run;
	
	%end;
	%else %do;
	
	data _null_;
		file print ods;
		text="Re-creation of table work.PGM_Meta_data table failed. A copy of the table before the failed recreation can be found at work.PGM_Meta_data_temp";
		put text;
	run;
	
	%end;
%end;
%else
%do;

	%if &does_transform_exist. > 0 %then 
		%do;
			data _null_;
				file print ods;
				text="Transform variable already exists, no transform added";
				put text;
			run;
		%end;
	%else 
		%do;
			data _null_;
				file print ods;
				text="Transform table does not exist";
				put text;
			run;
		%end;
%end;

%mend append_check;