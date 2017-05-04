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
