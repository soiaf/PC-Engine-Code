// converts 8/16 bit raw pcm file -> 5 bit file

// convertisseur fichier raw pcm 8/16 bits -> fichier 5 bits (chaque échantillon sur 1 octet)
// ne modifie pas la fréquence

#include <iostream.h>
#include <string.h>
#include <stdio.h>

int main(int nb_args, char** args)
{
	if(nb_args < 4)	// affiche help lorsque mauvais arguments
	{
		cout << "usage: " << endl
			<< args[0] << " -type fichier_entree fichier_sortie" << endl
			<< "\t-16\t fichier d'entree mono 16 bits" << endl
			<< "\t-8\t fichier d'entree mono 8 bits non signe" << endl;

		return 1;
	}

	bool type;	// comme il n'y a que 2 types possibles...
	if(!strcmp(args[1], "-16"))	// cas fichier 16 bits (signé)
	{
		type = true;
	}
	else if(!strcmp(args[1], "-8"))	// cas fichier 8 bits (non signé)
	{
		type = false;
	}
	else	// option non valide
	{
		cout << "erreur: option non valide" << endl;
		return 2;
	}

	// fichier entrée
	FILE* f = fopen(args[2], "rb");
	if(!f)
	{
		cout << "erreur: fichier entree" << endl;
		return 3;
	}

	// fichier sortie
	FILE* g = fopen(args[3], "wb");
	if(!g)
	{
		cout << "erreur: fichier sortie" << endl;
		return 4;
	}

	if(type)
	{
		// conversion depuis 16 bits
		short int tamp_in;
		unsigned char tamp_out;
		while(fread(&tamp_in, sizeof(tamp_in), 1, f))
		{
			tamp_out = (tamp_in + 32768) * 32 / 65536;
			fwrite(&tamp_out, sizeof(tamp_out), 1, g);
		}
	}
	else
	{
		// conversion depuis 8 bits
		unsigned char tamp;
		while(fread(&tamp, sizeof(tamp), 1, f))
		{
			tamp = tamp * 32 / 256;
			fwrite(&tamp, sizeof(tamp), 1, g);
		}
	}

	fclose(f);
	fclose(g);

	cout << "done" << endl;
	return 0;
}