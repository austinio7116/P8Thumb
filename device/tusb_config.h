/*
 * TinyUSB configuration for ThumbyP8: composite CDC + MSC.
 * CDC keeps stdio over USB serial; MSC exposes the flash disk so
 * the user can drag carts onto a removable drive.
 */
#ifndef THUMBYP8_TUSB_CONFIG_H
#define THUMBYP8_TUSB_CONFIG_H

#define CFG_TUSB_MCU            OPT_MCU_RP2040
#define CFG_TUSB_OS             OPT_OS_PICO
#define CFG_TUSB_DEBUG          0

/* CRITICAL: defining CFG_TUSB_RHPORT0_MODE is what causes
 * tusb_option.h to set TUD_OPT_RHPORT, which in turn is the only
 * gate that lets tusb_init() actually call tud_init() and bring up
 * the USB hardware. Without it, tusb_init() returns true but
 * silently does nothing — the device never enumerates. */
#define CFG_TUSB_RHPORT0_MODE   (OPT_MODE_DEVICE | OPT_MODE_FULL_SPEED)

#define CFG_TUD_ENABLED         1
#define CFG_TUD_MAX_SPEED       OPT_MODE_FULL_SPEED

#define CFG_TUD_ENDPOINT0_SIZE  64

/* Class enables */
#define CFG_TUD_CDC             1
#define CFG_TUD_MSC             1
#define CFG_TUD_HID             0
#define CFG_TUD_MIDI            0
#define CFG_TUD_VENDOR          0

/* CDC FIFO sizes */
#define CFG_TUD_CDC_RX_BUFSIZE  256
#define CFG_TUD_CDC_TX_BUFSIZE  256
#define CFG_TUD_CDC_EP_BUFSIZE  64

/* MSC sector buffer — must be at least one sector (512). */
#define CFG_TUD_MSC_EP_BUFSIZE  512

#endif
