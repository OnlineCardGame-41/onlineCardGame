// Embeds static assets into the binary via ghe `go:embed` directive

package static

import (
	"embed"
)

//go:embed *.html
var Assets embed.FS
