param([string]$AwsCli = 'aws', [string]$Region = 'us-east-1')
$ErrorActionPreference = 'Stop'
$accountId = & $AwsCli sts get-caller-identity --query Account --output text
if ($LASTEXITCODE -ne 0) { throw 'Falha ao validar identidade AWS.' }
$bucketName = "6322006-technova-tfstate-$accountId-$Region"
& $AwsCli s3api head-bucket --bucket $bucketName --expected-bucket-owner $accountId
if ($LASTEXITCODE -ne 0) {
    if ($Region -eq 'us-east-1') {
        & $AwsCli s3api create-bucket --bucket $bucketName --region $Region
    } else {
        & $AwsCli s3api create-bucket --bucket $bucketName --region $Region --create-bucket-configuration "LocationConstraint=$Region"
    }
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível criar o bucket do aluno. Verifique o erro antes de continuar.' }
}
# As configurações de versionamento, criptografia, bloqueio público e TLS
# são aplicadas pelo Terraform neste diretório. Não consultar Object Lock:
# essa operação é negada pelo SCP do Learner Lab.
Write-Output "Bucket disponível: $bucketName. Execute terraform apply neste diretório para aplicar as proteções."
