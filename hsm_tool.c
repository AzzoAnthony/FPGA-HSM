#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>

#define BAUD_RATE B115200

int open_serial(const char *port) {
    int fd = open(port, O_RDWR | O_NOCTTY | O_SYNC);
    if (fd < 0) {
        perror("Error opening serial port");
        return -1;
    }
    struct termios tty;
    tcgetattr(fd, &tty);
    cfsetospeed(&tty, BAUD_RATE);
    cfsetispeed(&tty, BAUD_RATE);
    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;
    tty.c_iflag &= ~IGNBRK;
    tty.c_lflag = 0;
    tty.c_oflag = 0;
    tty.c_cc[VMIN]  = 1;
    tty.c_cc[VTIME] = 5;
    tty.c_iflag &= ~(IXON | IXOFF | IXANY);
    tty.c_cflag |= (CLOCAL | CREAD);
    tty.c_cflag &= ~(PARENB | PARODD);
    tty.c_cflag &= ~CSTOPB;
    tty.c_cflag &= ~CRTSCTS;
    tcsetattr(fd, TCSANOW, &tty);
    return fd;
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: hsm_tool <port> <keygen|encrypt|decrypt|lockout> [hex_data]\n");
        printf("Example: hsm_tool /dev/ttyUSB0 encrypt 00112233445566778899aabbccddeeff\n");
        return 1;
    }

    int fd = open_serial(argv[1]);
    if (fd < 0) return 1;

    uint8_t response[18];
    int n;

    if (strcmp(argv[2], "keygen") == 0) {
        uint8_t cmd[] = {0x01, 0x00};
        write(fd, cmd, 2);
        n = read(fd, response, 1);
        printf("KEYGEN: %s\n", (n > 0 && response[0] == 0xAA) ? "Success" : "Failed");

    } else if (strcmp(argv[2], "encrypt") == 0 || strcmp(argv[2], "decrypt") == 0) {
        if (argc < 4) {
            printf("Error: provide 16-byte hex payload\n");
            return 1;
        }
        uint8_t cmd = (strcmp(argv[2], "encrypt") == 0) ? 0x02 : 0x03;
        uint8_t payload[16];
        for (int i = 0; i < 16; i++)
            sscanf(argv[3] + i*2, "%02hhx", &payload[i]);

        uint8_t packet[18] = {cmd, 0x10};
        memcpy(packet + 2, payload, 16);
        write(fd, packet, 18);

        n = read(fd, response, 17);
        if (n > 0 && response[0] == 0xAA) {
            printf("Result: ");
            for (int i = 1; i < 17; i++)
                printf("%02x", response[i]);
            printf("\n");
        } else {
            printf("Failed\n");
        }

    } else if (strcmp(argv[2], "lockout") == 0) {
        uint8_t cmd[] = {0x04, 0x00};
        write(fd, cmd, 2);
        n = read(fd, response, 1);
        printf("LOCKOUT: %s\n", (n > 0 && response[0] == 0xAA) ? "Success" : "Failed");
    }

    close(fd);
    return 0;
}
