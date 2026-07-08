import numpy as np
import pandas as pd
import pysam 
import os
import sys
import argparse
import logging

def vcf_reform(data, reference_dir):
    new_data = []
    for i in range(1,23):
        logging.info(f'Обработка chr{i}')
        try:
            data_chr = data[data['CHROM'] == f'chr{i}']
            dict_chr = {ids: [pos, a1, a2] for ids, pos, a1, a2 in zip(data_chr['ID'], data_chr['POS'], data_chr['allele1'], data_chr['allele2'])}

            with pysam.Fastafile(f'{reference_dir}/chr{i}.fa') as reference_fa:
                for ids in dict_chr:
                    pos = dict_chr[ids][0] - 1
                    allele1 = dict_chr[ids][1]
                    allele2 = dict_chr[ids][2]
                    nuc = reference_fa.fetch(reference=f'chr{i}', start=pos, end=pos+1).upper()
                    if nuc == allele1:
                        ref_allele = allele1
                        alt_allele = allele2
                    elif nuc == allele2:
                        ref_allele = allele2
                        alt_allele = allele1     
                    else:
                        ref_allele = nuc
                        alt_allele = allele1 + ',' + allele2
                    new_snp = {'CHROM' : f'chr{i}',
                               'POS' : pos + 1,
                               'ID' : ids,
                               'REF': ref_allele,
                               'ALT' : alt_allele}
                    new_data.append(new_snp)
        except Exception as e:
            logging.error(f'Ошибка при обработке chr{i}: {e}')
            continue
    output_data = pd.DataFrame(new_data)
    return output_data

def main():
    """Основная функция скрипта."""
    logging.basicConfig(level=logging.INFO, format="[%(asctime)s] %(message)s", 
    handlers=[logging.StreamHandler(sys.stdout), logging.FileHandler("/python_script/data/reformat.log", mode="w", encoding="utf-8")])

    parser = argparse.ArgumentParser(prog='Python скрипт для тестового задания', description='Преобразование файла с SNP из allele1-allele2 в REF-ALT',)
    parser.add_argument('-i', '--input', required=True, type=str, help='Путь к входному файлу')
    parser.add_argument('-o', '--output', required=True, type=str, help='Путь для сохранения выходного файла')
    parser.add_argument('-r','--ref_dir', required=False, default="/python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/", type=str, help='Путь к директории с хромосомами референса  в формате chr[1-22].fa c с индексами chr[1-22].fai (по умолчанию: "/python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/")')
    args = parser.parse_args()
    
    for i in range(1,23):
        if not os.path.isfile(f'{args.ref_dir}/chr{i}.fa') or not os.path.isfile(f'{args.ref_dir}/chr{i}.fa.fai'):
            logging.error(f'Отсутствует референсный файл/индекс chr{i}')
            sys.exit(1)
    
    if not os.path.isfile(args.input):
        logging.error('Отсутствует входной файл')
        sys.exit(1)
    
    data = pd.read_csv(args.input, delimiter='\t')
    if list(data.columns) != ['CHROM','POS', 'ID', 'allele1', 'allele2']:
        logging.error('Неверные названия колонок входного файла ("CHROM", "POS", "ID", "allele1", "allele2")')
        sys.exit(1)
    elif not (data['POS'].apply(type) == int).all():
        logging.error('Значения координат GRCh38 не числовые')
        sys.exit(1)
    elif not data['CHROM'].isin([f'chr{i}' for i in range(1, 23)]).all():
        logging.error('Неправильный формат названий хромосом (chr[1-22])')
        sys.exit(1)
    elif not data['allele1'].isin(['A', 'T', 'G', 'C']).all() or not data['allele2'].isin(['A', 'T', 'G', 'C']).all():
        logging.error('Неправильный формат SNP (A,T,G,C)')
        sys.exit(1)        
    else: 
        logging.info("Файл корректный. Запуск обработки")
        output_data = vcf_reform(data, args.ref_dir)
    
    if not output_data.empty:
        logging.info(f"Сохранение результатов в файл: {args.output}")
        output_data.to_csv(args.output, sep = '\t', index=False)
        os.chmod(args.output, 0o666)
        logging.info("Работа скрипта успешно завершена.")

if __name__ == "__main__":
    main()
    