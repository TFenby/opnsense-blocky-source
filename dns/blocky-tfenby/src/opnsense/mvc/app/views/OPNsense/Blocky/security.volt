{#
 # Copyright (C) 2024 Tyler Fenby <opnsense@fenby.me>
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without modification,
 # are permitted provided that the following conditions are met:
 #
 # 1.  Redistributions of source code must retain the above copyright notice,
 #     this list of conditions and the following disclaimer.
 #
 # 2.  Redistributions in binary form must reproduce the above copyright notice,
 #     this list of conditions and the following disclaimer in the documentation
 #     and/or other materials provided with the distribution.
 #
 # THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 # INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 # AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 # AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 # OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 # POSSIBILITY OF SUCH DAMAGE.
 #}

<ul id="securityTabsHeader" class="nav nav-tabs" role="tablist">
    {{ partial("layout_partials/base_tabs_header", ['formData': securityForm]) }}
</ul>

<div id="securityTabsContent" class="content-box tab-content">
    {{ partial("layout_partials/base_tabs_content", ['formData': securityForm]) }}
</div>

<script>
$( document ).ready(function() {
    mapDataToFormUI({'frm_security': "/api/blocky/settings/get"}).done(function(data){
        formatTokenizersUI();
        $('.selectpicker').selectpicker('refresh');
    });

    $('[id^="save_security-"]').each(function () {
        var $btn = $(this);
        var formId = this.id.replace(/^save_/, 'frm_');
        $btn.SimpleActionButton({
            onPreAction: function() {
                var dfrd = $.Deferred();
                saveFormToEndpoint(
                    "/api/blocky/settings/set",
                    formId,
                    function() { dfrd.resolve(); },
                    true,
                    function() { dfrd.reject(); }
                );
                return dfrd;
            }
        });
    });
});
</script>
