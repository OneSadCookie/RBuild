build(:targets => ['hello'],
      :dependencies => ['test.c'],
      :command => 'gcc test.c -o hello',
      :message => 'Compiling hello program from test.c')
