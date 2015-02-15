//
//  main.m
//  TestSound
//
//  Created by Malcolm on 1/2/15.
//  Copyright (c) 2015 Malcolm Harrow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*
 *    Example program for the Allegro library.
 */

#include <math.h>
#include <stdbool.h>


#include "allegro.h"
#include "allegro_audio.h"
#include "allegro_font.h"

#include <stdio.h>
#include <stdarg.h>
#include <stdbool.h>

#ifdef ALLEGRO_ANDROID
#include "allegro5/allegro_android.h"
#endif

void init_platform_specific(void);
void abort_example(char const *format, ...);
void open_log(void);
void open_log_monospace(void);
void close_log(bool wait_for_user);
void log_printf(char const *format, ...);

void init_platform_specific(void)
{
#ifdef ALLEGRO_ANDROID
    al_install_touch_input();
    al_android_set_apk_file_interface();
#endif
}

#ifdef ALLEGRO_POPUP_EXAMPLES

#include "allegro5/allegro_native_dialog.h"

ALLEGRO_TEXTLOG *textlog = NULL;

void abort_example(char const *format, ...)
{
    char str[1024];
    va_list args;
    ALLEGRO_DISPLAY *display;
    
    va_start(args, format);
    vsnprintf(str, sizeof str, format, args);
    va_end(args);
    
    if (al_init_native_dialog_addon()) {
        display = al_is_system_installed() ? al_get_current_display() : NULL;
        al_show_native_message_box(display, "Error", "Cannot run example", str, NULL, 0);
    }
    else {
        fprintf(stderr, "%s", str);
    }
    exit(1);
}

void open_log(void)
{
    if (al_init_native_dialog_addon()) {
        textlog = al_open_native_text_log("Log", 0);
    }
}

void open_log_monospace(void)
{
    if (al_init_native_dialog_addon()) {
        textlog = al_open_native_text_log("Log", ALLEGRO_TEXTLOG_MONOSPACE);
    }
}

void close_log(bool wait_for_user)
{
    if (textlog && wait_for_user) {
        ALLEGRO_EVENT_QUEUE *queue = al_create_event_queue();
        al_register_event_source(queue, al_get_native_text_log_event_source(
                                                                            textlog));
        al_wait_for_event(queue, NULL);
        al_destroy_event_queue(queue);
    }
    
    al_close_native_text_log(textlog);
    textlog = NULL;
}

void log_printf(char const *format, ...)
{
    char str[1024];
    va_list args;
    va_start(args, format);
    vsnprintf(str, sizeof str, format, args);
    va_end(args);
    al_append_native_text_log(textlog, "%s", str);
}

#else

void abort_example(char const *format, ...)
{
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    exit(1);
}

void open_log(void)
{
}

void open_log_monospace(void)
{
}

void close_log(bool wait_for_user)
{
    (void)wait_for_user;
}

void log_printf(char const *format, ...)
{
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
}

#endif


#define RESERVED_SAMPLES   16
#define PERIOD             5


static ALLEGRO_DISPLAY *display;
static ALLEGRO_FONT *font;
static ALLEGRO_SAMPLE *ping;
static ALLEGRO_TIMER *timer;
static ALLEGRO_EVENT_QUEUE *event_queue;


static ALLEGRO_SAMPLE *create_sample_s16(int freq, int len)
{
    char *buf = al_malloc(len * sizeof(int16_t));
    
    return al_create_sample(buf, len, freq, ALLEGRO_AUDIO_DEPTH_INT16,
                            ALLEGRO_CHANNEL_CONF_1, true);
}


/* Adapted from SPEED. */
static ALLEGRO_SAMPLE *generate_ping(void)
{
    float osc1, osc2, vol, ramp;
    int16_t *p;
    int len;
    int i;
    
    float t, m1=0, m2=0;
    
    /* ping consists of two sine waves */
    //len = 312*2*2;
    len=11360;
    //ping = create_sample_s16(22050, len);
    ping = create_sample_s16(31200, len);
    
    
    if (!ping)
        return NULL;
    
    p = (int16_t *)al_get_sample_data(ping);
    
    osc1 = 0;
    osc2 = 0;

    memset(p, 0, len);
    
    // rest 0xff0f
    // 80x 0x00f0
    // 80x 0xff0f
    // repeat 61x
    // rest 0xff0f
//    for (int t=0; t<800; t++)
//        *p++ = 0xff0f;
    for (int k=0; k<49; k++)
    {
        for (int t=0; t<80; t++)
            *p++ = 0x00f0;
        for (int t=0; t<80; t++)
            *p++ = 0xff0f;
    }
//    for (int t=0; t<800; t++)
//        *p++ = 0xff0f;
    
    return ping;
    
    
//    memset(p, 0xAF, len*2);
    for (i=0; i<len; i++) {

        
        
        
        
//        vol = (float)(len - i) / (float)len * 4000;
//        
//        ramp = (float)i / (float)len * 8;
//        if (ramp < 1.0f)
//            vol *= ramp;
//        
//        t = (sin(osc1) + sin(osc2) - 1) * vol;
//        
        if (i < 00)
            t = 4095; // 4095;
        else
            t = -4096; // -4096 ;
//
//        //  4095 = FFF
//        // -4096 = 000
//        
//        
//        if (t>m1)  m1 = t;
//        if (t<m2)  m2 = t;
        *p = t;
//        
//        osc1 += 0.1;
//        osc2 += 0.15;
//        
        p++;
    }
    

    printf("max %f min %f float size %d\n", m1, m2, sizeof(float));

    return ping;
}


int main(int argc, char **argv)
{
    ALLEGRO_TRANSFORM trans;
    ALLEGRO_EVENT event;
    int bps = 4;
    bool redraw = false;
    unsigned int last_timer = 0;
    
    (void)argc;
    (void)argv;
    
    if (!al_init()) {
        abort_example("Could not init Allegro.\n");
    }
    
    open_log();
    
    al_install_keyboard();
    
    display = al_create_display(640, 480);
    if (!display) {
        abort_example("Could not create display\n");
    }
    
    font = al_create_builtin_font();
    if (!font) {
        abort_example("Could not create font\n");
    }
    
    if (!al_install_audio()) {
        abort_example("Could not init sound\n");
    }
    
    if (!al_reserve_samples(RESERVED_SAMPLES)) {
        abort_example("Could not set up voice and mixer\n");
    }
    
    ping = generate_ping();
    if (!ping) {
        abort_example("Could not generate sample\n");
    }
    
    timer = al_create_timer(1.0 / bps);
    al_set_timer_count(timer, -1);
    
    event_queue = al_create_event_queue();
    al_register_event_source(event_queue, al_get_keyboard_event_source());
    al_register_event_source(event_queue, al_get_timer_event_source(timer));
    
    al_identity_transform(&trans);
    al_scale_transform(&trans, 16.0, 16.0);
    al_use_transform(&trans);
    
    al_start_timer(timer);
    
    while (true) {
        al_wait_for_event(event_queue, &event);
        if (event.type == ALLEGRO_EVENT_TIMER) {
            const float speed = pow(21.0/20.0, (event.timer.count % PERIOD));
            if (!al_play_sample(ping, 1.0, 0.0, speed, ALLEGRO_PLAYMODE_ONCE, NULL)) {
                log_printf("Not enough reserved samples.\n");
            }
            redraw = true;
            last_timer = event.timer.count;
        }
        else if (event.type == ALLEGRO_EVENT_KEY_CHAR) {
            if (event.keyboard.keycode == ALLEGRO_KEY_ESCAPE) {
                break;
            }
            if (event.keyboard.unichar == '+' || event.keyboard.unichar == '=') {
                if (bps < 32) {
                    bps++;
                    al_set_timer_speed(timer, 1.0 / bps);
                }
            }
            else if (event.keyboard.unichar == '-') {
                if (bps > 1) {
                    bps--;
                    al_set_timer_speed(timer, 1.0 / bps);
                }
            }
        }
        
        if (redraw && al_is_event_queue_empty(event_queue)) {
            ALLEGRO_COLOR c;
            if (last_timer % PERIOD == 0)
                c = al_map_rgb_f(1, 1, 1);
            else
                c = al_map_rgb_f(0.5, 0.5, 1.0);
            
            al_clear_to_color(al_map_rgb(0, 0, 0));
            al_draw_textf(font, c, 640/32, 480/32 - 4, ALLEGRO_ALIGN_CENTRE,
                          "%u", last_timer);
            al_flip_display();
        }
    }
    
    close_log(false);
    
    return 0;
}
