package user0d

import "core:fmt"

import reg "../registry0d"
import zd "../0d"
import leaf "../leaf0d"

start_logger :: proc () -> bool {
    return true
}

components :: proc (leaves: ^[dynamic]reg.Leaf_Initializer) {
    append(leaves, reg.Leaf_Instantiator { name = "1then2", init = leaf.deracer_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "?", init = leaf.probe_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "trash", init = leaf.trash_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "null tester", init = leaf.nulltester_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "stringconcat", init = leaf.stringconcat_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "panic", init = leaf.panic_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "command", init = leaf.command_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "icommand", init = leaf.icommand_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "Read Text File", init = leaf.read_text_file_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "Read Text From FD", init = leaf.read_text_from_fd_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "Open Text File", init = leaf.open_text_file_instantiate })

    append(leaves, reg.Leaf_Instantiator { name = "suffix", init = leaf.suffix_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "syncfilewrite", init = leaf.syncfilewrite_instantiate })

    // for ohmjs
    append(leaves, reg.Leaf_Instantiator { name = "HardCodedGrammar", init = leaf.hard_coded_rwr_grammar_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "HardCodedSemantics", init = leaf.hard_coded_rwr_semantics_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "HardCodedSupport", init = leaf.hard_coded_rwr_support_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "Bang", init = leaf.bang_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "concat", init = leaf.concat_instantiate })

    // for front end
    append(leaves, reg.Leaf_Instantiator { name = "'Word'", init = leaf.word_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "'rt/word.ohm'", init = leaf.wordohm_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "'rt/word.sem.js'", init = leaf.wordjs_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "OhmJS", init = leaf.ohmjs_instantiate })

    append(leaves, reg.Leaf_Instantiator { name = "'RWR'", init = leaf.rwr_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "'rwr/rwr.ohm'", init = leaf.rwrohm_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "'rwr/rwr.sem.js'", init = leaf.rwrsemjs_instantiate })

    append(leaves, reg.Leaf_Instantiator { name = "'Escapes'", init = leaf.escapes_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "'rt/escapes.ohm'", init = leaf.escapesohm_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "'rt/escapes.rwr'", init = leaf.escapesrwr_instantiate })
    
    append(leaves, reg.Leaf_Instantiator { name = "fakepipename", init = leaf.fakepipename_instantiate })
    append(leaves, reg.Leaf_Instantiator { name = "syncfilewrite2", init = leaf.syncfilewrite2_instantiate })
    

    append(leaves, reg.Leaf_Instantiator { name = "': '", init = leaf.colonspc_instantiate })

}



