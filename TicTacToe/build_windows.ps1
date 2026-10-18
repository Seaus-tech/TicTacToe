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

if ($BuildOnly) {
	& swift build -c $Configuration @compilerArguments
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}

	$showBinPathArguments = @('build', '-c', $Configuration, '--show-bin-path') + $compilerArguments
	$binaryDirectory = & swift @showBinPathArguments
	if ($LASTEXITCODE -ne 0) {
		exit $LASTEXITCODE
	}
	Write-Output "Build output: $(Join-Path $binaryDirectory 'TicTacToe.exe')"
} else {
	& swift run -c $Configuration @compilerArguments
	exit $LASTEXITCODE
}
