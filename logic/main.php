#!/usr/bin/env php
<?php
include("../lib/config.php");
include("../lib/update_kml.php");

include("../lib/validators.php");
include("../lib/api.php");
include("../lib/hub.php");

// Database
include("../lib/db/sessions.php");

// event handlers
include("./session.php");
include("./chat.php");
include("./claims.php");
include("./pieces.php");
include("./users.php");
include("./eggs.php");

/*
 *     MAIN CODE
 */

// Parse opts and set variables
$opts = getopt("dti:");

// to distinguish several logic instances
$LOGIC_ID= isset($opts['i']) ? $opts['i'] : (string) rand(1,65535);
$TEST_MODE = isset($opts['t']);
$DEBUG_MODE = isset($opts['d']) || getenv('MC_DEBUG');

// Main pipe reading/writing loop
$fp=fopen("php://stdin","r");
while(!feof($fp)) {
    $cmd = stream_get_line($fp, 4 * 1024 * 1024, "\n");
    $res = new HubResult();

    // Try to handle command. catch all exceptions
    try {
        process_hub_message($cmd, $res);
    }
    catch(Exception $e) {
        trigger_error("Exception: " . $e->getMessage());
        $msg = error_msg($e->getMessage());
        $res->to_sender($msg);
    }

    $res->output();

    if($DEBUG_MODE)
        trigger_error("Logic respond:\nvvvvvvvv\n" . join("\n", $res->data) . "\n^^^^^^^^^ ");

    // break after first run in testing mode
    if($TEST_MODE)
        break;
}
fclose($fp);

?>
