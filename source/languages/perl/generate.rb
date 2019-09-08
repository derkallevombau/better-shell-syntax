require_relative '../../../directory'
require_relative PathFor[:repo_helper]
require_relative PathFor[:textmate_tools]
require_relative PathFor[:sharedPattern]["numeric"]
require_relative PathFor[:sharedPattern]["control_flow"]
require_relative PathFor[:sharedPattern]["variable"]
require_relative './tokens.rb'

# 
# Setup grammar
# 
    Dir.chdir __dir__
    # reference https://perldoc.perl.org/perlvar.html
    original_grammar = JSON.parse(IO.read("original.tmlanguage.json"))
    Grammar.convertSpecificIncludes(json_grammar: original_grammar, convert:["$self", "$base"], into: :$initial_context)
    grammar = Grammar.new(
        name: original_grammar["name"],
        scope_name: original_grammar["scopeName"],
        version: "",
        information_for_contributors: [
            "This code was auto generated by a much-more-readble ruby file",
            "see https://github.com/jeff-hykin/cpp-textmate-grammar/blob/master",
        ],
    )
# 
# utils
# 
    # NOTE: this pattern can match 0-spaces so long as its still a word boundary
    std_space = newPattern(
        newPattern(
            at_least: 1,
            quantity_preference: :as_few_as_possible,
            match: newPattern(
                    match: @spaces,
                    dont_back_track?: true
                )
        # zero length match
        ).or(
            /\b/.or(
                lookBehindFor(/\W/)
            ).or(
                lookAheadFor(/\W/)
            ).or(
                @start_of_document
            ).or(
                @end_of_document
            )
        )
    )
#
#
# Contexts
#
#
    grammar[:$initial_context] = [
            :using_statement,
            :control_flow,
            :function_definition,
            :function_call,
            :label,
            :numbers,
            :inline_regex,
            :special_identifiers,
            :keyword_operators,
            # import all the original patterns
            *original_grammar["patterns"],
            :operators,
            :punctuation,
        ]
#
#
# Patterns
#
#
    # 
    # numbers
    # 
        grammar[:numbers] = numeric_constant(separator:"_")
    # 
    # regex
    # 
        grammar[:inline_regex] = newPattern(
            newPattern(
                match: /\//,
                tag_as: "punctuation.section.regexp"
            ).then(
                match: zeroOrMoreOf(
                    match: /[^\/\\]|\\./,
                    dont_back_track?: true,
                ),
                tag_as: "string.regexp",
                includes: [ :regexp ],
            ).then(
                match: /\//,
                tag_as: "punctuation.section.regexp"
            )
        )
    # 
    # builtins
    # 
        grammar[:special_identifiers] = [
            newPattern(
                match: /\$\^[A-Z^_?\[\]]/,
                tag_as: "variable.language.special.caret"
            ),
            newPattern(
                match: variableBounds(/undef/),
                tag_as: "constant.language.undef",
            )
        ]
            
    # 
    # operators
    # 
        grammar[:keyword_operators]  = [
            newPattern(
                match: variableBounds(@tokens.that(:areOperatorAliases)),
                tag_as: "keyword.operator.alias.$match",
            ),
        ]
        grammar[:operators] = [
            PatternRange.new(
                tag_content_as: "meta.readline",
                start_pattern: newPattern(
                    lookBehindToAvoid(/\s|\w|</).then(std_space).then(
                        match: /</,
                        tag_as: "punctuation.separator.readline",
                    ).lookAheadToAvoid(/</)
                ),
                end_pattern: newPattern(
                    match: />/,
                    tag_as:"punctuation.separator.readline",
                ),
                includes: [ :$initial_context ]
            ),
            newPattern(
                match: @tokens.that(:areComparisonOperators, not(:areOperatorAliases)),
                tag_as: "keyword.operator.comparison",
            ),
            newPattern(
                match: @tokens.that(:areAssignmentOperators, not(:areOperatorAliases)),
                tag_as: "keyword.operator.assignment",
            ),
            newPattern(
                match: @tokens.that(:areLogicalOperators, not(:areOperatorAliases)),
                tag_as: "keyword.operator.logical",
            ),
            newPattern(
                match: @tokens.that(:areArithmeticOperators, not(:areAssignmentOperators), not(:areOperatorAliases)),
                tag_as: "keyword.operator.arithmetic",
            ),
            newPattern(
                match: @tokens.that(:areBitwiseOperators, not(:areAssignmentOperators), not(:areOperatorAliases)),
                tag_as: "keyword.operator.bitwise",
            ),
            newPattern(
                match: @tokens.that(:areOperators, not(:areOperatorAliases)),
                tag_as: "keyword.operator",
            ),
        ]
    # 
    # punctuation
    # 
        grammar[:punctuation] = [
            grammar[:semicolon] = newPattern(
                match: /;/,
                tag_as: "punctuation.terminator.statement"
            ),
            grammar[:comma] = newPattern(
                match: /,/,
                tag_as: "punctuation.separator.comma"
            ),
            # unknown/other
            grammar[:square_brackets] = PatternRange.new(
                start_pattern: newPattern(
                    match: /\[/,
                    tag_as: "punctuation.section.square-brackets",
                ),
                end_pattern: newPattern(
                    match: /\]/,
                    tag_as: "punctuation.section.square-brackets",
                ),
                includes: [ :$initial_context ]
            ),
            grammar[:curly_brackets] = PatternRange.new(
                start_pattern: newPattern(
                    match: /\{/,
                    tag_as: "punctuation.section.curly-brackets",
                ),
                end_pattern: newPattern(
                    match: /\}/,
                    tag_as: "punctuation.section.curly-brackets",
                ),
                includes: [ :$initial_context ]
            ),
            grammar[:parentheses] = PatternRange.new(
                start_pattern: newPattern(
                    match: /\(/,
                    tag_as: "punctuation.section.parens",
                ),
                end_pattern: newPattern(
                    match: /\)/,
                    tag_as: "punctuation.section.parens",
                ),
                includes: [ :$initial_context ]
            )
        ]
    # 
    # imports
    # 
        grammar[:using_statement] = PatternRange.new(
            tag_as: "meta.import",
            start_pattern: newPattern(
                newPattern(
                    match: /use/,
                    tag_as: "keyword.other.use"
                ).then(std_space).then(
                    match: /[\w\.]+/,
                    tag_as: "entity.name.package",
                )
            ),
            end_pattern: grammar[:semicolon],
            includes: [
                newPattern(
                    match: /::/,
                    tag_as: "punctuation.separator.resolution"
                ),
                # qw()
                PatternRange.new(
                    start_pattern: newPattern(
                        newPattern(
                            match: /qw/,
                            tag_as: "entity.name.function.special"
                        ).then(std_space).then(
                            match: /\(/,
                            tag_as: "punctuation.section.block.function.special",
                        )
                    ),
                    end_pattern: newPattern(
                        match: /\)/,
                        tag_as: "punctuation.section.block.function.special",
                    ),
                    includes: [
                        :variable
                    ]
                ),
            ]
        )
    # 
    # control flow
    # 
        grammar[:control_flow] = [
            grammar[:if_statement]    = c_style_control(keyword:"if"    , parentheses_include:[ :$initial_context ], body_includes:[ :$initial_context ], secondary_includes:[:$initial_context]),
            grammar[:elsif_statement] = c_style_control(keyword:"elsif" , parentheses_include:[ :$initial_context ], body_includes:[ :$initial_context ], secondary_includes:[:$initial_context]),
            grammar[:else_statement]  = c_style_control(keyword:"else"  , parentheses_include:[ :$initial_context ], body_includes:[ :$initial_context ], secondary_includes:[:$initial_context]),
            grammar[:while_statement] = c_style_control(keyword:"while" , parentheses_include:[ :$initial_context ], body_includes:[ :$initial_context ], secondary_includes:[:$initial_context]),
            grammar[:for_statement]   = c_style_control(keyword:"for"   , parentheses_include:[ :$initial_context ], body_includes:[ :$initial_context ], secondary_includes:[:$initial_context]),
        ]
    # 
    # function definition
    # 
        # see https://perldoc.perl.org/perlsub.html
        grammar[:function_definition] = PatternRange.new(
            start_pattern: newPattern(
                newPattern(
                    match: /sub/,
                    tag_as: "storage.type.sub",
                ).then(std_space).maybe(
                    match: @variable,
                    tag_as: "entity.name.function.definition",
                )
            ),
            end_pattern: newPattern(
                newPattern(
                    match: /\}/,
                    tag_as: "punctuation.section.block.function",
                ).or(
                    grammar[:semicolon]
                )
            ),
            includes: [
                PatternRange.new(
                    start_pattern: newPattern(
                        match: /\{/,
                        tag_as: "punctuation.section.block.function",  
                    ),
                    end_pattern: lookAheadFor(/\}/),
                    includes: [ :$initial_context ],
                ),
                grammar[:parentheses] = PatternRange.new(
                    start_pattern: newPattern(
                        match: /\(/,
                        tag_as: "punctuation.section.parameters",
                    ),
                    end_pattern: newPattern(
                        match: /\)/,
                        tag_as: "punctuation.section.parameters",
                    ),
                    includes: [ :$initial_context ]
                ),
                newPattern(
                    newPattern(
                        match: /:/,
                        tag_as: "punctuation.definition.attribute entity.name.attribute"
                    ).then(std_space).then(
                        match: @variable,
                        tag_as: "entity.name.attribute",
                    ).then(std_space)
                ),
                # todo: make this more restrictive 
                :$initial_context
            ]
        )
        grammar[:function_call] = PatternRange.new(
            start_pattern: newPattern(
                newPattern(
                    match: @variable,
                    tag_as: "entity.name.function.call",
                    word_cannot_be_any_of: ["qq", "qw", "q", "m", "qr", "s" , "tr", "y"], # see https://perldoc.perl.org/perlop.html#Quote-and-Quote-like-Operators
                ).then(std_space).then(
                    match: /\(/,
                    tag_as: "punctuation.section.arguments",
                )
            ),
            end_pattern: newPattern(
                match: /\)/,
                tag_as: "punctuation.section.arguments",
            ),
            includes: [ :$initial_context ]
        )
    # 
    # Labels
    # 
        grammar[:label] = newPattern(
            /^/.then(std_space).then(
                tag_as: "entity.name.label",
                match: @variable,
            ).then(@word_boundary).then(
                std_space
            ).then(
                match: /:/.lookAheadToAvoid(/:/),
                tag_as: "punctuation.separator.label",
            )
        )
    # 
    # copy over all the repos
    # 
        for each_key, each_value in original_grammar["repository"]
            grammar[each_key.to_sym] = each_value
        end
 
# Save
saveGrammar(grammar)