# --
# Kernel/Modules/AgentChangesInEventCalendarEvents.pm - return all event data for changes
# Copyright (C) 2015 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentChangesInEventCalendarEvents;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::Output::HTML::Layout
    Kernel::System::Time
    Kernel::System::Web::Request
    Kernel::System::ITSMChange
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{Debug} = 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject      = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TimeObject       = $Kernel::OM->Get('Kernel::System::Time');
    my $ITSMChangeObject = $Kernel::OM->Get('Kernel::System::ITSMChange');
    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my @EventsForCalendar;
    my @From   = $TimeObject->SystemTime2Date(
        SystemTime => $ParamObject->GetParam( Param => 'start' ),
    );

    my @To = $TimeObject->SystemTime2(
        SystemTime => $ParamObject->GetParam( Param => 'end' ),
    );

    my $Start = sprintf( "%04d-%02d-%02d 00:00:00", @From[5,4,3] ),
    my $To    = sprintf( "%04d-%02d-%02d 23:59:59", @To[5,4,3] ),

    my @StartEvents = $ITSMChangeObject->ChangeSearch(
        PlannedStartTimeNewerDate => $Start,
        PlannedStartTimeOlderDate => $To,
        UserID                    => $Self->{UserID},
    );

    my @EndEvents = $ITSMChangeObject->ChangeSearch(
        PlannedEndTimeNewerDate => $Start,
        PlannedEndTimeOlderDate => $To,
        UserID                  => $Self->{UserID},
    );

    my $Color = $ConfigObject->Get('ITSMChange::CalendarColor') || '#aa0000';
    
    my %ChangesSeen;

    CHANGEID:
    for my $ChangeID ( @StartEvents, @EndEvents ) {
        next CHANGEID if $ChangesSeen{$ChangeID}++;

        my $Change = $ITSMChangeObject->ChangeGet(
            UserID   => $Self->{UserID},
            ChangeID => $ChangeID,
        );

        my $FromSeconds = $TimeObject->TimeStamp2SystemTime(
            String => $Change->{PlannedStartTime},
        );        

        my $ToSeconds = $TimeObject->TimeStamp2SystemTime(
            String => $Change->{PlannedEndTime},
        );        

        my $Title = sprintf "%s - %s", $Change->{Number}, $Change->{ChangeTitle};

        push @EventsForCalendar, {
                id     => 'change-' . $Event->{ID},
                title  => $Title,
                start  => $FromSeconds,
                end    => $ToSeconds,
                color  => $Color,
                allDay => 1,
            };
        }
    }

    my $JSON = $LayoutObject->JSONEncode( Data => \@EventsForCalendar );

    return $LayoutObject->Attachment(
        ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
        Content     => $JSON || '',
        Type        => 'inline',
        NoCache     => 0,
    );
}

1;
