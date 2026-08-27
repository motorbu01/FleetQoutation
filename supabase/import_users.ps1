# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Format CSV: username,password,display_name,role,issuer_name,issuer_branch

$SUPABASE_URL     = "https://nwoqddeexkciftpzoexl.supabase.co"
$SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im53b3FkZGVleGtjaWZ0cHpvZXhsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NzY2NDM0OCwiZXhwIjoyMTAzMjQwMzQ4fQ.y9XqvJymmApGJJY5Bx_2OVUoGhRpH12fMRxrPNU0GZ8"
$DOMAIN           = "dhipaya.co.th"
$CSV_FILE         = "$PSScriptRoot\users.csv"

if ($SERVICE_ROLE_KEY.Length -lt 50) { Write-Host "ERROR: Please set SERVICE_ROLE_KEY" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $CSV_FILE))       { Write-Host "ERROR: File not found: $CSV_FILE" -ForegroundColor Red; exit 1 }

# อ่าน CSV ด้วย UTF-8 explicit
$rawContent = [System.IO.File]::ReadAllText($CSV_FILE, [System.Text.Encoding]::UTF8)
$tempFile   = [System.IO.Path]::GetTempFileName() + ".csv"
[System.IO.File]::WriteAllText($tempFile, $rawContent, [System.Text.Encoding]::Unicode)
$users = Import-Csv -Path $tempFile -Encoding Unicode
Remove-Item $tempFile -Force

$success = 0
$fail    = 0
Write-Host "Found $($users.Count) users" -ForegroundColor Cyan
Write-Host ""

foreach ($u in $users) {
    $username      = $u.username.Trim()
    $password      = $u.password.Trim()
    $name          = $u.display_name.Trim()
    $role          = $u.role.Trim().ToLower()
    $issuer_name   = if ($u.PSObject.Properties['issuer_name']   -and -not [string]::IsNullOrWhiteSpace($u.issuer_name))   { $u.issuer_name.Trim() }   else { $name }
    $issuer_branch = if ($u.PSObject.Properties['issuer_branch'] -and -not [string]::IsNullOrWhiteSpace($u.issuer_branch)) { $u.issuer_branch.Trim() } else { $null }

    if ([string]::IsNullOrWhiteSpace($username)) { continue }
    if ($role -notin @("admin","lv1","lv2")) { $role = "lv1" }

    $email = "$username@$DOMAIN"
    Write-Host "  $username ($issuer_name / $issuer_branch) ... " -NoNewline

    try {
        # Step 1: สร้าง Auth user — ถ้ามีอยู่แล้วดึง uid แทน
        $uid = $null
        try {
            $authBody = @{ email = $email; password = $password; email_confirm = $true } | ConvertTo-Json -Compress
            $authRes  = Invoke-RestMethod `
                -Uri "$SUPABASE_URL/auth/v1/admin/users" `
                -Method POST `
                -Headers @{ "apikey" = $SERVICE_ROLE_KEY; "Authorization" = "Bearer $SERVICE_ROLE_KEY"; "Content-Type" = "application/json" } `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($authBody)) `
                -ErrorAction Stop
            $uid = $authRes.id
        } catch {
            $listRes = Invoke-RestMethod `
                -Uri "$SUPABASE_URL/auth/v1/admin/users?page=1&per_page=1000" `
                -Method GET `
                -Headers @{ "apikey" = $SERVICE_ROLE_KEY; "Authorization" = "Bearer $SERVICE_ROLE_KEY" } `
                -ErrorAction Stop
            $matched = $listRes.users | Where-Object { $_.email -eq $email }
            if ($matched) { $uid = $matched[0].id }
        }

        if (-not $uid) { throw "Cannot find uid for $email" }

        # Step 2: UPSERT user_profiles (INSERT ถ้าไม่มี, UPDATE ถ้ามีแล้ว)
        $profileObj = [ordered]@{
            id            = $uid
            display_name  = $name
            role          = $role
            is_active     = $true
            issuer_name   = $issuer_name
            issuer_branch = $issuer_branch
        }
        $profileBody = "[$(($profileObj | ConvertTo-Json -Compress))]"

        Invoke-RestMethod `
            -Uri "$SUPABASE_URL/rest/v1/user_profiles" `
            -Method POST `
            -Headers @{
                "apikey"        = $SERVICE_ROLE_KEY
                "Authorization" = "Bearer $SERVICE_ROLE_KEY"
                "Content-Type"  = "application/json"
                "Prefer"        = "resolution=merge-duplicates,return=minimal"
            } `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($profileBody)) `
            -ErrorAction Stop | Out-Null

        Write-Host "OK" -ForegroundColor Green
        $success++

    } catch {
        Write-Host "FAIL: $($_.Exception.Message)" -ForegroundColor Red
        $fail++
    }

    Start-Sleep -Milliseconds 300
}

Write-Host ""
Write-Host "Done - Success: $success  Failed: $fail" -ForegroundColor Cyan
