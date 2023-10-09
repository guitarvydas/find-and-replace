package debug

import "core:fmt"
import zd "../0d"

print_hierarchy :: proc (c : ^zd.Eh) {
    fmt.printf ("\n(%s", c.name)
    for child in c.children {
	print_hierarchy (child)
    }
    fmt.printf (")")
}
