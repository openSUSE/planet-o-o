# 🌎 [Planet DSA](https://planet.dsausa.org)

Planet DSA is a web feed aggregator forked from [Planet openSUSE](https://planet.opensuse.org) that collects blog posts from various DSA chapters across the country, national working groups and committees, and our publications. 

## Adding your feed
If you want to get your website added, we need your webpage to have an RSS feed. TBD for how to contribute -- Github form?

* Fork this repository
* Edit [planet.ini](https://github.com/dsa-ntc/dsa-planet/blob/master/planet.ini) and add:

```ini
[id]         # replace id with your feed's unique identifier (a-z0-9-_) (eg. open-build-service)
  title    = # title of your feed                                       (eg. Open Build Service)
  feed     = # url to your rss/atom feed                                (eg. https://openbuildservice.org/feed)
  link     = # link to the main page of your website                    (eg. https://openbuildservice.org)
  location = # ISO_639 language code (may include ISO 3166 country code)(eg. zh_TW)
  author   = # connect:openSUSE_nickname to contact you                 (eg. connect:obs)
             # some other tags about the author are possible, all added space separated
             #   irc:libera_nickname     (eg. irc:obs)
             #   member
             #   gsoc
  avatar   = # (optional) filename or url of your avatar                (eg. obs.png)
  email    = # (optional) your contact email                            (eg. admin@opensuse.org)
```

* Upload your avatar to [hackergotchi directory](https://github.com/dsa-ntc/dsa-planet/blob/master/hackergotchi)
* Send a Pull Request

Alternatively you can send an email to ntc@dsacommittees.org with all the mandatory information listed above

## Development environment
To run this website locally, use the following commands:
```sh
bundler install
bundler exec rake build
bundler exec jekyll serve
```
and visit [127.0.0.1:4000](http://127.0.0.1:4000)
