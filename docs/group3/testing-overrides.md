# Overwrite a built-in test

In some bits of the data "N/A" are seen and should be NULLs. Override the not_null test to allow for this. 

The not_null test should work as always, but there should be an optional parameter `null_values` where you pass in a list and it considers these nulls for that configuration of test.