require_relative '../../../directory'
require_relative PathFor[:repo_helper]
require_relative PathFor[:textmate_tools]
require_relative PathFor[:sharedPattern]["numeric"]
require_relative PathFor[:sharedPattern]["line_continuation"]
require_relative './tokens.rb'

#
# Setup grammar
#
    Dir.chdir __dir__
    # Standard refernce: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
    original_grammar = JSON.parse(IO.read("./original.tmlanguage.json"))
    Grammar.convertSpecificIncludes(json_grammar: original_grammar, convert:["$self", "$base"], into: :$initial_context)
    grammar = Grammar.new(
        name: original_grammar["name"],
        scope_name: original_grammar["scopeName"],
        file_types: [
            "sh"
        ],
        wrap_source: true,
        version: "",
        information_for_contributors: [
            "This code was auto generated by a much-more-readble ruby file",
            "see https://github.com/jeff-hykin/cpp-textmate-grammar/blob/master",
        ],
    )

#
#
# Contexts
#
#
    grammar[:$initial_context] = [
            :comment,
            :numeric_constant,
            :pipeline,
            :statement_seperator,
            :logical_expression_double,
            :logical_expression_single,
            :'compound-command',
            :loop,
            :string,
            :'function-definition',
            :variable,
            :interpolation,
            :heredoc,
            :herestring,
            :redirection,
            :pathname,
            :keyword,
            :assignment,
            :command_call,
            :support,
        ]
    grammar[:numeric_constant] = numeric_constant()
    grammar[:command_context] = [
            :comment,
            :pipeline,
            :statement_seperator,
            :'compound-command',
            :string,
            :variable,
            :interpolation,
            :heredoc,
            :herestring,
            :redirection,
            :pathname,
            :keyword,
            :support,
            :line_continuation,
        ]
    grammar[:option_context] = [
            :'compound-command',
            :string,
            :variable,
            :interpolation,
            :heredoc,
            :herestring,
            :redirection,
            :pathname,
            :keyword,
            :support,
        ]
    grammar[:logical_expression_context] = [
            :regex_comparison,
            :'logical-expression',
            :logical_expression_single,
            :logical_expression_double,
            :comment,
            :numeric_constant,
            :pipeline,
            :statement_seperator,
            :string,
            :variable,
            :interpolation,
            :heredoc,
            :herestring,
            :pathname,
            :keyword,
            :support,
        ]
    grammar[:variable_assignment_context] = [
            :$initial_context
        ]
#
#
# Patterns
#
#
    grammar[:line_continuation] = line_continuation()
    # copy over all the repos
    for each_key, each_value in original_grammar["repository"]
        grammar[each_key.to_sym] = each_value
    end

    std_space = /\s*+/
    variable_name_no_bounds = /[a-zA-Z_][a-zA-Z0-9_]*/
    variable_name = /(?:^|\b)#{variable_name_no_bounds.without_default_mode_modifiers}+(?:\b|$)/

    #
    # punctuation / operators
    #
    # replaces the old list pattern
    grammar[:statement_seperator] = newPattern(
            match: /;/,
            tag_as: "punctuation.terminator.statement.semicolon"
        ).or(
            match: /&&/,
            tag_as: "punctuation.separator.statement.and"
        ).or(
            match: /\|\|/,
            tag_as: "punctuation.separator.statement.or"
        ).or(
            match: /&/,
            tag_as: "punctuation.separator.statement.background"
        ).or(
            /\n/
        )
    statement_end = /[|&;]/

    # function thing() {}
    # thing() {}
    function_definition_start_pattern = std_space.then(
            # this is the case with the function keyword
            newPattern(
                match: /\bfunction /,
                tag_as: "storage.type.function"
            ).then(std_space).then(
                variable_name
            ).maybe(
                newPattern(
                    match: /\(/,
                    tag_as: "punctuation.definition.arguments",
                ).then(std_space).then(
                    match: /\)/,
                    tag_as: "punctuation.definition.arguments",
                )
            )
        ).or(
            # no function keyword
            variable_name.then(
                std_space
            ).then(
                match: /\(/,
                tag_as: "punctuation.definition.arguments",
            ).then(std_space).then(
                match: /\)/,
                tag_as: "punctuation.definition.arguments",
            )
        )
    grammar[:assignment] = PatternRange.new(
        tag_as: "meta.expression.assignment",
        start_pattern: std_space.then(
                match: variable_name,
                tag_as: "variable.other.assignment",
            ).then(
                match: /\+?\=/,
                tag_as: "keyword.operator.assignment",
            ),
        end_pattern: grammar[:statement_seperator].or(lookAheadFor(/ /)),
        includes: [ :variable_assignment_context ]
    )

    possible_pre_command_characters = /(?:^|;|\||&|!|\(|\{|\`)/
    possible_command_start   = lookAheadToAvoid(/(?:!|%|&|\||\(|\{|\[|<|>|#|\n|$|;)/)
    command_end              = lookAheadFor(/;|\||&|$|\n|\)|\`|\}|\{|#|\]/).lookBehindToAvoid(/\\/)
    unquoted_string_end      = lookAheadFor(/\s|;|\||&|$|\n|\)|\`/)
    invalid_literals         = Regexp.quote(@tokens.representationsThat(:areInvalidLiterals).join(""))
    valid_literal_characters = Regexp.new("[^\s#{invalid_literals}]+")

    grammar[:command_name] = PatternRange.new(
        tag_as: "entity.name.command",
        start_pattern: std_space.then(possible_command_start),
        end_pattern: lookAheadFor(@space).or(command_end),
        includes: [
            :custom_commands,
            :command_context,
        ]
    )
    grammar[:argument] = PatternRange.new(
        tag_as: "meta.argument",
        start_pattern: /\s++/.then(possible_command_start),
        end_pattern: unquoted_string_end,
        includes: [
            :command_context,
            newPattern(
                tag_as: "string.unquoted.argument",
                match: valid_literal_characters,
                includes: [
                    # wildcard
                    newPattern(
                        match: /\*/,
                        tag_as: "variable.language.special.wildcard"
                    ),
                ]
            ),
        ]
    )
    grammar[:option] = PatternRange.new(
        tag_content_as: "string.unquoted.argument constant.other.option",
        start_pattern: newPattern(
            /\s++/.then(
                match: /-/,
                tag_as: "string.unquoted.argument constant.other.option.dash"
            ).then(
                match: possible_command_start,
                tag_as: "string.unquoted.argument constant.other.option",
            )
        ),
        end_pattern: lookAheadFor(@space).or(command_end),
        includes: [
            :option_context,
        ]
    )
    grammar[:simple_options] = zeroOrMoreOf(
        /\s++/.then(
            match: /\-/,
            tag_as: "string.unquoted.argument constant.other.option.dash"
        ).then(
            match: /\w+/,
            tag_as: "string.unquoted.argument constant.other.option"
        )
    )
    keywords = @tokens.representationsThat(:areNonCommands)
    keyword_patterns = /#{keywords.map { |each| each+'\W|'+each+'\$' } .join('|')}/
    grammar[:command_call] = PatternRange.new(
        zeroLengthStart?: true,
        tag_as: "meta.statement",
        start_pattern: lookBehindFor(possible_pre_command_characters).then(std_space).lookAheadToAvoid(keyword_patterns),
        end_pattern: command_end,
        includes: [
            :option,
            :argument,
            :command_name,
            :command_context
        ]
    )
    grammar[:custom_commands] = [

        # Note:
        #   this sed does not cover all possible cases, it only covers the most likely case
        #   in the event of a more complicated case, it falls back on tradidional command highlighting
        grammar[:sed_command] = Pattern.new(
            Pattern.new(
                match: /\bsed\b/,
                tag_as: "entity.name.command.shell",
            ).then(
                grammar[:simple_options]
            ).then(@spaces).then(
                match: /['"]s\//,
                tag_as: "punctuation.section.regexp",
            ).then(
                match: /.*/, # find
                includes: [ :regexp ],
            ).then(
                match: /\//,
                tag_as: "punctuation.section.regexp",
            ).then(
                match: /.*/, # replace
                includes: [ :string ],
            ).then(
                match: /\/\w{0,4}['"]/,
                tag_as: "punctuation.section.regexp",
            ).then(
                match: /.*/,
                includes: [
                    :option,
                    :argument,
                    :command_context
                ]
            )
        ),

        # legacy built-in commands
        {
            "match": "(?<=^|;|&|\\s)(?:alias|bg|bind|break|builtin|caller|cd|command|compgen|complete|dirs|disown|echo|enable|eval|exec|exit|false|fc|fg|getopts|hash|help|history|jobs|kill|let|logout|popd|printf|pushd|pwd|read|readonly|set|shift|shopt|source|suspend|test|times|trap|true|type|ulimit|umask|unalias|unset|wait)(?=\\s|;|&|$)",
            "name": "support.function.builtin.shell"
        }
    ]
    # remove legacy support to fix pattern priorities
    grammar[:support]["patterns"].pop()

    grammar[:logical_expression_single] = PatternRange.new(
        tag_as: "meta.scope.logical-expression",
        start_pattern: newPattern(
                match: /\[/,
                tag_as: "punctuation.definition.logical-expression",
            ),
        end_pattern: newPattern(
                match: /\]/,
                tag_as: "punctuation.definition.logical-expression"
            ),
        includes: grammar[:logical_expression_context]
    )
    grammar[:logical_expression_double] = PatternRange.new(
        tag_as: "meta.scope.logical-expression",
        start_pattern: newPattern(
                match: /\[\[/,
                tag_as: "punctuation.definition.logical-expression",
            ),
        end_pattern: newPattern(
                match: /\]\]/,
                at_least: 1.times,
                at_most: 2.times,
                tag_as: "punctuation.definition.logical-expression"
            ),
        includes: grammar[:logical_expression_context]
    )
    grammar[:regex_comparison] = Pattern.new(
        Pattern.new(
            tag_as: "keyword.operator.logical",
            match: /\=~/,
        ).then(
            @spaces
        ).then(
            match: /[^ ]*/,
            includes: [
                :variable,
                :regexp
            ]
        )
    )

    def generateVariable(regex_after_dollarsign, tag)
        newPattern(
            match: newPattern(
                match: /\$/,
                tag_as: "punctuation.definition.variable #{tag}"
            ).then(
                match: regex_after_dollarsign.lookAheadFor(/\W/),
                tag_as: tag,
            )
        )
    end

	array = newPattern(
		match: variable_name,
		tag_as: 'variable.other.array'
	).then(
		match: /\[/,
		tag_as: 'punctuation.section.array'
	).then(
		match: newPattern(
			match: /[@*]/,
			tag_as: 'keyword.other.subscript.all'
		).or(
			# Treat subscript exactly like the contents of $((...)) and ((...))
			match: /[^\]]+/,
			tag_as: 'string.other.math',
			includes: [ :math ]
		)
	).then(
		match: /\]/,
		tag_as: 'punctuation.section.array'
	)

    grammar[:variable] = [
        generateVariable(/(?:[@*]|\{[@*]\})/, "variable.parameter.positional.all"),
        generateVariable(/(?:#|\{#\})/, 'variable.parameter.positional.number'),
        generateVariable(/(?:[1-9]|\{[1-9][0-9]*\})/, "variable.parameter.positional"),
		generateVariable(/(?:[-?$!0_]|\{[-?$!0_]\})/, "variable.language.special"),
		array,
        PatternRange.new(
            start_pattern: newPattern(
                    match: newPattern(
                        match: /\$/,
                        tag_as: "punctuation.definition.variable punctuation.section.bracket.curly.variable.begin"
                    ).then(
                        match: /\{/,
                        tag_as: "punctuation.section.bracket.curly.variable.begin",

                    )
                ),
            end_pattern: newPattern(
                    match: /\}/,
                    tag_as: "punctuation.section.bracket.curly.variable.end",
                ),
            includes: [
                {
                    "match": "!|:[-=?]?|\\*|@|\#{1,2}|%{1,2}|\\^{1,2}|,{1,2}|/",
                    "name": "keyword.operator.expansion.shell"
                },
                :variable,
                :string,
            ]
        ),
        # normal variables
        generateVariable(/\w+/, "variable.other.normal")
    ]

    #
    # regex (legacy format, imported from JavaScript regex)
    #
        grammar[:regexp] = {
            "patterns"=> [
                {
                    "name"=> "keyword.control.anchor.regexp",
                    "match"=> "\\\\[bB]|\\^|\\$"
                },
                {
                    "match"=> "\\\\[1-9]\\d*|\\\\k<([a-zA-Z_$][\\w$]*)>",
                    "captures"=> {
                        "0"=> {
                            "name"=> "keyword.other.back-reference.regexp"
                        },
                        "1"=> {
                            "name"=> "variable.other.regexp"
                        }
                    }
                },
                {
                    "name"=> "keyword.operator.quantifier.regexp",
                    "match"=> "[?+*]|\\{(\\d+,\\d+|\\d+,|,\\d+|\\d+)\\}\\??"
                },
                {
                    "name"=> "keyword.operator.or.regexp",
                    "match"=> "\\|"
                },
                {
                    "name"=> "meta.group.assertion.regexp",
                    "begin"=> "(\\()((\\?=)|(\\?!)|(\\?<=)|(\\?<!))",
                    "beginCaptures"=> {
                        "1"=> {
                            "name"=> "punctuation.definition.group.regexp"
                        },
                        "2"=> {
                            "name"=> "punctuation.definition.group.assertion.regexp"
                        },
                        "3"=> {
                            "name"=> "meta.assertion.look-ahead.regexp"
                        },
                        "4"=> {
                            "name"=> "meta.assertion.negative-look-ahead.regexp"
                        },
                        "5"=> {
                            "name"=> "meta.assertion.look-behind.regexp"
                        },
                        "6"=> {
                            "name"=> "meta.assertion.negative-look-behind.regexp"
                        }
                    },
                    "end"=> "(\\))",
                    "endCaptures"=> {
                        "1"=> {
                            "name"=> "punctuation.definition.group.regexp"
                        }
                    },
                    "patterns"=> [
                        {
                            "include"=> "#regexp"
                        }
                    ]
                },
                {
                    "name"=> "meta.group.regexp",
                    "begin"=> "\\((?:(\\?:)|(?:\\?<([a-zA-Z_$][\\w$]*)>))?",
                    "beginCaptures"=> {
                        "0"=> {
                            "name"=> "punctuation.definition.group.regexp"
                        },
                        "1"=> {
                            "name"=> "punctuation.definition.group.no-capture.regexp"
                        },
                        "2"=> {
                            "name"=> "variable.other.regexp"
                        }
                    },
                    "end"=> "\\)",
                    "endCaptures"=> {
                        "0"=> {
                            "name"=> "punctuation.definition.group.regexp"
                        }
                    },
                    "patterns"=> [
                        {
                            "include"=> "#regexp"
                        }
                    ]
                },
                {
                    "name"=> "constant.other.character-class.set.regexp",
                    "begin"=> "(\\[)(\\^)?",
                    "beginCaptures"=> {
                        "1"=> {
                            "name"=> "punctuation.definition.character-class.regexp"
                        },
                        "2"=> {
                            "name"=> "keyword.operator.negation.regexp"
                        }
                    },
                    "end"=> "(\\])",
                    "endCaptures"=> {
                        "1"=> {
                            "name"=> "punctuation.definition.character-class.regexp"
                        }
                    },
                    "patterns"=> [
                        {
                            "name"=> "constant.other.character-class.range.regexp",
                            "match"=> "(?:.|(\\\\(?:[0-7]{3}|x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4}))|(\\\\c[A-Z])|(\\\\.))\\-(?:[^\\]\\\\]|(\\\\(?:[0-7]{3}|x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4}))|(\\\\c[A-Z])|(\\\\.))",
                            "captures"=> {
                                "1"=> {
                                    "name"=> "constant.character.numeric.regexp"
                                },
                                "2"=> {
                                    "name"=> "constant.character.control.regexp"
                                },
                                "3"=> {
                                    "name"=> "constant.character.escape.backslash.regexp"
                                },
                                "4"=> {
                                    "name"=> "constant.character.numeric.regexp"
                                },
                                "5"=> {
                                    "name"=> "constant.character.control.regexp"
                                },
                                "6"=> {
                                    "name"=> "constant.character.escape.backslash.regexp"
                                }
                            }
                        },
                        {
                            "include"=> "#regex-character-class"
                        }
                    ]
                },
                {
                    "include"=> "#regex-character-class"
                }
            ]
        }
        grammar[:regex_character_class] = {
            "patterns"=> [
                {
                    "name"=> "constant.other.character-class.regexp",
                    "match"=> "\\\\[wWsSdDtrnvf]|\\."
                },
                {
                    "name"=> "constant.character.numeric.regexp",
                    "match"=> "\\\\([0-7]{3}|x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4})"
                },
                {
                    "name"=> "constant.character.control.regexp",
                    "match"=> "\\\\c[A-Z]"
                },
                {
                    "name"=> "constant.character.escape.backslash.regexp",
                    "match"=> "\\\\."
                }
            ]
        }

# Save
saveGrammar(grammar)
