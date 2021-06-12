// This reads in a PCM file, determines the lowest point and highest point and if
// the difference maps to a 5-bit PCM file then it converts the file to a 5-bit raw PCM
// file suitable for playback on the PC Engine

#include <iostream>
#include <string.h>
#include <stdio.h>

using namespace std;

int main(int nb_args, char** args)
{
	if(nb_args < 3)
	{
		cout << "usage: " << endl
			<< args[0] << "  source_file output_file" << endl;
		return 1;
	}

	FILE* f = fopen(args[1], "rb");
	if(!f)
	{
		cout << "error: source file" << endl;
		return 2;
	}

	// fichier sortie
	FILE* g = fopen(args[2], "wb");
	if(!g)
	{
		cout << "error: output file" << endl;
		return 3;
	}

	unsigned char min,max;
	
	min =255;
	max = 0;

	unsigned char tmp;
	while(fread(&tmp, sizeof(tmp), 1, f))
	{
		if(tmp<min)
			min=tmp;
			
		if(tmp>max)
			max=tmp;
			
	}
	
	if(max-min>32)
	{
		cout << "error: cannot remap values, range too large" << endl;
		cout << "min: " << +min <<endl;
		cout << "max: " << +max <<endl;
		return 3;		
	}
	
	// reset input file
	fclose(f);
	f = fopen(args[1], "rb");
	if(!f)
	{
		cout << "error: source file" << endl;
		return 2;
	}	
	
	
	unsigned char tamp;
	while(fread(&tamp, sizeof(tamp), 1, f))
	{
		tamp = tamp - min;
		fwrite(&tamp, sizeof(tamp), 1, g);
	}

	fclose(f);
	fclose(g);

	cout << "done" << endl;
	return 0;
}
