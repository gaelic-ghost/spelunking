#!/usr/bin/env zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

framework="/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
output_root="research/MediaRemote/experiments/message-ids/$timestamp"
mkdir -p "$output_root"

usage() {
  cat <<'EOF'
Usage: tools/mediaremote-message-id-callsites.zsh [--disassembly path]

Disassembles MediaRemote.framework through dyld_info, or reuses an existing
disassembly file, then extracts call sites that pass immediate message type
values to MRXPCConnection sendMessageWithType/sendSyncMessageWithType or
MRCreateXPCMessage.
EOF
}

disassembly=""
if (( $# > 0 )); then
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --disassembly)
      shift
      if (( $# == 0 )); then
        printf 'missing path after --disassembly\n' >&2
        exit 64
      fi
      disassembly="$1"
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
fi

if [[ -z "$disassembly" ]]; then
  disassembly="$output_root/mediaremote-disassemble.txt"
  dyld_info -disassemble "$framework" > "$disassembly" 2> "$output_root/disassemble.stderr"
fi

if [[ ! -f "$disassembly" ]]; then
  printf 'missing disassembly file: %s\n' "$disassembly" >&2
  exit 66
fi

perl - "$disassembly" > "$output_root/message-id-callsites.tsv" <<'PERL'
use strict;
use warnings;
no warnings 'portable';
use feature 'say';

my ($path) = @ARGV;
open my $fh, '<', $path or die "open $path: $!";

my $function = '<unknown>';
my %reg;
my @window;

sub remember {
    my ($line) = @_;
    push @window, $line;
    shift @window while @window > 12;
}

sub parse_imm {
    my ($value) = @_;
    return hex($1) if $value =~ /^#0x([0-9a-fA-F]+)$/;
    return int($1) if $value =~ /^#([0-9]+)$/;
    return undef;
}

sub record_call {
    my ($line, $target, $reg_name) = @_;
    my $state = $reg{$reg_name};
    return unless $state && defined $state->{value};

    my ($address) = $line =~ /^(0x[0-9A-Fa-f]+)/;
    $address //= '<unknown>';

    my $message_type = sprintf("0x%016X", $state->{value});
    my $domain = ($state->{value} >> 48) & 0xffff;
    my $ordinal = $state->{value} & 0xffffffffffff;
    my $source = join(" | ", @{$state->{instructions}});

    say join("\t", $address, $target, $function, $reg_name, $message_type, sprintf("0x%X", $domain), sprintf("0x%X", $ordinal), $source);
}

say join("\t", qw(address target function register message_type domain ordinal source_instructions));

while (my $line = <$fh>) {
    chomp $line;

    if ($line =~ /^(\S.*):$/ && $line !~ /^0x/) {
        $function = $1;
        %reg = ();
        @window = ();
        next;
    }

    if ($line =~ /^\s*$/) {
        next;
    }

    if ($line =~ /mov\s+(x[0-9]+),\s+(#[^\s]+)/) {
        my ($reg_name, $imm_text) = ($1, $2);
        my $imm = parse_imm($imm_text);
        if (defined $imm) {
            $reg{$reg_name} = {
                value => $imm,
                instructions => [ $line ],
            };
        }
    } elsif ($line =~ /movk\s+(x[0-9]+),\s+(#[^\s]+),\s+lsl\s+#([0-9]+)/) {
        my ($reg_name, $imm_text, $shift) = ($1, $2, $3);
        my $imm = parse_imm($imm_text);
        if (defined $imm && $reg{$reg_name}) {
            my $mask = 0xffff << $shift;
            $reg{$reg_name}->{value} &= ~$mask;
            $reg{$reg_name}->{value} |= ($imm & 0xffff) << $shift;
            push @{$reg{$reg_name}->{instructions}}, $line;
        }
    } elsif ($line =~ /mov\s+(x[0-9]+),\s+(x[0-9]+)/) {
        my ($dst, $src) = ($1, $2);
        if ($reg{$src}) {
            $reg{$dst} = {
                value => $reg{$src}->{value},
                instructions => [ @{$reg{$src}->{instructions}}, $line ],
            };
        } else {
            delete $reg{$dst};
        }
    }

    if ($line =~ /bl\s+.*sendMessageWithType:queue:reply:/) {
        record_call($line, 'sendMessageWithType:queue:reply:', 'x2');
    } elsif ($line =~ /bl\s+.*sendSyncMessageWithType:error:/) {
        record_call($line, 'sendSyncMessageWithType:error:', 'x2');
    } elsif ($line =~ /bl\s+_MRCreateXPCMessage/) {
        record_call($line, 'MRCreateXPCMessage', 'x0');
    }

    remember($line);
}
PERL

{
  printf '# MediaRemote Message ID Call Sites\n\n'
  printf -- '- timestamp: %s\n' "$timestamp"
  printf -- '- framework: %s\n' "$framework"
  printf -- '- disassembly: %s\n' "$disassembly"
  printf -- '- callsites: %s\n' "$output_root/message-id-callsites.tsv"
  printf -- '- rows: '
  tail -n +2 "$output_root/message-id-callsites.tsv" | wc -l | tr -d ' '
  printf '\n'
} > "$output_root/SUMMARY.md"

printf 'wrote %s\n' "$output_root"
