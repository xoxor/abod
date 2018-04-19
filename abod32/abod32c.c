/**************************************************************************************
 *
 * CdL Magistrale in Ingegneria Informatica
 * Corso di Architetture e Programmazione dei Sistemi di Elaborazione - a.a. 2015/16
 *
 * Progetto di un algoritmo di Angle-Based Outlier Detection
 * in linguaggio assembly x86-32 + SSE
 *
 * Candidati: Beatrice Napolitano, Mirko Nardi
 *
 * Fabrizio Angiulli, 18 aprile 2016
 *
 **************************************************************************************/


#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <xmmintrin.h>


/*	Le funzioni sono state scritte assumento che le matrici siano memorizzate
 * 	mediante un array (float*) e che siano memorizzate per righe (row-major order).
 */


#define	MATRIX		float*
#define	VECTOR		float*  //vettore risultato
#define	DATASET		float*	//matrice dei dati (una volta caricati)


void* get_block(int size, int elements) {
	return _mm_malloc(elements*size,16);
}


void free_block(void* p) {
	_mm_free(p);
}


MATRIX alloc_matrix(int rows, int cols) {
	return (MATRIX) get_block(sizeof(float),rows*cols);
}

void dealloc_matrix(MATRIX mat) {
	free_block(mat);
}


DATASET load_input(char* filename, int *n, int *d) {
	FILE* fp;
	int rows, cols, status, i;
	char fpath[256];

	sprintf(fpath, "%s.dataset", filename);
	fp = fopen(fpath, "rb");

	if (fp == NULL) {
		printf("Bad dataset file name!\n");
		exit(0);
	}

	status = fread(&cols, sizeof(int), 1, fp);
	status = fread(&rows, sizeof(int), 1, fp);
	DATASET data = alloc_matrix(rows,cols);
	status = fread(data, sizeof(float), rows*cols, fp);
	fclose(fp);

	*n = rows;
	*d = cols;

	return data;
}


void save_output(char* filename, VECTOR abof, int n) {
	FILE* fp;
	int i;
	char fpath[256];

	sprintf(fpath, "%s_abof.txt", filename);
	fp = fopen(fpath, "w");
	for (i = 0; i < n; i++)
		fprintf(fp, "%f\n", abof[i]);
	fclose(fp);
}

//------INIZIO IMPLEMENTAZIONE


extern void prodmat_Dunrollaps(MATRIX B, int n, int d, MATRIX norms, float* abof) ;
extern void prodmat_Dunrollaps_lb(MATRIX B, int n, int d, MATRIX norms, float* abof, float r, float den) ;
extern void normdiff_aps(DATASET data, MATRIX diffs, VECTOR norms,  int a, int n, int d);
extern void distances(DATASET data, VECTOR norms,  int a, int n, int d);


/*	abod
 * 	====
 * 	Restituisce in abof gli outlier score degli oggetti in data.
 */
VECTOR abod(DATASET data, int n, int d, int k) {
	int q = d%4;
	if(q!=0){
		int dd = d+4-q;
		DATASET datao = alloc_matrix(n, dd);
		int i, j;
		for(i=0; i<n; i++){
			for(j=0; j<d; j++){
				datao[i*dd+j] = data[i*d+j]; 
			}
			for(j=d; j<dd; j++){
				datao[i*dd+j] = 0.0; 
			}
		}
		d=dd;
		data = datao;
	}
	VECTOR abof = alloc_matrix(n,1);
	MATRIX diffs = alloc_matrix(n-1,d);
	VECTOR norms = alloc_matrix(n-1,1);
	int a;
	for(a=0; a<n; a++){
		//printf("%d\n", a);
		normdiff_aps(data,diffs,norms,a,n,d);
		prodmat_Dunrollaps(diffs, n-1, d, norms, &abof[a]);
	}
	return abof;
}

void exchange(VECTOR v, int a, int b){
	float temp;
	temp = v[a];
	v[a] = v[b];
	v[b] = temp;
}

int partion(VECTOR ind, VECTOR dist, int start, int end) {
	int pivot = start;
	while (start <= end) {
		while (start <= end && dist[start] <= dist[pivot])
			start++;
		while (start <= end && dist[end] > dist[pivot])
			end--;
		if (start > end)
			break;
		exchange(dist,start,end);
		exchange(ind,start,end);
	}
	exchange(dist,end,pivot);
	exchange(ind,end,pivot);
	return end;
}

float quickselect(VECTOR ind, VECTOR dist, int n, int k) {
	int start = 0;
	int end = n-1;
	int index = k - 1;
	while (start < end) {
		int pivot = partion(ind, dist, start, end);
		if (pivot < index)
			start = pivot + 1;
		else if (pivot > index)
			end = pivot - 1;
		else
			return dist[pivot];
	}
	return dist[start];
}

void quicksort(VECTOR ind, VECTOR dist, int start, int end) {
	int pivot;
	if (start < end) {
		pivot = partion(ind, dist, start, end);
		quicksort(ind, dist, start, pivot-1);
		quicksort(ind, dist, pivot+1, end);
	}
}

void createIndex(VECTOR index, int n){
	int i;
	for(i=0;i<n;i++){
		index[i]=i;
	}
}

void copyk(DATASET data, DATASET datak, VECTOR index, int a, int k, int d){
	int p,i,ind;
	for(i=0; i<d; i++){
		datak[i] = data[a*d+i];
	}
	for(p=0; p<k; p++){
		ind = index[p];
		if(ind>=a)
			ind++;
		for(i=0; i<d; i++){
			datak[(1+p)*d+i] = data[ind*d+i];
		}
	}
}

VECTOR fabod(DATASET data, int n, int d, int k) {
	int q = d%4;
	if(q!=0){
		int dd = d+4-q;
		DATASET datao = alloc_matrix(n, dd);
		int i, j;
		for(i=0; i<n; i++){
			for(j=0; j<d; j++){
				datao[i*dd+j] = data[i*d+j]; 
			}
			for(j=d; j<dd; j++){
				datao[i*dd+j] = 0.0; 
			}
		}
		d=dd;
		data = datao;
	}
	
	VECTOR abof = alloc_matrix(n,1);

	MATRIX diffs = alloc_matrix(k,d);
	VECTOR norms = alloc_matrix(k,1);

	VECTOR dists = alloc_matrix(n-1,1);
	VECTOR index = alloc_matrix(n-1,1);
	DATASET datak = alloc_matrix(k+1,d);

	int a;
	for(a=0; a<n; a++){
		//printf("%d\n", a);
		distances(data,dists,a,n,d);
		createIndex(index, n-1);
		quickselect(index,dists,n-1,k);
		copyk(data, datak, index, a, k, d);
		normdiff_aps(datak, diffs, norms, 0, k+1, d);
		prodmat_Dunrollaps(diffs, k, d, norms, &abof[a]);		
	}
	return abof;
}


void calcr2 (VECTOR dist, int n, VECTOR norms, int k, float *r2, float *den){
	int i;
	float s1=0,s2=0,s3=0,s4=0;
	for(i=0; i<n; i++){
		s1+= 1.0/dist[i];
		s2+= 1.0/dist[i]*1.0/dist[i];
	}	
	s3= s1*s1-s2;

	s1=0;
	s2=0;
	for(i=0; i<k; i++){
		s1+= 1.0/norms[i];
		s2+= 1.0/norms[i]*1.0/norms[i];
	}
	s4= s1*s1-s2;

	*den= s3;
	*r2= s3-s4;

}

int max(VECTOR v, int n){
	int i;
	int max = 0;
	for(int i=1; i<n; i++){
		if(v[i]>v[max]){
			max = i;
		}
	}
	return i;
}

VECTOR lbabod(DATASET data, int n, int d, int k) {
	int i, j;
	int l=20;
	int q = d%4;
	if(q!=0){
		int dd = d+4-q;
		DATASET datao = alloc_matrix(n, dd);
		for(i=0; i<n; i++){
			for(j=0; j<d; j++){
				datao[i*dd+j] = data[i*d+j]; 
			}
			for(j=d; j<dd; j++){
				datao[i*dd+j] = 0.0; 
			}
		}
		d=dd;
		data = datao;
	}
	
	VECTOR abof = alloc_matrix(l,1);
	VECTOR labof = alloc_matrix(n,1);

	MATRIX diffs = alloc_matrix(k,d);
	VECTOR norms = alloc_matrix(k,1);

	VECTOR dists = alloc_matrix(n-1,1);
	VECTOR index = alloc_matrix(n-1,1);
	DATASET datak = alloc_matrix(k+1,d);

	int a;
	for(a=0; a<n; a++){
		//printf("%d\n", a);
		distances(data,dists,a,n,d);
		createIndex(index, n-1);
		quickselect(index,dists,n-1,k);
		copyk(data, datak, index, a, k, d);
		normdiff_aps(datak, diffs, norms, 0, k+1, d);

		float den=0.0;
		float r2 =0.0;
		calcr2(dists, n-1, norms, k, &r2, &den);
		prodmat_Dunrollaps_lb(diffs, k, d, norms, &labof[a], r2, den);
	}
	
	createIndex(index, n);
	quicksort(index,labof,0,n-1);
	diffs = alloc_matrix(n-1,d);
	norms = alloc_matrix(n-1,1);
	int imax = 0;
	for(i=0; i<l; i++){
		a=index[i];
		//printf("%d\n", a);
		normdiff_aps(data,diffs,norms,a,n,d);
		prodmat_Dunrollaps(diffs, n-1, d, norms, &abof[i]);
		if(abof[imax]<abof[i]){
			imax = i;
		}
	}
	float ab;
	int ll=l;
	do{
		ll++;
		a=index[ll];
		normdiff_aps(data,diffs,norms,a,n,d);
		prodmat_Dunrollaps(diffs, n-1, d, norms, &ab);
		if(ab<abof[imax]){
			abof[imax] = ab;
			imax = max(abof, l);
		}
	}while(abof[ll+1]<abof[imax]);
	return abof;
}


#define ABOD		0
#define FASTABOD	1
#define	LBABOD		2

char* method_name[3] = {"ABOD",
	"FastABOD",
	"LB-ABOD"};

VECTOR run_abod(DATASET data, int n, int d, int k, int method) {

	switch (method) {
		case ABOD:	
			return abod(data, n, d, 0); 
		case FASTABOD:	
			return fabod(data, n, d, k);
		case LBABOD:	
			return lbabod(data, n, d, k);
		default:	
			printf("Bad method specification!");
			exit(1);
	}
}


int main(int argc, char** argv) {
	DATASET data;
	int n = 10;		// numero di oggetti del dataset
	int d = 2;		// numero di dimensioni di ogni oggetto
	int k = 5;		// numero di vicini da considerare (FastABOD)
	int method = 0;

	char* filename = "";
	int silent = 0, display = 0;
	int i, j;

	int par = 1;
	while (par < argc) {
		if (par == 1) {
			filename = argv[par];
			par++;
		} else if (strcmp(argv[par],"-s") == 0) {
			silent = 1;
			par++;
		} else if (strcmp(argv[par],"-d") == 0) {
			display = 1;
			par++;
		} else if (strcmp(argv[par],"-k") == 0) {
			par++;
			if (par >= argc) {
				printf("Missing k value!\n");
				exit(1);
			}
			k = atoi(argv[par]);
			par++;
		} else if (strcmp(argv[par],"-abod") == 0) {
			method = ABOD;
			par++;
		} else if (strcmp(argv[par],"-fastabod") == 0) {
			method = FASTABOD;
			par++;
		} else if (strcmp(argv[par],"-lbabod") == 0) {
			method = LBABOD;
			par++;
		} else
			par++;
	}

	if (!silent) {
		printf("Usage: %s <file_name> [-d][-s][-k <k_value>]\n", argv[0]);
		printf("\nParameters:\n");
		printf("\t-d : display input and output\n");
		printf("\t-s : silent\n");
		printf("\t-k <k_value> : number of nearest neighbors for FastABOD\n");
		printf("\t-<method>, where <method> can be:\n");
		printf("\t\tabod (for ABOD; default)\n");
		printf("\t\tfastabod (for FastABOD)\n");
		printf("\t\tlbabod (for LB-ABOD)\n");
		printf("\n");
	}

	if (strlen(filename) == 0) {
		printf("Missing dataset file name!\n");
		exit(1);
	}

	data = load_input(filename, &n, &d);

	if (!silent && display) {
		printf("\nInput dataset:\n");
		for (i = 0; i < n*d; i++) {
			if (i % d == 0)
				printf("\n");
			printf("%f ", data[i]);
		}
		printf("\n\n");
	}

	if (!silent) {
		if (method != FASTABOD)
			printf("Executing %s: n=%d examples, d=%d attributes...\n", method_name[method], n, d);
		else
			printf("Executing %s: n=%d examples, d=%d attributes, k=%d neighbors...\n", method_name[method], n, d, k);
	}

	clock_t t = clock();
	VECTOR abof = run_abod(data, n, d, k, method);
	t = clock() - t;

	if (!silent)
		printf("\nExecution time = %.3f seconds\n", ((float)t)/CLOCKS_PER_SEC);
	else
		printf("%.3f\n", ((float)t)/CLOCKS_PER_SEC);

	if (!silent && display) {
		printf("\nABOF scores:\n");
		for (i = 0; i < n; i++) {
			printf("object#%d = %f\n", i, abof[i]);
		}
	}

	save_output(filename,abof,n);

	return 0;
}




















