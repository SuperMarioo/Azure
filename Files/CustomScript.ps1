<# Custom Script for Windows #>

Update-DscConfiguration -wait -ver 

"test" | out-file c:\windowsazure\test.txt
