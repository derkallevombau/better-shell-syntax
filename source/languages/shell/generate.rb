require_relative('../../../directory')
require(PathFor[:repo_helper])
require(PathFor[:textmate_tools])
require(PathFor[:sharedPattern]['numeric'])
require(PathFor[:sharedPattern]['line_continuation'])
require_relative('tokens')
require(PathFor[:logger_wrapper])

#
# Setup grammar
#

# $logger = LoggerWrapper.new(STDOUT)

Dir.chdir(__dir__)

# Standard reference: http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html
original_grammar = JSON.parse(IO.read('./original.tmlanguage.json'))
Grammar.convertSpecificIncludes(json_grammar: original_grammar, convert: ['$self', '$base'], into: :$initial_context)

grammar = Grammar.new(
	name: original_grammar['name'],
	scope_name: original_grammar['scopeName'],
	file_types: [
		'sh'
	],
	wrap_source: true,
	version: '',
	information_for_contributors: [
		'This code was auto generated by a much-more-readable ruby file',
		'see https://github.com/jeff-hykin/cpp-textmate-grammar/blob/master',
	],
)

#
#
# Contexts
#
#

grammar[:$initial_context] = [
	:comment,
	:boolean,
	:numeric_constant,
	:pipeline,
	:statement_separator,
	:'compound-command',
	:loop,
	:string,
	:'function-definition',
	:variable,
	:interpolation, # Arithmetic expansion, command substitution
	:heredoc,
	:herestring,
	:redirection,
	:pathname,
	:keyword,
	:assignment,
	:command_call,
	:support,
]

grammar[:command_context] = [
	:comment,
	:pipeline,
	:statement_separator,
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
	# Somewhat misleading: These are the usual comparison and logical operators,
	# as well as =~ and Bash's special file-related operators and the old-fashioned
	# arithmetic comparison operators like -eq, -lt and so on, all tagged as 'keyword.operator.logical.shell'.
	:'logical-expression',
	:rvalue
]

grammar[:rvalue] = [
	:string,
	:numeric_constant,
	:variable,
	:interpolation,
	:pathname,
]

#
#
# Patterns
#
#

grammar[:boolean] = newPattern(
	match: /\b(?:true|false)\b/,
	tag_as: 'support.function.builtin.$match'
)

grammar[:numeric_constant] = numeric_constant()

grammar[:line_continuation] = line_continuation()

# copy over all the repos
for key, value in original_grammar['repository']
	if key == 'compound-command'
		grammar[:'compound-command'] = [
			:logical_expression_double,
			:logical_expression_single,
			value
		]
	else
		grammar[key.to_sym] = value
	end
end

whitespace_maybe        = /\s*+/ # N.B.: \s also matches \t. '+' after a quantifier denotes possessive matching.
whitespace              = /\s++/
variable_name_no_bounds = /[a-zA-Z_]\w*/
@variable_name          = /(?:^|\b)#{variable_name_no_bounds.without_default_mode_modifiers}+(?:\b|$)/

#
# punctuation / operators
#

# replaces the old list pattern
grammar[:statement_separator] = newPattern(
	match: /;/,
	tag_as: 'punctuation.terminator.statement.semicolon'
).or(
	match: /&&/,
	tag_as: 'punctuation.separator.statement.and'
).or(
	match: /\|\|/,
	tag_as: 'punctuation.separator.statement.or'
).or(
	match: /&/,
	tag_as: 'punctuation.separator.statement.background'
).or(
	/\n/
)

#
# Assignment
#

# @param type [String]
def generateAssignedVariable(type)
	newPattern(
		match: @variable_name,
		tag_as: "variable.other.#{type} variable.other.assignment.#{type}",
	)
end

# @type [Regexp]
assign_op =
	newPattern(
		match: /\+=/,
		tag_as: 'keyword.operator.assignment.compound'
	).or(
		match: /=/,
		tag_as: 'keyword.operator.assignment'
	)

# @param paren [String]
def generateArrayLiteralParen(paren)
	{
		match: /#{'\\' + paren}/,
		tag_as: 'variable.other.assignment.rvalue punctuation.definition.array-literal'
	}
end

# @param bracket [String]
def generateArraySubscriptBracket(bracket)
	{
		match: /#{'\\' + bracket}/,
		tag_as: 'punctuation.section.array'
	}
end

array_subscript_contents_math =
	{
		# Treat subscript exactly like the contents of $((...)) and ((...))
		match: /[^\]]+/,
		tag_as: 'string.other.math',
		includes: [:math]
	}

# rvalue in assignment to array element or normal variable.
normal_rvalue =
	newPattern(
		# Unquoted, single-quoted, double-quoted or any mixture.
		# Match everything but characters allowed after a statement,
		# if any, possibly with preceding whitespace.
		# '#' is important to be recognised if you have a comment after the assignment,
		# ';' is important to be recognised when you write e. g. 'foo="$1"; shift'.
		# '&&' and '||' are important if you use a construct like '[[ $foo ]] && bar=$(some-command "$foo") || bar="$baz"'
		# You will probably not use & or | after an assignment, but it would be grammatically correct.
		# since an assignment is a command.
		# N.B.: - First, we try to match something that ends with a quoted string, possibly followed by an unquoted one.
		#         We must match greedily for the positive lookahead to start after the last closing quote to prevent it
		#         from matching any of the chars in the non-capture group inside a quoted string.
		#         This way, we don't need to define dedicated patterns for quoted strings.
		#       - If the first expression doesn't match, we match everything that does NOT end with a quote.
		#       - Obviously, it is crucial to match .* immediately before the positive lookahead assertion non-greedily
		#         for the alternation inside to work.
		#       - Don't use any of the chars in the non-capture group within an unquoted string
		#         since this would cause the rvalue to end before such a char because of the non-greedy matching.
		#         However, in most cases you would use quotes for a string containing a regex or commands anyway.
		match: /.*["'].*?(?=\s*(?:#|;|&|\||$))|.*?(?=\s*(?:#|;|&|\||$))/,
		tag_as: 'variable.other.assignment.rvalue',
		includes: [:rvalue]
	)

grammar[:assignment] =
	newPattern(
		tag_as: 'meta.expression.assignment',
		match: whitespace_maybe
			.then(
				newPattern( # Assignment to array as a whole
					generateAssignedVariable('array')
					.then(
						assign_op
					).then(
						**generateArrayLiteralParen('(')
					).then(
						# Since we might have nested parentheses here,
						# use positive lookahead to match everything but the last closing parenthesis.
						# Also take into account that there could be a comment containing parens
						# after the last closing paren belonging to the rvalue.
						match: /.*(?=\)\s*#)|.*(?=\))/,
						tag_as: 'variable.other.assignment.rvalue',
						includes: [:rvalue]
					).then(
						**generateArrayLiteralParen(')')
					)
				).or( # Assignment to array element
					generateAssignedVariable('array')
					.then(
						**generateArraySubscriptBracket('[')
					).then(
						**array_subscript_contents_math
					).then(
						**generateArraySubscriptBracket(']')
					).then(
						assign_op
					).then(
						normal_rvalue
					)
				).or( # Assignment to normal variable
					generateAssignedVariable('normal')
					.then(
						assign_op
					).then(
						normal_rvalue
					)
				)
			)
	)

#
# Commands
#

possible_pre_command_characters = /(?:^|;|\||&|!|\(|\{|`|if|elif|then|while|until|do)/
possible_command_start          = lookAheadToAvoid(/(?:!|%|&|\||\(|\{|\[|<|>|#|\n|$|;)/)
command_end                     = lookAheadFor(/;|\||&|$|\n|\)|`|\}|\{|#|\]/).lookBehindToAvoid(/\\/)
unquoted_string_end             = lookAheadFor(/\s|;|\||&|$|\n|\)|`/)
invalid_literals                = Regexp.quote(@tokens.representationsThat(:areInvalidLiterals).join(''))
valid_literal_characters        = Regexp.new("[^\s#{invalid_literals}]+")

grammar[:command_name] = PatternRange.new(
	tag_as: 'entity.name.command',
	start_pattern: whitespace_maybe.then(possible_command_start),
	end_pattern: lookAheadFor(@space).or(command_end),
	includes: [
		:custom_commands,
		:command_context,
	]
)

grammar[:argument] = PatternRange.new(
	tag_as: 'meta.argument',
	start_pattern: whitespace.then(possible_command_start),
	end_pattern: unquoted_string_end,
	includes: [
		:command_context,
		newPattern(
			tag_as: 'string.unquoted.argument',
			match: valid_literal_characters,
			includes: [
				# wildcard
				newPattern(
					match: /\*/,
					tag_as: 'variable.language.special.wildcard'
				),
			]
		),
	]
)

grammar[:option] = PatternRange.new(
	tag_content_as: 'string.unquoted.argument constant.other.option',
	start_pattern: newPattern(
		whitespace.then(
			match: /-/,
			tag_as: 'string.unquoted.argument constant.other.option.dash'
		).then(
			match: possible_command_start,
			tag_as: 'string.unquoted.argument constant.other.option',
		)
	),
	end_pattern: lookAheadFor(@space).or(command_end),
	includes: [
		:option_context,
	]
)

grammar[:simple_options] = zeroOrMoreOf(
	whitespace.then(
		match: /-/,
		tag_as: 'string.unquoted.argument constant.other.option.dash'
	).then(
		match: /\w+/,
		tag_as: 'string.unquoted.argument constant.other.option'
	)
)

keywords         = @tokens.representationsThat(:areNonCommands)
keyword_patterns = /#{keywords.map { |keyword| keyword + '\W|' + keyword + '\$' }.join('|')}/

grammar[:command_call] = PatternRange.new(
	zeroLengthStart?: true,
	tag_as: 'meta.statement',
	start_pattern: lookBehindFor(possible_pre_command_characters).then(whitespace_maybe).lookAheadToAvoid(keyword_patterns),
	end_pattern: command_end,
	includes: [
		:option,
		:argument,
		:command_name,
		:command_context
	]
)

grammar[:custom_commands] = [

	# NOTE: This sed does not cover all possible cases, it only covers the most likely case
	#       in the event of a more complicated case, it falls back on traditional command highlighting
	grammar[:sed_command] = Pattern.new(
		Pattern.new(
			match: /\bsed\b/,
			tag_as: 'entity.name.command.shell',
		).then(
			grammar[:simple_options]
		).then(@spaces).then(
			match: /['"]s\//,
			tag_as: 'punctuation.section.regexp',
		).then(
			match: /.*/, # find
			includes: [:regexp],
		).then(
			match: /\//,
			tag_as: 'punctuation.section.regexp',
		).then(
			match: /.*/, # replace
			includes: [:string],
		).then(
			match: /\/\w{0,4}['"]/,
			tag_as: 'punctuation.section.regexp',
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
		'match': '(?<=^|;|&|\\s)(?:alias|bg|bind|break|builtin|caller|cd|command|compgen|complete|dirs|disown|echo|enable|eval|exec|exit|false|fc|fg|getopts|hash|help|history|jobs|kill|let|logout|popd|printf|pushd|pwd|read|readonly|set|shift|shopt|source|suspend|test|times|trap|true|type|ulimit|umask|unalias|unset|wait)(?=\\s|;|&|$)',
		'name': 'support.function.builtin.shell'
	}
]

# remove legacy support to fix pattern priorities
grammar[:support]['patterns'].pop()

#
# logical_expression_single, logical_expression_double
#

# N.B.: * corresponds to JS's rest operator, which enables us to pack
# an arbitrary number of arguments into an array, whereas in JS, we need
# to pass an object literal to get named parameters.
# In Ruby, we can use double splat operator to pack named parameters
# and their values into a hash, as we can do in Perl (%args = @_).

# @return [Regexp]
def generatePatternNeedingSpace(**args)
	invalidPattern = args[:pattern]
	validPattern   = ' ' + invalidPattern if args[:before]
	validPattern   = invalidPattern + ' ' if args[:after]

	newPattern(
		match: /#{validPattern}/,
		tag_as: args[:tag_as_if_valid]
	).or(
		match: /#{invalidPattern}/,
		tag_as: args[:tag_as_if_invalid]
	)
end

# @return [Hash]
def generateStartAndEndPatternsNeedingSpace(**args)
	tagAs =
		{
			tag_as_if_valid:   args[:tag_as_if_valid],
			tag_as_if_invalid: args[:tag_as_if_invalid]
		}

	# N.B.: Merging hashes: In Perl, we can simply put a (direct) hash
	# into a hash literal (or more precisely, a list), whereas in JS,
	# we need to use the spread operator to decompose an object to insert
	# it into an object literal.
	# What we do with the double splat below is perfectly analogous to that.
	{
		start_pattern: generatePatternNeedingSpace(
			after: true,
			pattern: args[:start_pattern],
			**tagAs
		),
		end_pattern: generatePatternNeedingSpace(
			before: true,
			pattern: args[:end_pattern],
			**tagAs
		)
	}
end

grammar[:logical_expression_single] = PatternRange.new(
	tag_as: 'meta.scope.logical-expression',
	**generateStartAndEndPatternsNeedingSpace(
		start_pattern: '\[',
		end_pattern: '\]',
		tag_as_if_valid: 'punctuation.definition.logical-expression',
		tag_as_if_invalid: 'punctuation.definition.logical-expression.invalid'
	),
	includes: [:logical_expression_context]
)

grammar[:logical_expression_double] = PatternRange.new(
	tag_as: 'meta.scope.logical-expression',
	**generateStartAndEndPatternsNeedingSpace(
		start_pattern: '\[\[',
		end_pattern: '\]\]',
		tag_as_if_valid: 'punctuation.definition.logical-expression',
		tag_as_if_invalid: 'punctuation.definition.logical-expression.invalid'
	),
	includes: [
		# Regex comparison is possible within [[ ... ]] only.
		# :regex_comparison must be placed before :logical_expression_context
		# for regex metacharacters to be recognised because the latter contains
		# :'logical-expression', which in turn contains a pattern that matches =~ too.
		:regex_comparison,
		:logical_expression_context
	]
)

grammar[:regex_comparison] = Pattern.new(
	tag_as: 'keyword.operator.logical',
	match: /=~/,
).then(
	@spaces
).then(
	match: /[^ ]*/,
	includes: [
		:variable,
		:regexp
	]
)

#
# Variable
#

# @param regex_after_dollarsign [Regexp]
# @param tag [String]
# @return [Regexp]
def generateVariable(regex_after_dollarsign, tag)
	newPattern(
		match: /\$/,
		tag_as: "punctuation.definition.variable #{tag}"
	).then(
		match: regex_after_dollarsign.then(lookAheadFor(/\W/).or(lookAheadFor(/$/))),
		tag_as: tag,
	)
end

# @type [Regexp]
array =
	newPattern(
		match: $variable_name,
		tag_as: 'variable.other.array'
	).then(
		**generateArraySubscriptBracket('[')
	).then(
		newPattern(
			match: /[@*]/,
			tag_as: 'keyword.other.subscript.all'
		).or(
			**array_subscript_contents_math
		)
	).then(
		**generateArraySubscriptBracket(']')
	)

grammar[:variable] =
	[
		generateVariable(/(?:[@*]|\{[@*]\})/, 'variable.parameter.positional.all'),
		generateVariable(/(?:#|\{#\})/, 'variable.parameter.positional.number'),
		generateVariable(/(?:[1-9]|\{[1-9][0-9]*\})/, 'variable.parameter.positional'),
		generateVariable(/(?:[-?$!0_]|\{[-?$!0_]\})/, 'variable.language.special'),
		# Parameter expansion
		PatternRange.new(
			start_pattern: newPattern(
				match: /\$/,
				tag_as: 'punctuation.definition.variable punctuation.section.bracket.curly.variable.begin'
			).then(
				match: /\{/,
				tag_as: 'punctuation.section.bracket.curly.variable.begin',
			),
			end_pattern: newPattern(
				match: /\}/,
				tag_as: 'punctuation.section.bracket.curly.variable.end',
			),
			includes: [
				{
					'match': "!|:[-=?]?|\\*|@|\#{1,2}|%{1,2}|\\^{1,2}|,{1,2}|/",
					'name': 'keyword.operator.expansion.shell'
				},
				:variable,
				:string,
				array
			]
		),
		# normal variables
		generateVariable(/\w+/, 'variable.other.normal')
	]

#
# regex (legacy format, imported from JavaScript regex)
#

grammar[:regexp] = [
	newPattern(
		tag_as: 'keyword.control.anchor.regexp',
		match: /\\[bB]|\^|\$/,
	),
	newPattern(
		tag_as: 'keyword.other.back-reference.regexp variable.other.regexp',
		match: /\\[1-9]\d*|\\k<([a-zA-Z_$][\w$]*)>/,
	),
	newPattern(
		tag_as: 'keyword.operator.quantifier.regexp',
		match: /[?+*]|\{(\d+,\d+|\d+,|,\d+|\d+)\}\??/,
	),
	newPattern(
		tag_as: 'keyword.operator.or.regexp',
		match: /\\|/,
	),
	PatternRange.new(
		tag_as: 'meta.group.assertion.regexp',
		start_pattern: newPattern(
			match: /\(/,
			tag_as: 'punctuation.definition.group.regexp'
		),
		includes: [
			newPattern(
				tag_as: 'punctuation.definition.group.assertion.regexp',
				match: newPattern(
					match: /\?=/,
					tag_as: 'meta.assertion.look-ahead.regexp'
				).or(
					match: /\?!/,
					tag_as: 'meta.assertion.negative-look-ahead.regexp'
				).or(
					match: /\?<=/,
					tag_as: 'meta.assertion.look-behind.regexp'
				).or(
					match: /\?<!/,
					tag_as: 'meta.assertion.negative-look-behind.regexp'
				)
			),
			:regexp
		],
		end_pattern: newPattern(
			match: /\)/,
			tag_as: 'punctuation.definition.group.regexp'
		),
	),
	{
		'name' => 'meta.group.regexp',
		'begin' => '\\((?:(\\?:)|(?:\\?<([a-zA-Z_$][\\w$]*)>))?',
		'beginCaptures' => {
			'0' => {
				'name' => 'punctuation.definition.group.regexp'
			},
			'1' => {
				'name' => 'punctuation.definition.group.no-capture.regexp'
			},
			'2' => {
				'name' => 'variable.other.regexp'
			}
		},
		'end' => '\\)',
		'endCaptures' => {
			'0' => {
				'name' => 'punctuation.definition.group.regexp'
			}
		},
		'patterns' => [
			{
				'include' => '#regexp'
			}
		]
	},
	{
		'name' => 'constant.other.character-class.set.regexp',
		'begin' => '(\\[)(\\^)?',
		'beginCaptures' => {
			'1' => {
				'name' => 'punctuation.definition.character-class.regexp'
			},
			'2' => {
				'name' => 'keyword.operator.negation.regexp'
			}
		},
		'end' => '(\\])',
		'endCaptures' => {
			'1' => {
				'name' => 'punctuation.definition.character-class.regexp'
			}
		},
		'patterns' => [
			{
				'name' => 'constant.other.character-class.range.regexp',
				'match' => '(?:.|(\\\\(?:[0-7]{3}|x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4}))|(\\\\c[A-Z])|(\\\\.))\\-(?:[^\\]\\\\]|(\\\\(?:[0-7]{3}|x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4}))|(\\\\c[A-Z])|(\\\\.))',
				'captures' => {
					'1' => {
						'name' => 'constant.character.numeric.regexp'
					},
					'2' => {
						'name' => 'constant.character.control.regexp'
					},
					'3' => {
						'name' => 'constant.character.escape.backslash.regexp'
					},
					'4' => {
						'name' => 'constant.character.numeric.regexp'
					},
					'5' => {
						'name' => 'constant.character.control.regexp'
					},
					'6' => {
						'name' => 'constant.character.escape.backslash.regexp'
					}
				}
			},
			{
				'include' => '#regex-character-class'
			}
		]
	},
	{
		'include' => '#regex-character-class'
	}
]

grammar[:regex_character_class] = {
	'patterns' => [
		{
			'name' => 'constant.other.character-class.regexp',
			'match' => '\\\\[wWsSdDtrnvf]|\\.'
		},
		{
			'name' => 'constant.character.numeric.regexp',
			'match' => '\\\\([0-7]{3}|x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4})'
		},
		{
			'name' => 'constant.character.control.regexp',
			'match' => '\\\\c[A-Z]'
		},
		{
			'name' => 'constant.character.escape.backslash.regexp',
			'match' => '\\\\.'
		}
	]
}

# Save
saveGrammar(grammar)
