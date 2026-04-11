/*
 * test_translate — host-side tool to decode a .p8.png and emit
 * translated Lua 5.4 source on stdout.
 *
 * Usage: test_translate <cart.p8.png>
 *
 * Pipeline: PNG → cart bytes → PXA decompress → raw PICO-8 Lua
 *           → p8_translate_full → Lua 5.4 on stdout.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "p8_machine.h"
#include "p8_p8png.h"
#include "p8_translate.h"

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "usage: %s <cart.p8.png>\n", argv[0]);
        return 1;
    }

    /* Read the PNG file into memory. */
    FILE *f = fopen(argv[1], "rb");
    if (!f) {
        perror(argv[1]);
        return 1;
    }
    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);

    unsigned char *png_data = (unsigned char *)malloc((size_t)fsize);
    if (!png_data) {
        fprintf(stderr, "malloc failed (%ld bytes)\n", fsize);
        fclose(f);
        return 1;
    }
    if (fread(png_data, 1, (size_t)fsize, f) != (size_t)fsize) {
        fprintf(stderr, "short read on %s\n", argv[1]);
        free(png_data);
        fclose(f);
        return 1;
    }
    fclose(f);

    /* Decode .p8.png → raw PICO-8 Lua source. */
    p8_machine m;
    p8_machine_reset(&m);

    char *lua_src = NULL;
    size_t lua_len = 0;
    int rc = p8_p8png_load(&m, png_data, (size_t)fsize,
                           &lua_src, &lua_len, NULL);
    free(png_data);
    if (rc != 0 || !lua_src) {
        fprintf(stderr, "p8_p8png_load failed (rc=%d)\n", rc);
        return 1;
    }

    /* Translate PICO-8 dialect → Lua 5.4. */
    size_t out_len = 0;
    char *translated = p8_translate_full(lua_src, lua_len, &out_len);
    free(lua_src);
    if (!translated) {
        fprintf(stderr, "p8_translate_full failed\n");
        return 1;
    }

    /* Write to stdout. */
    fwrite(translated, 1, out_len, stdout);
    free(translated);
    return 0;
}
