# this is just a convenience sh script.
# Please if you are on Windows do this with a MySQL administration tool

mysql -u root -p <<SQL
drop database if exists gastosgem_development;
create database gastosgem_development character set utf8;
grant all on gastosgem_development.* to 'gastosgem'@'localhost' identified by 'gastosgem';
SQL