require_relative '../../textmate_tools.rb'
tokens = [
    { representation: 'ENV'    , areBuiltIn: true },
    { representation: 'INC'    , areBuiltIn: true },
    { representation: 'ARGV'   , areBuiltIn: true },
    { representation: 'ARGVOUT', areBuiltIn: true },
    { representation: 'SIG'    , areBuiltIn: true },
    { representation: 'STDIN'  , areBuiltIn: true },
    { representation: 'STDOUT' , areBuiltIn: true },
    { representation: 'STDERR' , areBuiltIn: true },
    { representation: 'DATA',                },
    { representation: 'atan2',               },
    { representation: 'bind',                },
    { representation: 'binmode',             },
    { representation: 'bless',               },
    { representation: 'caller',              },
    { representation: 'chdir',               },
    { representation: 'chmod',               },
    { representation: 'chomp',               },
    { representation: 'chop',                },
    { representation: 'chown',               },
    { representation: 'chr',                 },
    { representation: 'chroot',              },
    { representation: 'close',               },
    { representation: 'closedir',            },
    { representation: 'cmp',                 },
    { representation: 'connect',             },
    { representation: 'cos',                 },
    { representation: 'crypt',               },
    { representation: 'dbmclose',            },
    { representation: 'dbmopen',             },
    { representation: 'defined',             },
    { representation: 'delete',              },
    { representation: 'dump',                },
    { representation: 'each',                },
    { representation: 'endgrent',            },
    { representation: 'endhostent',          },
    { representation: 'endnetent',           },
    { representation: 'endprotoent',         },
    { representation: 'endpwent',            },
    { representation: 'endservent',          },
    { representation: 'eof',                 },
    { representation: 'eq',                  },
    { representation: 'eval',                },
    { representation: 'exec',                },
    { representation: 'exists',              },
    { representation: 'exp',                 },
    { representation: 'fcntl',               },
    { representation: 'fileno',              },
    { representation: 'flock',               },
    { representation: 'fork',                },
    { representation: 'formline',            },
    { representation: 'ge',                  },
    { representation: 'getc',                },
    { representation: 'getgrent',            },
    { representation: 'getgrgid',            },
    { representation: 'getgrnam',            },
    { representation: 'gethostbyaddr',       },
    { representation: 'gethostbyname',       },
    { representation: 'gethostent',          },
    { representation: 'getlogin',            },
    { representation: 'getnetbyaddr',        },
    { representation: 'getnetbyname',        },
    { representation: 'getnetent',           },
    { representation: 'getpeername',         },
    { representation: 'getpgrp',             },
    { representation: 'getppid',             },
    { representation: 'getpriority',         },
    { representation: 'getprotobyname',      },
    { representation: 'getprotobynumber',    },
    { representation: 'getprotoent',         },
    { representation: 'getpwent',            },
    { representation: 'getpwnam',            },
    { representation: 'getpwuid',            },
    { representation: 'getservbyname',       },
    { representation: 'getservbyport',       },
    { representation: 'getservent',          },
    { representation: 'getsockname',         },
    { representation: 'getsockopt',          },
    { representation: 'glob',                },
    { representation: 'gmtime',              },
    { representation: 'grep',                },
    { representation: 'gt',                  },
    { representation: 'hex',                 },
    { representation: 'import',              },
    { representation: 'index',               },
    { representation: 'int',                 },
    { representation: 'ioctl',               },
    { representation: 'join',                },
    { representation: 'keys',                },
    { representation: 'kill',                },
    { representation: 'lc',                  },
    { representation: 'lcfirst',             },
    { representation: 'le',                  },
    { representation: 'length',              },
    { representation: 'link',                },
    { representation: 'listen',              },
    { representation: 'local',               },
    { representation: 'localtime',           },
    { representation: 'log',                 },
    { representation: 'lstat',               },
    { representation: 'lt',                  },
    { representation: 'm',                   },
    { representation: 'map',                 },
    { representation: 'mkdir',               },
    { representation: 'msgctl',              },
    { representation: 'msgget',              },
    { representation: 'msgrcv',              },
    { representation: 'msgsnd',              },
    { representation: 'ne',                  },
    { representation: 'no',                  },
    { representation: 'oct',                 },
    { representation: 'open',                },
    { representation: 'opendir',             },
    { representation: 'ord',                 },
    { representation: 'pack',                },
    { representation: 'pipe',                },
    { representation: 'pop',                 },
    { representation: 'pos',                 },
    { representation: 'print',               },
    { representation: 'printf',              },
    { representation: 'push',                },
    { representation: 'quotemeta',           },
    { representation: 'rand',                },
    { representation: 'read',                },
    { representation: 'readdir',             },
    { representation: 'readlink',            },
    { representation: 'recv',                },
    { representation: 'ref',                 },
    { representation: 'rename',              },
    { representation: 'reset',               },
    { representation: 'reverse',             },
    { representation: 'rewinddir',           },
    { representation: 'rindex',              },
    { representation: 'rmdir',               },
    { representation: 's',                   },
    { representation: 'say',                 },
    { representation: 'scalar',              },
    { representation: 'seek',                },
    { representation: 'seekdir',             },
    { representation: 'semctl',              },
    { representation: 'semget',              },
    { representation: 'semop',               },
    { representation: 'send',                },
    { representation: 'setgrent',            },
    { representation: 'sethostent',          },
    { representation: 'setnetent',           },
    { representation: 'setpgrp',             },
    { representation: 'setpriority',         },
    { representation: 'setprotoent',         },
    { representation: 'setpwent',            },
    { representation: 'setservent',          },
    { representation: 'setsockopt',          },
    { representation: 'shift',               },
    { representation: 'shmctl',              },
    { representation: 'shmget',              },
    { representation: 'shmread',             },
    { representation: 'shmwrite',            },
    { representation: 'shutdown',            },
    { representation: 'sin',                 },
    { representation: 'sleep',               },
    { representation: 'socket',              },
    { representation: 'socketpair',          },
    { representation: 'sort',                },
    { representation: 'splice',              },
    { representation: 'split',               },
    { representation: 'sprintf',             },
    { representation: 'sqrt',                },
    { representation: 'srand',               },
    { representation: 'stat',                },
    { representation: 'study',               },
    { representation: 'substr',              },
    { representation: 'symlink',             },
    { representation: 'syscall',             },
    { representation: 'sysopen',             },
    { representation: 'sysread',             },
    { representation: 'system',              },
    { representation: 'syswrite',            },
    { representation: 'tell',                },
    { representation: 'telldir',             },
    { representation: 'tie',                 },
    { representation: 'tied',                },
    { representation: 'time',                },
    { representation: 'times',               },
    { representation: 'tr',                  },
    { representation: 'truncate',            },
    { representation: 'uc',                  },
    { representation: 'ucfirst',             },
    { representation: 'umask',               },
    { representation: 'undef',               },
    { representation: 'unlink',              },
    { representation: 'unpack',              },
    { representation: 'unshift',             },
    { representation: 'untie',               },
    { representation: 'utime',               },
    { representation: 'values',              },
    { representation: 'vec',                 },
    { representation: 'waitpid',             },
    { representation: 'wantarray',           },
    { representation: 'warn',                },
    { representation: 'write',               },
    { representation: 'y',                   },
    # arithmetic,
    { representation: "+",    areOperators: true, areArithmeticOperators: true },
    { representation: "-",    areOperators: true, areArithmeticOperators: true },
    { representation: "*",    areOperators: true, areArithmeticOperators: true },
    { representation: "/",    areOperators: true, areArithmeticOperators: true },
    { representation: "**",   areOperators: true, areArithmeticOperators: true },
    { representation: "%",    areOperators: true, areArithmeticOperators: true },
    # arithmetic assignment,
    { representation: "+=",   areOperators: true, areArithmeticOperators: true, areAssignmentOperators: true },
    { representation: "-=",   areOperators: true, areArithmeticOperators: true, areAssignmentOperators: true },
    { representation: "*=",   areOperators: true, areArithmeticOperators: true, areAssignmentOperators: true },
    { representation: "/=",   areOperators: true, areArithmeticOperators: true, areAssignmentOperators: true },
    { representation: "**=",  areOperators: true, areArithmeticOperators: true, areAssignmentOperators: true },
    { representation: "%=",   areOperators: true, areArithmeticOperators: true, areAssignmentOperators: true },
    { representation: "--",   areOperators: true, areArithmeticOperators: true, },
    { representation: "++",   areOperators: true, areArithmeticOperators: true, },
    # comparison,
    { representation: "==",   areOperators: true, areComparisonOperators: true },
    { representation: "!=",   areOperators: true, areComparisonOperators: true },
    { representation: ">",    areOperators: true, areComparisonOperators: true },
    { representation: "<",    areOperators: true, areComparisonOperators: true },
    { representation: ">=",   areOperators: true, areComparisonOperators: true },
    { representation: "<=",   areOperators: true, areComparisonOperators: true },
    { representation: "<=>",  areOperators: true, areComparisonOperators: true },
    { representation: "=~",   areOperators: true, areComparisonOperators: true },
    { representation: "!~",   areOperators: true, areComparisonOperators: true },
    
    { representation: "lt",   areOperators: true, areComparisonOperators: true, areOperatorAliases: true },
    { representation: "gt",   areOperators: true, areComparisonOperators: true, areOperatorAliases: true },
    { representation: "le",   areOperators: true, areComparisonOperators: true, areOperatorAliases: true },
    { representation: "ge",   areOperators: true, areComparisonOperators: true, areOperatorAliases: true },
    { representation: "eq",   areOperators: true, areComparisonOperators: true, areOperatorAliases: true },
    { representation: "ne",   areOperators: true, areComparisonOperators: true, areOperatorAliases: true },
    { representation: "cmp",  areOperators: true, areComparisonOperators: true, areOperatorAliases: true },
    { representation: "~~",   areOperators: true, areComparisonOperators: true },
    # logical operators,
    { representation: "&&",   areOperators: true, areLogicalOperators: true },
    { representation: "and",  areOperators: true, areLogicalOperators: true, areOperatorAliases: true },
    { representation: "||",   areOperators: true, areLogicalOperators: true },
    { representation: "or",   areOperators: true, areLogicalOperators: true, areOperatorAliases: true },
    { representation: "//",   areOperators: true, areLogicalOperators: true },
    # bitwise,
    { representation: "<<",   areOperators: true, areBitwiseOperators: true },
    { representation: ">>",   areOperators: true, areBitwiseOperators: true },
    { representation: "&",    areOperators: true, areBitwiseOperators: true },
    { representation: "|",    areOperators: true, areBitwiseOperators: true },
    { representation: "^",    areOperators: true, areBitwiseOperators: true },
    { representation: "<<=",  areOperators: true, areBitwiseOperators: true, areAssignmentOperators: true },
    { representation: ">>=",  areOperators: true, areBitwiseOperators: true, areAssignmentOperators: true },
    { representation: "&=",   areOperators: true, areBitwiseOperators: true, areAssignmentOperators: true },
    { representation: "|=",   areOperators: true, areBitwiseOperators: true, areAssignmentOperators: true },
    { representation: "^=",   areOperators: true, areBitwiseOperators: true, areAssignmentOperators: true },
    # assignment,
    { representation: "=",    areOperators: true, areAssignmentOperators: true },
    # other
    { representation: ".",    areOperators: true },
    { representation: ".=",   areOperators: true, areAssignmentOperators: true },
]

@tokens = TokenHelper.new tokens, for_each_token: ->(each) do 
    # isSymbol, isWordish
    if each[:representation] =~ /[a-zA-Z0-9_]/
        each[:isWordish] = true
    else
        each[:isSymbol] = true
    end
end