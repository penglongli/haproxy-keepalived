package version

import "fmt"

var (
	REVISION = "Unknown"

	BUILDTIME = "Unknown"

	GOVERSION = "Unknown"

	KEEPALIVEDVERSION = "Unknown"

	HAPROXYVERSION = "Unknown"
)

func String() string {
	return fmt.Sprintf(`-----------------------------------------
-----------------------------------------
Revision:     		%v
Go:           		%v
BuildTime:    		%v
KeepvaliedVersion:	%v
HAProxyVersion:     %v
-----------------------------------------
-----------------------------------------
`, REVISION, GOVERSION, BUILDTIME, KEEPALIVEDVERSION, HAPROXYVERSION)
}
