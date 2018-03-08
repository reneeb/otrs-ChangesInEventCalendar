# --
# Copyright (C) 2015 - 2018 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterContent::ChangeEvents;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Language
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Templatename = $ParamObject->GetParam( Param => 'Action') || '';

    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

    my $JS = sprintf q~
        <script type="text/javascript">//<![CDATA[
        Core.App.Ready( function() {
        if( !Core.Config.Get('LoadChangesInEventCalendar') ) {
            $('#calendar').fullCalendar(
                'addEventSource',
                {
                    url: Core.Config.Get('Baselink') + "Action=AgentChangesInEventCalendarEvents",
                    dataType: 'JSON',
                    success: function (data) {
                        var Container = $('.EventDetailsHiddenContainer');
                        $(data).each( function( index, eventdata ) {
                            var Details = $('<div class="EventDetails" id="event-content-' + eventdata.id + '"></div>');
                            var H3      = $('<h3>%s</h3>');
                            var Spacing = $('<div class="SpacingTopSmall"></div>');
                            var H4      = $('<h4>%s: ' + eventdata.title + '</h4>');

                            Details.append( H3 ).append( Spacing ).append( H4 );

                            Container.append( Details );
                        });
                    }
                }
            );

            Core.Config.Set('LoadChangesInEventCalendar', 1 );
        }
        });
        //]]></script>
    ~,
    $LanguageObject->Translate('Change Information'),
    $LanguageObject->Translate('ITSMChange');

    ${ $Param{Data} } =~ s~
        </body>
    ~$JS</body>~xms;

    ${ $Param{Data} } =~ s~div \s* class="Hidden \K ~ EventDetailsHiddenContainer~xms;

    return 1;
}

1;
