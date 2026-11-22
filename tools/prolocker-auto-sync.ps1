[CmdletBinding()]
param(
  [switch]$RunOnce,
  [int]$DebounceSeconds = 75,
  [int]$PollSeconds = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$LogDirectory = Join-Path $env:LOCALAPPDATA 'ProLockerGitAutoSync'
$LogPath = Join-Path $LogDirectory 'sync.log'
$TaskMutex = New-Object System.Threading.Mutex($false, 'Local\ProLockerGitAutoSync')

function Write-SyncLog {
  param([Parameter(Mandatory)][string]$Message)
  New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
  $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
  Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Get-GitExecutable {
  $candidate = Get-Command git -ErrorAction SilentlyContinue
  if ($candidate) { return $candidate.Source }

  foreach ($path in @(
    'C:\Program Files\Git\cmd\git.exe',
    'C:\Program Files\Git\bin\git.exe'
  )) {
    if (Test-Path -LiteralPath $path) { return $path }
  }

  throw 'Git is not available on this computer.'
}

$GitExecutable = Get-GitExecutable

function Invoke-Git {
  param([Parameter(Mandatory)][string[]]$Arguments)

  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = & $GitExecutable -C $ProjectPath @Arguments 2>$null
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
      $diagnostic = & $GitExecutable -C $ProjectPath @Arguments 2>&1
      $details = ($diagnostic | Out-String).Trim()
    }
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  if ($exitCode -ne 0) {
    throw ('git {0} failed. {1}' -f ($Arguments -join ' '), $details)
  }

  return @($output | ForEach-Object { $_.ToString() })
}

function Get-GitStatus {
  return ((Invoke-Git @('status', '--porcelain=v1', '--untracked-files=all')) -join [Environment]::NewLine).Trim()
}

function Test-GitIndexClean {
  & $GitExecutable -C $ProjectPath diff --cached --quiet
  return $LASTEXITCODE -eq 0
}

function Get-ChangedPaths {
  $tracked = Invoke-Git @('diff', '--name-only')
  $untracked = Invoke-Git @('ls-files', '--others', '--exclude-standard')
  return @((@($tracked) + @($untracked)) | Where-Object { $_ } | Sort-Object -Unique)
}

function Test-AutoSyncSafePath {
  param([Parameter(Mandatory)][string]$Path)

  $normalized = $Path.Replace('\', '/')
  if ($normalized -match '(^|/)(\.env(?:\..*)?|secrets?|credentials?)(/|$)') { return $false }
  if ($normalized -match '(^|/)(id_rsa|id_ed25519)(\.pub)?$') { return $false }
  if ($normalized -match '\.(pem|key|pfx|p12|secret|token)$') { return $false }
  if ($normalized -match '^(?:\.gitignore|tools/)') { return $false }
  if ($normalized -in @('CNAME', '.nojekyll', '.htaccess')) { return $true }

  $extension = [System.IO.Path]::GetExtension($normalized).ToLowerInvariant()
  return $extension -in @(
    '.html', '.css', '.js', '.xml', '.txt', '.md', '.json',
    '.jpeg', '.jpg', '.png', '.svg', '.webp', '.gif', '.ico',
    '.woff', '.woff2'
  )
}

function Invoke-SafeSync {
  try {
    $status = Get-GitStatus
    if ([string]::IsNullOrWhiteSpace($status)) { return }

    if (-not (Test-GitIndexClean)) {
      Write-SyncLog 'Paused: manually staged changes were detected. No automatic commit was created.'
      return
    }

    Invoke-Git @('fetch', '--prune', 'origin', 'main') | Out-Null
    $local = (Invoke-Git @('rev-parse', 'main')).Trim()
    $remote = (Invoke-Git @('rev-parse', 'origin/main')).Trim()
    $base = (Invoke-Git @('merge-base', 'main', 'origin/main')).Trim()

    if ($local -ne $remote) {
      if ($local -eq $base) {
        Write-SyncLog 'Paused: origin/main is ahead while local edits exist. A manual pull is required to avoid a conflict.'
        return
      }

      if ($remote -eq $base) {
        Invoke-Git @('push', 'origin', 'main') | Out-Null
        Write-SyncLog 'Recovered a previously committed local change by pushing main.'
      } else {
        Write-SyncLog 'Paused: local main and origin/main have diverged. A manual resolution is required.'
        return
      }
    }

    $paths = @(Get-ChangedPaths)
    if ($paths.Count -eq 0) { return }

    $unsafePaths = @($paths | Where-Object { -not (Test-AutoSyncSafePath $_) })
    if ($unsafePaths.Count -gt 0) {
      Write-SyncLog ('Paused: files require a manual review before commit: {0}' -f ($unsafePaths -join ', '))
      return
    }

    Invoke-Git @('add', '--all') | Out-Null
    $stagedPaths = @(Invoke-Git @('diff', '--cached', '--name-only'))
    $unsafeStaged = @($stagedPaths | Where-Object { -not (Test-AutoSyncSafePath $_) })
    if ($unsafeStaged.Count -gt 0) {
      Invoke-Git @('reset') | Out-Null
      Write-SyncLog ('Stopped: protected files reached the index and were unstaged: {0}' -f ($unsafeStaged -join ', '))
      return
    }

    $message = 'chore: synchronisation automatique {0}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm')
    Invoke-Git @('commit', '-m', $message) | Out-Null
    Invoke-Git @('push', 'origin', 'main') | Out-Null
    Write-SyncLog ('Committed and pushed: {0}' -f $message)
  } catch {
    Write-SyncLog ('Paused after an error: {0}' -f $_.Exception.Message)
  }
}

function Test-IgnoredWatchPath {
  param([Parameter(Mandatory)][string]$Path)
  $relative = [System.IO.Path]::GetRelativePath($ProjectPath, $Path).Replace('\', '/')
  return $relative -match '^(?:\.git/|\.prolocker-sync/|~\$)'
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath '.git'))) {
  throw "The project is not a Git repository: $ProjectPath"
}

if ($RunOnce) {
  Invoke-SafeSync
  exit 0
}

$ownsMutex = $false
try {
  $ownsMutex = $TaskMutex.WaitOne(0)
  if (-not $ownsMutex) {
    Write-SyncLog 'A synchronisation watcher is already running. This instance will exit.'
    exit 0
  }

  $watcher = New-Object System.IO.FileSystemWatcher $ProjectPath
  $watcher.IncludeSubdirectories = $true
  $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, Size, DirectoryName'
  $watcher.EnableRaisingEvents = $true

  $subscriptions = @(
    Register-ObjectEvent -InputObject $watcher -EventName Changed -SourceIdentifier 'ProLockerGitAutoSync.Changed',
    Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier 'ProLockerGitAutoSync.Created',
    Register-ObjectEvent -InputObject $watcher -EventName Deleted -SourceIdentifier 'ProLockerGitAutoSync.Deleted',
    Register-ObjectEvent -InputObject $watcher -EventName Renamed -SourceIdentifier 'ProLockerGitAutoSync.Renamed'
  )

  $knownStatus = Get-GitStatus
  $lastChange = if ($knownStatus) { Get-Date } else { $null }
  $nextPoll = (Get-Date).AddSeconds($PollSeconds)
  Write-SyncLog ('Watcher started for {0}; debounce is {1} seconds.' -f $ProjectPath, $DebounceSeconds)

  while ($true) {
    $event = Wait-Event -Timeout $PollSeconds
    if ($event) {
      $path = $event.SourceEventArgs.FullPath
      Remove-Event -EventIdentifier $event.EventIdentifier -ErrorAction SilentlyContinue
      if (-not (Test-IgnoredWatchPath $path)) {
        $currentStatus = Get-GitStatus
        if ($currentStatus -ne $knownStatus) {
          $knownStatus = $currentStatus
          $lastChange = if ($currentStatus) { Get-Date } else { $null }
        }
      }
    }

    if ((Get-Date) -ge $nextPoll) {
      $currentStatus = Get-GitStatus
      if ($currentStatus -ne $knownStatus) {
        $knownStatus = $currentStatus
        $lastChange = if ($currentStatus) { Get-Date } else { $null }
      }
      $nextPoll = (Get-Date).AddSeconds($PollSeconds)
    }

    if ($lastChange -and (((Get-Date) - $lastChange).TotalSeconds -ge $DebounceSeconds)) {
      Invoke-SafeSync
      $knownStatus = Get-GitStatus
      $lastChange = $null
    }
  }
} finally {
  if ($subscriptions) { $subscriptions | Unregister-Event -ErrorAction SilentlyContinue }
  if ($watcher) { $watcher.Dispose() }
  if ($ownsMutex) { $TaskMutex.ReleaseMutex() }
  $TaskMutex.Dispose()
}
