/*
 * ThumbyP8 — TinyUSB descriptors for composite CDC + MSC device.
 *
 * Endpoint layout (full speed, 64-byte packets):
 *   EP0 IN/OUT  : control
 *   EP1 IN      : CDC notification (interrupt)
 *   EP2 OUT/IN  : CDC data (bulk)
 *   EP3 OUT/IN  : MSC data (bulk)
 *
 * VID/PID: borrows the TinyUSB demo VID with a custom PID. Not
 * a registered USB-IF assignment — fine for development.
 */
#include "tusb.h"
#include "pico/unique_id.h"
#include <string.h>

/* --- device descriptor ---------------------------------------------- */
tusb_desc_device_t const desc_device = {
    .bLength            = sizeof(tusb_desc_device_t),
    .bDescriptorType    = TUSB_DESC_DEVICE,
    .bcdUSB             = 0x0200,
    .bDeviceClass       = TUSB_CLASS_MISC,
    .bDeviceSubClass    = MISC_SUBCLASS_COMMON,
    .bDeviceProtocol    = MISC_PROTOCOL_IAD,
    .bMaxPacketSize0    = 64,
    .idVendor           = 0xCafe,
    .idProduct          = 0x4011,
    .bcdDevice          = 0x0100,
    .iManufacturer      = 0x01,
    .iProduct           = 0x02,
    .iSerialNumber      = 0x03,
    .bNumConfigurations = 0x01,
};
uint8_t const *tud_descriptor_device_cb(void) {
    return (uint8_t const *)&desc_device;
}

/* --- configuration descriptor --------------------------------------- */
enum {
    ITF_NUM_CDC = 0,
    ITF_NUM_CDC_DATA,
    ITF_NUM_MSC,
    ITF_NUM_TOTAL,
};

#define EPNUM_CDC_NOTIF   0x81
#define EPNUM_CDC_OUT     0x02
#define EPNUM_CDC_IN      0x82
#define EPNUM_MSC_OUT     0x03
#define EPNUM_MSC_IN      0x83

#define CONFIG_TOTAL_LEN  (TUD_CONFIG_DESC_LEN + TUD_CDC_DESC_LEN + TUD_MSC_DESC_LEN)

uint8_t const desc_fs_configuration[] = {
    TUD_CONFIG_DESCRIPTOR(1, ITF_NUM_TOTAL, 0, CONFIG_TOTAL_LEN, 0x00, 100),

    /* CDC: 2 interfaces (control + data) */
    TUD_CDC_DESCRIPTOR(ITF_NUM_CDC, 4, EPNUM_CDC_NOTIF, 8,
                       EPNUM_CDC_OUT, EPNUM_CDC_IN, 64),

    /* MSC: 1 interface */
    TUD_MSC_DESCRIPTOR(ITF_NUM_MSC, 5, EPNUM_MSC_OUT, EPNUM_MSC_IN, 64),
};

uint8_t const *tud_descriptor_configuration_cb(uint8_t index) {
    (void)index;
    return desc_fs_configuration;
}

/* --- string descriptors --------------------------------------------- */
char const *string_desc_arr[] = {
    (const char[]){0x09, 0x04},   /* 0: language id - English */
    "ThumbyP8",                    /* 1: manufacturer */
    "ThumbyP8 Console",            /* 2: product */
    NULL,                          /* 3: serial — filled at runtime */
    "ThumbyP8 Serial",             /* 4: CDC interface */
    "ThumbyP8 Carts",              /* 5: MSC interface */
};

static uint16_t _desc_str[32];
static char _serial[2 * PICO_UNIQUE_BOARD_ID_SIZE_BYTES + 1] = {0};

uint16_t const *tud_descriptor_string_cb(uint8_t index, uint16_t langid) {
    (void)langid;
    uint8_t chr_count;

    if (index == 0) {
        memcpy(&_desc_str[1], string_desc_arr[0], 2);
        chr_count = 1;
    } else if (index == 3) {
        if (_serial[0] == 0) {
            pico_unique_board_id_t bid;
            pico_get_unique_board_id(&bid);
            for (int i = 0; i < PICO_UNIQUE_BOARD_ID_SIZE_BYTES; i++) {
                static const char hex[] = "0123456789ABCDEF";
                _serial[i*2 + 0] = hex[(bid.id[i] >> 4) & 0xf];
                _serial[i*2 + 1] = hex[bid.id[i] & 0xf];
            }
            _serial[2 * PICO_UNIQUE_BOARD_ID_SIZE_BYTES] = 0;
        }
        chr_count = (uint8_t)strlen(_serial);
        if (chr_count > 31) chr_count = 31;
        for (uint8_t i = 0; i < chr_count; i++) _desc_str[1 + i] = _serial[i];
    } else {
        if (index >= sizeof(string_desc_arr) / sizeof(string_desc_arr[0])) return NULL;
        const char *s = string_desc_arr[index];
        if (!s) return NULL;
        chr_count = (uint8_t)strlen(s);
        if (chr_count > 31) chr_count = 31;
        for (uint8_t i = 0; i < chr_count; i++) _desc_str[1 + i] = s[i];
    }

    /* first byte: total descriptor length, second: type */
    _desc_str[0] = (uint16_t)((TUSB_DESC_STRING << 8) | (2 * chr_count + 2));
    return _desc_str;
}
