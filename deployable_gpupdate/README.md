# deployable_gpupdate.ps1
Deployable script to trigger a gpupdate for user or computer

Pass -target parameter with "user" or "computer" value, and optionally the -force parameter. 

If you are targeting user you should deploy the script so that it is run in the user's context. 
