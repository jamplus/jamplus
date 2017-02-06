#include <stdio.h>

int main(int argc, char** argv) {
    FILE* file = fopen(argv[1], "rb");
    fseek(file, 0, SEEK_END);
    long fileSize = ftell(file);
    fseek(file, 0, SEEK_SET);
    unsigned char* buffer = new unsigned char[fileSize];
    fread(buffer, 1, fileSize, file);
    fclose(file);

    file = fopen(argv[2], "wb");
    for (size_t i = 0; i < fileSize; ++i) {
        buffer[i]++;
    }
    fwrite(buffer, 1, fileSize, file);
    fclose(file);
    return 0;
}


//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
