# Enrollment #

You must use version 0.1.0 or higher of RTanque. Previous versions do not respect seeds and will give random battle configurations.

Ruby 1.9.3 is required.

## Identifiers ##

Player handles are the player's plan name.

Tanks must be given a name via the `NAME` constant. This name is of the player's choosing. If multiple players choose the same name, the names will be disambiguated by appending a dash and the player's handle. For example, a tank named `"hulk"` would be disambiguated to `"hulk-youngian"`. This change will be made in the code before the battle commences.

## Submission ##

One non-participating individual will be designated as the Trusted Third Party (TTP). This person is charged with receiving and compiling links tank code gists, choosing a set of random numbers, and distributing this information to all players.

Tank code shall be placed in a gist (you may wish to make this a private gist). The URL for that gist shall be submitted to TTP by the arranged deadline.

If a player does not submit tank code by the deadline, their tank from the previous round will be used as-is. In the first round, players not submitting code will be assigned a tank arbitrarily.

# Rules and Restrictions #

## No zerging ##

Each player's tank code must spawn a single tank. Spawning more than one tank will result in immediate disqualification.

## Randomness ##

The only acceptable source of randomness is `Kernel.rand` or code that relies on this. Code must run completely deterministically if this is given a known seed.

## External resources ##

No remote resources. No net requests. No gigantic database files. No special platform dependencies. All this should be pretty obvious.

## Logging ##

Any logging/debug output *must* respect `ENV["LOG"]`. If this variable is not set, no logging should occur from the tank code. Failure to obey this rule is punishable by severe heckling.

Logging utilities *should* respect the standard log levels (as described in the [Logger docs](http://www.ruby-doc.org/stdlib-2.0/libdoc/logger/rdoc/Logger.html)) and limit logging to `DEBUG`, `INFO`, and `WARN`.

# Fight day #

The TTP compiles a list of links to tank code for each player.

The TTP generates an ordered list of random numbers. The list should contain n^2 numbers, where n is the number of players. These numbers should be sufficiently long, say, between 0 and 1 trillion.

The TTP emails all gist links and the list of random numbers to all players. Upon receiving this information, players are able to replay the battles on their own machines with identical results.

## Tournament format ##

Battles are run in order until one player reaches 3 victories. This player wins the round.

To achieve victory in a battle, simply be the last tank standing. If the battle ends (due to the tick limits) with more than one tank remaining, each player receives the appropriate fraction of a victory. For example, if three tanks remain, each player receives 1/3 of a victory, which is about as useful as it sounds.

If multiple players achieve 3 victories at the same time (due to a tied battle), the round is tied and everyone involved should feel embarrassed.

## Running a battle ##

### Easy version ###

```bash
git clone git://github.com/iangreenleaf/tanked.git
cd tanked
bundle install
git checkout round-01 # or whatever round you wish
./fight 1
./fight 2
# And so on for however many rounds take place
```

### Hard version ###

Download each tank code from the linked gists. This can be done manually or using this command:

    bundle exec rtanque get_gist <gist_id> ...

Tank code files should be renamed using the player's handle, in the `bots` directory. For example, Ian Young's tank code will be placed in `bots/youngian.rb`.

If a tank needs multiple files, these may be placed in a directory in `bots` named for the player's handle. The primary tank code will be named as before in the main `bots` directory and may require these additional files.

To begin the battle, invoke the command with the following parameters:

 * Each player's tank is passed in alphabetical order by handle (order is important).
 * Pass the `--seed` option with a number from the list of random numbers. Numbers are used from the list in order, so the first battle uses the first number on the list, the second battle uses the second number, and so on.
 * Pass `--max-ticks=50000`.

For example, a battle might be invoked as follows:

    bundle exec rtanque start bots/depetris bots/kuipersb bots/lundersk bots/sedberry bots/william3 bots/youngian --seed 187807059976434646498980857137039991886 --max-ticks=50000

### Errors and other failures ###

If a player's tank code throws an exception that crashes the battle, that player is immediately eliminated from the battle. The battle is then restarted with exactly the same parameters (including the same random seed), except the eliminated player's tank is not included.

If a player's code enters an endless loop or demands unreasonable amounts of processing power such that the battle will not complete in a reasonable amount of clock time, the player will be eliminated as described above. Just like obscenity, we'll know it when we see it.
