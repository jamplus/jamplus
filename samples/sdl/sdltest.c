#include <SDL.h>
#ifdef __APPLE__
#include "TargetConditionals.h"
#if TARGET_IPHONE_SIMULATOR  ||  TARGET_OS_IPHONE
#include <SDL_opengles2.h>
#elif TARGET_OS_MAC
#include <SDL_opengl.h>
#endif
#else
#include <SDL_opengles2.h>
#endif

int main(int argc, char** argv)
{
    SDL_Window* window;
    SDL_Event event;
    int done = 0;
    SDL_GLContext gl;

    SDL_Init(SDL_INIT_EVERYTHING);

    SDL_DisplayMode displayMode;
    SDL_GetDesktopDisplayMode(0, &displayMode);

    window = SDL_CreateWindow("SDL Tutorial", 0, 0, displayMode.w, displayMode.h, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
    gl = SDL_GL_CreateContext(window);

    while (!done) {
        SDL_PumpEvents();
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
                case SDL_QUIT:
                    done = 1;
                    break;

                case SDL_APP_DIDENTERFOREGROUND:
                    SDL_Log("SDL_APP_DIDENTERFOREGROUND");
                    break;

                case SDL_APP_DIDENTERBACKGROUND:
                    SDL_Log("SDL_APP_DIDENTERBACKGROUND");
                    break;

                case SDL_APP_LOWMEMORY:
                    SDL_Log("SDL_APP_LOWMEMORY");
                    break;

                case SDL_APP_TERMINATING:
                    SDL_Log("SDL_APP_TERMINATING");
                    break;

                case SDL_APP_WILLENTERBACKGROUND:
                    SDL_Log("SDL_APP_WILLENTERBACKGROUND");
                    break;

                case SDL_APP_WILLENTERFOREGROUND:
                    SDL_Log("SDL_APP_WILLENTERFOREGROUND");
                    break;

                case SDL_FINGERMOTION:
                    SDL_Log("SDL_FINGERMOTION");
                    break;

                case SDL_FINGERDOWN:
                    SDL_Log("SDL_FINGERDOWN");
                    break;

                case SDL_FINGERUP:
                    SDL_Log("SDL_FINGERUP");
                    break;
            }
        }

        //glClearColor(rand() % 255 / 255.0f, rand() % 255 / 255.0f, rand() % 255 / 255.0f, 1);
        glClearColor(0.0f, 0.0f, 1.0f, 1);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
        SDL_GL_SwapWindow(window);
    }

    SDL_GL_DeleteContext(gl);
    //SDL_Surface* screenSurface;
    //screenSurface = SDL_GetWindowSurface(window);
    //SDL_FillRect(screenSurface, NULL, SDL_MapRGB(screenSurface->format, 0xFF, 0xFF, 0xFF));
    //SDL_UpdateWindowSurface(window);
    SDL_Delay(2000);
    SDL_DestroyWindow( window );
    SDL_Quit();

    return 0;
}
