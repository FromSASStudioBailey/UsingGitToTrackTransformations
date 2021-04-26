/* SASHELP.APPLIANC */
/* SASHELP.DEMOGRAPHICS */
/* SASHELP.CARS */
/* SASHELP.PRICEDATA */

/* PROC FCMP INLIB=Auto2020.Trnsfrms LISTFUNCS; RUN; */
/* %prn(WORK.Package_Functions_Ins_Outs,200,); */

/* PROC DATASETS LIB=AUTO2020 KILL;RUN;QUIT; */


libname AUTO2020 '/home/sasdemo/Auto2020Funcs/FCMP_Table';
/* libname DATA2020 '/home/sasdemo/CodeTable/Data'; */


/* LIBNAME AUTO2020 clear;run; */

proc fcmp outlib=AUTO2020.TRNSFRMS.APP;
	subroutine StartOfAPP(StartOfAPP,DUMMY) ;
	outargs StartOfAPP;
	endsub;
quit;

proc fcmp outlib=AUTO2020.TRNSFRMS.DEM;
	subroutine StartOfDEM(StartOfDEM,DUMMY) ;
	outargs StartOfDEM;
	endsub;
quit;

proc fcmp outlib=AUTO2020.TRNSFRMS.CAR;
	subroutine StartOfCAR(StartOfCAR,DUMMY) ;
	outargs StartOfCAR;
	endsub;
quit;

proc fcmp outlib=AUTO2020.TRNSFRMS.PRC;
	subroutine StartOfPRC(StartOfPRC,DUMMY) ;
	outargs StartOfPRC;
	endsub;
quit;




