Project:      Lab2Code
Build Number: 0
Date:         Thu Oct 01 14:58:54 2015
Compiler:     ICC12
Version:      7.09.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   C000   0228 =    552. bytes (rel,con,rom)

       Addr  Global Symbol
      -----  --------------------------------
       C000  __start
       C053  _exit
       C055  _main
       C223  __HC12Setup
       C228  __text_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             bss   0800   000F =     15. bytes (rel,con,rom)

       Addr  Global Symbol
      -----  --------------------------------
       0800  __bss_start
       0800  TICKS_1
       0802  COUNT_1
       0804  DONE_1
       0805  TICKS_2
       0807  COUNT_2
       0809  DONE_2
       080A  t1state
       080B  t2state
       080C  t3state
       080D  t4state
       080E  t5state
       080F  __bss_end

Area                               Start  End    Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
               interrupt_vectors   0000   10000 =  65536. bytes (abs,ovr,rom)

Files Linked      [ module(s) ]

Y:\icc\lib\crt12ext.o	[ crt12ext.s ]
Lab2Code.o	[ Lab2Code.s ]
<library>	[ setup.c ]

User Global Definitions

init_sp = 0xbb0

Area Definitions

-btext:0xc000.0xffff
-bdata:0x800.0xffff

