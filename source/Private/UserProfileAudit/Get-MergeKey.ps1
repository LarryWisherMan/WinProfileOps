# Helper function to generate a key
function Get-MergeKey
{
    param(
        [string]$SID,
        [string]$ProfilePath
    )

    # Generate a composite key based on both SID and ProfilePath
    return "$SID|$ProfilePath"
}
