$ErrorActionPreference = 'Stop'

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
	throw 'Node.js 18 or later is required. Install it from https://nodejs.org/ and reopen PowerShell.'
}

$dependencyPath = Join-Path $PSScriptRoot 'node_modules\ws'
if (-not (Test-Path $dependencyPath)) {
	Push-Location $PSScriptRoot
	try {
		npm install
		if ($LASTEXITCODE -ne 0) {
			throw "npm install failed with exit code $LASTEXITCODE."
		}
	}
	finally {
		Pop-Location
	}
}

Push-Location $PSScriptRoot
try {
	npm start
	if ($LASTEXITCODE -ne 0) {
		throw "The TicTacToe server exited with code $LASTEXITCODE."
	}
}
finally {
	Pop-Location
}
