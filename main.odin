package find_and_replace

import "debug"

import "core:fmt"
import "core:log"
import "core:runtime"
import "core:strings"
import "core:slice"
import "core:os"
import "core:unicode/utf8"

import reg "registry0d"
import "process"
import "syntax"
import zd "0d"
import user "user0d"
import leaf "leaf0d"

main :: proc() {

    fmt.println ("*** starting logger ***")
    context.logger = log.create_console_logger(
	lowest=log.Level.Debug,
        opt={.Level, .Time, .Terminal_Color},
    )

    // load arguments
    diagram_source_file := slice.get(os.args, 1) or_else "find-and-replace.drawio"
    main_container_name := slice.get(os.args, 2) or_else "main"

    if !os.exists(diagram_source_file) {
        fmt.println("Source diagram file", diagram_source_file, "does not exist.")
        os.exit(1)
    }

    // set up shell leaves
    leaves := make([dynamic]reg.Leaf_Instantiator)

    leaf.collect_process_leaves(diagram_source_file, &leaves)

    // export native leaves
    reg.append_leaf (&leaves, reg.Leaf_Instantiator {
        name = "stdout",
        instantiate = leaf.stdout_instantiate,
    })

    user.components (&leaves)

    regstry := reg.make_component_registry(leaves[:], diagram_source_file)

    run (&regstry, main_container_name, diagram_source_file, inject)
}

run :: proc (r : ^reg.Component_Registry, main_container_name : string, diagram_source_file : string, injectfn : #type proc (^zd.Eh)) {
    pregstry := r
    // get entrypoint container
    main_container, ok := reg.get_component_instance(pregstry, main_container_name, owner=nil)
    fmt.assertf(
        ok,
        "Couldn't find main container with page name %s in file %s (check tab names, or disable compression?)\n",
        main_container_name,
        diagram_source_file,
    )
    inject (main_container)
    fmt.println("--- Outputs ---")
    zd.print_output_list(main_container)
    // reg.print_stats (pregstry)
    zd.print_specific_output (main_container, "output")
}


inject :: proc (main_container : ^zd.Eh) {
    p := zd.new_datum_string ("fr/find.md")
    fmt.printf ("A0 p=0x%p 0x%x 0x%x\n",
		p,
		(transmute(runtime.Raw_String)(p.data.(string))).data,
		(transmute(runtime.Raw_String)(p.data.(string))).len
	       )
    fmt.printf ("A1 len=0x%x\n", len(p.data.(string)))
    fmt.printf ("A2 len=0x%x p.data.(string)=%s\n", len(p.data.(string)), p.data.(string))
    msg := zd.make_message("filename", p, main_container, nil )
    fmt.printf ("B\n")
    fmt.printf ("msg=%v\n", msg)
    fmt.printf ("C\n")
    main_container.handler(main_container, msg)
}
