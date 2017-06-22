#include <windows.h>
#include <stdio.h>

void pf(const char* name){
	wchar_t wname[_MAX_DIR];
	mbstowcs_s(NULL, wname, sizeof(wname)/sizeof(wchar_t), name, _TRUNCATE);

    HANDLE file = CreateFile(wname, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if(file == INVALID_HANDLE_VALUE){ printf("couldn't open %s\n", name); return; };

    unsigned int len  = GetFileSize(file, 0);

    HANDLE mapping  = CreateFileMapping(file, 0, PAGE_READONLY, 0, 0, 0);
    if(mapping == 0) { printf("couldn't map %s\n", name); return; }

    const char* data = (const char*) MapViewOfFile(mapping, FILE_MAP_READ, 0, 0, 0);

    if(data){
        printf("prefetching %s... ", name);

        // need volatile or need to use result - compiler will otherwise optimize out whole loop
        volatile unsigned int touch = 0;

        for(unsigned int i = 0; i < len; i += 4096){
            touch += data[i];
		}
		printf("Done\n");
    }
    else{
        printf("couldn't create view of %s\n", name);
	}

    UnmapViewOfFile(data);
    CloseHandle(mapping);
    CloseHandle(file);
}

int main(int argc, const char** argv){
    if(argc >= 2){
		for(int i = 1; argv[i]; ++i){
			pf(argv[i]);
		}
	}
    return 0;
}