<?php
/**
 *    Copyright (C) 2024 Tyler Fenby <opnsense@fenby.me>
 *    All rights reserved.
 *
 *    Redistribution and use in source and binary forms, with or without
 *    modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *
 *    2. Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *    THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 *    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *    AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 *    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *    POSSIBILITY OF SUCH DAMAGE.
 */

// Path to OPNsense core inside the container (cloned during Docker build)
$ui_core_dir = '/opt/core';
require_once rtrim($ui_core_dir, '/') . '/src/opnsense/mvc/app/config/AppConfig.php';

return new OPNsense\Core\AppConfig([
    'application' => [
        'baseUri'   => '/opnsense_gui/',
        'cacheDir'  => '/opt/ui_devtools/cache/',
        'tempDir'   => '/opt/ui_devtools/temp/',
        'configDir' => '/opt/ui_devtools/conf/',
    ],
    'globals' => [
        'debug'         => false,
        'owner'         => 'wwwonly:wheel',
        'simulate_mode' => true,
        'contrib'       => [],
    ],
    'environment' => [
        'packages' => [
            '/opt/plugin/dns/blocky-tfenby',
        ],
        'coreDir'  => $ui_core_dir,
    ],
]);
