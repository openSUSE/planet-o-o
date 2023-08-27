# 🌎 [DSA Feed](https://feed.dsausa.org) 🌹
[Read our announcement post on tech.dsausa.org 
here](https://tech.dsausa.org/introducing-dsa-feed-an-aggregator-for-dsa-publications-from-the-ntc/)

DSA Feed is a web feed aggregator forked from [Planet
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
  title    = # title of your feed                                       (eg. DSA Chapter News or something like Publication Name: A Blog of this DSA Chapter)
  feed     = # url to your rss/atom feed                                (eg. https://dsausa.org/feed)
  link     = # link to the main page of your website                    (eg. https://dsausa.org)
  location = # ISO_639 language code (may include ISO 3166 country code)(eg. en)
  avatar   = # filename or url of your avatar in hackergotchi dir       (eg. obs.png)
  email    = # (optional) your contact email                            (eg. admin@opensuse.org)
```
An example you may copy and paste is here: 
```
[exampledsa]
 title     = Example DSA
 feed      = https://www.example.com/feed/
 link      = https://www.example.com
 location  = en
 avatar    = example.png
 email     = dsa@example.com
```
* Upload your avatar to [hackergotchi directory](https://github.com/dsa-ntc/dsa-planet/blob/master/hackergotchi)
  * Supported formats: `jpg`, `png`, (some) `svg` files, and `webp`. When in doubt, just use your chapter's Twitter or Facebook avatar. Webp is preferred as it speeds up load times
* Send a Pull Request

Alternatively you can send an email to 
[ntc@dsacommittees.org](mailto:ntc@dsacommittees.org?subject=%5Bdsa-feed%5D%20&body=I%20have%20a%20question%20about%20DSA%20Feed)
with all the mandatory information listed above

## Development environment
To run this website locally, use the following commands:

```sh
git clone https://github.com/dsa-ntc/dsa-planet # substitute in your fork url if you're using your fork
cd dsa-planet
bundler install
bundler exec rake build
bundler exec jekyll serve
```
and visit [127.0.0.1:4000](http://127.0.0.1:4000)
