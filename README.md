# Cookie Collector

Cookie Collector is a Discord bot meant to help encourage chat activity through a simple, yet fun
way of letting people collect cookies!

It is currently in development and is not publically available for inviting just yet. But when it is available, the bot can be invited from [here](https://discord.com/oauth2/authorize?client_id=659480764915777536&scope=bot&permissions=2416241856).

# Self Hosting
Cookie Collector runs on [Dart](https://dart.dev).
It also requires a MySQL or MariaDB database with a user who has access to `CREATE, INSERT, SELECT, UPDATE`.

Once cloning the repository, run `pub get` in the source folder to get the required dependencies. Then adjust `bin/config.toml` as necessary.

After that run (from the root folder of the bot) `dart run bin/main.dart`.