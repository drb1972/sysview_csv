/* --- ----- REXX ----------------------------------------------- --- */
/*                                                                    */
/* --- CSVGEN - ReportWriter Output to CSV ---                        */
/*                                                                    */
/* --- ---------------------------------------------------------- --- */
tinit = time(s)

/* --- INITIALIZATION ------------------------------------------- --- */

reportStructure. = 0                              /* report structure */

outputData.0 = 0                            /* number of output lines */

dataLength = 1023               /* when removing formatting character */

/* --- Optional parameters and initial values ------------------- --- */
optParm. = 0                                   /* optional parameters */
optParm.1 = 'VS'                                   /* value separator */
optParm.2 = 'DS'                                 /* decimal separator */
optParm.0 = 2                             /* number of optional parms */
DS = '.'                                             /* decimal point */
VS = ','                                           /* value separator */
change. = 0                                /* optional parms changed? */

/* --- Input arguments ------------------------------------------ --- */
/*     - ddIn - DDNAME of ReportWriter's output                       */
/*     - ddOut - DDNAME of .csv output                                */
/*     - optParm - optional parameters                                */
/* --- ---------------------------------------------------------- --- */
parse arg ddIn ddOut optParm                  /* read input arguments */
lddIn = length(ddIn)               /* check ddIn and ddOut is present */
lddOut = length(ddOut)
if (lddIn = 0 | lddOut = 0) then signal inpError       /* input error */
retC = setOptParm(optParm)                 /* set optional parameters */

/* --- Input read ----------------------------------------------- --- */
/* "execio * diskr "ddIn" (stem inputData. finis)"         read input */
/* dxr */
   rr = 0
/*   input_file  = 'CICS031.TXT' */
   /* dxr */ say '500.000 records'
   input_file  = 'report100000.txt'
   do while lines(input_file) \= 0
    rr = rr+1
    inputData.rr = linein(input_file)
   end
   inputData.0 = rr

/* --- Remove formatting characters ----------------------------- --- */
/*     - Strip formatting characters (first column) of inputData      */
/* --- ---------------------------------------------------------- --- */

do i = 1 to inputData.0
/* dxr  inputData.i = right(inputData.i,dataLength)  */ /* strip first column */
/* dxr */ parse var inputData.i 1 trash 2 rest
          inputData.i = rest
 end
/* --- Copy report ---------------------------------------------- --- */
/* "execio * diskw rwo (stem inputData. finis)"  copy input to output */

/* --- MAIN PROCESSING ------------------------------------------ --- */

/* --- Parse report --------------------------------------------- --- */
call parseReport                                /* parse given report */
/* --- Write output --------------------------------------------- --- */
call writeOutput                                 /* create CSV report */

/* --- FINAL PROCESSING ----------------------------------------- --- */

/* --- Write output --------------------------------------------- --- */
/* "execio * diskw "ddOut" (stem outputData. finis)"  */ /* write CSV */

output_file = 'csv.txt'
do rr = 1 to outputData.0
  call lineout output_file, outputData.rr
end
call lineout output_file


/* --- EXIT ----------------------------------------------------- --- */
call exit_dxr
exit 0

/* --- ---------------------------------------------------------- --- */

/* --- UTILS ---------------------------------------------------- --- */

/* --- Set optional parameters ---------------------------------- --- */
/*     - Parse optional parameters and set-up variables accordingly.  */
/* --- ---------------------------------------------------------- --- */
setOptParm:
 arg optString                          /* variable parameters string */
 changed = 0                                          /* return value */
 do p = 1 to optParm.0                 /* for all known optinal parms */
   srchString = optParm.p||"="
   position = pos(srchString,optString)     /* parm position in string*/
   if (position <> 0) then                      /* if parm is present */
     do                                 /* get it's value - ONE CHAR! */
       parmValue = substr(optParm,position+length(srchString),1)
       changeValue = 'change.'||optParm.p     /* create change notice */
       retC = value(optParm.p,parmValue)       /* save optional value */
       retC = value(changeValue,1)              /* save change notice */
       changed = changed + 1                     /* number of changed */
     end
 end
 return changed

/* --- ERRORS --------------------------------------------------- --- */

/* --- Argument error ------------------------------------------- --- */
/*     - Wrong or no arguments provided                               */
/* --- ---------------------------------------------------------- --- */
inpError:
 say "Wrong arguments provided."
 say
 say "Usage: CSVGEN <DDIN> <DDOUT> {OPTIONAL PARAMETERS}"
 say "       {OPTIONAL PARAMETERS} - VS - Value separator"
 say "                               DS - Decimal separator"
 say "Optional parameters are one character only!"
 say
 say "Example: CSVGEN CSVIN CSVOUT VS=; DS=,"
 say
 exit 17

/* --- Input can't be parsed ------------------------------------ --- */
/*     - This script can't parse provided ReportWriter's report       */
/* --- ---------------------------------------------------------- --- */
cantParse:
 call exit_dxr
 say "Sorry, this report can't be parsed."
 say
 exit 18

/* --- Delimiter not found -------------------------------------- --- */
/*     - Delimiter was not found where expected                       */
/* --- ---------------------------------------------------------- --- */
delimNotFound:
 call exit_dxr
 say "Delimiter was not found where expected"
 say
 exit 19

/* --- Last line not found -------------------------------------- --- */
/*     - Last line of report data not found                           */
/* --- ---------------------------------------------------------- --- */
lastlineNotFound:
 call exit_dxr
 say "Last line of report data not found"
 say
 exit 20


/* --- ---------------------------------------------------------- --- */
/* --- PARSE INPUT ---------------------------------------------- --- */
/* --- ---------------------------------------------------------- --- */
parseReport: procedure expose reportStructure. inputData.

/* --- Constants for input parsing ------------------------------ --- */
rpColumn = 103                       /* column with REPORT-PAGE field */
rpLength = 22                          /* length of REPORT-PAGE field */
rColumn = 88                          /* column with 'REPORT n' field */
rLength = 10                            /* length of 'REPORT n' field */
rpSeparation = 3             /* number of lines between reports/pages */
eoarField = 54                /* column with End of All Reports field */
eoarLength = 26                 /* length of End of All Reports field */
eoarText = "*** END OF ALL REPORTS ***"

/* --- Get type of reports -------------------------------------- --- */
/*     - Find out type of reports for parsing                         */
/*     - Signal error if other than TAB or TAB2 found                 */
/*     - Assume ERPT200I message is the start of input                */
/*     - Assume ERPT231I message is the end   of input                */
/* --- ---------------------------------------------------------- --- */
lineERPT200I = -1                                 /* ERPT200I message */
lineERPT231I = -1                                 /* ERPT231I message */
reports = -1                                     /* number of reports */
do i = 1 to inputData.0                              /* for all lines */
  if (word(inputData.i,1) = "ERPT200I") then         /* find ERPT200I */
  do
    lineERPT200I = i                                /* ERPT200I found */
    leave                                           /* stop searching */
  end
end
do i = lineERPT200I+1 to inputData.0           /* for following lines */
  if (word(inputData.i,1) = "ERPT231I") then         /* find ERPT231I */
  do
    lineERPT231I = i                                /* ERPT231I found */
    leave                                           /* stop searching */
  end
end

if ((lineERPT200I = -1) | (lineERPT231I = -1)) then
  do                                        /* if header not detected */
    say "Header information not found."
    signal cantParse                                         /* error */
  end
do i = lineERPT200I to lineERPT231I                  /* check reports */
  if (word(inputData.i,1) = "FLASHBACK") then      /* found FLASHBACK */
  do
    reports = 1                                    /* one report only */
    reportStructure.1.reportType = "FLASHBACK"
    leave                              /* there can't be more reports */
  end
  rField = substr(inputData.i,rColumn,rLength)/* get 'REPORT n' field */
  if (word(rField,1) = "REPORT") then
  do
    rep = word(rField,2)                             /* report number */
    reports = max(rep,reports)             /* number of reports found */
    type = word(inputData.i,1)                     /* get report type */
    tmpIndex = i + 1
    subType = word(inputData.tmpIndex,1)          /* possible subtype */
    if (left(subType,length(type)) = type) then type = subType
    reportStructure.rep.reportType = type  /* save to reportStructure */
  end
end
if (reports = -1) then                            /* no reports found */
  do
    say "No reports found."
    signal cantParse                                         /* error */
  end
do i = 1 to reports
  if ((reportStructure.i.reportType <> "TAB") &,/* if other than TAB, */
      (reportStructure.i.reportType <> "TAB2") &,/* TAB2 or FLASHBACK */
      (reportStructure.i.reportType <> "FLASHBACK")) then
    do
      say "Report "i" is of a type "reportStructure.i.reportType
      say "This script can parse TAB, TAB2 and FLASHBACK only"
      signal cantParse                                       /* error */
    end
end

/* --- Get structure of reports --------------------------------- --- */
/*     - Find existing reports and division to pages                  */
/*     - Two sections for reports with different structure            */
/* --- ---------------------------------------------------------- --- */
do i = 1 to inputData.0                         /* for all lines */

  rpField = substr(inputData.i,rpColumn,rpLength)
  if (reportStructure.1.reportType = "FLASHBACK") then /* for FLSHBCK */
  do
    if (word(rpField,3) = "PAGE") then
    do
      commaPos = pos(',',rpField)                   /* Strip comma    */
      /* dxr */ if commaPos > 0 then rpField = delstr(rpField,commaPos,1) 
      pageNumber = word(rpField,4)                  /* page of report */
      /* dxr */ if pageNumber // 100 = 0 then say pageNumber
      reportStructure.1.pageNumber = i              /* save page line */
      reportStructure.0 = 1                        /* only one report */
      reportStructure.1.0 = max(reportStructure.1.0,pageNumber)
    end
  end
  else                            /* for reports other than FLASHBACK */
  do
    if ((word(rpField,1) = "REPORT") & (word(rpField,3) = "PAGE")) then
    do                                       /* get REPORT-PAGE field */
      commaPos = pos(',',rpField)                   /* Strip comma    */
      if commaPos <> 0 then rpField = delstr(rpField,commaPos,1)
      reportNumber = word(rpField,2)              /* number of report */
      pageNumber = word(rpField,4)                  /* page of report */
                              /* store information to reportStructure */
      reportStructure.reportNumber.pageNumber = i
      reportStructure.0 = max(reportStructure.0,reportNumber)
      reportStructure.reportNumber.0 =                                 ,
                          max(reportStructure.reportNumber.0,pageNumber)
    end
  end
end

/* --- Get first delimiter and last line ------------------------ --- */
/*     - Get first delimiter and last line of each report page        */
/*       and save it to reportStructure                               */
/* --- ---------------------------------------------------------- --- */
do i = 1 to reportStructure.0                      /* for all reports */
  do j = 1 to reportStructure.i.0        /* and for all of it's pages */
    line = getLastLine(i,j)                              /* last line */
      if (line <> -1) then reportStructure.i.j.lastLine = line
      else signal lastlineNotFound                           /* error */
    delim = getNextDelimiter(reportStructure.i.j,reportStructure.i.j.lastLine) /* dxr */
      if (delim <> -1) then reportStructure.i.j.firstDelimiter = delim
      else signal delimNotFound                              /* error */
  end
end

/* --- Get columns number and width ----------------------------- --- */
/*     - Reads column structure from first delimiter in report        */
/*       and stores it to reportStructure                             */
/* --- ---------------------------------------------------------- --- */
do i = 1 to reportStructure.0                      /* for all reports */
  fDelim = reportStructure.i.1.firstDelimiter   /* get delimiter line */
                                             /* get number of columns */
  reportStructure.i.columns.0 = words(inputData.fDelim)
  do j = 1 to reportStructure.i.columns.0 /* get width of all columns */
    reportStructure.i.columns.j = wordlength(inputData.fDelim,j)
  end
end

/* --- Return from PARSE INPUT ---------------------------------- --- */
return 0                                                    /* return */

/* --- Functions of PARSE INPUT --------------------------------- --- */

/* --- Is delimiter? -------------------------------------------- --- */
/*     - Check whether given string has structure of delimiter        */
/*       as used in report (contains only spaces and dashes)          */
/* --- ---------------------------------------------------------- --- */
isDelimiter:
  arg str
  if (verify(str,' -') = 0 & pos('-',str) <> 0) then return 1
  else return 0

/* --- Get next delimiter --------------------------------------- --- */
/*     - Returns line number of next delimiter following given line   */
/*     - Return value '-1' means no delimiter found                   */
/* --- ---------------------------------------------------------- --- */
getNextDelimiter:
  arg fLine,lLine
  retLine = -1                                        /* return value */
  do l = fLine to lLine
    if isDelimiter(inputData.l) then            /* if delimiter found */
    do
      retLine = l                        /* store current line number */
      leave
    end
  end
  return retLine

/* --- Get last line of data ------------------------------------ --- */
/*     - Find last line of current page - for data extraction         */
/* --- ---------------------------------------------------------- --- */
getLastLine:
  arg reportN,pageN                                   /* report, page */
  nextPage = pageN + 1                                   /* next page */
  nextReport = reportN + 1                             /* next report */
  retLine = -1                                        /* return value */
  if (reportStructure.reportN.nextPage <> 0) then /* before next page */
    retLine = reportStructure.reportN.nextPage - rpSeparation
  else
  if (reportStructure.nextReport.1 <> 0) then   /* before next report */
    retLine = reportStructure.nextReport.1 - rpSeparation
  else
    retLine = getLastDelimiter()                    /* last data line */
  return retLine

/* --- Get last data delimiter ---------------------------------- --- */
/*     - Returns line number of last delimiter in data for whole      */
/*       report                                                       */
/* --- ---------------------------------------------------------- --- */
getLastDelimiter:
  line = -1                                           /* return value */
  eoaRep = inputData.0                                   /* last line */
  do k = inputData.0 to 1 by -1            /* for all lines backwards */
    eoD = compare(substr(inputData.k,eoarField,eoarLength),eoarText)
    if (eoD = 0) then                         /* if found end of data */
    do
      eoaRep = k
      leave
    end
  end
  /* If eoaRep=inputData.0 eoaR not found*/
  /* continue search for last delimiter */
  do k = eoaRep to 1 by -1
    if isDelimiter(inputData.k) then            /* if delimiter found */
      do
        line = k                         /* store current line number */
        leave
      end
  end
                        /* if k=-1 last delimiter in report not found */
  return line
/* --- End of PARSE INPUT --------------------------------------- --- */

/* --- ---------------------------------------------------------- --- */
/* --- WRITE OUTPUT --------------------------------------------- --- */
/* --- ---------------------------------------------------------- --- */
writeOutput:

/* --- Extract data from each report ---------------------------- --- */
/*     - Get all data from reports and create csv output              */
/* --- ---------------------------------------------------------- --- */
do report = 1 to reportStructure.0                 /* for all reports */
  h1l = reportStructure.report.1.firstDelimiter - 2
  h2l = reportStructure.report.1.firstDelimiter - 1
  header1 = formatOutput(inputData.h1l,report)        /* first header */
  header2 = formatOutput(inputData.h2l,report)       /* second header */
  retC = writeLine2Output(header1)             /* write report header */
  retc = writeLine2Output(header2)             /* write report header */
  do page = 1 to reportStructure.report.0        /* and for all pages */
    do data = reportStructure.report.page.firstDelimiter + 1 to        ,
              reportStructure.report.page.lastLine  /* all data lines */
      if (isDelimiter(inputData.data) = 0) then          /* data only */
        retC = writeLine2Output(formatOutput(inputData.data,report))
    end
  end
end

/* --- Return from WRITE OUPTUT --------------------------------- --- */
return 0

/* --- Functions of WRITE OUPTUT -------------------------------- --- */

/* --- Change decimal separator --------------------------------- --- */
/*     - Use specified decimal separator rather than '.'              */
/* --- ---------------------------------------------------------- --- */
dSepChange:
  arg str
  if (verify(str,"0123456789.") = 0) then ,           /* is numeric ? */
    str = translate(str,DS,'.')                  /* replace . with DS */
  return str

/* --- Format one line for output ------------------------------- --- */
/*     - Formats one line of input data into csv format               */
/* --- ---------------------------------------------------------- --- */
formatOutput:
  arg string,repN      /* what and for which report we are formatting */
  cIndex = 1                                         /* parsing index */
  outpLine = ""
  do c = 1 to reportStructure.repN.columns.0       /* for all columns */
    element = strip(substr(string,cIndex,,        /* get data element */
                           reportStructure.repN.columns.c+1))
    if change.DS then element = dSepChange(element)  /* change decSep */
    outpLine = outpLine||element||VS      /* add one column to output */
    cIndex = cIndex + reportStructure.report.columns.c + 1    /* next */
  end
  outpLine = left(outpLine,length(outpLine)-1)       /* strip last VS */
  return outpLine

/* --- Write output line ---------------------------------------- --- */
/*     - Writes one line to output stem                               */
/* --- ---------------------------------------------------------- --- */
writeLine2Output:
  arg string                                           /* output line */
  outputIndex = outputData.0 + 1    /* index of last written line + 1 */
  outputData.outputIndex = string;             /* copy line to output */
  outputData.0 = outputIndex                     /* current last line */
  return outputIndex
/* --- End of WRITE OUPTUT -------------------------------------- --- */

/* dxr */
exit_dxr:
  tend = time(s)
  time = tend - tinit
  say '['||time()||'] Starting '
  say '['||time()||'] Finish after 'time 's.'
  say ' Number of records 'inputData.0
return



/* --- ---------------------------------------------------------- --- */
/* --- -------------------------- END --------------------------- --- */
/* --- ---------------------------------------------------------- --- */
