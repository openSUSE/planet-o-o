# 🌎 [Planet openSUSE](https://planet.opensuse.org)

Planet openSUSE is a web feed aggregator that collects blog posts from people who contribute to openSUSE.

## Adding your feed
If you want to get your feed added, we prefer Pull Requests via GitHub.

* Fork this repository
* Edit [planet.ini](https://github.com/openSUSE/planet-o-o/blob/master/planet.ini) and add:

```ini
[id]         # replace id with your feed's unique identifier (a-z0-9-_) (eg. open-build-service)
  title    = # title of your feed                                       (eg. Open Build Service)
  feed     = # url to your rss/atom feed                                (eg. https://openbuildservice.org/feed)
  link     = # link to the main page of your website                    (eg. https://openbuildservice.org)
  location = # two letter language code                                 (eg. en)
  avatar   = # (optional) filename or url of your avatar                (eg. obs.png)
  email    = # (optional) your contact email                            (eg. admin@opensuse.org)
  author   = # (optional) includes various space separated tags about the author:
             #   irc:freenode_nickname     (eg. irc:obs)
             #   connect:openSUSE_nickname (eg. connect:obs)
             #   member
             #   gsoc
```

(You can verify if your feed is properly formatted by running `./feedcheck feed_url`)

* Upload your avatar to [hackergotchi directory](https://github.com/openSUSE/planet-o-o/blob/master/hackergotchi)
* Send a Pull Request

Alternatively you can send an email to admin@opensuse.org with all the mandatory information listed above

## Development environment
To run this website locally, use the following commands:
```sh
bundler install
./update.sh
bundler exec jekyll serve
```
and visit [127.0.0.1:4000](127.0.0.1:4000)
