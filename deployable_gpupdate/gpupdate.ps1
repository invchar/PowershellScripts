param (
    [string]$target = $(throw "You must specify user or computer target by passing -target [user|computer]"),
    [switch]$force
)

if ($force) {
    echo n | gpupdate /target:$target /force
}
else {
    gpupdate /target:$target
}
