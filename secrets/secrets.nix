let
	mylaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGktPxdZf3Y2x2p4qk8YDn7Rm4JMb+x+3JFBq9Pg45NE";
in {
	"ssh/reed.age".publicKeys = [mylaptop];
	"ssh/rsync-net.age".publicKeys = [mylaptop];
	"ssh/csci-vm.age".publicKeys = [mylaptop];
	"ssh/miles.age".publicKeys = [mylaptop];
	"restic/password.age".publicKeys = [mylaptop];
	"restic/repo-local.age".publicKeys = [mylaptop];
	"restic/repo-remote.age".publicKeys = [mylaptop];
}
