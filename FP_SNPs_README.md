# Python скрипт - Задача 3

Скрипт reformat_script.py для преобразования файла с SNP из формата allele1-allele2 в REF-ALT с использованием в качестве референса геном человека GRCh38.
## Параметры

* **`-i`, `--input`** - Путь к входному файлу
* **`-o`, `--output`** - Путь для сохранения выходного файла
* **`-r`, `--ref_dir`** - Путь к директории с хромосомами референса в формате `chr[1-22].fa` с индексами `chr[1-22].fa.fai` (по умолчанию: `/python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/`)
* **`-h`, `--help`** - Описание флагов.

## Команда для запуска в docker контейнере

Папка с референсом должна содержать fasta файлы chr[1-22] в формате .fa и индексы chr[1-22].fa.fai.

```bash
docker run \
  -v путь-к-папке-с-референсом:/python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/ \
  -v путь-к-папке-с-SNP-файлом:/python_script/data/ \
  test_csp \
  python3 reformat_script.py \
  --input /python_script/data/имя-входного-файла \
  --output /python_script/data/имя-выходного-файла \
  --ref_dir /python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/
```

Пример:

```bash
docker run \
  -v /mnt/data/ref/GRCh38.d1.vd1_mainChr/sepChrs/:/python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/ \
  -v "$(pwd)":/python_script/data/ \
  test_csp \
  python3 reformat_script.py \
  --input /python_script/data/FP_SNPs_10k_GB38_twoAllelsFormat.tsv \
  --output /python_script/data/output_SNP.tsv \
  --ref_dir /python_script/ref/GRCh38.d1.vd1_mainChr/sepChrs/
```

## Предподготовка входного файла.

Содержится в preprocessing.ipynb. 

```python
data = pd.read_csv('graf_2.4/data/FP_SNPs.txt', delimiter='\t')
#Удаляем столбец с координатами по GRCh37
data = data[['chromosome','GB38_position', 'rs#', 'allele1', 'allele2']]
#Переименовываем и поменяли колонки местами
data.columns = ['CHROM','POS', 'ID', 'allele1', 'allele2']
#Добавляем префиксы chr и rs
data['CHROM'] = data['CHROM'].apply(lambda x: 'chr' + str(x))
data['ID'] = data['ID'].apply(lambda x: 'rs' + str(x))
#Удаляем варианты с X-хромосомы
data = data[data['CHROM'] != 'chr23']
#Сохранение
data.to_csv('FP_SNPs_10k_GB38_twoAllelsFormat.tsv', sep='\t', index=False)
```

## Предподготовка референса.

```bash
#Распаковываем в новую папку и индексируем
mkdir -p GRCh38
tar -xzf GRCh38.d1.vd1.fa.tar.gz -C GRCh38/
samtools faidx GRCh38/GRCh38.d1.vd1.fa
#Извлекаем хромосомы 1-22 и индексируем
for chr in chr{1..22} chrX chrY chrM; do 
samtools faidx GRCh38/GRCh38.d1.vd1.fa "$chr" > "GRCh38/${chr}.fa"; 
samtools faidx "GRCh38/${chr}.fa"; 
done
```
## Результаты работы скрипта и описание итогового файла

В ходе работы скрипта была проведена проверка 10 000 вариантов (соответствующих аутосомам с 1 по 22 хромосому) из исходных 11 000 позиций файла `FP_SNPs.txt`. Процесс восстановления референсных аллелей осуществлялся по геному сборки GRCh38.d1.vd1 с использованием библиотеки `pysam`. Все 10 000 вариантов были успешно отформатированы. Для каждого из этих SNP было подтверждено точное совпадение одного из зарегистрированных аллелей с референсным основанием генома.

Итоговый файл представляет собой текстовый табличный файл с разделителями-табуляциями (TSV), совместимый по своей логике со стандартом VCF.

`CHROM`\t`POS`\t`ID`\t`REF`\t`ALT`

`CHROM` - Имя хромосомы с префиксом `chr`

`POS` - Позиция SNP в геноме GRCh38 (1-based)

`ID` - Идентификатор SNP с префиксом

`REF` - Референсный аллель

`ALT` - Альтернативный аллель

