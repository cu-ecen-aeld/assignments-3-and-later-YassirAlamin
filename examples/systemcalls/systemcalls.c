#include "systemcalls.h"
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
    int rn = system(cmd);
    if(rn == -1){
    	return false;
    }
    return true;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/
    printf("\r\n-----------------\r\n");fflush(stdout);
    for(int i=0;i<count;i++){
	    printf("cmd[%d]:%s\r\n",i,command[i]);fflush(stdout);
    }
    
    pid_t pid_1  = fork();
    
   if(pid_1 < 0){
   	perror("fork");
	exit(EXIT_FAILURE);
   }    
   if(pid_1 == 0){
    	int rn = execv(command[0],command);
	printf("\r\n[child]rn:%d\terrno:%d\tpid:%d\r\n",rn,errno,pid_1);fflush(stdout);
	perror("execv");fflush(stdout);
	exit(EXIT_FAILURE);	
    }else if(pid_1 > 0){
	int pstatus,ret;
        ret = waitpid(0,&pstatus,0);
	printf("\r\n[Parent]ret:%d\t errnno:%d\r\n",ret,errno);fflush(stdout);
	
	if(WIFEXITED(pstatus)){
	    if(WEXITSTATUS(pstatus)){
		printf("child exit with status:%d, ret:%d\r\n",WEXITSTATUS(pstatus),ret);
		return false;
	    }
	}
   }
       
    printf("\r\n###############\r\n");fflush(stdout);
    va_end(args);
    return true;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    
    printf("\r\n@@@@@@@@@@@\r\n");
    fflush(stdout);
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;
    // this line is to avoid a compile warning before your implementation is complete
    // and may be removed
    command[count] = command[count];


/*
 * TODO
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/

    pid_t pid = fork();
    int stat;

   int fds = open (outputfile,O_WRONLY, 0777);
   if(fds == -1){
       printf("\r\n Open file error");
   }
   dup2(fds,STDOUT_FILENO);
   close(fds);
    
    if(pid < 0){
   	perror("fork");
	exit(EXIT_FAILURE);
   }    
   if(pid == 0){
    	execv(command[0],command);
	exit(EXIT_FAILURE);	
    }else if(pid > 0){
        waitpid(pid,&stat,0);
	if(WIFEXITED(stat)){
	    if(WEXITSTATUS(stat)){
		return false;
	    }
	}
   }
    
    va_end(args);
    
    return true;
}
