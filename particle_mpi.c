#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <mpi.h>

#define DEFAULT_PARTICLE_PER_PROC 500
#define UPDATES 300
#define DT 0.02

const int Width = 20;
const int Height = 20;
const int Depth = 20;

static size_t particle_per_proc;
static int rank;
static int size;

const double Wall_Stiffness = 50.0;

double *px, *py, *pz;
double *vx, *vy, *vz;
double *ax, *ay, *az;
double * global_px, * global_py, * global_pz;

inline double update_position(double p, double v, double a);
inline double update_velocity(double v, double a);
void update_acceleration();
void allocate(int);

int main(int argc, char* argv[]){

	size_t i, r;

	MPI_Init(&argc, &argv);

	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	if (argc > 1)
		particle_per_proc = atoi(argv[1]);
	else
		particle_per_proc = DEFAULT_PARTICLE_PER_PROC;

	allocate(particle_per_proc);

	for (i=0; i < particle_per_proc; i++){
		px[i] = (double)(i % Width);
		py[i] = (double)((i / Width) % Height);
		pz[i] = (double)((i / Width / Height) % Depth);
	}

	for (r = 0; r < UPDATES; r++) {
		for (i=0; i < particle_per_proc; i++){
			px[i] = update_position(px[i], vx[i], ax[i]);
			py[i] = update_position(py[i], vy[i], ay[i]);
			pz[i] = update_position(pz[i], vz[i], az[i]);

			vx[i] = update_velocity(vx[i], ax[i]);
			vy[i] = update_velocity(vy[i], ay[i]);
			vz[i] = update_velocity(vz[i], az[i]);

		}

		MPI_Allgather(px, particle_per_proc, MPI_DOUBLE,
				global_px, particle_per_proc,
				MPI_DOUBLE, MPI_COMM_WORLD);
		MPI_Allgather(py, particle_per_proc, MPI_DOUBLE,
				global_py, particle_per_proc,
				MPI_DOUBLE, MPI_COMM_WORLD);
		MPI_Allgather(pz, particle_per_proc, MPI_DOUBLE,
				global_pz, particle_per_proc,
				MPI_DOUBLE, MPI_COMM_WORLD);

		update_acceleration();

		for (i=0; i < particle_per_proc; i++){
			vx[i] = update_velocity(vx[i], ax[i]);
			vy[i] = update_velocity(vy[i], ay[i]);
			vz[i] = update_velocity(vz[i], az[i]);
		}
	}

	MPI_Gather(px, particle_per_proc, MPI_DOUBLE, global_px,
			particle_per_proc, MPI_DOUBLE, 0,
			MPI_COMM_WORLD);

	if (rank == 0){
		for (i=0; i < particle_per_proc; i++){
			printf("%g\t%g\n",px[i],py[i]);//,pz[i]);
		}
	}

	MPI_Finalize();

	return EXIT_SUCCESS;
}

inline double update_position(double p, double v, double a){
	return p + DT * v + (0.5 * DT * DT * a);
}

inline double update_velocity(double v, double a){
	return v + DT * a * 0.5;
}

void update_acceleration(){
	size_t i, j;

	for (i=0; i<particle_per_proc; i++){
		if (px[i] < 0.5) {
			ax[i] = Wall_Stiffness * (0.5 - px[i]);
		} else if (px[i] > (Width - 0.5)) {
			ax[i] = Wall_Stiffness * (Width - 0.5 - px[i]);
		} else {
			ax[i] = 0.0;
		}

		if (py[i] < 0.5) {
			ay[i] = Wall_Stiffness * (0.5 - py[i]);
		} else if (py[i] > (Height - 0.5)) {
			ay[i] = Wall_Stiffness * (Height - 0.5 - py[i]);
		} else {
			ay[i] = 0.0;
		}

		if (pz[i] < 0.5) {
			az[i] = Wall_Stiffness * (0.5 - pz[i]);
		} else if (pz[i] > (Depth - 0.5)) {
			az[i] = Wall_Stiffness * (Depth - 0.5 - pz[i]);
		} else {
			az[i] = 0.0;
		}

		for (j=0; j<particle_per_proc; j++){
			const double rx = px[i] - px[j];
			const double ry = py[i] - py[j];
			const double rz = pz[i] - pz[j];

			const double rsquared = rx * rx + ry * ry + rz * rz;

			if (rsquared > 1.0) {
				const double inv_r_squared = 1.0 / rsquared;
				double attract, repel, F;
				attract = inv_r_squared * inv_r_squared * inv_r_squared;
				repel = attract * attract;
				F = 24.0 * ((2.0 * repel) - attract) * inv_r_squared;
				ax[i] += F * rx;
				ay[i] += F * ry;
				az[i] += F * rz;
			}
		}

	}
}

void allocate(int len){
	px = (double*)malloc(len * sizeof(double));
	py = (double*)malloc(len * sizeof(double));
	pz = (double*)malloc(len * sizeof(double));

	vx = (double*)calloc(len , sizeof(double));
	vy = (double*)calloc(len , sizeof(double));
	vz = (double*)calloc(len , sizeof(double));

	ax = (double*)calloc(len , sizeof(double));
	ay = (double*)calloc(len , sizeof(double));
	az = (double*)calloc(len , sizeof(double));

	global_px = (double*)malloc(particle_per_proc * size * sizeof(double));
	global_py = (double*)malloc(particle_per_proc * size * sizeof(double));
	global_pz = (double*)malloc(particle_per_proc * size * sizeof(double));
}
