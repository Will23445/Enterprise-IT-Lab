# Progetto di Laboratorio IT: Rete Aziendale con Windows Server e Linux

## 1. Panoramica del Progetto
Questo repository contiene il mio progetto personale in cui ho simulato da zero la rete informatica di una piccola azienda. L'obiettivo era mettere in pratica quello che ho studiato, creando una rete mista con server Windows e macchine Linux. 

Mi sono concentrato sulla gestione centralizzata degli utenti tramite Active Directory, sulla creazione automatica degli account usando uno script e sul monitoraggio per controllare che i server siano sempre accesi e funzionanti.

Ho usato **Oracle VirtualBox** per creare tutte le macchine virtuali e le ho collegate tra loro usando una rete NAT (Network Address Translation) per simulare la LAN dell'azienda.

## 2. Architettura di Rete
La rete usa la sottorete `10.0.2.0/24` e il gateway è `10.0.2.1`. Ho assegnato un indirizzo IP statico a ogni server per far sì che si trovino sempre all'interno della rete.

| Nome Computer | Indirizzo IP | Sistema Operativo | A cosa serve |
| :--- | :--- | :--- | :--- |
| **SRV-DC01** | `10.0.2.10` | Windows Server 2022 | Domain Controller, Server DNS e Active Directory |
| **SRV-WEB01** | `10.0.2.11` | Ubuntu Server 24.04 | Server Web (Nginx) per la pagina interna dell'azienda |
| **CLIENT-W11** | `10.0.2.50` | Windows 11 Pro | PC del dipendente e postazione per monitorare la rete |

## 3. Lavori svolti sui Server

### 3.1 Windows Server (Dominio e DNS)
Ho configurato il server Windows principale come **Domain Controller** per creare il dominio `acmecorp.local`. 
* **DNS:** Ho impostato il server DNS locale. Per permettere ai computer della rete di navigare su Internet, ho aggiunto degli Inoltratori (Forwarders) che puntano ai server DNS di Google (8.8.8.8).
* **Active Directory:** Ho creato e gestito gli utenti e i computer direttamente dal server.

### 3.2 Script in PowerShell per gli Utenti
Invece di creare gli utenti a mano uno per uno, ho scritto uno script in PowerShell (`Create-AdUsers.ps1`). Lo script funziona così:
* Legge i nomi e i cognomi dei dipendenti da un file `.csv`.
* Crea in automatico l'account utente (prendendo l'iniziale del nome e il cognome).
* Assegna una password temporanea generica.
* Attiva l'impostazione che obbliga il dipendente a cambiare la password al suo primo accesso su Windows 11, per motivi di sicurezza.

### 3.3 Server Web Linux (Ubuntu)
Ho usato un server Linux senza interfaccia grafica (a riga di comando) per ospitare il sito web dell'azienda.
* **Rete:** Ho impostato l'IP statico modificando i file di configurazione di Netplan.
* **Firewall:** Ho attivato il firewall UFW per lasciare aperta solo la porta 80, quella che serve per il sito web.
* **Sito:** Ho installato Nginx per far funzionare la pagina web interna.

## 4. Monitoraggio della Rete
Per controllare che tutto funzioni bene, ho installato il software **OpManager** sul PC Windows 11, usandolo come se fosse la postazione dell'amministratore di rete. Ho aggiunto i server alla dashboard per monitorare se rispondono ai Ping (ICMP) e se la porta del sito web (TCP) è aperta.

### Test di Allarme sul Server Web
Per dimostrare che il monitoraggio funziona, ho fatto un test pratico:
1. **Problema:** Dal terminale di Ubuntu, ho spento di proposito il servizio del sito web usando il comando `sudo systemctl stop nginx`.
2. **Risultato:** Dopo pochi minuti, la dashboard di OpManager su Windows 11 ha fatto comparire un allarme critico (rosso) per avvisare che il sito non era più raggiungibile.
3. **Soluzione:** Ho riattivato Nginx e l'allarme su OpManager è tornato verde da solo.

## 5. File presenti nel Repository
* `/scripts/Create-AdUsers.ps1`: Il mio script in PowerShell per importare gli utenti.
* `/data/utenti.csv`: Il file di testo con i dati dei dipendenti finti.
* `/images/`: Qui ci sono gli screenshot del lavoro finito (Active Directory, allarme su OpManager e terminale di Ubuntu).

## 6. Conclusioni
Questo progetto mi è servito per capire come i sistemi operativi diversi (Windows e Linux) possono comunicare e lavorare insieme nella stessa rete. Ho anche imparato quanto è importante usare gli script per fare meno lavoro manuale e usare i software di monitoraggio per accorgersi subito se c'è un problema.
