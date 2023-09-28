package user0d

import "core:fmt"

import reg "../registry0d"
import zd "../0d"
import leaf "../leaf0d"

start_logger :: proc () -> bool {
    return true
}

components :: proc (leaves: ^[dynamic]reg.Leaf_Template) {
    append(leaves, reg.Leaf_Template { name = "1then2", init = leaf.deracer_instantiate })
    append(leaves, reg.Leaf_Template { name = "?", init = leaf.probe_instantiate })
    append(leaves, reg.Leaf_Template { name = "trash", init = leaf.trash_instantiate })
    append(leaves, reg.Leaf_Template { name = "null tester", init = leaf.nulltester_instantiate })
    append(leaves, reg.Leaf_Template { name = "stringconcat", init = leaf.stringconcat_instantiate })
    append(leaves, reg.Leaf_Template { name = "panic", init = leaf.panic_instantiate })
    append(leaves, reg.Leaf_Template { name = "command", init = leaf.command_instantiate })
    append(leaves, reg.Leaf_Template { name = "icommand", init = leaf.icommand_instantiate })
    append(leaves, reg.Leaf_Template { name = "Read Text File", init = leaf.read_text_file_instantiate })
    append(leaves, reg.Leaf_Template { name = "Read Text From FD", init = leaf.read_text_from_fd_instantiate })
    append(leaves, reg.Leaf_Template { name = "Open Text File", init = leaf.open_text_file_instantiate })

    append(leaves, reg.Leaf_Template { name = "suffix", init = leaf.suffix_instantiate })
    append(leaves, reg.Leaf_Template { name = "syncfilewrite", init = leaf.syncfilewrite_instantiate })

    // for ohmjs
    append(leaves, reg.Leaf_Template { name = "HardCodedGrammar", init = leaf.hard_coded_rwr_grammar_instantiate })
    append(leaves, reg.Leaf_Template { name = "HardCodedSemantics", init = leaf.hard_coded_rwr_semantics_instantiate })
    append(leaves, reg.Leaf_Template { name = "HardCodedSupport", init = leaf.hard_coded_rwr_support_instantiate })
    append(leaves, reg.Leaf_Template { name = "Bang", init = leaf.bang_instantiate })
    append(leaves, reg.Leaf_Template { name = "concat", init = leaf.concat_instantiate })

    // for front end
    append(leaves, reg.Leaf_Template { name = "'Word'", init = leaf.word_instantiate })
    append(leaves, reg.Leaf_Template { name = "'rt/word.ohm'", init = leaf.wordohm_instantiate })
    append(leaves, reg.Leaf_Template { name = "'rt/word.sem.js'", init = leaf.wordjs_instantiate })
    append(leaves, reg.Leaf_Template { name = "OhmJS", init = leaf.ohmjs_instantiate })

    append(leaves, reg.Leaf_Template { name = "'RWR'", init = leaf.rwr_instantiate })
    append(leaves, reg.Leaf_Template { name = "'rwr/rwr.ohm'", init = leaf.rwrohm_instantiate })
    append(leaves, reg.Leaf_Template { name = "'rwr/rwr.sem.js'", init = leaf.rwrsemjs_instantiate })

    append(leaves, reg.Leaf_Template { name = "'Escapes'", init = leaf.escapes_instantiate })
    append(leaves, reg.Leaf_Template { name = "'rt/escapes.ohm'", init = leaf.escapesohm_instantiate })
    append(leaves, reg.Leaf_Template { name = "'rt/escapes.rwr'", init = leaf.escapesrwr_instantiate })
    
    append(leaves, reg.Leaf_Template { name = "fakepipename", init = leaf.fakepipename_instantiate })
    append(leaves, reg.Leaf_Template { name = "syncfilewrite2", init = leaf.syncfilewrite2_instantiate })
    

    append(leaves, reg.Leaf_Template { name = "': '", init = leaf.colonspc_instantiate })

    append(leaves, reg.Leaf_Template { name = "'Find'", init = leaf.find_instantiate })

}



