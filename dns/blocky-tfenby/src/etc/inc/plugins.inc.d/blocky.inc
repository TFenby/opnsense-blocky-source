<?php

/*
 * Copyright (C) 2024 Tyler Fenby <opnsense@fenby.me>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

function blocky_enabled()
{
    $model = new \OPNsense\Blocky\Blocky();
    return (string)$model->general->enabled == '1';
}

function blocky_configure()
{
    return [
        'dns' => ['blocky_configure_do'],
    ];
}

function blocky_services()
{
    $services = [];

    if (!blocky_enabled()) {
        return $services;
    }

    $services[] = [
        'dns_ports' => ['5353'],
        'description' => gettext('Blocky DNS'),
        'configd' => [
            'restart' => ['blocky restart'],
            'start' => ['blocky start'],
            'stop' => ['blocky stop'],
        ],
        'pidfile' => '/var/run/blocky.pid',
        'name' => 'blocky',
    ];

    return $services;
}

function blocky_configure_do($verbose)
{
    service_log('Starting Blocky DNS...', $verbose);
    configd_run('template reload OPNsense/Blocky');
    configd_run('blocky restart');
    service_log("done.\n", $verbose);
}

function blocky_syslog()
{
    $logfacilities = [];
    $logfacilities['blocky'] = ['facility' => ['blocky']];
    return $logfacilities;
}
