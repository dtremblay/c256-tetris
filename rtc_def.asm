;;;
;;; F256 definitions for the real time clock (bq4802)
;;;

RTC_SECS        = $D690
RTC_SECS_ALRM   = $D691
RTC_MINS        = $D692
RTC_MINS_ALRM   = $D693
RTC_HOURS       = $D694
RTC_HOURS_ALRM  = $D695
RTC_DAY         = $D696
RTC_DAY_ALRM    = $D697
RTC_DAY_OF_WEEK = $D698
RTC_MONTH       = $D699
RTC_YEAR        = $D69A

RTC_RATES = $D69B
    RTC_PI_0     = $00    ; Periodic Interrupt rates...
    RTC_PI_30us  = $01
    RTC_PI_61us  = $02
    RTC_PI_122us = $03
    RTC_PI_244us = $04
    RTC_PI_488us = $05
    RTC_PI_976us = $06
    RTC_PI_1ms   = $07
    RTC_PI_3ms   = $08
    RTC_PI_7ms   = $09
    RTC_PI_15ms  = $0A
    RTC_PI_31ms  = $0B
    RTC_PI_62ms  = $0C
    RTC_PI_125ms = $0D
    RTC_PI_250ms = $0E
    RTC_PI_500ms = $0F

RTC_ENABLES = $D69C
    RTC_ABE   = $01
    RTC_PWRIE = $02
    RTC_PIE   = $04
    RTC_AIE   = $08

RTC_FLAGS = $D69D
    RTC_BVF  = $01
    RTC_PWRF = $02
    RTC_PF   = $04
    RTC_AF   = $08

RTC_CTRL = $D96E
    RTC_DSE  = $01
    RTC_24HR = $02
    RTC_STOP = $04
    RTC_UTI  = $08

RTC_CENTURY = $D69F