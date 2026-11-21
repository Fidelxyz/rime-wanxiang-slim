${ErrorActionPreference} = 'Stop'

${runtime} = [System.Runtime.InteropServices.RuntimeInformation,mscorlib]
${platform} = [System.Runtime.InteropServices.OSPlatform,mscorlib]

${arch} = switch (${runtime}::OSArchitecture) {
    'X64' { 'x86_64' }
    'Arm64' { 'aarch64' }
    default { throw 'Unsupported CPU architecture' }
}

${windows} = ${runtime}::IsOSPlatform(${platform}::Windows)
${target} = if (${windows}) { "${arch}-pc-windows-msvc" }
    elseif (${runtime}::IsOSPlatform(${platform}::OSX)) { "${arch}-apple-darwin" }
    elseif (${runtime}::IsOSPlatform(${platform}::Linux)) { "${arch}-unknown-linux-gnu" }
    else { throw 'Unsupported operating system' }
${suffix} = if (${windows}) { '.exe' } else { '' }

${name} = "rime-wanxiang-slim-installer-${target}${suffix}"
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
        if (-not ${windows}) {
            & chmod +x ${temp}
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
