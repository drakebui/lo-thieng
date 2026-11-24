$gdFiles = Get-ChildItem -Path scripts, scenes, resources, data -Recurse -Include "*.gd", "*.tscn", "*.tres" -ErrorAction SilentlyContinue
$broken = @()
foreach ($f in $gdFiles) {
    $lines = Get-Content $f.FullName
    $i = 0
    foreach ($line in $lines) {
        $i++
        $trimmed = $line.Trim()
        if ($trimmed.StartsWith("#") -or $trimmed.StartsWith(";")) { continue }
        $idx = $line.IndexOf("res://")
        while ($idx -ge 0) {
            $end = $line.Length
            foreach ($char in @('"', "'", ")", " ", "`t", ",")) {
                $cidx = $line.IndexOf($char, $idx)
                if ($cidx -gt $idx -and $cidx -lt $end) { $end = $cidx }
            }
            $p = $line.Substring($idx, $end - $idx)
            if (-not $p.EndsWith(".uid") -and -not $p.EndsWith(".import")) {
                $rel = $p.Substring(6).Replace("/", "\")
                if (-not (Test-Path $rel)) {
                    $broken += "$($f.Name):$i -> $p"
                }
            }
            $idx = $line.IndexOf("res://", $end)
        }
    }
}
Write-Host "Total broken paths: $($broken.Count)"
foreach ($b in $broken) {
    Write-Host $b
}
