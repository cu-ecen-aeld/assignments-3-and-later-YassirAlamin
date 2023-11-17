#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <syslog.h>

int main(int argc, char* argv[]){ 

int fds;

  openlog("writer",LOG_PID | LOG_CONS, LOG_USER);

  if(argc != 3){
    syslog(LOG_ERR,"Input prameter Error");
    return 1;
  }
  
  fds = open(argv[1],O_WRONLY | O_CREAT | O_TRUNC, 0644);
  int rn = write(fds,argv[2],strlen(argv[2]));
  if(rn != strlen(argv[2])){ 
     syslog(LOG_ERR,"write to file Error");
    return 1;
  }else{
    syslog(LOG_DEBUG,"Write %s to file %s",argv[2],argv[1]);
  }
  
  if(close(fds) != 0){ 
    syslog(LOG_ERR,"close file Error");
    return 1;
  }

  return 0;
}
