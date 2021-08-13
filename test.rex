/* rexx */
input_file  = 'report.txt'
output_file = 'report500000.txt'
do 500000
   line = linein(input_file)
   call lineout output_file, line
end
call lineout input_file
call lineout output_file
exit