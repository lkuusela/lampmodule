# lampmodule

## moduuli, mikä asentaa LAMP:in ja kofiguroi sen valmiiksi käyttäjille

Moduuli asentaa Apache2:n, PHP:n ja mySQL:n. Käyttäjien kotihakemistot toimivat selaimessa ja tukevat php:tä. Moduuli ei osaa varmistaa "public_html" kansion olemassa oloa, ellei käyttäjän nimieä itse kirjoita "init.pp" tiedostoon. MySQL:ään voit kirjautua komennolla $sudo mysql ja tämän jälkeen luoda haluamat käyttäjät.



## Lähteitä

- http://simosuominen.com/index.php/2017/04/14/palvelinten-hallinta-kotitehtavat-3/
- https://github.com/rgevaert/puppet-mysql/blob/master/manifests/init.pp
- https://github.com/example42/puppet-mysql
- https://github.com/jrodriguezjr/puppet-lamp-stack/blob/master/modules/mysql/manifests/init.pp
- https://ask.puppet.com/question/30752/creating-public_html-for-every-user/
- https://www.puppetcookbook.com/



# Raportti

## Moduulin käyttötarkoitus
Ideana on luoda moduuli mikä asentaa LAMP:in ja konfiguroiperusasetukset valmiiksi. Käyttäjähakemistot enabloidaan ja käyttäjien nettisivut tukevat heti php:tä. MySQL pyritään toteuttamaan, siten että ylläpitäjän ei tarvitsisi luoda omaa käyttäjää taikka positaa root tunnusta. Ainoastaan oman salasanan vaihtaminen/asettaminen jää moduulin ajajan harteille.

### Työskentely sujuvaksi githubin kanssa
Työstän moduulia aina live-istunnossa, joten moduulin kopioiminen joka kerta git kansiosta puppet kansioon on hidasta ja ärsyttävää. Jotta näin ei olisi täytyi minun luoda git tietueeseen kaksi tiedostoa;

  apply.sh 

      sudo puppet apply --modulepath puppet/modules/ -e 'class {lampmodule:}'
      
  start.sh
    
      sudo apt-get update
      git clone https://github.com/lkuusela/lampmodule.git
      bash apply.sh
Git tietueessa moduulini tulee olla polkuna /puppet/modules/lampmodule kuten polku apply.sh sanoo. Kun käynnistän koneen live-tikulla annan seuraavat komennot

      $ sudo apt-get update
      $ git clone https://github.com/lkuusela/lampmodule.git
      $ bash apply.sh
Bash apply.sh ajaa moduulin normaaliin tapaan. Voin muokata moduulia helposti siirtelemättä sitä mihinkään ja lopuksi tehdä git toimenpiteet päivittääkseni sen githubiin.

### Apache2 ja userdir
Aloitin moduulin veistämisen Apache2 ja userdir:istä. Halusin kuitenkin, että moduuli suorittaa päivityksen aina ennnen kuin aloittaa ohjelmien asennuksen. 

    class lampmodule {

    # Apache2 and userdir

Tässä suoritetaan apt-update komento        
        
        exec {'apt-update':
                command => '/usr/bin/apt-get update',
        }

Apache2 asennetaan, mutta require:rillä varmistetaan että apt-update on suoritettu

        package { 'apache2':
                ensure => 'installed',
                allowcdrom => 'true',
                require => Exec['apt-update'],
        }

Servicen tarkoitus on huolehtia, siitä että apache2 on käynnissä

        service { 'apache2':
                ensure => 'running',
                enable => 'true',
                require => Package['apache2'],
        }

Loin templates kansion polkuun /etc/puppet/modules/lampmodule/ ja sinne kopioin Apache testisivun tiedoston jota muokkasin oman mieleni mukaan ja lisäsin siihen vielä .erb päätteen. Kun haetaan localhostia selaimella, niin content uudelleen ohjaa haun templateskansiossa olevaan omaan tiedostooni ja saadaan minun muokkaamani sivu näkyviin. 

        file { '/var/www/html/index.html':
                content => template('lampmodule/index.html.erb'),
        }

Halusin asettaa käyttäjä hakemistot toimimaan selaimessa. Tämä varmistaa että käyttäjällä on public_html kansio.
Tarkoitus on että moduuli varmistaisi, että kaikilla käyttäjillä on tämä hakemisto, mutta aika näyttää saanko selvitettyä kuinka tämä toteutettaisiin.

        file { '/home/xubuntu/public_html':
                ensure => 'directory',

        }
En löytänyt ikinä tapaa jolla olisin saanut kaikille käyttäjille hakemistot ilman käyttäjä listan tekemistä. AskPuppet sivustolta sain myös vastauksen että puppet ei ole järin pätevä käsittelemään tietoja joita ei pysty listaamaan. https://ask.puppet.com/question/30752/creating-public_html-for-every-user/ 


Enabloi userdir:in ja ilmoittaa apache:lle, jotta tämä voi uudelleen käynnistyä automaattisesti

        exec { 'userdir':
                notify => Service['apache2'],
                command => '/usr/sbin/a2enmod userdir',
                require => Package['apache2'],
        }
        
        
### PHP
Halusin asentaa php:n normaaliin tapaan ja tehdä käyttäjille mahdolliseksi luoda heti php sivuja kotihakemistoihinsa.
Package toimii samalla tavalla kun edelläkin olevat, eli asentaa paketin. Käytin taas notify toimintoa jotta apache saisi ilmoituksen tapahtumasta ja vältyttäisiin virheilmotuksilta.

        package {'libapache2-mod-php':
                ensure => 'installed',
                notify => Service['apache2'],
                allowcdrom => 'true',
        }

Kopioin php7.0.conf tiedoston moduulin templates kansioon. Muokkasin tiedostoa lisäämällä # merkin seuraaviin kohtiin;

    # <IfModule mod_userdir.c>
    # <Directory /home/*/public_html>
    # php_admin_flag engine Off
    # </Directory>
    # </IfModule>

Tämän jälkeen lisäsin tiedostoon vielä .erb päätteen. Alla olevan koodin mukaan käyttäessään php7.0.conf tiedostoa haku uudelleen ohjataan templateskansiossa sijaitsevaan php7.0.conf.erb tiedostoon johon olin tehnyt edellä olevat muutokset. 

        file { '/etc/apache2/mods-available/php7.0.conf':
                content => template('lampmodule/php7.0.conf.erb'),
                require => Package['libapache2-mod-php'],
                notify => Service['apache2'],
        }
Nyt käyttäjä voi luoda php kotisivut ja ne toimivat. 

### mySQL

MySQL asentuu samalla tavalla, kuin muutkin paketit. Halusin ohittaa mySLQ root tunnuksen luonti vaiheen, joten laitoin root salasanaksi automaattisen salasana generoinnin. Nyt root tunnuksille pääsee sisään komennolla $sudo mysql .

         package {'mysql-server':
                ensure => 'installed',
                root => ['root_password' => 'auto'],
                allowcdrom => 'true',
         }

         

