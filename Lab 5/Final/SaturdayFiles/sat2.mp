Project:      sat2
Build Number: 0
Date:         Sat Dec 05 16:09:32 2015
Compiler:     ICC12
Version:      7.09.00


Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                            text   C000   0EE1 =   3809. bytes (rel,con,rom)

       Addr  Global Symbol
      -----  --------------------------------
       C000  __start
       C053  _exit
       C055  _main
       CEDC  __HC12Setup
       CEE1  __text_end

Area                               Addr   Size   Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                             bss   0800   007B =    123. bytes (rel,con,rom)

       Addr  Global Symbol
      -----  --------------------------------
       0800  mmState
       0800  __bss_start
       0801  kpdState
       0802  displayState
       0803  backspaceState
       0804  stateVariableState
       0805  tc0State
       0806  V_Ref
       0808  V_Act
       080A  Error
       080C  E_Sum
       080E  KiplusKp
       0810  A_Prime
       0812  A_Star
       0814  Ki
       0816  oldKi
       0818  Kp
       081A  Kpdivs
       081C  Kidivs
       081E  Dac_Value
       0820  Theta_New
       0822  Theta_Old
       0824  Effort
       0826  slopeTimesDacValue
       0828  bConstant
       082A  DAC_PLUS_FIVE
       082C  SS_ERROR
       082E  keyStore
       082F  buffer
       0835  result
       0837  updateBuffer
       083C  updateResult
       083E  stateVariable
       083F  Dac_ValueMinusSixVolts
       0841  Dac_ValueTimesHundred
       0843  digitCounter
       0844  updateCounter
       0845  LCDUpdateCounter
       0846  keyFlag
       0847  echoFlag
       0848  enterFlag
       0849  firstChar
       084A  backspaceFlag
       084B  digitFlag
       084C  charFlag
       084D  RUN
       084E  loopSetFlag
       084F  stateVariableFlag
       0850  autoManualFlag
       0851  LCDUpdateFlag
       0852  VRefFlag
       0853  VActFlag
       0854  effortFlag
       0855  errorFlag
       0856  KiFlag
       0857  KpFlag
       0858  AFlag
       0859  BFlag
       085A  CFlag
       085B  DFlag
       085C  EFlag
       085D  FFlag
       085E  firstKiFlag
       085F  onPrintFlag
       0860  offPrintFlag
       0861  openLoopPrintFlag
       0862  closedLoopPrintFlag
       0863  autoPrintFlag
       0864  manualPrintFlag
       0865  VRefNegPrintFlag
       0866  VRefPosPrintFlag
       0867  backspacePrint
       0868  VRefPromptFlag
       0869  KiPromptFlag
       086A  KpPromptFlag
       086B  digitAllowed
       086C  VRefSignFlag
       086D  updateValuesFlag
       086E  updateLine1Flag
       086F  updateLine2Flag
       0870  promptUpFlag
       0871  VRefSign
       0872  VActSign
       0873  effortSign
       0874  errorSign
       0875  pointer
       0877  updatePointer
       0879  displayPointer
       087B  __bss_end

Area                               Start  End    Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
               interrupt_vectors   0000   10000 =  65536. bytes (abs,ovr,rom)

Area                               Start  End    Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                     LCD_KEY_BUF   0BB0   0BFD =   3069. bytes (abs,ovr,rom)

       Addr  Global Symbol
      -----  --------------------------------
       0BB0  L$CHARACTER
       0BB1  L$KEY_FLG
       0BB2  L$VREF_BUF
       0BB6  L$VACT_BUF
       0BBA  L$ERR_BUF
       0BBE  L$EFRT_BUF
       0BC2  L$KI_BUF
       0BC7  L$KP_BUF
       0BF9  L$POS_BUF
       0BFB  L$VEL_BUF

Area                               Start  End    Decimal Bytes (Attributes)
--------------------------------   ----   ----   ------- ----- ------------
                          IO_LIB   FB00   FF9B =  65435. bytes (abs,ovr,rom)

       Addr  Global Symbol
      -----  --------------------------------
       FB00  _initlcd
       FB00  INITLCD
       FB78  _putchar
       FB78  PUTCHAR
       FBFE  OUTSTRING
       FC16  OUTCHAR_AT
       FC25  OUTCHAR
       FC37  _clrscreen
       FC37  CLRSCREEN
       FC41  _setaddr
       FC43  SETADDR
       FC4D  BACKSPC
       FC4D  _backspc
       FC61  CURSOR
       FC61  _cursor
       FC6B  _dispoff
       FC6B  DISPOFF
       FCF9  _loadaddr
       FCFF  LOAD_ADDR
       FD3A  LCDTEMPLATE
       FD41  UPDATELCDL1
       FD68  UPDATELCDL2
       FE5C  _initkey
       FE5C  INITKEY
       FE67  KP_ACTIVE
       FE67  _kp_active
       FE6C  _kp_inactive
       FE6C  KP_INACTIVE
       FE71  FLUSH_BFR
       FE77  _getchar
       FE77  GETCHAR
       FE8B  _echo
       FE8B  ECHO
       FE9F  KEYPAD
       FECB  INITSC0
       FEDF  INITSC1
       FEF3  SC0_GETCHAR
       FF01  SC1_GETCHAR
       FF0F  SC0_PUTCHAR
       FF24  SC1_PUTCHAR
       FF39  SC0_PUTDATA
       FF6A  SC1_PUTDATA

Files Linked      [ module(s) ]

Y:\icc\lib\crt12ext.o	[ crt12ext.s ]
sat2.o	[ sat2.s ]
<library>	[ ME305libV7.s, setup.c ]

User Global Definitions

init_sp = 0xbb0

Area Definitions

-btext:0xc000.0xffff
-bdata:0x800.0xffff

