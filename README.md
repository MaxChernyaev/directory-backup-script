### Скрипт делал по следующему заданию:  
Bash. Скрипт резервного копирования.  
Предположим у вас есть мега важные файлы сайта. Их необходимо резервировать в определенный промежуток времени.
Для выполнения задания понадобится виртуальная машина с ОС на базе ядра линукс.
На первом этапе необходимо сделать простой скрипт резервного копирования директории. Файлы должны быть упакованы в архив и сложены в заранее оговоренную директорию.
1) Необходимо получить из stdin путь до места хранения (пока это будет локальное хранение).
2) Необходимо проверить установлен ли архиватор, которым будем сжимать файлы.
3) Название файла бэкапа должно содержать дату, время бэкапа и название директории.
4) При команде ls файлы архива должны выводиться по порядку создания бэкапа.
5) Скрипт должен уметь делать дневные, недельные, месячные и годовой бэкап и раскладывать их по директориям с соответствующим названием. Годовой 31 декабря. Месячный делается 1 числа каждого месяца, недельный в воскресенье, все остальные считаются дневными.
6) Скрипт должен очищать директории по следующему правилу: храним 6 дневных, 4 недельных и 3 месячных и 1 годовую копию.
7) Сделать 2 функции: одна создает бэкап, вторая очищает.
