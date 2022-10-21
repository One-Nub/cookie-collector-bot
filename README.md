## **Cookie Collector**

---

Cookie Collector is a Discord bot meant to help encourage chat activity through a simple, yet fun
way of letting people collect cookies!

It is currently in development and is not publicly available for inviting just yet. But when it is available, the bot can be invited from [here](https://discord.com/oauth2/authorize?client_id=659480764915777536&scope=bot&permissions=2416241856).

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

To run the bot, it can be ran manually with `dart run bin/main.dart` (or `/main-local.dart` for development usage - this file looks for the .env file).

Alternatively, the bot can be run via a [Docker](https://www.docker.com/) container. All that is required is that the image is first built, which can be done by cloning the repo & running `docker build -t cc_bot .` in the cloned directory. Then after that, you can run the image in your preferred way, either through [Docker Compose](https://docs.docker.com/compose/), the [docker run](https://docs.docker.com/engine/reference/run/) command, or some other utility like [Portainer](https://www.portainer.io/).
