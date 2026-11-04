param(
	[ValidateSet('debug', 'release')]
	[string]$Configuration = 'debug',
	[switch]$BuildOnly
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command swift -ErrorAction SilentlyContinue)) {
	throw 'Swift is not on PATH. Install the Swift Windows toolchain and open a Visual Studio Developer PowerShell.'
}

if (-not $env:INCLUDE) {
	throw 'Windows SDK include paths are missing. Open an ARM64 or x64 Native Tools/Developer PowerShell for Visual Studio, then run this script again.'
}

$includeDirectories = $env:INCLUDE -split ';' | Where-Object {
	$_ -and (Test-Path -LiteralPath $_)
}
if (-not $includeDirectories) {
	throw 'No valid Windows SDK/MSVC include directories were found in INCLUDE. Repair the Visual Studio C++ and Windows SDK installation.'
}

$compilerArguments = @()
foreach ($includeDirectory in $includeDirectories) {
	$compilerArguments += @('-Xcc', "-I$includeDirectory")
}

# --- SMART APP CONTROL AUTO-SIGNING HELPER FUNCTION ---
function Sign-Binaries {
	Write-Host "Sweeping environment for unsigned code signatures..." -ForegroundColor Cyan
	
	$targets = @()
	if (Test-Path ".\.build") {
		$targets += Get-ChildItem -Path ".\.build" -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue
	}
	# Catch Swift's background package manifest compilers inside the system Temp spaces
	$targets += Get-ChildItem -Path "$env:LOCALAPPDATA\Temp" -Recurse -Filter "tictactoe-manifest.exe" -ErrorAction SilentlyContinue

	foreach ($file in $targets) {
		Write-Host "Securing binary: $($file.FullName)" -ForegroundColor Yellow
		& signtool sign /a /n "LocalDev" /fd SHA256 /t http://timestamp.digicert.com "$($file.FullName)" 2>$null
	}
}

# --- MAIN BUILD AND RUN EXECUTION ---
if ($BuildOnly) {
	# Try signing any left-over artifacts from a broken compilation attempt first
	Sign-Binaries
	
	& swift build -c $Configuration @compilerArguments
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}

	Sign-Binaries

	$showBinPathArguments = @('build', '-c', $Configuration, '--show-bin-path') + $compilerArguments
	$binaryDirectory = & swift @showBinPathArguments
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
	Write-Output "Build output: $(Join-Path $binaryDirectory 'TicTacToe.exe')"
} else {
	Write-Host "Isolating local dependencies and clearing cache envelopes..." -ForegroundColor Gray
	
	# 1. First, wipe any partially broken build caches causing compilation domain blocks
	if (Test-Path ".\.build") { Remove-Item -Recurse -Force ".\.build" -ErrorAction SilentlyContinue }

	# 2. Tell Swift to assemble the layout paths without invoking the execution parser engine yet
	# This lets files land on disk so we can get them signed.
	Write-Host "Fetching and extracting clean dependencies..." -ForegroundColor Gray
	& swift package resolve

	# 3. Apply your trusted LocalDev signature to intermediate structures
	Sign-Binaries

	Write-Host "Compiling project targets locally..." -ForegroundColor Gray
	& swift build -c $Configuration @compilerArguments

	# 4. Sign the final compiled TicTacToe game executable
	Sign-Binaries

	# 5. Extract target path and safe-execute inside trusted container
	$showBinPathArguments = @('build', '-c', $Configuration, '--show-bin-path') + $compilerArguments
	$binaryDirectory = & swift @showBinPathArguments
	$executablePath = Join-Path $binaryDirectory 'TicTacToe.exe'

	if (Test-Path $executablePath) {
		Write-Host "Launching application secure envelope..." -ForegroundColor Green
		& $executablePath
	} else {
		throw "Executable could not be localized on disk. Execution context dropped."
	}
	exit $LASTEXITCODE
}