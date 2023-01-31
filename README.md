![Build](https://github.com/build-failure/nginx-modsecurity/actions/workflows/main.yml/badge.svg)

# Nginx ModSecurity

Provides containerized Nginx reverse-proxy with [ModSecurity WAF](https://github.com/SpiderLabs/ModSecurity-nginx) library,
[ModSecurity-nginx](https://github.com/SpiderLabs/ModSecurity-nginx) module and [OWASP Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset).

Based on official [Nginx Docker image](https://hub.docker.com/_/nginx).

[ModSecurity WAF](https://github.com/SpiderLabs/ModSecurity-nginx) is installed and included as a dynamic module according to the [official documentation](https://github.com/SpiderLabs/ModSecurity/wiki/Compilation-recipes-for-v3.x).

# Supported Versions

Below the list of current supported version combinations between [Nginx](https://www.nginx.com/), [ModSecurity WAF](https://github.com/SpiderLabs/ModSecurity-nginx),
[ModSecurity-nginx](https://github.com/SpiderLabs/ModSecurity-nginx) and [OWASP Core Rule Set (CRS)](https://github.com/coreruleset/coreruleset).

| Nginx | ModSecurity | ModSecurity-nginx | OWASP Core Rule Set (CRS) |
|---|---|---|---|
| 1.22.1 | 3.0.8 | 1.0.3 | 3.3.4 |

# Usage

See [Nginx Docker image documentation](https://hub.docker.com/_/nginx) for advanced usage examples.

    $ docker run --name some-nginx -v /some/content:/usr/share/nginx/html:ro -d nginx

# Test
For testing purposes use the nginx server [default.conf](test/etc/nginx/conf.d/default.conf) configuration file with [ModSecurity WAF](https://github.com/SpiderLabs/ModSecurity-nginx) enabled.

[WAF Bypass Tool](https://github.com/nemesida-waf/waf-bypass) is used to analyze the WAF runtime protection to compare different WAFs.

    $ cd test
    $ docker-compose run waf-anylizer
    ...

# License

See the [LICENSE.md](LICENSE.md) file for details.
