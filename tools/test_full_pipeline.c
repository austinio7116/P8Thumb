/*
 * Test the full on-device pipeline locally:
 * .p8.png → PNG decode → PXA decompress → shrinko8 unminify →
 * translate → compile → dump .luac + save .rom + save .bmp
 *
 * Usage: test_full_pipeline <input.p8.png> <output_dir>
 * Produces: <output_dir>/<stem>.luac, .rom, .bmp
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "p8_p8png.h"
#include "p8_translate.h"
#include "p8_machine.h"

#include "lua.h"
#include "lauxlib.h"

/* BMP writer — same as device/p8_bmp.c p8_bmp_save_128 */
static void wr16(unsigned char *p, unsigned short v) {
    p[0] = v & 0xff; p[1] = (v >> 8) & 0xff;
}
static void wr32(unsigned char *p, unsigned int v) {
    p[0] = v & 0xff; p[1] = (v >> 8) & 0xff;
    p[2] = (v >> 16) & 0xff; p[3] = (v >> 24) & 0xff;
}

static int write_bmp(const char *path, const uint16_t *rgb565) {
    unsigned char hdr[14 + 40 + 12];
    memset(hdr, 0, sizeof(hdr));
    unsigned int hdr_size = 14 + 40 + 12;
    unsigned int img_size = 128 * 128 * 2;
    unsigned int file_size = hdr_size + img_size;
    hdr[0] = 'B'; hdr[1] = 'M';
    wr32(hdr + 2, file_size);
    wr32(hdr + 10, hdr_size);
    wr32(hdr + 14, 40);
    wr32(hdr + 18, 128);
    wr32(hdr + 22, 128);
    wr16(hdr + 26, 1);
    wr16(hdr + 28, 16);
    wr32(hdr + 30, 3);
    wr32(hdr + 34, img_size);
    wr32(hdr + 38, 2835);
    wr32(hdr + 42, 2835);
    wr32(hdr + 54, 0xF800);
    wr32(hdr + 58, 0x07E0);
    wr32(hdr + 62, 0x001F);
    FILE *f = fopen(path, "wb");
    if (!f) return -1;
    fwrite(hdr, 1, sizeof(hdr), f);
    for (int y = 127; y >= 0; y--) {
        fwrite(rgb565 + y * 128, 2, 128, f);
    }
    fclose(f);
    return 0;
}

/* lua_dump writer */
typedef struct { unsigned char *data; size_t len, cap; } dump_buf;
static int dump_writer(lua_State *L, const void *p, size_t sz, void *ud) {
    dump_buf *db = (dump_buf *)ud;
    (void)L;
    if (db->len + sz > db->cap) {
        size_t nc = db->cap ? db->cap : 1024;
        while (nc < db->len + sz) nc *= 2;
        unsigned char *nd = realloc(db->data, nc);
        if (!nd) return 1;
        db->data = nd; db->cap = nc;
    }
    memcpy(db->data + db->len, p, sz);
    db->len += sz;
    return 0;
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: test_full_pipeline <input.p8.png> <output_dir>\n");
        return 1;
    }
    const char *png_path = argv[1];
    const char *out_dir = argv[2];

    /* Extract stem from filename */
    const char *base = strrchr(png_path, '/');
    base = base ? base + 1 : png_path;
    char stem[64];
    strncpy(stem, base, sizeof(stem) - 1);
    stem[sizeof(stem) - 1] = 0;
    char *ext = strstr(stem, ".p8.png");
    if (ext) *ext = 0;

    char luac_path[256], rom_path[256], bmp_path[256], lua_path[256];
    snprintf(luac_path, sizeof(luac_path), "%s/%s.luac", out_dir, stem);
    snprintf(rom_path, sizeof(rom_path), "%s/%s.rom", out_dir, stem);
    snprintf(bmp_path, sizeof(bmp_path), "%s/%s.bmp", out_dir, stem);
    snprintf(lua_path, sizeof(lua_path), "%s/%s.lua", out_dir, stem);

    /* 1. Load PNG */
    printf("[%s] loading png...\n", stem);
    FILE *f = fopen(png_path, "rb");
    if (!f) { fprintf(stderr, "can't open %s\n", png_path); return 1; }
    fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
    unsigned char *png_data = malloc(sz);
    fread(png_data, 1, sz, f);
    fclose(f);
    printf("  png: %ld bytes\n", sz);

    /* 2. Decode PNG → ROM + Lua source + thumbnail */
    printf("  decoding...\n");
    p8_machine m;
    memset(&m, 0, sizeof(m));
    char *lua_src = NULL;
    size_t lua_len = 0;
    uint16_t thumb[128 * 128];
    /* p8_p8png_load takes ownership of png_data and frees it */
    int rc = p8_p8png_load(&m, png_data, (size_t)sz,
                            &lua_src, &lua_len, thumb);
    /* png_data already freed inside p8_p8png_load */
    if (rc != 0 || !lua_src) {
        fprintf(stderr, "  PNG decode FAILED\n");
        return 1;
    }
    printf("  raw lua: %zu bytes\n", lua_len);

    /* 3. Save ROM */
    f = fopen(rom_path, "wb");
    if (f) { fwrite(m.mem, 1, 0x4300, f); fclose(f); }
    printf("  saved %s\n", rom_path);

    /* 4. Save BMP from visible PNG thumbnail */
    write_bmp(bmp_path, thumb);
    printf("  saved %s\n", bmp_path);

    /* 5. Translate */
    printf("  translating...\n");
    size_t translated_len = 0;
    /* p8_translate_full takes ownership of lua_src */
    char *translated = p8_translate_full(lua_src, lua_len, &translated_len);
    if (!translated) {
        fprintf(stderr, "  translate FAILED\n");
        return 1;
    }
    printf("  translated: %zu bytes\n", translated_len);

    /* Save translated .lua for debugging */
    f = fopen(lua_path, "wb");
    if (f) { fwrite(translated, 1, translated_len, f); fclose(f); }

    /* 6. Compile */
    printf("  compiling...\n");
    lua_State *L = luaL_newstate();
    if (!L) { fprintf(stderr, "  lua VM alloc FAILED\n"); free(translated); return 1; }

    rc = luaL_loadbuffer(L, translated, translated_len, "=cart");
    free(translated);

    if (rc != LUA_OK) {
        const char *err = lua_tostring(L, -1);
        fprintf(stderr, "  COMPILE FAILED: %s\n", err ? err : "(no msg)");
        lua_close(L);
        return 1;
    }
    printf("  compile OK\n");

    /* 7. Dump bytecode */
    dump_buf db = {0};
    lua_dump(L, dump_writer, &db);  /* Lua 5.2: no strip parameter */
    lua_close(L);

    if (!db.data || db.len == 0) {
        fprintf(stderr, "  dump FAILED\n");
        return 1;
    }

    f = fopen(luac_path, "wb");
    if (f) { fwrite(db.data, 1, db.len, f); fclose(f); }
    free(db.data);
    printf("  saved %s (%zu bytes)\n", luac_path, db.len);

    printf("[%s] DONE OK\n", stem);
    return 0;
}
