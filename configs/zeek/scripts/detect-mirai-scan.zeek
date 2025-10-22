##! Detect Mirai-like scanning patterns on Telnet ports
##! Author: Michał Król

module Mirai;

export {
    redef enum Notice::Type += {
        ## Indicates Mirai-like scanning behavior detected
        Mirai_Scan_Detected,
        
        ## Indicates Mirai credential attempt
        Mirai_Credentials_Attempt
    };
    
    ## Time window for scan detection (seconds)
    const scan_window = 60sec &redef;
    
    ## Minimum number of connections to trigger alert
    const scan_threshold = 10 &redef;
}

# Track scanning sources
global scan_tracker: table[addr] of table[time] of addr &create_expire=2min;

# Known Mirai credentials
const mirai_creds = set(
    "root:xc3511",
    "root:vizxv",
    "root:admin",
    "admin:admin",
    "root:888888",
    "root:xmhdipc"
);

event connection_established(c: connection)
{
    # Check if this is a connection to Telnet ports
    if ( c$id$resp_p == 23/tcp || c$id$resp_p == 2323/tcp )
    {
        local src = c$id$orig_h;
        local dst = c$id$resp_h;
        local now = current_time();
        
        # Initialize tracking table for this source if needed
        if ( src !in scan_tracker )
            scan_tracker[src] = table();
        
        # Record this connection
        scan_tracker[src][now] = dst;
        
        # Count connections in the time window
        local scan_count = 0;
        for ( t in scan_tracker[src] )
        {
            if ( now - t < scan_window )
                ++scan_count;
        }
        
        # Alert if threshold exceeded
        if ( scan_count >= scan_threshold )
        {
            NOTICE([$note=Mirai_Scan_Detected,
                    $msg=fmt("Mirai-like rapid Telnet scan from %s (%d connections in %s)", 
                             src, scan_count, scan_window),
                    $src=src,
                    $identifier=cat(src)]);
        }
    }
}

# Detect Mirai credential attempts in Telnet traffic
event telnet_authentication_accepted(c: connection, user: string, password: string)
{
    local cred = fmt("%s:%s", user, password);
    
    if ( cred in mirai_creds )
    {
        NOTICE([$note=Mirai_Credentials_Attempt,
                $msg=fmt("Mirai known credential used: %s from %s", cred, c$id$orig_h),
                $src=c$id$orig_h,
                $conn=c]);
    }
}