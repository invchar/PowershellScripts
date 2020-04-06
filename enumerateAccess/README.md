-server option specifies target server on which the shares are located

-dbfile option specifies an explicity path and name for a new Access database file which will be created to hold the resulting records. You need to include the full path excplicitly.

-recurse option selects whether to get records for subdirectories of the share(s)

-ignoreinherited option selects whether to ignore inherited permissions and only create records for explicit permissions

-expandgroups option will expand groups into its members and create records for the members instead of for the group

-share option specifies a particular share to check instead of checking all shares on the target server

-user option specifies to record only records which pertain to the specified user

-group option specifies to record only records which pertain to the specified group

Certain option combinations, namely a combination of user and group options, are not allowed, because I didn't feel as though the combination made sense and so there was no reasonably expectable behavior to be coded for such a combination of options. If a combination is allowed but produces unexpected results, consider it an oversight. You can let me know, or change the code to disallow the combination, or change the code to add logic to handle the combination reasonably.

This script uses Access 2013 to create an Access database file in which to store resulting records. 

Table headers in the resulting database will be as follows:

ID will show the group or user to which the record pertains

viaID will show the group who's membership in which results in the access permissions being recorded

Path will show the path on which the access permissions are set

Type will show the access permission type (e.g. allow/deny)

Inherited will show whether the access permissions are inherited or explicitly set

Access will show the access permissions (e.g. read/modify/full)

The createDB function is called to create the database file and create the table therein.

The openDB function is called to open that database so that we can later add records.

The closeDB function is called to close the database after we're finished adding records.

The addRecord function is called and passed parameters to add a record to the database. Variables are passed to the function corresponding to each field, this function doesn't perform logic to decide what value to put in the record.

The validateOptions function is used to block the use of combinations of options for which I was too lazy to code the logic. 

The processPath function is a backbone function which gets the ACL for a given path and then performs logic to determine what values need to be recorded. If a group needs to be expanded, that functionality is handled in the separate function, processADMembers. This is also a recursive function in that if the recurse option is set, this function will get the children of the path on which it is working and then call itself for each of the paths of those children directories. 

The processADMemberships function gets the memberships to which the passed sid belongs. 

The processADMembers function is used when the expandgroups option is used and the processPath function comes across a record for a domain group. The path and the ACE are passed to this function, which will get the members of the group and list them individually rather than the group. The viaID will be set to the group name so that it is evident that the individual members recorded have access by way of their membership in the group.

The main function contains logic for cases where the user or group options are specified, getting their group memberships to be included when comparing to ACEs. It also contains logic to handle the cases when the share option is used, or not, getting a list of the shares on the server if not, and then looping through them to process each by way of the processPath function.
