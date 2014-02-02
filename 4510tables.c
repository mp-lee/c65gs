#include <stdio.h>
#include <strings.h>
#include <string.h>
#include <stdlib.h>

char *opnames[256]={NULL};
char *modes[256]={NULL};

int main(int argc,char **argv)
{
  FILE *f=fopen("64net.opc","r");
  if (!f) {
    perror("Could not open 64net.opc");
    return -1;
  }
  int i;
  for(i=0;i<256;i++) {
    char line[1024];    
    int n;
    char opcode[1024];
    char mode[1024];
    
    line[0]=0; fgets(line,1024,f);
    int r=sscanf(line,"%02x   %s %s",&n,opcode,mode);
    if (n==i) {
      if (r==3) {
	opnames[i] = strdup(opcode);
	modes[i]=strdup(mode);
      } else if (r==2) {
	opnames[i] = strdup(opcode);
	modes[i]="";
      }
    }
  }

  printf("  type instruction is (\n    -- 4510 opcodes\n    ");
  int j,icount=0;
  for(i=0;i<256;i++) {
    int dup=0;
    for(j=0;j<i;j++) if (!strncasecmp(opnames[i],opnames[j],3)) dup=1;
    if (!dup) {
      if (icount>0) printf(",");
      if ((icount&7)==7) printf("\n    ");
      printf("I_%c%c%c",opnames[i][0],opnames[i][1],opnames[i][2]);
      icount++;
    }
  }
  printf(");\n\n");

  printf("  type ilut8bit is array(0 to 255) of instruction;\n");
  printf("  constant instruction_lut : ilut8bit := (\n    ");
  for(i=0;i<256;i++) {
    printf("I_%c%c%c",opnames[i][0],opnames[i][1],opnames[i][2]);
    if (i<255) printf(","); else printf(");\n");
    if ((i&15)==15) printf("\n    ");
  }

  printf("\n  type mlut8bit is array(0 to 255) of addressingmode;\n  constant mode_lut : mlut8bit := (\n    ");
  for(i=0;i<256;i++) {
    char mode[1024]="M_";
    int o=2;
    for(j=0;modes[i][j];j++) {
      switch(modes[i][j]) {
      case '(': mode[o++]='I'; break;
      case 'n': case 'r': case 'X': case 'Y': case 'Z': case 'S': case 'P':
	mode[o++]=modes[i][j]; break;
      }
    }
    mode[o]=0; if (o==2) strcpy(mode,"M_implied");
    printf("%s",mode);
    if (i<255) printf(","); else printf(");\n");
    if ((i&7)==7) printf("\n    ");
  }

}