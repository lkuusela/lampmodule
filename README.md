# lampmodule

## moduuli, mikä asentaa LAMP:in ja kofiguroi sen valmiiksi käyttäjille

- oletuksena, että käyttäjät ovat luoneet valmiiksi itselleen polun /home/käyttäjä/public_html

## Tämän pitäisi toimia jollain tasolla
  
    package {"mysql-server":
                ensure => "installed",
                root => ["root_password" => "auto"],
                allowcdrom => "true",
        }





## Lähteitä

- http://simosuominen.com/index.php/2017/04/14/palvelinten-hallinta-kotitehtavat-3/
- https://github.com/rgevaert/puppet-mysql/blob/master/manifests/init.pp
- https://github.com/example42/puppet-mysql



# Raportti

## Moduulin käyttötarkoitus
Ideana on luoda moduuli mikä asentaa LAMP:in ja konfiguroiperusasetukset valmiiksi. Käyttäjähakemistot enabloidaan ja käyttäjien nettisivut tukevat heti php:tä. MySQL pyritään toteuttamaan, siten että ylläpitäjän ei tarvitsisi luoda omaa käyttäjää taikka positaa root tunnusta. Ainoastaan oman salasanan vaihtaminen/asettaminen jää moduulin ajajan harteille.

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

Enabloi userdir:in ja ilmoittaa apache:lle, jotta tämä voi uudelleen käynnistyä automaattisesti

        exec { 'userdir':
                notify => Service['apache2'],
                command => '/usr/sbin/a2enmod userdir',
                require => Package['apache2'],
        }
