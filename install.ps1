${ErrorActionPreference} = 'Stop'

${arch} = switch ([System.Runtime.InteropServices.RuntimeInformation,mscorlib]::OSArchitecture) {
    'X64' { 'x86_64' }
    'Arm64' { 'aarch64' }
    default { throw 'Unsupported CPU architecture' }
}

${name} = "rime-wanxiang-slim-installer-${arch}-pc-windows-msvc.exe"
${binary} = Join-Path (Get-Location).Path ".installer/${name}"
New-Item -ItemType Directory -Force -Path (Split-Path ${binary}) | Out-Null

Add-Type -AssemblyName System.Net.Http
${client} = [System.Net.Http.HttpClient]::new()
${response} = ${null}
try {
    if (Test-Path -LiteralPath ${binary} -PathType Leaf) {
        ${client}.DefaultRequestHeaders.IfModifiedSince = [System.IO.File]::GetLastWriteTimeUtc(${binary})
    }

    ${response} = ${client}.GetAsync(
        "https://github.com/Fidelxyz/rime-wanxiang-slim-installer/releases/latest/download/${name}"
    ).GetAwaiter().GetResult()
    if (${response}.StatusCode -ne 304) {
        ${response}.EnsureSuccessStatusCode() | Out-Null
    }
    if (${response}.StatusCode -eq 200) {
        if (Test-Path -LiteralPath ${binary} -PathType Leaf) {
            Write-Host 'Updating installer...'
        }
        ${temp} = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllBytes(${temp}, ${response}.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
        ${modified} = ${response}.Content.Headers.LastModified
        if (${null} -ne ${modified}) {
            [System.IO.File]::SetLastWriteTimeUtc(${temp}, ${modified}.UtcDateTime)
        }
        Move-Item -LiteralPath ${temp} -Destination ${binary} -Force
    }
} finally {
    if (${null} -ne ${response}) {
        ${response}.Dispose()
    }
    ${client}.Dispose()
}

& ${binary}
