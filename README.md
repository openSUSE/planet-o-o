# 🌎 [Planet DSA](https://planet.dsausa.org)

Planet DSA is a web feed aggregator forked from [Planet
openSUSE](https://planet.opensuse.org) that collects blog posts from various DSA
chapters across the country, national working groups and committees, and our
local and national publications. 

## Adding your feed
If you want to get your website or publication added, we need your webpage to
have an RSS feed. Any WordPress or many other providers provide this by default!
Once you have your RSS feed, submit it over via the [new Feed
form](https://github.com/dsa-ntc/dsa-planet/issues/new?assignees=&labels=addition&projects=dsa-ntc%2Fdsa-planet&template=feed-request.yml&title=%5BFEED%5D%3A+)

* Fork this repository
* Edit [planet.ini](https://github.com/dsa-ntc/dsa-planet/blob/master/planet.ini) and add:

```ini
[id]         # replace id with your feed's unique identifier (a-z0-9-_) (eg. dsa-chapter)
  title    = # title of your feed                                       (eg. DSA Chapter News)
  feed     = # url to your rss/atom feed                                (eg. https://dsausa.org/feed)
  link     = # link to the main page of your website                    (eg. https://dsausa.org)
  location = # ISO_639 language code (may include ISO 3166 country code)(eg. en)
  avatar   = # filename or url of your avatar in hackergotchi dir       (eg. obs.png)
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
