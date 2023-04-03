#!python3

import sys,os,codecs,csv

def export_csv2strfile(csvpath, outputdir):
    with open(csvpath, mode='r') as csv_file:
        csv_reader = csv.reader(csv_file, delimiter=';')

        files = {}
        lang_codes = csv_reader.__next__()
        lang_names = csv_reader.__next__()
        id_col = lang_codes.index("id")

        for col in range(id_col + 1, len(lang_codes)):
            if lang_codes[col] in ['', 'id']:
                continue
            dirname = outputdir + '/' + lang_codes[col] + '.lproj'
            if not os.path.exists(dirname):
                os.makedirs(dirname)
            files[col] = codecs.open(dirname + '/Localizable.strings', 'a')
            files[col].write('/**\n * ' + lang_names[col] + ' localization.\n*/\n')

        for row in csv_reader:
            for col in range(id_col + 1, len(row)):
                if row[col] != '' and col in files:
                    files[col].write('\"' + row[id_col] + '\" = \"' + row[col].replace("%s","%@").replace('"', '\\"') + '\";\n')

        for file in files:
            files[file].close()

def main(argv):
    current_dir = os.path.realpath(os.path.dirname(__file__))
    os.system(f"find '{current_dir}' -name 'Localizable.strings' | xargs rm")
    export_csv2strfile(f'{current_dir}/strings.csv', f'{current_dir}/Generated')

if __name__ == '__main__':
    main(sys.argv[1:])
