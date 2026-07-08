# Docker Image - Задача 2

Docker-образ содержит samtools-1.23.1 + htslib-1.23.1 + libdeflate-1.25, bcftools-1.23.1, vcftools-0.1.17.

## Инструкция по сборке

Команда для сборки Docker-образа:
```bash
docker build -t test_csp .

```
(В папке должен лежать reformat_script.py)

## Инструкция по запуску в интерактивном режиме

Команда для запуска в интерактивном режиме:

```bash
docker run -it test_csp
```