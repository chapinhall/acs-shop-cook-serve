/* This file was downloaded from http://www2.census.gov/acs2012_1yr/summaryfile/UserTools/ on 1/3/2014.
	It has been renamed (from "SF_All_Macro.sas") and modified from its original form to improve its digestibility */

/* The macros defined here are:
	* AnyGeo - reads in and labels the geography files
	* TableShell - based on table id argument -- obtains relevant metadata from the SequenceNumberTableNumberLookup file
	* TablesBySeq - based on sequence number argument -- obtains relevant metadata from the SequenceNumberTableNumberLookup file
	* ReadDataFile - based on type (which is either "e" for estimate or "m" for margin of error, geography, and sequence arguments -- 
		Reads the corresponding file into a SAS data set. The header for these files is ... put " 	   FILEID  ='File Identification' FILETYPE='File Type' STUSAB  ='State/U.S.-Abbreviation (USPS)' CHARITER='Character Iteration' SEQUENCE='Sequence Number' LOGRECNO='Logical Record Number'
		This function was written by a person who is not familiar with macro programming in SAS
	* AllTableShells - takes no arguments, simply separates the metadata by table id. I'm surprised that this function would work, given that it calls on function "TableShells()" whereas only a "TableShell" function has been defined.
	* AllSeqs - takes a geography argument -- calls the AnyGeofile, and then loops through all 178 sequences
	* CallSt
	* GetData
	
*/

DM "clear log";
LIBNAME stubs '/pc_common/dataproducts/2012';
LIBNAME sas '/pc_common/dataproducts/2012/code/sum_data';

%macro AnyGeo(geography);
	/*  All ACS geographic Summary File headers have the same following layout
		See Technical documentation for more information on geographic header files
		and additional ACS Geography information  									*/
	data work.&geography;
			 /*Location on geographic header file saved to from;											*/
		  INFILE "/tab4/sumfile/prod/2012/geo/&geography..txt" MISSOVER TRUNCOVER LRECL=500;

		FILEID  ='File Identification'         	STUSAB   ='State Postal Abbreviation'
		SUMLEVEL='Summary Level'            	COMPONENT='geographic Component'
		LOGRECNO='Logical Record Number'	    US       ='US'
		REGION  ='Region'						DIVISION ='Division'
		STATECE ='State (Census Code)'			STATE    ='State (FIPS Code)'
		COUNTY  ='County'						COUSUB   ='County Subdivision (FIPS)'
		PLACE   ='Place (FIPS Code)'			TRACT    ='Census Tract'
		BLKGRP  ='Block Group'					CONCIT   ='Consolidated City'
		CSA     ='Combined Statistical Area'	METDIV  ='Metropolitan Division'
		UA      ='Urban Area'                   UACP    ='Urban Area Central Place'
		VTD     ='Voting District'				ZCTA3  ='ZIP Code Tabulation Area (3-digit)'
		SUBMCD  ='Subbarrio (FIPS)'				SDELM  ='School District (Elementary)'
		SDSEC   ='School District (Secondary)'	SDUNI  ='School District (Unified)'
		UR      ='Urban/Rural'					PCI    ='Principal City Indicator'
		TAZ     ='Traffic Analysis Zone'		UGA    ='Urban Growth Area'
		GEOID   ='geographic Identifier'		NAME   ='Area Name' 					    
		AIANHH  ='American Indian Area/Alaska Native Area/Hawaiian Home Land (Census)'
		AIANHHFP='American Indian Area/Alaska Native Area/Hawaiian Home Land (FIPS)'
		AIHHTLI ='American Indian Trust Land/Hawaiian Home Land Indicator'
		AITSCE  ='American Indian Tribal Subdivision (Census)'
		AITS    ='American Indian Tribal Subdivision (FIPS)'
		ANRC    ='Alaska Native Regional Corporation (FIPS)'
		CBSA    ='Metropolitan and Micropolitan Statistical Area'
		MACC    ='Metropolitan Area Central City'	
		MEMI    ='Metropolitan/Micropolitan Indicator Flag'
		NECTA   ='New England City and Town Combined Statistical Area'
		CNECTA  ='New England City and Town Area'
		NECTADIV='New England City and Town Area Division'
		CDCURR  ='Current Congressional District'
		SLDU    ='State Legislative District Upper'	
		SLDL    ='State Legislative District Lower'
		ZCTA5   ='ZIP Code Tabulation Area (5-digit)'
		PUMA5   ='Public Use Microdata Area - 5% File'
		PUMA1   ='Public Use Microdata Area - 1% File';
		INPUT
			FILEID    $ 1-6			STUSAB    $ 7-8			SUMLEVEL  $ 9-11							
			COMPONENT $	12-13		LOGRECNO  $ 14-20		US        $ 21-21  
			REGION    $ 22-22		DIVISION  $ 23-23		STATECE   $ 24-25							
			STATE     $ 26-27		COUNTY    $ 28-30		COUSUB    $ 31-35 
			PLACE     $	36-40		TRACT     $	41-46		BLKGRP    $ 47-47							
			CONCIT    $ 48-52		AIANHH    $ 53-56		AIANHHFP  $ 57-61
			AIHHTLI   $ 62-62		AITSCE    $ 63-65		AITS      $ 66-70							
			ANRC      $ 71-75		CBSA      $ 76-80   	CSA       $ 81-83
			METDIV    $ 84-88		MACC      $ 89-89		MEMI      $ 90-90							
			NECTA     $	91-95   	CNECTA    $ 96-98		NECTADIV  $ 99-103	
			UA        $ 104-108		UACP      $ 109-113		CDCURR    $ 114-115						    
			SLDU      $ 116-118		SLDL      $ 119-121 	VTD       $ 122-127
			ZCTA3     $ 128-130		ZCTA5     $ 131-135		SUBMCD    $ 136-140						    
			SDELM     $ 141-145	    SDSEC     $ 146-150	    SDUNI     $	151-155
			UR        $ 156-156		PCI       $ 157-157		TAZ       $ 158-163							
			UGA       $ 164-168		PUMA5     $ 169-173		PUMA1     $	174-178
			GEOID     $ 179-218		NAME      $ 219-418 					      ;
	run;
%mend;	

%macro TableShell(tblid);
	/*The TableShell Marco is a basic SAS set statement that will get basic metadata 																			
	  information about ACS Detailed Tables	from the SequenceNumberTableNumberLookup dataset by table id
	  see chapter 5 and 6 of technical documentation for more information				 */
	data work.Table_&tblid;
	  set stubs.SequenceNumberTableNumberLookup;
	   /*Remove single quotes from metadata (Note: This is done to simplify reading in the 
		 metadata																		 */
	   title=tranwrd(title, "'", "''");
	   /*Remove non data lines these lines end with .7 and do NOT have a linking 
		 field in the data files they are made available for readability (they can be kept)*/
	   if index(order,".") then order = ".";
	   if tblid=upcase("&tblid") then output;
	run;
%mend;

%macro TablesBySeq(Seq);
	/*The TablesBySeq Marco is a basic SAS set statement that will get basic metadata 																			
	  information about ACS Detailed Tables	from the SequenceNumberTableNumberLookup dataset by sequence number
	  see chapter 5 and 6 of technical documentation for more information				   */
	data work.Seq_&seq;
	  set stubs.SequenceNumberTableNumberLookup;
	   /*Remove single quotes from metadata (Note: This is done to simplify reading in the 
		 metadata																		   */
	   title=tranwrd(title, "'", "''");
	   /*Remove non data lines these lines end with .7 and do NOT have a linking 
		 field in the data files they are made available for readability (they can be kept)*/
	   if index(order,".") then order = ".";
	   if seq=upcase("&seq") then output;
	run;
%mend;


%macro ReadDataFile(type,geo,seq);
	/*The ReadDataFile is a macro that will generate SAS code for a specific estimate type,
	  a specific geography, by sequence number.  The macro will run the code as well reading
	  the data into the SAS work directory by estimate type, geography and sequence number.  */

	/*rootdir is a directory (that must exist) to store the generated SAS code				 */
	%let rootdir=/pc_common/dataproducts/2012/code/;
	/*Start to generate SAS code from the metadata file created from the TablesBySeq macro   */
	data _null_;
	  set work.Seq_&seq;
	  /*Save code to FILE statement below*/
		FILE "&rootdir&type&geo._&seq..sas" ;
		/*For the first observation of the metadata dataset start to write out code to read in
		  the first 6 fields of data summary files, this is consistent for every summary file
		  see Chapter 2 of the technical documentation 										 */
		if _n_ =1 then 		 do;
			put "TITLE ""&type.20121&geo.&seq.000"";";
			put "DATA work.SF&type.&seq.&geo;";
			put " ";
			put "	LENGTH FILEID   $6";
			put "		   FILETYPE $6";
			put "		   STUSAB   $2";
			put "		   CHARITER $3";
			put "		   SEQUENCE $4";
			put "		   LOGRECNO $7;";
			put " ";
			put "INFILE '/tab4/sumfile/prod/2012/data/&type.20121&geo.&seq.000.txt' DSD TRUNCOVER DELIMITER =',' LRECL=3000;";
			put " ";
			put "LABEL FILEID  ='File Identification'";
			put "      FILETYPE='File Type'  ";
			put " 	   STUSAB  ='State/U.S.-Abbreviation (USPS)'";
			put " 	   CHARITER='Character Iteration'";
			put " 	   SEQUENCE='Sequence Number'";
			put " 	   LOGRECNO='Logical Record Number'";
			put " ";
		 end;
																	*/
		if position ^=. then put " ";
		/*If the order is blank than the title is a non-data line, Table Title, Table Universe or non
		  data line; these lines are written out but commented out 									*/
		if order =.     then put "/*" title "*/";
		/*If we are at the first line of the table put in a space for readability  					*/
		if order =1     then put " ";
		/*If the order is not blank then write out SAS code for LABEL								*/
		if order ^=. then	 do;
			lineout= compress(tblid)||"&type"||compress(order)||"='"||trim(title)||"'";
			put	lineout;
		end;
	run;

	/*Now write out the "INPUT" section of the SAS code to read in the data							*/
	data _null_;
	  set work.Seq_&seq;
	   FILE "&rootdir&type&geo._&seq..sas" MOD;
		/*Again first 6 fields are constants like the LABEL section									*/
		if _n_ =1 then do;
			put ";";			put " ";		put " ";
			put "INPUT";		put " ";		
			put "FILEID   $ ";
			put "FILETYPE $ ";         
			put "STUSAB   $ ";   
			put "CHARITER $ "; 
			put "SEQUENCE $ "; 
			put "LOGRECNO $ "; 
		end;
		if order =1 then put " ";
		/*INPUT the table data																		*/
		if order ^=. then 	 do;
			lineout= compress(tblid)||"&type"||compress(order);
			put	lineout;
		end;
	run;

	data _null_;
		/*Finish up the program																		*/
	   FILE "&rootdir&type&geo._&seq..sas" MOD;
			put ";"; put "RUN;";
	run;
	/***********************

	EDIT
	**********************/
	/*Run the generated code																		*/
	%include "&rootdir&type&geo._&seq..sas";
%mend;

%macro AllTableShells;
	/*The AllTableShells macro will divide up the SequenceNumberTableNumberLookup dataset into separate
	  metadata files by table ID for more information on the SequenceNumberTableNumberLookup dataset
	  of the technical documentation												
	  NOTE:  This is just an example of getting multiple table shells				*/
	/*Create a dataset with distinct table ids 										*/
	proc sql;
		create table work.tblids as select distinct(tblid) from stubs.SequenceNumberTableNumberLookup;;
	quit;

	/*Call the TableShells macro with each distinct Table ID						*/
	data _null_;
	  set work.tblids;
		call execute('%TableShells(' || compress(tblid) || ')');
	run;

%mend;

%macro AllSeqs(geo);
	/*The AllSeqs Macro serves as a control to read in data for a single geography 	
	  by passing in the two digit alpha state abbreviation per sequence number		*/
	/*Read in the geographic header file for a single geography 					*/
	*********************
	/*

	EDIT
	*/;

	%AnyGeo (g20121&geo);
	/*The do loop will create a sequence number; valid values are 1 to 145 if you 
	  only want a table in sequence 56 then set the do loop to be %do x=56 %to 56;   
	  and that will be the only sequence number read in to SAS 						*/
	%do x=1 %to 178;
		%let var=000&x;
		%let seq = %substr(&var,%length(&var)-3,4);
		/*Note:  The Sequence number IS 0 filled									*/
		/*Get the metadata for the sequence number created by the do loop			*/
		%TablesBySeq(&seq);
		/*Generate SAS code to read in the estimates, margin of error, and standard 
		  error for the geography passed into the AllSeqs macro and the sequence 
		  number created in the do loop above   									*/
		%ReadDataFile(e,&geo,&seq);
		%ReadDataFile(m,&geo,&seq);

		/*Merge the Geography file created from the %AnyGeo macro and the 3 types  
		  of estimates from the %ReadDataFile macro into a single file by geography */
	/**************************************

	EDIT COMMENT OUT
		**/
	/*    data sas.SF&seq&geo;
		  merge  g20121&geo(IN=g) SFe&seq&geo(IN=x) SFm&seq&geo(IN=y);
			by logrecno;
		run;
	*/
	%end;

%mend;
%macro CallSt;
	/*The CallSt macro is used to generate State 2 digit abbreviations see Appendix B
	  of the technical documentation for a list of state codes							*/
	/*The ACS summary file contains state 2 digit numeric codes from 1 to 72  
	  Note:  FIPS codes are NOT sequential so if a code does not exist such as 71  
			 The call execute statement will NOT run because there is no state abbrev	*/
	/*If you want just a single state, such as Alabama set the do statement to start 
	  and end at that state code such as %do i=1 %to 1; for Alabama 					*/
	%do i=0 %to 0;
		data _null_;
		  stabbrv=compress(trim(lowcase(FIPSTATE(&i))));
			/*Note:  DC and PR are not covered in FIPS state function, and the two digit 
			function is not required to be 0 filled		*/
			if &i=0  then stabbrv = 'us';
			if &i=11 then stabbrv = 'dc';
			if &i=72 then stabbrv = 'pr';
			/*FIPS Codes 60 and 66 are fpr American Samoa and Guam */
			if &i>56 and &i<72 then stabbrv = "--";
			/*If the function returns a state abbreviation then run the AllSeqs macro			*/
			if stabbrv ^= "--" then do;
				call execute('%AllSeqs(' || compress(stabbrv) || ')');				
			end;
		run;
	%end;
%mend;
%macro GetData(seq,tblid,geo);
	/*The GetData macro will grab an individual tables estimates, margin of errors and
	  standard errors once it is read into SAS through the ReadDataFile macro 	
	  NOTE:  This macro is just an example on how to get just an individual table     */

	/*	Get the maximum number of lines in the table so it can be used in a keep 
		statement	*/

	proc sql;
		select max(order) into :tot from stubs.SequenceNumberTableNumberLookup where tblid="&tblid";
	quit;

	/*Remove spaces from the maximum number of lines variable						  */
	%let max = %trim(&tot);
	/*Separate a single tables estimates, margin of errors, and standard errors from
	  the rest of the tables in the sequence										  */
	data work.test_&tblid (keep = &tblid.e1-&tblid.e&max &tblid.m1-&tblid.m&max);
	 set work.SF&seq&geo;
	run;
%mend;
*%GetData(0010,B01001,al);
%CallSt;
