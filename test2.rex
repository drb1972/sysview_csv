/* rexx */
   drop inputData.
   rr = 0
/*   input_file  = 'CICS031.TXT' */
   input_file  = 'report.txt'
   do while lines(input_file) \= 0
    rr = rr+1
    inputData.rr = linein(input_file)
/*    if pos("ERPT200I",inputData.rr) > 0 then do */
    if pos("ERPT200I",inputData.rr) > 0 then do 

       say inputData.rr 
       leave
   end
   inputData.0 = rr
   end
say 'inputData ' inputData.0
exit