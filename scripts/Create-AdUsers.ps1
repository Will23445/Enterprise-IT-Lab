# 1. Legge il file in formato corretto
$utenti = Import-Csv "C:\Users\Administrator\Desktop\utenti.csv" -Encoding UTF8

# 2. Crea una password temporanea sicura (Requisito obbligatorio di Active Directory)
$SecurePassword = ConvertTo-SecureString "Azienda2026!" -AsPlainText -Force

# 3. Inizia a creare gli utenti
foreach ($utente in $utenti) {
    $nomecompleto = $utente.Nome + " " + $utente.Cognome
    $sAMAccountName = ($utente.Nome[0] + $utente.Cognome).ToLower()
    
    # Crea l'utente inserendolo in CN=Users e assegnando la password
    New-ADUser -Name $nomecompleto `
               -SamAccountName $sAMAccountName `
               -UserPrincipalName "$sAMAccountName@acmecorp.local" `
               -Path "CN=Users,DC=acmecorp,DC=local" `
               -AccountPassword $SecurePassword `
               -Enabled $true `
               -ChangePasswordAtLogon $true
}
