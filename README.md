# NOTICE

Cookie Collector has now been recreated and replaced by my friend [here](https://github.com/MrCookieBot/MrCookie) as he has started his journey
into the world of programming like I once did.

Because of this, this bot and repository will sit idle for a while and eventually be archived. I would say that this bot helped me learn a tremendous amount
during the span of me slowly learning more about programming and then applying that to the code. I am extremely happy with how Cookie Collector came to be
and how it has served both me and the Discord servers it was in over time.

With this in mind, this repository will ultimately be left to sit as a reference for anyone potentially curious about making a Discord bot with Dart (even though 
it is using chat commands, which are not the suggested way of running commands anymore).

Going forward I expect to continue working on little things related to my other hobby discord bot, [Pyrite](https://github.com/Pyrite-X/Pyrite), 
and my work for [Bloxlink](https://github.com/bloxlink/) (as long as I work there xD), and at some point anything related to my career or hobbies!

---
<br>

## **Cookie Collector**

Cookie Collector is a Discord bot meant to help encourage chat activity through a simple, yet fun
way of letting people collect cookies!

---

### **Self Hosting**

Cookie Collector runs on [Dart](https://dart.dev).
It also requires a MySQL or MariaDB database with a user who has access to `INSERT, SELECT, & UPDATE`, with `CREATE` optionally.

The expected database configuration is not made upon initialization of the bot, as such it is either required to manually run [these queries](https://github.com/One-Nub/cookie-collector-bot/blob/master/lib/src/core/CCDatabase.dart#L34)
or to call the `CCDatabase().initializeTables` method yourself.

After cloning the repository, run `pub get` in the source folder to get the required dependencies. The variables required for the bot to run can be found in the [example.env](https://github.com/One-Nub/cookie-collector-bot/blob/master/bin/example.env)
which should be renamed to `.env` for development usage.

--- 
### **Running the Bot**

To run the bot, it can be run manually with `dart run bin/main.dart` (or `/main-local.dart` for development usage - this file looks for the .env file).

Alternatively, the bot can be run via a [Docker](https://www.docker.com/) container. All that is required is that the image is first built, which can be done by cloning the repo & running `docker build -t cc_bot .` in the cloned directory. Then after that, you can run the image in your preferred way, either through [Docker Compose](https://docs.docker.com/compose/), the [docker run](https://docs.docker.com/engine/reference/run/) command, or some other utility like [Portainer](https://www.portainer.io/).

Cookie Collector needs a MariaDB database to connect to, as well as a Redis client to connect to. The (docker compose)[docker-compose.yml] file does not include a MariaDB instance, 
but it does include the Redis instance. As mentioned previously, prior to the first usage of the bot it is necessary that the database is set up with the default tables!
