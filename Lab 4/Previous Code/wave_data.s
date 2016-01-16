SQUARE::
	.byte 4                   ; Number of Segments In A Square Wave
	.word 0000                ; Initial Da Input Value (0 volts)
	.byte 1                   ; Length for Segment_1
	.word 3276                ; Increment For Segment_1
	.byte 9                   ; Length for Segment_2
	.word 0                   ; Increment For Segment_2
	.byte 1                   ; Length for Segment_3
	.word -3276               ; Increment For Segment_3
	.byte 9                   ; Length for Segment_4
	.word 0                   ; Increment For Segment_4
	
SINE_15::
	.byte 15                  ; number of segments for SINE
	.word 2048                ; initial DAC input value
	.byte 10 				  ; length for segment_1
	.word 41                  ; increment for segment_1
	.byte 21                  ; length for segment_2
	.word 37                  ; increment for segment_2
	.byte 21                  ; length for segment_3
	.word 25                  ; increment for segment_3
	.byte 21                  ; length for segment_4
	.word 9                   ; increment for segment_4
	.byte 21                  ; length for segment_5
	.word -9                  ; increment for segment_5
	.byte 21                  ; length for segment_6
	.word -25                 ; increment for segment_6
	.byte 21                  ; length for segment_7
	.word -37                 ; increment for segment_7
	.byte 20                  ; length for segment_8
	.word -41                 ; increment for segment_8
	.byte 21                  ; length for segment_9
	.word -37                 ; increment for segment_9
	.byte 21                  ; length for segment_10
	.word -25                 ; increment for segment_10
	.byte 21                  ; length for segment_11
	.word -9                  ; increment for segment_11
	.byte 21                  ; length for segment_12
	.word 9                   ; increment for segment_12
	.byte 21                  ; length for segment_13
	.word 25                  ; increment for segment_13
	.byte 21                  ; length for segment_14
	.word 37                  ; increment for segment_14
	.byte 10                  ; length for segment_15
	.word 41                  ; increment for segment_15
	
TRIANGLE::
	.byte 3                   ; number of segments for TRIANGLE
	.word 2048                ; initial DAC input value
	.byte 50                  ; length for segment_1
	.word 30                  ; increment for segment_1
	.byte 100                 ; length for segment_2
	.word -30                 ; increment for segment_2
	.byte 50                  ; length for segment_3
	.word 30                  ; increment for segment_3
	
SINE_7::
	.byte 7                   ; Number of Segments In A Square Wave
	.word 2048                ; Initial Da Input Value (0 volts)
	.byte 24                  ; Length for Segment_1
	.word 34                  ; Increment For Segment_1
	.byte 100                 ; Length for Segment_2
	.word 4                   ; Increment For Segment_2
	.byte 100                 ; Length for Segment_3
	.word -4                  ; Increment For Segment_3
	.byte 100                 ; Length for Segment_4
	.word -16                 ; Increment For Segment_4
	.byte 100                 ; Length for Segment_5
	.word -4                  ; Increment For Segment_5
	.byte 100                 ; Length for Segment_6
	.word 4                   ; Increment For Segment_6
	.byte 24                  ; Length for Segment_7
	.word 34                  ; Increment For Segment_7
	
SAWTOOTH::
	.byte 2                   ; Number of Segments In A Square Wave
	.word 0000                ; Initial Da Input Value (0 volts)
	.byte 19                  ; Length for Segment_1
	.word 172                 ; Increment For Segment_1
	.byte 1                   ; Length for Segment_2
	.word -3268               ; Increment For Segment_2
	