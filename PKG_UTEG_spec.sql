create or replace PACKAGE          pkg_UTEG is

PROCEDURE  Genera_Bloque_periodo (PERIODO varchar2, PTRM_CODE varchar2, CAMPUS varchar2, PROGRAMA varchar2, GRUPOS number, 
            MAX_ENROLL number,GRADO varchar2, TURNO varchar2, PROULEX varchar2);

PROCEDURE  Inserta_CRN (PERIODO varchar2, SUBJ_CODE varchar2,CRSE_NUMB varchar2,
            PTRM_CODE varchar2, CAMPUS varchar2, PROGRAMA varchar2, GRUPOS number, MAX_ENROLL number,
            GRADO varchar2, TURNO varchar2, SECCION varchar2);

procedure Asigna_Bloque (PERIODO varchar2 , TURNO varchar2, CAMPUS varchar2, GMOD_CODE varchar2, 
PROGRAMA varchar2, SECCION varchar2, GRADO varchar2, MAX_ENROLL number, CRN varchar2);

FUNCTION f_periodos_activos  RETURN PKG_UTEG.cursor_periodos;
CURSOR c_out_active_term  IS
SELECT
   'term_code',
   'term_desc'
FROM
    DUAL
WHERE
    1 = 1;
TYPE cursor_periodos IS REF CURSOR
RETURN c_out_active_term%ROWTYPE;

FUNCTION f_campus  RETURN PKG_UTEG.cursor_campus;
CURSOR c_out_campus  IS
SELECT
   'camp_code',
   'camp_desc'
FROM
    DUAL
WHERE
    1 = 1;
TYPE cursor_campus IS REF CURSOR
RETURN c_out_campus%ROWTYPE;

FUNCTION f_campus_programa(CAMPUS varchar2)  RETURN PKG_UTEG.cursor_campus_programa;
CURSOR c_out_campus_programa  IS
SELECT
   'program_code',
   'levl_code',
   'program_desc'
FROM
    DUAL
WHERE
    1 = 1;
TYPE cursor_campus_programa IS REF CURSOR
RETURN c_out_campus_programa%ROWTYPE;

FUNCTION f_programa_periodos(PROGRAMA varchar2)  RETURN PKG_UTEG.cursor_programa_periodos;
CURSOR c_out_programa_periodos  IS
SELECT
   'numero_periodos'
FROM
    DUAL
WHERE
    1 = 1;
TYPE cursor_programa_periodos IS REF CURSOR
RETURN c_out_programa_periodos%ROWTYPE;

FUNCTION f_partes_periodo(PERIODO varchar2)  RETURN PKG_UTEG.cursor_partes_periodo;
CURSOR c_out_partes_periodo  IS
SELECT
   'ptrm_code',
   'ptrm_desc',
   'fini_ffin'
FROM
    DUAL
WHERE
    1 = 1;
TYPE cursor_partes_periodo IS REF CURSOR
RETURN c_out_partes_periodo%ROWTYPE;

FUNCTION F_MATERIAS_DOCENTE(IDEN varchar2)  RETURN PKG_UTEG.CURSOR_MATERIAS_DOCENTE;
CURSOR c_out_materias_docente  IS
SELECT
   'PERIODO',
   'CRN',
   'BLOQUE',
   'PROG',
   'PROGRAMA',
   'CLAVE',
   'MATERIA',
   'ESCALA'  
FROM
    DUAL
WHERE
    1 = 1;
TYPE CURSOR_MATERIAS_DOCENTE IS REF CURSOR
RETURN c_out_materias_docente%ROWTYPE;


FUNCTION F_FECHAS_PARCIAL(PERIODO varchar2, CRN varchar2) RETURN PKG_UTEG.CURSOR_FECHAS_PARCIAL;
CURSOR c_out_fechas_parcial  IS
SELECT
   'PARCIAL',
   'NOMBRE',
   'F_INICIO',
   'F_FIN',
   'PONDERACION',
   'NO_PARCIAL'
FROM
    DUAL
WHERE
    1 = 1;
TYPE CURSOR_FECHAS_PARCIAL IS REF CURSOR
RETURN c_out_fechas_parcial%ROWTYPE;

FUNCTION F_DATOS_PERSONALES(matricula varchar2) RETURN PKG_UTEG.cursor_datos_personales;
CURSOR c_out_datos_personales IS 

SELECT
'MATRICULA',
'NOMBRE',
'ESTATUS',
'FECHA_NACIMIENTO',
'NACIONALIDAD',
'GENERO',
'CURP',
'TELEFONO_CASA',
'CELULAR',
'CORREO',
'CALLE_NUMERO',
'ESTADO',
'MUNICIPIO',
'CODIGO_POSTAL',
'COLONIA'
FROM
DUAL
WHERE 1=1;
TYPE cursor_datos_personales IS REF CURSOR
RETURN c_out_datos_personales%ROWTYPE;

FUNCTION F_EXISTE_BLOQUE(PERIODO varchar2, PROGRAMA varchar2, TURNO varchar2,  GRADO varchar) RETURN PKG_UTEG.cursor_existe_bloque;
CURSOR c_out_existe_bloque IS 

SELECT
'CRNS',
'INSCRITOS'
FROM
    DUAL
WHERE 1=1;
TYPE cursor_existe_bloque IS REF CURSOR
RETURN c_out_existe_bloque%ROWTYPE;

PROCEDURE  INSERTA_INASISTENCIA (PERIODO varchar2, CRN varchar2, IDEN varchar2, FECHA varchar2);

PROCEDURE  ACTUALIZA_INASISTENCIA (PERIODO varchar2, CRN varchar2, IDEN varchar2, FECHA varchar2);

FUNCTION F_ALUMNOS_PARCIAL(PERIODO varchar2, CRN varchar2, PARCIAL varchar2) RETURN PKG_UTEG.cursor_alumnos_parcial;
CURSOR c_out_alumnos_parcial IS 

SELECT
'Matricula',
'Nombre',
'Apellidos',
'No_faltas',
'No_adeudos',
'Ponderacion',
'Calificacion',
'parcial',
'F_inicio',
'F_fin'
FROM
    DUAL
WHERE 1=1;
TYPE cursor_alumnos_parcial IS REF CURSOR
RETURN c_out_alumnos_parcial%ROWTYPE;

PROCEDURE  FECHAS_INASISTENCIA (PERIODO varchar2, CRN varchar2);

PROCEDURE  ACTUALIZA_CALIF_PARCIAL (PERIODO varchar2, CRN varchar2, ID_ESTU varchar2, PARCIAL varchar2, ID_DOC varchar2, CALI varchar2, PROGRAMA varchar2);

FUNCTION NUMERO_SESIONES(PERIODO varchar2, CRN varchar2) return number;

PROCEDURE GENERA_CRN_EXT;

FUNCTION F_FECHAS_INASISTENCIA(PERIODO varchar2, CRN varchar2) RETURN PKG_UTEG.cursor_fechas_inasistencia;
CURSOR c_out_fechas_inasistencia IS 

SELECT
'Dia',
'Fecha',
'Clase'
FROM
    DUAL
WHERE 1=1;
TYPE cursor_fechas_inasistencia IS REF CURSOR
RETURN c_out_fechas_inasistencia%ROWTYPE;

FUNCTION F_LISTA_INASISTENCIA(PERIODO varchar2, CRN varchar2) RETURN PKG_UTEG.cursor_lista_inasistencia;
CURSOR c_out_lista_inasistencia IS 

SELECT
'Matricula',
'Nombre'
FROM
DUAL
WHERE 1=1;
TYPE cursor_lista_inasistencia IS REF CURSOR
RETURN c_out_lista_inasistencia%ROWTYPE;

FUNCTION F_RETORNA_INACISTENCIA (periodo varchar2, crn varchar2, fecha_min varchar2, fecha_max varchar2)  RETURN PKG_UTEG.cursor_retorna_inasistencia;
CURSOR c_out_retorna_inasistencia IS 
SELECT
'Matricula',
'Nombre',
'periodo',
'día',
'fecha'
FROM DUAL
WHERE 1=1;
TYPE cursor_retorna_inasistencia IS REF CURSOR
RETURN c_out_retorna_inasistencia%ROWTYPE;


FUNCTION F_CALIFICACIONES_PARCIALES(periodo varchar2, crn varchar2) RETURN PKG_UTEG.cursor_calif_par;

CURSOR c_out_calif_par IS

SELECT
'programa',
'grado',
'parcial',
'clave_grupo',
'turno',
'matricula_prof',
'nombre_prof',
'clave_materia',
'nombre_materia',
'ciclo',
'matricula_alumno',
'nombre_alumno',
'No_Faltas',
'calif_no',
'calif_letra'
FROM DUAL
WHERE 1=1;
TYPE cursor_calif_par IS REF CURSOR
RETURN c_out_calif_par%ROWTYPE;

FUNCTION F_INSERTA_CAL_EXT (matricula varchar2, term_code varchar2, crn varchar2, grade_code varchar2) return varchar2;

FUNCTION F_REPORTE_CAL_FINALES (iden varchar2, periodo varchar2, parcial varchar2, crn varchar2) RETURN PKG_UTEG.cursor_calif_fin;
CURSOR c_out_calif_fin IS

SELECT
'programa',
'grado',
'clave_grupo',
'turno',
'matricula_prof',
'nombre_prof',
'clave_materia',
'nombre_materia',
'ciclo',
'matricula_alumno',
'nombre_alumno',
'No_Faltas',
'calif_no',
'calif_letra'
FROM DUAL
WHERE 1=1;
TYPE cursor_calif_fin IS REF CURSOR
RETURN c_out_calif_fin%ROWTYPE;

FUNCTION F_ALUMNOS_GRUPO  (periodo varchar2, crn varchar2) RETURN PKG_UTEG.cursor_alumnos_crn;

CURSOR c_out_alumnos_crn IS

SELECT 
'matricula',
'nombre_alumno',
'parcial',
'grupo'
FROM DUAL
WHERE 1=1;
TYPE cursor_alumnos_crn IS REF CURSOR
RETURN c_out_alumnos_crn%ROWTYPE;

FUNCTION F_FALTAS_X_GRUPO (periodo varchar2, crn varchar2) RETURN PKG_UTEG.cursor_faltas_x_grupo;

CURSOR c_out_faltas_x_grupo IS

SELECT
'grupo',
'matricula',
'nombre_alumno',
'total_faltas'
FROM DUAL
WHERE 1=1;
TYPE cursor_faltas_x_grupo IS REF CURSOR
RETURN c_out_faltas_x_grupo%ROWTYPE;


FUNCTION F_LISTA_EXTRAORDINARIO(PERIODO varchar2, CRN varchar2) RETURN PKG_UTEG.CURSOR_LISTA_EXT;
CURSOR c_out_lista_ext  IS
SELECT
   'MATRICULA',
   'NOMBRE',
   'APELLIDOS',
   'NO_FALTAS',
   'PARCIAL_1',
   'PARCIAL_2',
   'PARCIAL_3',
   'ORDINARIO',
   'EXTRAORDINARIO'
FROM
    DUAL
WHERE
    1 = 1;
TYPE CURSOR_LISTA_EXT IS REF CURSOR
RETURN c_out_lista_ext%ROWTYPE;


FUNCTION F_HORARIOS_CLASE(periodo varchar2, crn varchar2) RETURN PKG_UTEG.cursor_horarios_clase;
CURSOR c_out__horarios_clase IS
SELECT 'clave_materia',
'materia',
'grupo',
'ciclo',
'Lunes',
'Martes',
'Miércoles',
'Jueves',
'Viernes',
'Sábado',
'salón',
'edificio',
'ubicación',
'h_inicio',
'h_termino'
FROM DUAL
WHERE 1=1;

TYPE cursor_horarios_clase IS REF CURSOR
RETURN c_out__horarios_clase%ROWTYPE;






--últimos Cambios 
end pkg_UTEG;
