sendy-sync
==========

A set of bash scripts that keeps Sendy's lists synchronized with a system's users database.

Foreword
--------

The motivation for the project arises from the inability to synchronize the users of a system with the subscribers of Sendy lists using the users attributes to decide in which lists the user must be subscribed. Currently, Sendy API provides very basic functionality to manage subscriptions, and its use involves risks that the list runs out of date when communication problems occur.
This project attempts to implement a solution that ensures that the lists are kept synchronized without modifying Sendy's code.

Setup
-----

The first step to setup sendy-sync is to create a configuration file called `config.sh`. You can use complete and rename `config.sh.sample`.

The second step is to define the lists that will be synchronized, which must be done including the lists IDs in files with extension `.lists` located in the `local/` folder. Also, each list name must be changed to include its code (just add it the suffix " - [code]") that will be used to filter users that will be subscribed to it. [See the example.](#example)

Finally, the users information must be located in the `remote/` folder in CSV format and .csv extension. It must include the user name in the first field, its e-mail address in the second field and the lists codes in the other fields. [See the example.](#example)

Use
---

The command `sendy-fetch.sh` dumps the current subscribers of Sendy's lists included in `.lists` files. This command *must* be run at least once before using the other command. We recommend running this command on a regular basis (eg weekly) to ensure that the Sendy lists are synchronized with the users database.

The command `sendy-sync.sh` should be run each time the users files in the `remote\` folder are updated. It will add and delete subscribers from Sendy's lists to make these correspond to the data in users files.

Features
--------

* Updates Sendy's lists with users data in CSV format.
* Filters users to subscribe to each list using user-defined codes. Specifically, it uses a prefix system, which allows to assign a user to several lists with a unique code. This is useful in cases of hierarchical lists where the code is compound by the parents codes followed by the child code.
* Prevents process the same file version several times. If a synchronization process halts, it can be resumed running it again.

Example
-------

**Goal**: Manage lists by country and region in Sendy syncronized with a system users.

1. Create lists for each country and region to use in Sendy. Assign a code to each country and to each region. For example, ES_A_ could be the code for Alicante, Spain (note the final underscore to prevent mixing ES_A with ES_AV). You can create a script that extract these from a public database and run SQL commands to insert them into Sendy.
2. Dump IDs of created lists into a file called `local/geo.lists`. You can extract these ID from the URLs of the lists in Sendy (`http://{YOUR_DOMAIN}/subscribers?i={APP_ID}&l={LIST_ID}`) or directly from the `lists` table in the database. You have to add one list ID per line:

   ```
   4
   8
   15
   16
   23
   42
   ```
   
3. Execute the command `sendy-fetch.sh`. You should schedule a weekly execution, for example with cron. Here is an example of cron contents that runs a fetch process every Thursday at 3AM.
   ```
   0 3 * * 4 cd [SENDY-SYNC-FOLDER] && ./sendy-fetch.sh > /var/log/sendy-sync/fetch.log
   ```

4. Dump the users database including name, email and location code. Sample data for this could be:

   ```
   "John Doe",john.doe@example.com,US_DE_
   "Juan Perez",juan.perez@example.com,ES_A_
   ```
5. Execute the command `sendy-sync.sh`.
6. Again, you should schedule a daily execution of these two last steps, in the same order. Here is an example of cron contents that runs a syncronization process every day at 5AM. It assumes that there is a script that updates the csv with users information.

   ```
   0 5 * * * [SCRIPT_PATH]/get_users.sh && cd [SENDY-SYNC-FOLDER] && ./sendy-sync.sh > /var/log/sendy-sync/sync.log
   ```

7. Profit!

Requirements
------------
* Sendy (tested with 1.1.8.2)
* Python (tested with version 2.6.9)
* curl (tested with version 7.38)

Bonus track
-----------
Sendy doesn't paginate the lists view. If you are going to work with more than a few hundreds lists, this could make very slow loading this page. A [patch file](list.patch) is included in the repo that implement a list filter with just three changes in Sendy's file `list.php`:

* Add a search form between the page title and the "Add new list" button.
   ```
   <form style="float:right">Filter by name: <input type="text" name="filter" value="<?php echo $_GET['filter']?>"/><input type="hidden" name="i" value="<?php echo get_app_info('app')?>"/></form>
   ```

* Modify the query with the filter and limit the number of rows to show (after the `tbody` element).
   ```
    $where = $_GET["filter"];
    if ($where) $where = " AND name LIKE '%".$mysqli->real_escape_string($where)."%'";
    $q = 'SELECT id, name FROM lists WHERE app = '.get_app_info('app').' AND userID = '.get_app_info('main_userID').$where.' ORDER BY name ASC LIMIT 101';

    $r = mysqli_query($mysqli, $q);
    $nr = $r?min(mysqli_num_rows($r),101):0;
    if ($r && $nr > 0)
    {
        if ($nr>100) {
            echo "<tr><td colspan=7>"._('There are too many lists to show. Not all lists are shown. Use filter to look for a list.')."</td></tr>";
        }
        while(($row = mysqli_fetch_array($r)) && $nr-- > 0)
   ```

* Change the message shown when there are no lists to show if the filter is active (in the last `echo`).
   ```
   <td>'.($where?_('No list matches your filter.'):_('No list yet.').' <a href="'.get_app_info('path').'/new-list?i='.get_app_info('app').'" title="">'._('Add one').'</a>!').'</td>`
   ```
