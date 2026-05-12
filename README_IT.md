*English version available. [Click here to read the README in English](./README.md)*

---

# Progetto di Laboratorio IT: Rete Aziendale con Windows Server e Linux

## 1. Panoramica del Progetto
Questo repository contiene il mio progetto personale in cui ho simulato da zero la rete informatica di una piccola azienda. L'obiettivo era mettere in pratica quello che ho studiato, creando una rete mista con server Windows e macchine Linux. 

Mi sono concentrato sulla gestione centralizzata degli utenti tramite Active Directory, sulla creazione automatica degli account usando script, sul rilascio automatico dei software, sulla condivisione dei file e sul monitoraggio continuo. Inoltre, ho implementato protocolli di sicurezza avanzati per gli account amministratore locali e ho eseguito con successo una migrazione dell'intera infrastruttura tra hypervisor diversi.

Inizialmente, ho utilizzato Oracle VirtualBox per creare l'ambiente su una rete NAT. Successivamente, ho migrato l'intero laboratorio su VMware Workstation Pro per testare un hypervisor di livello enterprise.

## 2. Architettura di Rete
La rete usa la sottorete 10.0.2.0/24, simulando la LAN dell'azienda "ACME Corp". Ho assegnato un indirizzo IP statico a ogni server per far sì che siano sempre raggiungibili.

| Nome Computer | Indirizzo IP | Sistema Operativo | A cosa serve |
| :--- | :--- | :--- | :--- |
| **SRV-DC01** | 10.0.2.10 | Windows Server 2022 | Domain Controller, Server DNS e Active Directory |
| **SRV-WEB01** | 10.0.2.11 | Ubuntu Server 24.04 | Server Web (Nginx) per la pagina interna dell'azienda |
| **CLIENT-W11** | 10.0.2.50 | Windows 11 Pro | PC del dipendente e postazione per monitorare la rete |

## 3. Configurazioni dei Server

### 3.1 Windows Server (Dominio e DNS)
Ho configurato il server Windows principale come Domain Controller per creare il dominio acmecorp.local. 
* **DNS:** Ho impostato il server DNS locale. Per permettere ai computer della rete di navigare su Internet, ho aggiunto degli Inoltratori (Forwarders) che puntano ai server DNS di Google (8.8.8.8).
* **Active Directory:** Ho creato e gestito gli utenti e i computer direttamente dal server.

### 3.2 Script in PowerShell per gli Utenti
Invece di creare gli utenti a mano uno per uno, ho scritto uno script in PowerShell (Create-AdUsers.ps1). Lo script funziona così:
* Legge i nomi e i cognomi dei dipendenti da un file .csv.
* Crea in automatico l'account utente (prendendo l'iniziale del nome e il cognome).
* Assegna una password temporanea generica.
* Attiva l'impostazione che obbliga il dipendente a cambiare la password al suo primo accesso su Windows 11, per motivi di sicurezza.

### 3.3 Server Web Linux (Ubuntu)
Ho usato un server Linux senza interfaccia grafica (a riga di comando) per ospitare il sito web dell'azienda.
* **Rete:** Ho impostato l'IP statico modificando i file di configurazione di Netplan.
* **Firewall:** Ho attivato il firewall UFW per lasciare aperta solo la porta 80, quella che serve per il sito web.
* **Sito:** Ho installato Nginx per far funzionare la pagina web interna.

## 4. Gestione dell'Infrastruttura Aziendale

### 4.1 File Server e Unità di Rete (Disco Z:)
Per fornire ai dipendenti un luogo centralizzato e sicuro dove salvare il lavoro, ho configurato un File Server.
* **Cartella Condivisa:** Ho creato una cartella chiamata Dati_Aziendali sul Server e l'ho condivisa.
* **Permessi NTFS:** Ho assegnato permessi di "Modifica" al gruppo Domain Users. Questo garantisce che solo i dipendenti autenticati possano accedere e modificare i file.
* **Mappatura Disco:** Ho utilizzato una Group Policy (GPO) affinché, al login dell'utente su Windows 11, la cartella condivisa appaia automaticamente come Disco Z: in "Questo PC".

<details>
<summary>Clicca per espandere i dettagli tecnici della GPO per il Disco Z:</summary>

* Percorso GPO: Configurazione Utente > Preferenze > Impostazioni di Windows > Mappe unità
* Azione: Crea
* Percorso: \\SRV-DC01\Dati_Aziendali
* Lettera Unità: Z:
</details>

### 4.2 Software Deployment Automatico
Per evitare di installare i programmi manualmente su ogni client, ho automatizzato il processo.
* Ho creato una cartella condivisa chiamata Deploy_Software sul Server e vi ho inserito il file di installazione 7-Zip.msi.
* Ho configurato una GPO (Configurazione Computer > Criteri > Impostazioni Software) collegandola ai computer. All'avvio di Windows 11, il PC installa automaticamente 7-Zip tramite la rete prima ancora che l'utente veda il desktop.

### 4.3 Sicurezza Avanzata: LAPS
Per prevenire attacchi hacker che sfruttano password standard per gli amministrator locali, ho implementato LAPS (Local Administrator Password Solution). LAPS genera una password complessa e casuale per ogni PC e la memorizza in modo sicuro in Active Directory.

* **Risoluzione Conflitto di Versione:** Windows 11 dispone di un "Native LAPS" moderno, mentre Server 2022 utilizza il sistema "Legacy" precedente. Ho risolto questa incompatibilità configurando i criteri locali su Windows 11 per forzare la comunicazione con la directory di backup di Active Directory.
* **Attivazione Account:** Poiché Windows 11 disattiva di default l'account Administrator locale, ho creato una GPO specifica sul Server per abilitarlo, rendendo la password di LAPS effettivamente utilizzabile in caso di emergenza.

<details>
<summary>Clicca per espandere i passaggi di configurazione tecnica di LAPS</summary>

1. Preparazione Active Directory: Esecuzione di Update-AdmPwdADSchema e Set-AdmPwdComputerSelfPermission tramite PowerShell sul Server.
2. Attivazione Admin Locale (GPO Server): Configurazione Computer > Criteri > Impostazioni di Windows > Impostazioni di sicurezza > Criteri locali > Opzioni di sicurezza > Account: stato account amministratore impostato su Attivato.
3. Criterio Locale (Windows 11): Configurazione Computer > Modelli amministrativi > Sistema > LAPS > Configura directory di backup delle password impostato su Active Directory.
</details>

## 5. Monitoraggio e Test della Rete

### 5.1 Monitoraggio Web con OpenManage
Per controllare che tutto funzioni correttamente, ho utilizzato OpenManage tramite browser web sul PC Windows 11, agendo come postazione dell'amministratore di rete. Ho aggiunto i server alla dashboard web per monitorare se rispondono ai Ping (ICMP) e se la porta del sito web (TCP) è aperta.

**Test di Allarme sul Server Web:**
Per dimostrare il funzionamento del monitoraggio, ho effettuato un test pratico:
1. **Problema:** Dal terminale di Ubuntu, ho arrestato intenzionalmente il servizio del sito web con il comando sudo systemctl stop nginx.
2. **Risultato:** Dopo pochi minuti, la dashboard web di OpenManage ha mostrato un allarme critico (rosso) avvisando che il sito non era raggiungibile.
3. **Soluzione:** Ho riavviato Nginx e l'allarme su OpenManage è tornato automaticamente verde.

### 5.2 Test di Disaster Recovery Offline
Per verificare la configurazione di LAPS, ho eseguito una simulazione di disastro:
1. Ho scollegato la scheda di rete del client Windows 11.
2. Ho recuperato la password generata dall'applicazione LAPS UI sul Server.
3. Ho effettuato l'accesso al PC Windows 11 offline utilizzando l'account locale .\Administrator e la password LAPS.
4. L'accesso è avvenuto con successo, dimostrando la capacità di mantenere il controllo amministrativo anche con il Domain Controller completamente irraggiungibile.

## 6. Migrazione Cross-Hypervisor (da VirtualBox a VMware)
Per fare un upgrade dell'ambiente di laboratorio, ho migrato con successo tutte le macchine virtuali da Oracle VirtualBox a VMware Workstation Pro. 

Questa operazione ha richiesto un'attenta preparazione per prevenire conflitti hardware (come schermate blu su Windows o Kernel Panic su Linux) e problemi di rete (schede di rete fantasma).

**Passaggi di Migrazione Eseguiti:**
1. **Preparazione (Rimozione Driver):** Prima dell'esportazione, ho disinstallato le VirtualBox Guest Additions da tutte le macchine. Nota: avendo precedentemente applicato una GPO che bloccava il Pannello di Controllo per gli utenti standard su Windows 11, ho aggirato la restrizione eseguendo direttamente il file uninst.exe dal disco C: con i privilegi di Amministratore di Dominio.
2. **Esportazione:** Ho esportato ogni macchina virtuale da VirtualBox nel formato universale .ova (Open Virtualization Format).
3. **Importazione:** Ho importato i file .ova all'interno di VMware Workstation Pro.
4. **Riconfigurazione di Rete:** Per mantenere gli IP statici e la comunicazione con il dominio, ho sostituito la rete NAT predefinita con un "LAN Segment" personalizzato in VMware, che funge da switch virtuale isolato.
5. **Finalizzazione:** Ho avviato le macchine e installato i VMware Tools su tutti i sistemi operativi per garantire prestazioni e integrazione ottimali.

## 7. File presenti nel Repository
* /scripts/Create-AdUsers.ps1: Il mio script in PowerShell per importare gli utenti.
* /data/utenti.csv: Il file di testo con i dati dei dipendenti fittizi.
* /images/: Gli screenshot del lavoro completato (Active Directory, allarmi dashboard OpenManage, terminale Ubuntu, rilascio 7-Zip, Disco Z:, LAPS UI e Dashboard VMware).

## 8. Conclusioni
Questo progetto mi è servito per capire come sistemi operativi diversi (Windows e Linux) possano comunicare e lavorare insieme nella stessa rete. Ho appreso l'importanza di utilizzare gli script per ridurre il lavoro manuale, di implementare misure di sicurezza avanzate come LAPS e di impiegare strumenti di monitoraggio per individuare immediatamente i problemi. Infine, la migrazione dell'infrastruttura mi ha insegnato come spostare in sicurezza ambienti aziendali tra piattaforme di virtualizzazione differenti.
