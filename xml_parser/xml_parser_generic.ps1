# generic xml parser

$input_dir = '\\path\to\xml\files\directory'
$output_dir = '\\path\to\output\directory'
$xml_files = Get-ChildItem -Path $input_dir -Filter '*.xml'

# check for file output directory existence
if (-not(Test-Path -Path "$($output_dir)")) {
        
	Write-Host "$($output_dir) does not exist.`n" -ForegroundColor Yellow
		
	try {
		New-Item -Path "$($output_dir)" -ItemType Directory > $null -Force
		Write-Host "Created directory: $($output_dir)`n" -ForegroundColor Green
	}
	catch {
		Write-Host "Could not create directory!`n" -ForegroundColor Red
	    break
	}
}

# build a dictionary to hold the xml <name> tag values and translate them to human-friendly names for the final csv headers
# change the left names to match the <name> tags in your xml documents as these are just examples

$tag_names = @{
    "fname123" = "First Name"
    "lname234" = "Last Name"
    "email345" = "Email"
}

# create an empty array before the xml loop
# this will be used to store all xml data from each loop in memory and be output to a csv at the end
$xml_full_records = @()

#loop through the xml files
foreach ($file in $xml_files) {

	# get xml file content (nodes)
	[xml]$xml_content = Get-Content -Path $file

    # create an empty array then add the xml content into the array (this will pivot the data)
    # make sure to go through and look for nested tags (like mine which has the <repeateritem> with nested names and values)
    # yours may be different so edit the below array according to the tags in your xml files
    # you can add as many nested nodes here as you need so that the array captures everything
    $xml_nodes = @()
	$xml_nodes += @($xml_content.form.field) # usually the main xml content
	$xml_nodes += @($xml_content.form.repeater.repeateritem.field) # found some nested stuff to include (yours may be different)

	# create an ordered dictionary to hold the pivoted <name> and <value> data
	$csv_object = [ordered]@{}

    # create a dictionary for holding <name> tags (used for renaming any repeating names later)
    $countTable = @{}

	# loop through the xml array
	foreach ($node in $xml_nodes) {

		# ensure there is a <name> tag and value
		if ($node -and $node.name) {
		
			# loop through each xml <name> tag to translate them to user-friendly tags using the $tag_names @{} dictionary from earlier
            $xml_names_cleanup = foreach ($name in $node.name) {
                if ($tag_names.ContainsKey($name)) {
                    $new_node_name = $tag_names[$name]
                    $new_node_name
                }
                #catch any <name> tags in your output that might not be in the $tag_names @{} dictionary (you can manually go back and add them to the dictionary)
                else {
                    $name
                }
            }
	    
			# rename repeating <name> tags by appending numbers to the end so that Excel is happy with unique headers
			$xml_name_rename = foreach ($n in $xml_names_cleanup) {
				if ($countTable.ContainsKey($n)) {
					$countTable[$n]++
					"${n}_$($countTable[$n])"
				}
				else {
					$countTable[$n] = 1
					$n
				}
			}
			
			# get the inner text/string value for csv preparation
            $csv_object[$xml_name_rename] = $node.value
		}
	}
	
	# populate that empty array from earlier with all xml data
    $xml_full_records += [PSCustomObject]$csv_object
}

# final csv packaging
if ($xml_full_records) {
	Write-Host "gathering headers and exporting to csv..." -ForegroundColor Cyan

	# gather every unique items found across all processed files
	$xml_headers = $xml_full_records | ForEach-Object { $_.PSObject.Properties.Name } | Select-Object -Unique

	# export headers and value data to csv
	$xml_full_records | Select-Object -Property $xml_headers | Export-Csv -Path "$($output_dir)\xml_output.csv" -NoTypeInformation -Force

	Write-Host "Done!" -ForegroundColor Green
}