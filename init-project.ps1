# init-project.ps1
# Template: Grails 5 REST API with Spring Security, JWT, PostgreSQL, CORS
# Localização: W:\projects\Templates\grails-rest-api-template

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [string]$PackageName = "com.myapp",
    
    [Parameter(Mandatory=$false)]
    [string]$DbName = "mydb",
    
    [Parameter(Mandatory=$false)]
    [string]$DbUser = "myuser",
    
    [Parameter(Mandatory=$false)]
    [string]$DbPass = "mypassword"
)

Write-Host "`n🚀 Criando novo projeto Grails REST API" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Nome do Projeto: $ProjectName" -ForegroundColor Cyan
Write-Host "Pacote: $PackageName" -ForegroundColor Cyan
Write-Host "Banco: $DbName" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green

# CAMINHO FIXO DO TEMPLATE
$templatePath = "W:\projects\Templates\grails-rest-api-template"

# Verificar se o template existe
if (-not (Test-Path $templatePath)) {
    Write-Host "❌ ERRO: Template não encontrado em: $templatePath" -ForegroundColor Red
    Write-Host "Verifique se o template está em W:\projects\Templates\grails-rest-api-template" -ForegroundColor Yellow
    exit 1
}

# Criar novo projeto a partir do template
Write-Host "📁 Copiando template..." -ForegroundColor Yellow
$targetPath = Join-Path (Get-Location) $ProjectName

# Copiar excluindo pastas desnecessárias
Copy-Item -Path $templatePath -Destination $targetPath -Recurse -Exclude ".git",".gradle","build"

# Entrar no projeto
Set-Location $targetPath

# Remover diretórios de build
Remove-Item -Path ".gradle" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue

# Converter nome do pacote para caminho
$oldPackage = "app.timali"
$packagePath = $PackageName -replace '\.', '\'
$oldPackagePath = "app\timali"

Write-Host "📝 Renomeando pacotes..." -ForegroundColor Yellow

# Mover diretórios de domínio
if (Test-Path "grails-app\domain\$oldPackagePath") {
    New-Item -Path "grails-app\domain\$packagePath" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "grails-app\domain\$oldPackagePath\*" -Destination "grails-app\domain\$packagePath\" -Recurse -Force
    Remove-Item -Path "grails-app\domain\$oldPackagePath" -Recurse -Force -ErrorAction SilentlyContinue
}

# Mover diretórios de init
if (Test-Path "grails-app\init\$oldPackagePath") {
    New-Item -Path "grails-app\init\$packagePath" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "grails-app\init\$oldPackagePath\*" -Destination "grails-app\init\$packagePath\" -Recurse -Force
    Remove-Item -Path "grails-app\init\$oldPackagePath" -Recurse -Force -ErrorAction SilentlyContinue
}

# Mover diretórios de controllers
if (Test-Path "grails-app\controllers\$oldPackagePath") {
    New-Item -Path "grails-app\controllers\$packagePath" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "grails-app\controllers\$oldPackagePath\*" -Destination "grails-app\controllers\$packagePath\" -Recurse -Force
    Remove-Item -Path "grails-app\controllers\$oldPackagePath" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "🔄 Atualizando referências nos arquivos..." -ForegroundColor Yellow

# Atualizar package nos arquivos Groovy
Get-ChildItem -Recurse -Filter "*.groovy" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "package app\.timali") {
        $content = $content -replace "package app\.timali", "package $PackageName"
        $content = $content -replace "import app\.timali\.", "import $PackageName."
        Set-Content $_.FullName $content -NoNewline
    }
}

# Atualizar application.yml
$ymlPath = "grails-app\conf\application.yml"
if (Test-Path $ymlPath) {
    $ymlContent = Get-Content $ymlPath -Raw
    $ymlContent = $ymlContent -replace "defaultPackage: app\.timali", "defaultPackage: $PackageName"
    $ymlContent = $ymlContent -replace "timali_db", $DbName
    $ymlContent = $ymlContent -replace "timali_user", $DbUser
    $ymlContent = $ymlContent -replace "timali_password", $DbPass
    Set-Content $ymlPath $ymlContent -NoNewline
}

Write-Host "🗄️ Criando docker-compose.yml..." -ForegroundColor Yellow

# Criar docker-compose.yml
$dockerCompose = @"
version: '3.8'
services:
  postgres:
    image: postgres:17
    container_name: ${ProjectName}_postgres
    environment:
      POSTGRES_USER: $DbUser
      POSTGRES_PASSWORD: $DbPass
      POSTGRES_DB: $DbName
    ports:
      - "5433:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $DbUser"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
"@
Set-Content "docker-compose.yml" $dockerCompose

Write-Host "📦 Inicializando Git..." -ForegroundColor Yellow
git init
git add .
git commit -m "Initial commit: $ProjectName REST API"

Write-Host "`n✅ PROJETO CRIADO COM SUCESSO!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "📁 Local: $targetPath" -ForegroundColor White
Write-Host ""
Write-Host "📝 Próximos passos:" -ForegroundColor Yellow
Write-Host "   1. cd $ProjectName" -ForegroundColor White
Write-Host "   2. docker-compose up -d" -ForegroundColor White
Write-Host "   3. ./gradlew bootRun" -ForegroundColor White
Write-Host ""
Write-Host "🔑 Login: admin / admin123" -ForegroundColor Cyan
Write-Host "🌐 API: http://localhost:8080/api" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green
