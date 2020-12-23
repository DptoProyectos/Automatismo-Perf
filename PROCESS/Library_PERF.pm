package Library_PERF;
 
use strict;
use Redis;
#use Email::Send;
#use Email::Send::Gmail;
#use Email::Simple::Creator;
use DBI;

 
BEGIN {
  use Exporter ();
  use vars qw|$VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS|;
 
 # $VERSION  = '1.00';  
   
  @ISA = qw|Exporter|;
 
  @EXPORT = qw|&update_PARAM read_PARAM dlg_performance|; 
 
  @EXPORT_OK = qw(); 
 
  %EXPORT_TAGS = ( ); 
 }

	# version 1.4.6	30-07-2020 

	# -------------------CONTROL DE VERSIONES---------------------------
	#
	#	1.4.3	27-08-2019
	#   Se implementaron las funciones BD_connect, read_MySQL, update_PARAM y write_MySQL
	
	#	1.4.3	18-09-2019
	#	Se implemento la funcion read_PARAM
	#
	#
	#-------------------------------------------------------------------



	




sub update_PARAM	
{
	# ACTUALIZA EL VALOR DE CONFIGURACION DE UN PARAMETRO
	# CALL:
	#	ubdate_PARAM($DLGID,$TIPO_CONFIG,$PARAM,$VALUE);
	
	# VARIABLES DE ENTRADA
		my $DLGID = $_[0];
		my $TIPO_CONFIG = $_[1];
		my $PARAM = $_[2];
		my $VALUE = $_[3];
		#
	## IMPRIMO VARIAVLES DE ENTRADA	
	#	print "\$DLGID = $DLGID\n";
	#	print "\$TIPO_CONFIG = $TIPO_CONFIG\n";
	#	print "\$PARAM = $PARAM\n";
	#	print "\$VALUE = $VALUE	\n";
		
	# OBTENGO LAS unidades_id
		my $query = 'SELECT id FROM spx_unidades WHERE dlgid = '."'".$DLGID."'";
		my $unidades_id = read_MySQL($query);
		#print "\$unidades_id = $unidades_id\n";
		#
	# OBTENGO LAS tipo_configuracion_id
		my $query = 'SELECT id FROM spx_tipo_configuracion WHERE tipo_configuracion = '."'".$TIPO_CONFIG."'";
		my $tipo_configuracion_id = read_MySQL($query);
		#print "\$tipo_configuracion_id = $tipo_configuracion_id\n";
		#
	# OBTENGO LAS unidades_configuracion_id
		my $query = "SELECT id FROM spx_unidades_configuracion WHERE dlgid_id = $unidades_id AND tipo_configuracion_id = $tipo_configuracion_id";
		my $unidades_configuracion_id = read_MySQL($query);
		#print "\$unidades_configuracion_id = $unidades_configuracion_id\n";
		#
	# LEO EL VALOR DEL PREVIO DEL PARAMETRO QUE SE QUIERE CAMBIAR 
		my $query = 'SELECT value FROM spx_configuracion_parametros WHERE parametro = '."'".$PARAM."'"." AND configuracion_id = $unidades_configuracion_id";
		my $out = read_MySQL($query);
		#print "LAST $PARAM = $out\n";
		#
	# ACTUALIZO EL VALOR DEL PARAMETRO QUE SE QUIERE CAMBIAR 
		my $query = "UPDATE spx_configuracion_parametros SET value = $VALUE WHERE parametro = "."'".$PARAM."'"." AND configuracion_id = $unidades_configuracion_id";
		my $out = write_MySQL($query);
		#print "WRITE $PARAM = $VALUE\n";
		#
	# LEO EL VALOR PARA CHEQUEAR QUE SE HIZO LA ACTUALIZACION DEL PARAMETRO QUE SE QUIERE CAMBIAR 	
		my $query = 'SELECT value FROM spx_configuracion_parametros WHERE parametro = '."'".$PARAM."'"." AND configuracion_id = $unidades_configuracion_id";
		my $out = read_MySQL($query);
		#print "CURRENT $PARAM = $out\n";
}

sub read_PARAM	
{
	# ACTUALIZA EL VALOR DE CONFIGURACION DE UN PARAMETRO
	# CALL:
	#	read_PARAM($DLGID,$TIPO_CONFIG,$PARAM);
	
	# VARIABLES DE ENTRADA
		my $DLGID = $_[0];
		my $TIPO_CONFIG = $_[1];
		my $PARAM = $_[2];
		#
	# IMPRIMO VARIAVLES DE ENTRADA	
		#print "\$DLGID = $DLGID\n";
		#print "\$TIPO_CONFIG = $TIPO_CONFIG\n";
		#print "\$PARAM = $PARAM\n";
		#
	# OBTENGO LAS unidades_id
		my $query = 'SELECT id FROM spx_unidades WHERE dlgid = '."'".$DLGID."'";
		my $unidades_id = read_MySQL($query);
		#print "\$unidades_id = $unidades_id\n";
		#
	# OBTENGO LAS tipo_configuracion_id
		my $query = 'SELECT id FROM spx_tipo_configuracion WHERE tipo_configuracion = '."'".$TIPO_CONFIG."'";
		my $tipo_configuracion_id = read_MySQL($query);
		#print "\$tipo_configuracion_id = $tipo_configuracion_id\n";
		#
	# OBTENGO LAS unidades_configuracion_id
		my $query = "SELECT id FROM spx_unidades_configuracion WHERE dlgid_id = $unidades_id AND tipo_configuracion_id = $tipo_configuracion_id";
		my $unidades_configuracion_id = read_MySQL($query);
		#print "\$unidades_configuracion_id = $unidades_configuracion_id\n";
		#
	# LEO EL VALOR DEL PREVIO DEL PARAMETRO QUE SE QUIERE CAMBIAR 
		my $query = 'SELECT value FROM spx_configuracion_parametros WHERE parametro = '."'".$PARAM."'"." AND configuracion_id = $unidades_configuracion_id";
		my $out = read_MySQL($query);
		#print "LAST $PARAM = $out\n";
		#
	# RETORNO LA VARIABLE DE SALIDA
		return $out;
}

sub read_MySQL
{
	# EJECUTA UNA CONSULTA Y DEVUELVE EL VALOR DEL PRIMER RESULTADO
		my $select_query = $_[0];
		#
	# ME CONECTO A LA BASE DE DATOS
		my $DBH = BD_connect();
		#
	# EJECUTO OPERACIONES CON EL query
		#print "\$select_query = $select_query\n";
		my $sth0 = $DBH->prepare ($select_query);
		#print 'sth0 = '."$sth0"."\n";
		my $rows = $sth0->execute();	
		my @row0 = $sth0->fetchrow_array();
		
		#
	# OBTENGO LA LECTURA
		my $out = $row0[0];
		#print "##out = $out\n";	#muestra los parametros
		#
	# RETORNO EL VALOR LEIDO
		return $out;
		print("lo que esta sacando es esto: $out")
}

sub write_MySQL
{
	
	#ACTUALIZA EL VALOR REFERIDO EN UNA CONSULTA
		my $select_query = $_[0];
		#
	# ME CONECTO A LA BASE DE DATOS
		my $DBH = BD_connect();
		#
	# EJECUTO OPERACIONES CON EL query
		#print "\$select_query = $select_query\n";
		my $sth0 = $DBH->prepare ($select_query);
		#print 'sth0 = '."$sth0"."\n";
		my $rows = $sth0->execute();	
}

sub BD_connect
{
	### Base de datos OSE ###
		my $dbuser = $PERF_CONFIG::dbuser;
		my $dbpasswd = $PERF_CONFIG::dbpasswd;
		my $host= $PERF_CONFIG::host;
		my $dbase= $PERF_CONFIG::dbase;
		#my $datasource="DBI:mysql:database=$dbase;host=$host";
		my $datasource="DBI:Pg:database=$dbase;host=$host";
		my $DBH;
		
	# MySQL CONFIG
		#~ $dbuser = "yosniel";
		#~ $dbpasswd = "root";
		#~ $host="localhost";
		#~ $dbase="GDA_OSE";
		
	# Conexion a la BD.
	$DBH = DBI->connect($datasource, $dbuser, $dbpasswd);
	if (! $DBH) 
	{
		spx_log( "ERROR No puedo conectarme a la base de datos".DBI->errstr);
		die;
	}
	return $DBH;
}



### Finalizar retornando un valor `verdadero'
1;
