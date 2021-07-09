/* rexx */
   input_file  = 'report.txt'
   do while lines(input_file) \= 0
      line = linein(input_file)
      var1 = '' 
      parse var line . 'PAGE ' var1 .
      if var1 <> '' then say line
   end /* do while */
   call lineout input_file
exit