#include "../libc.h"
#include "util.h"

int *board;
int **stack;
char **reaches;
int dir[3];
int num;
int size;
static const int size3 = 64;

void show_board() {
    int i, j;
    for (i = 0; i < size; i++) {
        for (j = 0; j < size; j++) {
            print_int(board[i*size+j]);
            print_str(" ");
            //printf("%d ", board[i*size+j]);
        }
        puts("");
    }
}

int search4(int d, int *p){
    int s = 0;
    int *n = p + num;
    int *q = p + num/2;
    int even = num&1 == 0;
    int *first = q;
    while (1) {
        if(!*q){
            if(d==1){
                s++;
                if (even || !*first) s++;
            }
            else{
                char **rp = reaches + ((q-board)<<6);
                while (*rp) ++**rp++;
                *stack++=q;
                d--;
                q=n+1;
                n+=size;
            }
        }
        q++;
        while (q == n) {
            char **rp;
            if(d==num) {
                return s;
            }
            n-=size;
            d++;
            q=*--stack;
            rp = reaches + ((q-board)<<6);
            while (*rp) --**rp++;
            q++;
        }
    }
}

int main(int argc, char* argv[]){
    int i,j,k;
    //if(argc==1)return 1;
    //num = atoi(argv[1]);
    num = 7;
    size = num+2;
    board = (int*)malloc(sizeof(int)*size*size);
    stack = (int**)malloc(sizeof(int*)*size);
    reaches = (char**)malloc(size*size*size3);
    dir[0]=size-1;
    dir[1]=size;
    dir[2]=size+1;
    for(i=0; i<size; i++){
        board[i]=-1;
        board[i*size]=-1;
        board[size*(size-1)+i]=-1;
        board[size-1+i*size]=-1;
    }
    int *p = board + size + 1;
    for(i=0; i<num-1; i++){
        for(j=0; j<num; j++){
            int **rp = reaches + size3*(p-board);
            if (i == 0 && j == num/2 && num&1 == 1) {
                *rp = p;
                rp++;
            }
            for(k=3; k--; ) {
                int d = dir[k];
                int *q = p + d;
                while (*q != -1) {
                    *rp = q;
                    rp++;
                    q += d;
                }
            }
            *rp = 0;
            p++;
        }
        p += 2;
    }
    print_int(search4(num,&board[size+1]));
    print_str("\n");
    //printf("%d\n",search4(num,&board[size+1]));
    return 0;
}
