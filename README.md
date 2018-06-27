# sso-demo
Single Sign On demo setup, which forms a basis for testing you app with Shibboleth/SAML-based authentication.

## Build
```sh
docker build -t sso-demo-sp sso-demo-sp
docker build -t sso-demo-idp sso-demo-idp
```

## Run
The SP and IdP need to exchange metadata, but also your browser needs access to both via the same hostnames. Lookup the `IP` address of your machine (for scripting see [stackoverflow](https://stackoverflow.com/questions/13322485/how-to-get-the-primary-ip-address-of-the-local-machine-on-linux-and-os-x)).

```sh
docker run -p 443:443 --name=sso-demo-sp --rm -it --add-host sp.example.org:IP --add-host idp.example.org:IP sso-demo-sp
```

Wait till the SP runs, then start the IdP so it can fetch some metadata.

```sh
docker run -p 9443:8443 --name=sso-demo-idp --rm -it --add-host sp.example.org:IP --add-host idp.example.org:IP sso-demo-idp
```

Add the same IP to `sp.example.org` and `idp.example.org` to your `/etc/hosts`:

```
IP    sp.example.org idp.example.org
```

Visit https://sp.example.org/ and click on [Shibboleth login](https://sp.example.org/Shibboleth.sso/Login?target=https://sp.example.org/index.php) to login via the IdP (use `jsmith:password` (see sso-demo-idp/ldap/users.ldif)).

Shibboleth requires HTTPS and this setup uses self-signed certificates, so you'll have to (temporarily) accept those.

## Adaption

(to be extended)

### Apache

- add your app to the SP Apache
- add a proxy to your application to the SP Apache config, make sure the pass on `REMOTE_USER`
```
SSLProxyEngine On # so we can proxy to a https:// address
ProxyPreserveHost On # so the app on the inner server thinks it runs on www.meertens.knaw.nl
<Location /APP>
    AuthType shibboleth
    ShibRequireSession Off
    ShibUseHeaders On
    Satisfy All
    Require shibboleth
    RewriteCond %{REMOTE_USER} (.+)
        RewriteRule . - [E=RU:%1]
        RequestHeader set REMOTE_USER %{RU}e
    ProxyPass https://PROXY/APP
    ProxyPassReverse https://PROXY/APP
</Location>

```
- mimic the `mod_shib` setup in your own environment and reuse the IdP

## Acknowledgements

Based on https://github.com/UniconLabs/sso-demo-docker (via https://github.com/menzowindhouwer/sso-demo-docker)