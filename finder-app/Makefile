TARGET = writer

ifdef CROSS_COMPILER
	CC = $(CROSS_COMPILER)gcc
TARGET := $(TARGET)-cross
	DEBUG_INFO =  cross using $(CROSS_COMPILER)
else
	CC = gcc
	DEBUG_INFO = Native
endif

all: $(TARGET)
	@echo "$(DEBUG_INFO)"
	file $(TARGET) | tee ../assignments/assignment2/fileresult.txt

$(TARGET): writer.o
	$(CC)  writer.o -o $(TARGET)

writer.o: writer.c
	$(CC) -c writer.c


clean:
	rm *.o $(TARGET) $(TARGET)-cross

