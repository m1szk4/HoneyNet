##! Local site policy for IoT Honeynet
##! Custom scripts for detecting IoT-specific attacks

@load base/frameworks/software
@load base/protocols/conn
@load base/protocols/dns
@load base/protocols/http
@load base/protocols/ssl
@load base/protocols/ssh
@load base/protocols/ftp

# Policy scripts for threat detection
@load policy/protocols/ssh/detect-bruteforcing
@load policy/protocols/conn/known-hosts
@load policy/frameworks/files/extract-all-files
@load policy/frameworks/files/hash-all-files

# Custom scripts (local)
@load ./scripts/detect-mirai-scan.zeek
@load ./scripts/http-exploit-detection.zeek
@load ./scripts/ssh-bruteforce-enhanced.zeek

# Define local networks
redef Site::local_nets = { 172.20.0.0/24 };

# Logging settings
redef Log::default_rotation_interval = 1 hr;
redef Log::default_rotation_postprocessor_cmd = "gzip";

# SSH brute force detection thresholds
redef SSH::password_guesses_limit = 10;

# File extraction settings
redef FileExtract::prefix = "/nsm/zeek/logs/extract/";
redef FileExtract::default_limit = 10485760;  # 10MB max

# Notice framework configuration
redef Notice::mail_dest = "";  # Disabled for honeypot