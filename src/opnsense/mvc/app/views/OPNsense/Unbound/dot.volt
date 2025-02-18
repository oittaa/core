{#
 # Copyright (c) 2014-2015 Deciso B.V.
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without modification,
 # are permitted provided that the following conditions are met:
 #
 # 1. Redistributions of source code must retain the above copyright notice,
 #    this list of conditions and the following disclaimer.
 #
 # 2. Redistributions in binary form must reproduce the above copyright notice,
 #    this list of conditions and the following disclaimer in the documentation
 #    and/or other materials provided with the distribution.
 #
 # THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
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

<script>

    $( document ).ready(function() {
        $('tr[id="row_forwarding.info"]').addClass('hidden');
        /* Handle retrieval and saving of the single system forwarding checkbox */
        let data_get_map = {'frm_ForwardingSettings':"/api/unbound/settings/getSystemForward"};
        mapDataToFormUI(data_get_map).done(function(data) {
            /* only called on page load */
            if (data.frm_ForwardingSettings.forwarding.enabled) {
                toggle_nameservers(true);
            }
        });

        $(".forwarding-enabled").click(function() {
            saveFormToEndpoint(url="/api/unbound/settings/toggleSystemForward", formid='frm_ForwardingSettings');

            let checked = ($(this).is(':checked'));
            toggle_nameservers(checked);
        });

        function toggle_nameservers(checked) {
            if (checked) {
                ajaxGet(url="/api/unbound/settings/getNameservers", {}, callback=function(data, status) {
                    $('tr[id="row_forwarding.info"]').removeClass('hidden');
                    if (data.length && !data.includes('')) {
                        $('div[id="control_label_forwarding.info"]').append(
                            "<span>{{ lang._('The following nameservers are used:') }}</span>"
                        );
                        $('span[id="forwarding.info"]').append(
                            "<div><b>" + data.join(", ") + "</b></div>"
                        );
                    } else {
                        $('div[id="control_label_forwarding.info"]').append(
                            "<span>{{ lang._('There are no system nameservers configured. Please do so in ') }}<a href=\"/system_general.php\">System: General setup</a></span>"
                        );
                    }

                });
            } else {
                $('tr[id="row_forwarding.info"]').addClass('hidden');
                $('div[id="control_label_forwarding.info"]').children().not(':first').remove();
                $('span[id="forwarding.info"]').children().remove();
            }
        }


        /**
         * inline open dialog, go back to previous page on exit
         */
        function openDialog(uuid) {
            var editDlg = "DialogEdit";
            var setUrl = "/api/unbound/settings/setDot/";
            var getUrl = "/api/unbound/settings/getDot/";
            var urlMap = {};
            urlMap['frm_' + editDlg] = getUrl + uuid;
            mapDataToFormUI(urlMap).done(function () {
                // update selectors
                $('.selectpicker').selectpicker('refresh');
                // clear validation errors (if any)
                clearFormValidation('frm_' + editDlg);
                // show
                $('#'+editDlg).modal({backdrop: 'static', keyboard: false});
                $('#'+editDlg).on('hidden.bs.modal', function () {
                    // go back to previous page on exit
                    parent.history.back();
                });
            });


            // define save action
            $("#btn_"+editDlg+"_save").unbind('click').click(function(){
                saveFormToEndpoint(setUrl+uuid, 'frm_' + editDlg, function(){
                    // do reconfigure of unbound after save (because we're leaving back to the sender)
                    ajaxCall("/api/unbound/service/reconfigure", {}, function(data,status) {
                        $("#"+editDlg).modal('hide');
                    });
                }, true);
            });

        }

        /*************************************************************************************************************
         * link grid actions
         *************************************************************************************************************/

        $("#grid-dot").UIBootgrid(
                {   'search':'/api/unbound/settings/searchDot/',
                    'get':'/api/unbound/settings/getDot/',
                    'set':'/api/unbound/settings/setDot/',
                    'add':'/api/unbound/settings/addDot/',
                    'del':'/api/unbound/settings/delDot/',
                    'toggle':'/api/unbound/settings/toggleDot/'
                }
        );

        $("div.actionBar").parent().prepend($('<td id="heading-wrapper" class="col-sm-2 theading-text">{{ lang._('Custom forwarding') }}</div>'));

        /* Hide/unhide verify field based on type */
        if ("{{selected_forward}}" == "forward") {
            $('tr[id="row_dot.verify"]').addClass('hidden');
        } else {
            $('tr[id="row_dot.verify"]').removeClass('hidden');
        }

        {% if (selected_uuid|default("") != "") %}
            openDialog('{{selected_uuid}}');
        {% endif %}

        /*************************************************************************************************************
         * Commands
         *************************************************************************************************************/

        /**
         * Reconfigure unbound - activate changes
         */
        $("#reconfigureAct").SimpleActionButton();

	updateServiceControlUI('unbound');
    });

</script>

<style>
    .theading-text {
        font-weight: 800;
        font-style: bold;
    }
</style>

<div class="tab-content content-box col-xs-12 __mb">
    {# include base forwarding form #}
    {{ partial("layout_partials/base_form",['fields':forwardingForm,'id':'frm_ForwardingSettings'])}}
</div>
<ul class="nav nav-tabs" data-tabs="tabs" id="maintabs"></ul>
<div class="tab-content content-box col-xs-12 __mb">
    <div id="dot" class="tab-pane fade in active">
        <table id="grid-dot" class="table table-condensed table-hover table-striped table-responsive" data-editDialog="DialogEdit">
            <tr>
            <thead>
            <tr>
                <th data-column-id="enabled" data-width="6em" data-type="string" data-formatter="rowtoggle">{{ lang._('Enabled') }}</th>
                <th data-column-id="domain" data-type="string">{{ lang._('Domain') }}</th>
                <th data-column-id="server" data-type="string">{{ lang._('Address') }}</th>
                <th data-column-id="port" data-type="int">{{ lang._('Port') }}</th>
                {% if (selected_forward|default("") == "") %}
                <th data-column-id="verify" data-type="int">{{ lang._('Hostname') }}</th>
                {% endif %}
                <th data-column-id="commands" data-width="7em" data-formatter="commands" data-sortable="false">{{ lang._('Edit') }} | {{ lang._('Delete') }}</th>
                <th data-column-id="uuid" data-type="string" data-identifier="true" data-visible="false">{{ lang._('ID') }}</th>
            </tr>
            </thead>
            <tbody>
            </tbody>
            <tfoot>
            <tr>
                <td></td>
                <td>
                    <button data-action="add" type="button" class="btn btn-xs btn-primary"><span class="fa fa-fw fa-plus"></span></button>
                    <button data-action="deleteSelected" type="button" class="btn btn-xs btn-default"><span class="fa fa-fw fa-trash-o"></span></button>
                </td>
            </tr>
            </tfoot>
            </tr>
        </table>
    </div>
    <div id="infosection" class="tab-content col-xs-12 __mb">
        {{ lang._('Please note that entries without a specific domain (and thus all domains) specified in both Query Forwarding and DNS over TLS
        are considered duplicates, DNS over TLS will be preferred. If "Use System Nameservers" is checked, Unbound will use the DNS servers entered
        in System->Settings->General or those obtained via DHCP or PPP on WAN if the "Allow DNS server list to be overridden by DHCP/PPP on WAN" is checked.') }}
    </div>
    <div class="col-md-12">
        <hr/>
        <button class="btn btn-primary" id="reconfigureAct"
                data-endpoint='/api/unbound/service/reconfigure'
                data-label="{{ lang._('Apply') }}"
                data-error-title="{{ lang._('Error reconfiguring unbound') }}"
                type="button"
        ></button>
        <br/><br/>
    </div>
</div>

{# include dialog #}
{{ partial("layout_partials/base_dialog",['fields':formDialogEdit,'id':'DialogEdit','label':lang._('Edit server')])}}
