create or replace PACKAGE BODY          pkg_UTEG
is

PROCEDURE  Genera_Bloque_periodo (PERIODO varchar2, PTRM_CODE varchar2, CAMPUS varchar2, PROGRAMA varchar2, GRUPOS number, 
            MAX_ENROLL number,GRADO varchar2, TURNO varchar2, PROULEX varchar2) is

cursor materias_grado is
select smracaa_subj_code, smracaa_crse_numb_low, smracaa_seqno
from smracaa, smrpaap
where smrpaap_program=PROGRAMA and smrpaap_area=smracaa_area
and   smrpaap_area like '%'||lpad(GRADO,2,'0')||'%'
order by 3;

cursor materias_grado_proulex is
select smracaa_subj_code, smracaa_crse_numb_low, smracaa_seqno
from smracaa, smrpaap, scbcrse
where smrpaap_program=PROGRAMA and smrpaap_area=smracaa_area
and   smrpaap_area like '%'||lpad(GRADO,2,'0')||'%'
and   scbcrse_subj_code=smracaa_subj_code and scbcrse_crse_numb=smracaa_crse_numb_low
and   scbcrse_title not like '%INGLES%'
union
select scbcrse_subj_code, scbcrse_crse_numb, 99
from scbcrse
where scbcrse_subj_code='ALEX' and scbcrse_crse_numb=substr(scbcrse_crse_numb,1,4)||GRADO
and   scbcrse_title like '%PROULEX%'
order by 3;

no_grupos number;
v_subj varchar2(6);  v_crse varchar2(6); v_seqno number;
seccion varchar2(1);

BEGIN
no_grupos:=0;
if PROULEX='S' then
   no_grupos:=GRUPOS-1;
else
   no_grupos:=GRUPOS;
end if;
dbms_output.put_line('Proulex:'||PROULEX||' no_grupos:'||no_grupos||'GRUPOS:'||GRUPOS);
for f in 1..no_grupos loop

if f=1 then seccion:='A'; end if;
if f=2 then seccion:='B'; end if;
if f=3 then seccion:='C'; end if;
if f=4 then seccion:='D'; end if;
if f=5 then seccion:='E'; end if;
if f=6 then seccion:='F'; end if;
if f=7 then seccion:='G'; end if;
if f=8 then seccion:='H'; end if;
if f=9 then seccion:='I'; end if;
if f=10 then seccion:='J'; end if;

OPEN materias_grado;
        LOOP
         FETCH materias_grado
         INTO v_subj, v_crse, v_seqno;
         
         EXIT WHEN materias_grado%NOTFOUND;

        begin
            
            Inserta_CRN (PERIODO , v_subj ,v_crse ,PTRM_CODE, CAMPUS,PROGRAMA, no_grupos, MAX_ENROLL,
            GRADO , TURNO, seccion);            
        
        end;


        END LOOP;

    CLOSE materias_grado;
end loop;

if PROULEX = 'S' then

    seccion:='X';
    
    OPEN materias_grado_proulex;
        LOOP
         FETCH materias_grado_proulex
         INTO v_subj, v_crse, v_seqno;
         
         EXIT WHEN materias_grado_proulex%NOTFOUND;

        begin
            
            Inserta_CRN (PERIODO , v_subj ,v_crse ,PTRM_CODE, CAMPUS,PROGRAMA, no_grupos, MAX_ENROLL,
            GRADO , TURNO, seccion);            
        
        end;


    END LOOP;

    CLOSE materias_grado_proulex;    

end if;


commit;

END Genera_Bloque_periodo;


 procedure Inserta_CRN (PERIODO varchar2, SUBJ_CODE varchar2,CRSE_NUMB varchar2,
            PTRM_CODE varchar2, CAMPUS varchar2,PROGRAMA varchar2, GRUPOS number, MAX_ENROLL number,
            GRADO varchar2, TURNO varchar2, SECCION varchar2) is


crn number;
title varchar2(30);
creditos decimal(6,2);
f_inicio date;
f_fin    date;
semanas  number;
teo     number;
prac    number;
otr     number;
cont    number;
nulo varchar2(1) default null;
SCHD_CODE varchar2(4);
INSM_CODE varchar2(4);
GSCH_NAME varchar2(10);
GMOD_CODE varchar2(1);

BEGIN


update sobterm set sobterm_crn_oneup=sobterm_crn_oneup+1
where sobterm_term_code=periodo;

select sobterm_crn_oneup into crn from sobterm
where sobterm_term_code=periodo;



select SCBCRSE_TITLE, SCBCRSE_LEC_HR_LOW, SCBCRSE_LAB_HR_LOW, SCBCRSE_OTH_HR_LOW, SCBCRSE_CONT_HR_LOW
into title, teo, prac, otr, cont
from scbcrse
where scbcrse_subj_code=SUBJ_CODE and scbcrse_crse_numb=CRSE_NUMB;

begin
select SMRACAA_MAX_CRED_CRSE into creditos 
from smracaa, smrpaap
where smrpaap_program=PROGRAMA and smrpaap_area=smracaa_area
and   smracaa_subj_code=SUBJ_CODE and smracaa_crse_numb_low=CRSE_NUMB;
exception when others then
 select SCBCRSE_CREDIT_HR_LOW into creditos 
    from scbcrse
    where scbcrse_subj_code=SUBJ_CODE and scbcrse_crse_numb=CRSE_NUMB;  
end;

select sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
into f_inicio, f_fin, semanas
from sobptrm
where sobptrm_term_code=PERIODO and sobptrm_ptrm_code=PTRM_CODE;

SELECT 
SCRSCHD_SCHD_CODE,
SCRSCHD_INSM_CODE
INTO 
SCHD_CODE,
INSM_CODE 
FROM SCRSCHD C1
WHERE C1.SCRSCHD_SUBJ_CODE = SUBJ_CODE
AND C1.SCRSCHD_CRSE_NUMB   = CRSE_NUMB
AND C1.SCRSCHD_EFF_TERM   = ( select max(C2.SCRSCHD_EFF_TERM)
                              FROM SCRSCHD C2
                             WHERE C2.SCRSCHD_SUBJ_CODE = SUBJ_CODE
                               AND C2.SCRSCHD_CRSE_NUMB   =CRSE_NUMB
                               AND C2.SCRSCHD_EFF_TERM <= PERIODO
                          );


begin

/*
    BANINST1.sb_section.p_create(  
    PERIODO,  		-- Clave de periodo en dónde se crea el CRN
    CRN,				-- Se obtiene de SOBTERM_CRN_ONEUP +1 buscando por SOBTERM_TERM_CODE
    PTRM_CODE,		-- Regla de negocio para poner la parte de periodo
    SUBJ_CODE  ,		-- Subject de la matera (SUBJ_CODE)
    CRSE_NUMB  ,		-- Course de la materia (CRSE_NUMB)
    seccion,		-- Definir valor para la sección (puede ser la letra del Bloque)
    'A',      		-- Valor por default 'A' Activo
    SCHD_CODE,      		-- Tipo de hora Teórico, Práctico Tabla (STVSCHD)
    CAMPUS,    		-- Clave de Campus
    title       ,  	-- Nombre Materia (SCBCRSE_TITLE)
    creditos    , 	-- Créditos (SMRACAA_MAX_CRED_CRSE) 
    1       , 	-- Valor por default 1
    GMOD_CODE             , 	-- Tipo de Calificación (S=Standard, G=Base 100)
    nulo              , 	-- Valor por defaul null
    nulo               , 	-- Valor por defaul null
    nulo              , 	-- Valor por defaul null 
    'Y'               , 	-- Valor por default 'Y'
    'Y'           ,	-- Valor por default 'Y'
    nulo               ,	-- Valor por defaul null 
    0             ,	-- Valor por default 0 (cero)
    0             ,	-- Valor por default 0 (cero) 
    0              ,	-- Valor por default 0 (cero) 
    MAX_ENROLL               ,	-- Capacidad máxima del grupo
    0                   ,	-- Valor por default 0 (cero) 
    MAX_ENROLL            ,	-- Capacidad máxima del grupo
    0         ,	-- Valor por default 0 (cero)
    0            ,	-- Valor por default 0 (cero)
    f_inicio      ,   -- Fecha Inicio (SOBPTRM_START_DATE) dependiendo de la parte de periodo (PTRM_CODE)
    f_inicio        ,   -- Fecha Inicio (SOBPTRM_START_DATE) dependiendo de la parte de periodo (PTRM_CODE)
    f_fin       ,   -- Fecha Fin    (SOBPTRM_END_DATE) dependiendo de la parte de periodo (PTRM_CODE)
    semanas,               -- SOBPTRM_PTRM_WEEKS dependiendo de la parte de periodo (PTRM_CODE)
    nulo           ,	-- Valor por default null
    0          ,	-- Valor por default 0 (cero)
    0             ,	-- Valor por default 0 (cero)
    0             ,	-- Valor por default 0 (cero)
    teo                 ,	-- Horas teóricas (SCBCRSE_LEC_HR_LOW)
    prac                 ,	-- Horas teóricas (SCBCRSE_LAB_HR_LOW)
    otr                 ,	-- Horas teóricas (SCBCRSE_OTH_HR_LOW)
    cont                ,	-- Horas teóricas (SCBCRSE_CONT_HR_LOW)
    nulo              ,	-- Valor por default null 
    nulo              ,	-- Valor por default null 
    nulo          ,	-- Valor por default null 
    nulo      ,	-- Valor por default null 
    nulo      ,	-- Valor por default null 
    nulo      ,	-- Valor por default null 
    0          ,	-- Valor por default 0 (cero)
    'Y'            ,	-- Valor por default 'Y'
    'N'   ,	-- Valor por default 'N'
    GSCH_NAME              ,	-- Regla para obtener la escala númerica de Calificación
    nulo           ,	-- Valor por default null 
    nulo         ,	-- Valor por default null 
    INSM_CODE, ----p_insm_code,   -- Regla para obtener la modalidad del grupo materia. Tabla (GTVINSM)
    nulo          ,	-- Valor por default null
    nulo            ,	-- Valor por default null
    nulo ,	-- Valor por default null
    nulo ,	-- Valor por default null
    nulo              ,	-- Valor por default null
    nulo        ,	-- Valor por default null
    0   ,	-- Valor por default 0 (cero)
    'INTERFAZ'            , -- Valor por default Usuario 'INTERFAZ'
    'AUTM'                ,	-- Valor por default Usuario 'AUTM'
    nulo               ,	-- Regla de negocio para colocar el socio de integración (MOODL) desde inicio del CRN o proceso posterior
    'B'  ,	-- Valor por default 'B'
    nulo, 	    -- Valor por default null
    nulo,
    nulo,
    nulo,
    nulo,
    'N',
    nulo,
    nulo);*/
    -- Obtiene Escala de Calificación
    select  CASE SYS.ANYDATA.getTypeName(gorsdav_value) 
                            WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(gorsdav_value) 
                            WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(gorsdav_value))
                            WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(gorsdav_value), 'DD-MON-YYYY') 
                        END  into GSCH_NAME
                from gorsdav, sobcurr
                where sobcurr_camp_code=CAMPUS and sobcurr_program=PROGRAMA
                and  gorsdav_table_name='STVLEVL' and gorsdav_attr_name='ESCLA_CALI' 
                and gorsdav_pk_parenttab='UTG'||chr(1)||sobcurr_levl_code;
                
    -- Obtiene Modo de Calificación
    select  CASE SYS.ANYDATA.getTypeName(gorsdav_value) 
                            WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(gorsdav_value) 
                            WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(gorsdav_value))
                            WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(gorsdav_value), 'DD-MON-YYYY') 
                        END  into GMOD_CODE
                from gorsdav, sobcurr
                where sobcurr_camp_code=CAMPUS and sobcurr_program=PROGRAMA
                and  gorsdav_table_name='STVLEVL' and gorsdav_attr_name='MOD_CALI' 
                and gorsdav_pk_parenttab='UTG'||chr(1)||sobcurr_levl_code;

    insert into ssbsect values(
     PERIODO,  		-- Clave de periodo en dónde se crea el CRN
    CRN,				-- Se obtiene de SOBTERM_CRN_ONEUP +1 buscando por SOBTERM_TERM_CODE
    PTRM_CODE,		-- Regla de negocio para poner la parte de periodo
    SUBJ_CODE  ,		-- Subject de la matera (SUBJ_CODE)
    CRSE_NUMB  ,		-- Course de la materia (CRSE_NUMB)
    SECCION,		-- Definir valor para la sección (puede ser la letra del Bloque)
    'A',      		-- Valor por default 'A' Activo
    SCHD_CODE,      		-- Tipo de hora Teórico, Práctico Tabla (STVSCHD)
    CAMPUS,    		-- Clave de Campus
    title       ,  	-- Nombre Materia (SCBCRSE_TITLE)
    creditos    , 	-- Créditos (SMRACAA_MAX_CRED_CRSE) 
    1       , 	-- Valor por default 1
    GMOD_CODE             , 	-- Tipo de Calificación (S=Standard, G=Base 100)
    nulo              , 	-- Valor por defaul null
    nulo               , 	-- Valor por defaul null
    nulo              , 	-- Valor por defaul null 
    'Y'               , 	-- Valor por default 'Y'
    'Y'           ,	-- Valor por default 'Y'
    nulo               ,	-- Valor por defaul null 
    0             ,	-- Valor por default 0 (cero)
    0             ,	-- Valor por default 0 (cero) 
    0              ,	-- Valor por default 0 (cero) 
    MAX_ENROLL               ,	-- Capacidad máxima del grupo
    0                   ,	-- Valor por default 0 (cero) 
    MAX_ENROLL            ,	-- Capacidad máxima del grupo
    0         ,	-- Valor por default 0 (cero)
    0            ,	-- Valor por default 0 (cero)
    f_inicio      ,   -- Fecha Inicio (SOBPTRM_START_DATE) dependiendo de la parte de periodo (PTRM_CODE)
    sysdate        , -- Fecha de registro
    f_inicio        ,   -- Fecha Inicio (SOBPTRM_START_DATE) dependiendo de la parte de periodo (PTRM_CODE)
    f_fin       ,   -- Fecha Fin    (SOBPTRM_END_DATE) dependiendo de la parte de periodo (PTRM_CODE)
    semanas,               -- SOBPTRM_PTRM_WEEKS dependiendo de la parte de periodo (PTRM_CODE)
    nulo           ,	-- Valor por default null
    0          ,	-- Valor por default 0 (cero)
    0             ,	-- Valor por default 0 (cero)
    0             ,	-- Valor por default 0 (cero)
    teo                 ,	-- Horas teóricas (SCBCRSE_LEC_HR_LOW)
    prac                 ,	-- Horas teóricas (SCBCRSE_LAB_HR_LOW)
    otr                 ,	-- Horas teóricas (SCBCRSE_OTH_HR_LOW)
    cont                ,	-- Horas teóricas (SCBCRSE_CONT_HR_LOW)
    nulo              ,	-- Valor por default null 
    nulo              ,	-- Valor por default null 
    nulo          ,	-- Valor por default null 
    nulo      ,	-- Valor por default null 
    nulo      ,	-- Valor por default null 
    nulo      ,	-- Valor por default null 
    0          ,	-- Valor por default 0 (cero)
    'Y'            ,	-- Valor por default 'Y'
    'N'   ,	-- Valor por default 'N'
    GSCH_NAME              ,	-- Regla para obtener la escala númerica de Calificación
    nulo           ,	-- Valor por default null 
    nulo         ,	-- Valor por default null 
    INSM_CODE, ----p_insm_code,   -- Regla para obtener la modalidad del grupo materia. Tabla (GTVINSM)
    nulo          ,	-- Valor por default null
    nulo            ,	-- Valor por default null
    nulo ,	-- Valor por default null
    nulo ,	-- Valor por default null
    nulo              ,	-- Valor por default null
    nulo        ,	-- Valor por default null
    0   ,	-- Valor por default 0 (cero)
    'INTERFAZ'            , -- Valor por default Usuario 'INTERFAZ'
    'AUTM'                ,	-- Valor por default Usuario 'AUTM'
    nulo               ,	-- Regla de negocio para colocar el socio de integración (MOODL) desde inicio del CRN o proceso posterior
    'B'  ,	-- Valor por default 'B'
    PROGRAMA,
    nulo,
    nulo,
    nulo,
    nulo,
    nulo,
    nulo,
    nulo,
    'N',
    nulo,
    nulo);
   
    -- Genera e inserta en BLOQUE CRN
    begin
        Asigna_Bloque (PERIODO , TURNO , CAMPUS , GMOD_CODE , 
        PROGRAMA , seccion ,GRADO,  MAX_ENROLL, CRN );
    end;
    
end;


END Inserta_CRN;

procedure Asigna_Bloque (PERIODO varchar2, TURNO varchar2, CAMPUS varchar2, GMOD_CODE varchar2, 
PROGRAMA varchar2, SECCION varchar2 , GRADO varchar2, MAX_ENROLL number, CRN varchar2) is


letra_campus varchar2(1);
incorporante varchar2(3);
r_sorcmjr    varchar2(4);
majr_code    varchar2(4);
bloque       varchar2(10);
conta_bloque number;
contador     number;
creditos decimal(6,2);


begin


select 
CASE SYS.ANYDATA.getTypeName(gorsdav_value) 
                            WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(gorsdav_value) 
                            WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(gorsdav_value))
                            WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(gorsdav_value), 'DD-MON-YYYY') 
                        END into letra_campus
from gorsdav
where gorsdav_table_name='STVCAMP'
and   gorsdav_attr_name='LE_CAM_BLO'
and   gorsdav_pk_parenttab='UTG'||chr(1)||CAMPUS;

select sorcmjr_cmjr_rule, sorcmjr_majr_code into r_sorcmjr, majr_code 
from sorcmjr, sobcurr
where sobcurr_program=PROGRAMA and sobcurr_camp_code=CAMPUS
and   sorcmjr_curr_rule=sobcurr_curr_rule
and   substr(sorcmjr_dept_code,1,1) != 'T';

select CASE SYS.ANYDATA.getTypeName(gorsdav_value) 
                            WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(gorsdav_value) 
                            WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(gorsdav_value))
                            WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(gorsdav_value), 'DD-MON-YYYY') 
                        END into incorporante
from gorsdav
where gorsdav_table_name='SORCMJR'
and   gorsdav_pk_parenttab='UTG'||chr(1)||r_sorcmjr
and   gorsdav_attr_name='INCORPO';


bloque:=GRADO||letra_campus||substr(majr_code,1,3)||substr(incorporante,1,1)||substr(TURNO,1,1)||SECCION;
dbms_output.put_line('Bloque:'||bloque);

select count(*) into conta_bloque from stvblck
where stvblck_code=bloque;

if conta_bloque=0 then

    insert into stvblck values(bloque, 'Bloque '||bloque, sysdate, null, null, user, 'AUTM', null);

end if;

select count(*) into contador from SFBBLCD
where sfbblcd_term_code=PERIODO and sfbblcd_blck_code=bloque;

if contador = 0 then

    insert into SFBBLCD values(PERIODO, bloque, MAX_ENROLL, user, sysdate, null,null,null, 'AUTM', null);

end if;

contador:=0;

select count(*) into contador from SSRBLCK
where ssrblck_term_code=PERIODO and ssrblck_blck_code=bloque and ssrblck_crn=CRN;

if contador = 0 then

    begin
    select SMRACAA_MAX_CRED_CRSE into creditos 
    from ssbsect, smracaa, smrpaap
    where ssbsect_term_code=PERIODO and ssbsect_crn=CRN 
    and   smrpaap_program=PROGRAMA and smrpaap_area=smracaa_area
    and   smracaa_subj_code=ssbsect_subj_code and smracaa_crse_numb_low=ssbsect_crse_numb;
    exception when others then creditos:=0;
    end;

    insert into SSRBLCK values(PERIODO, bloque, CRN, creditos, 1, GMOD_CODE, null, sysdate, 'N', null, null, user, 'AUTM', null);

end if;

end Asigna_Bloque;

FUNCTION f_periodos_activos RETURN PKG_UTEG.cursor_periodos

AS c_out_active_term PKG_UTEG.cursor_periodos;

BEGIN

OPEN c_out_active_term FOR
select
stvterm_code term_code, stvterm_code||'--'||stvterm_desc term_desc
from stvterm
where trunc(stvterm_end_date) >= trunc(sysdate)
and   substr(stvterm_code,1,1) != '9' and   substr(stvterm_code,6,1) not in ('1','6')
order by stvterm_code;

RETURN(c_out_active_term);

END f_periodos_activos;

FUNCTION f_campus RETURN PKG_UTEG.cursor_campus

AS c_out_campus PKG_UTEG.cursor_campus;

BEGIN

OPEN c_out_campus FOR
select
stvcamp_code camp_code, stvcamp_desc camp_desc
from stvcamp
order by stvcamp_code;

RETURN(c_out_campus);

END f_campus;

FUNCTION f_campus_programa(CAMPUS varchar2) RETURN PKG_UTEG.cursor_campus_programa

AS c_out_campus_programa PKG_UTEG.cursor_campus_programa;

BEGIN

OPEN c_out_campus_programa FOR
select 
sobcurr_program program_code, sobcurr_levl_code levl_code, sobcurr_program||'--'||smrprle_program_desc program_desc
from sobcurr, smrprle
where sobcurr_camp_code=CAMPUS
and   sobcurr_program=smrprle_program;

RETURN(c_out_campus_programa);

END f_campus_programa;

FUNCTION f_programa_periodos(PROGRAMA varchar2) RETURN PKG_UTEG.cursor_programa_periodos

AS c_out_programa_periodos PKG_UTEG.cursor_programa_periodos;

BEGIN

OPEN c_out_programa_periodos FOR
select 
count(distinct smracaa_area) numero_periodos
from smracaa, smrpaap
where smrpaap_program=PROGRAMA and smrpaap_area=smracaa_area;

RETURN(c_out_programa_periodos);

END f_programa_periodos;

FUNCTION f_partes_periodo(PERIODO varchar2) RETURN PKG_UTEG.cursor_partes_periodo

AS c_out_partes_periodo PKG_UTEG.cursor_partes_periodo;

BEGIN

OPEN c_out_partes_periodo FOR
select 
sobptrm_ptrm_code ptrm_code, sobptrm_desc ptrm_desc, to_char(sobptrm_start_date,'dd/mm/yyyy')||'--'||
to_char(sobptrm_end_date,'dd/mm/yyyy') fini_ffin
from sobptrm
where sobptrm_term_code=PERIODO;

RETURN(c_out_partes_periodo);

END f_partes_periodo;

FUNCTION F_MATERIAS_DOCENTE(IDEN varchar2) RETURN PKG_UTEG.CURSOR_MATERIAS_DOCENTE

AS c_out_materias_docente PKG_UTEG.CURSOR_MATERIAS_DOCENTE;

BEGIN

OPEN c_out_materias_docente FOR
select SSBSECT_TERM_CODE PERIODO, SSBSECT_CRN CRN, SSRBLCK_BLCK_CODE BLOQUE,SSBSECT_KEYWORD_INDEX_ID PROG, 
SMRPRLE_PROGRAM_DESC PROGRAMA, SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB CLAVE, SCBCRSE_TITLE MATERIA, SHBGSCH_DESCRIPTION ESCALA
from stvterm, sirasgn, ssbsect , smrprle, scbcrse, ssrblck,shbgsch
where trunc(sysdate) <= trunc(stvterm_end_date) 
and   stvterm_code=sirasgn_term_code
and   sirasgn_pidm in (select spriden_pidm from spriden where spriden_id=IDEN)
and   sirasgn_percent_response > 0
and   ssbsect_term_code=sirasgn_term_code and ssbsect_crn=sirasgn_crn
and   ssbsect_keyword_index_id=smrprle_program
and   scbcrse_subj_code=ssbsect_subj_code and scbcrse_crse_numb=ssbsect_crse_numb
and   ssbsect_gsch_name=shbgsch_name
and   ssbsect_term_code=ssrblck_term_code and ssbsect_crn=ssrblck_crn
order by CRN;

RETURN(c_out_materias_docente);

END F_MATERIAS_DOCENTE;


FUNCTION F_FECHAS_PARCIAL(PERIODO varchar2, CRN varchar2) RETURN PKG_UTEG.CURSOR_FECHAS_PARCIAL

AS c_out_fechas_parcial PKG_UTEG.CURSOR_FECHAS_PARCIAL;

BEGIN

OPEN c_out_fechas_parcial FOR
select shrgcom_name PARCIAL, shrgcom_description NOMBRE, to_char(sfrrsts_start_date,'dd/mm/yyyy')F_INICIO, 
to_char(sfrrsts_end_date,'dd/mm/yyyy') F_FIN, shrgcom_weight PONDERACION, substr(shrgcom_name,1,1) NO_PARCIAL
from shrgcom, sfrrsts
where shrgcom_term_code=PERIODO and shrgcom_crn=CRN --and shrgcom_name=PARCIAL
and   sfrrsts_term_code=shrgcom_term_code and substr(sfrrsts_rsts_code,1,1)=substr(shrgcom_name,1,1);

RETURN(c_out_fechas_parcial);

END F_FECHAS_PARCIAL;

PROCEDURE INSERTA_INASISTENCIA (PERIODO varchar2, CRN varchar2, IDEN varchar2, FECHA varchar2) is

hora_ini varchar2(4);
hora_fin varchar2(4);
pidm     number;
secuencia number;
day_number number;
contador number;

BEGIN

-- Obtiene pidm del alumno
select spriden_pidm into pidm from spriden
where spriden_id=IDEN and spriden_change_ind is null;

-- Verifica si ya se insertó registro de falta
select count(*) into contador
from skrattr
where skrattr_term_code=PERIODO and skrattr_crn=CRN
and   skrattr_pidm=pidm and trunc(skrattr_date)=to_date(FECHA,'dd/mm/yyyy');

if contador = 0 then
    -- Obtiene número secuencia
    select SKRATTR_KEY_SEQ.nextval into secuencia from dual;
    
    
    --Obtiene dia de la semana de la fecha de falta
    select DECODE(RTRIM(LTRIM(to_char(to_date(FECHA,'dd/mm/yyyy'), 'DAY', 'NLS_DATE_LANGUAGE=SPANISH'))),
    'LUNES', 1, 'MARTES', 2, 'MIÉRCOLES', 3, 'JUEVES', 4,
    'VIERNES', 5, 'S�?BADO', 6, 7) into day_number
    from dual;
    
    hora_ini:='0000'; 
    hora_fin:='0000';
    
    -- Obtiene horario del CRN y Fecha 
    
    if day_number= 1 then
        begin
        select ssrmeet_begin_time, ssrmeet_end_time into hora_ini, hora_fin
        from ssrmeet
        where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
        and   ssrmeet_mon_day='M';
        exception when others then hora_ini:='0000'; hora_fin:='0000';
        end;
    end if;
    
    if day_number= 2 then
        begin
        select ssrmeet_begin_time, ssrmeet_end_time into hora_ini, hora_fin
        from ssrmeet
        where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
        and   ssrmeet_tue_day='T';
        exception when others then hora_ini:='0000'; hora_fin:='0000';
        end;
    end if;
    
    if day_number= 3 then
        begin
        select ssrmeet_begin_time, ssrmeet_end_time into hora_ini, hora_fin
        from ssrmeet
        where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
        and   ssrmeet_wed_day='W';
        exception when others then hora_ini:='0000'; hora_fin:='0000';
        end;
    end if;
    
    if day_number= 4 then
        begin
        select ssrmeet_begin_time, ssrmeet_end_time into hora_ini, hora_fin
        from ssrmeet
        where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
        and   ssrmeet_thu_day='R';
        exception when others then hora_ini:='0000'; hora_fin:='0000';
        end;
    end if;
    
    if day_number= 5 then
        begin
        select ssrmeet_begin_time, ssrmeet_end_time into hora_ini, hora_fin
        from ssrmeet
        where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
        and   ssrmeet_fri_day='F';
        exception when others then hora_ini:='0000'; hora_fin:='0000';
        end;
    end if;
    
    if day_number= 6 then
        begin
        select ssrmeet_begin_time, ssrmeet_end_time into hora_ini, hora_fin
        from ssrmeet
        where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
        and   ssrmeet_sat_day='S';
        exception when others then hora_ini:='0000'; hora_fin:='0000';
        end;
    end if;
    
    if day_number= 7 then
        begin
        select ssrmeet_begin_time, ssrmeet_end_time into hora_ini, hora_fin
        from ssrmeet
        where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
        and   ssrmeet_sun_day='U';
        exception when others then hora_ini:='0000'; hora_fin:='0000';
        end;
    end if;
    
    insert into skrattr values(secuencia,pidm, CRN, null, PERIODO, null, to_date(FECHA,'dd/mm/yyyy'), null, null,
    'CLAS',null,null,'N',null, null, null, 'Y', sysdate, user, 'PORTAL',hora_ini,hora_fin, sysdate, null,null, null);
    
    commit;
end if;

END INSERTA_INASISTENCIA;

PROCEDURE ACTUALIZA_INASISTENCIA (PERIODO varchar2, CRN varchar2, IDEN varchar2, FECHA varchar2) is

hora_ini varchar2(4);
hora_fin varchar2(4);
pidm     number;
secuencia number;
day_number number;

BEGIN

-- Obtiene pidm del alumno
select spriden_pidm into pidm from spriden
where spriden_id=IDEN and spriden_change_ind is null;

update skrattr set skrattr_attend_ind='J' 
where skrattr_term_code=PERIODO and skrattr_crn=CRN
and   skrattr_pidm=pidm and trunc(skrattr_date)=to_date(FECHA,'dd/mm/yyyy');

commit;

END ACTUALIZA_INASISTENCIA;


 FUNCTION F_DATOS_PERSONALES(matricula varchar2) RETURN PKG_UTEG.cursor_datos_personales
 
 AS c_out_datos_personales PKG_UTEG.cursor_datos_personales;
 
 BEGIN
 
 OPEN c_out_datos_personales FOR
 SELECT SPRIDEN_ID matricula,
 SPRIDEN_FIRST_NAME||' '||SPRIDEN_LAST_NAME nombre, 
 STVFCST_DESC estatus,
 SPBPERS_BIRTH_DATE fecha_nacimiento,
 STVNATN_NATION nacionalidad,
 SPBPERS_SEX genero,
 GORADID_ADID_CODE curp,
 SPRTELE_PHONE_NUMBER telefono_casa,
 (SELECT a.SPRTELE_PHONE_NUMBER FROM SPRTELE a WHERE 1=1 AND SPRTELE_PIDM IN(SELECT SPRIDEN_PIDM FROM SPRIDEN WHERE 1=1 AND SPRIDEN_ID = 'G00125853') AND SPRTELE_TELE_CODE = 'MO') celular,
 GOREMAL_EMAIL_ADDRESS correo,
 SPRADDR_STREET_LINE1 calle_numero,
 STVSTAT_DESC estado,
 STVCNTY_DESC municipio,
 SPRADDR_ZIP codigo_postal,
 SPRADDR_STREET_LINE2 colonia
 FROM SPRIDEN, SIBINST, GORADID, SPBPERS, SPRTELE, GOREMAL, SPRADDR, STVNATN, STVSTAT, STVCNTY, STVFCST
 WHERE 1=1
 AND SPRIDEN_PIDM = SIBINST_PIDM
 AND SPRIDEN_CHANGE_IND IS NULL
 AND SPRIDEN_PIDM = SPBPERS_PIDM
 AND SPRIDEN_PIDM = GORADID_PIDM
 AND GORADID_ADID_CODE = 'CURP'
 AND SPRIDEN_PIDM = SPRTELE_PIDM
 AND SPRTELE_TELE_CODE = 'MA'
 AND SIBINST_FCST_CODE = STVFCST_CODE
 AND SPRIDEN_PIDM = GOREMAL_PIDM
 AND GOREMAL_EMAL_CODE = 'UNIV'
 AND GOREMAL_PREFERRED_IND = 'Y'
 AND SPRIDEN_PIDM = SPRADDR_PIDM
 AND SPRADDR_STAT_CODE = STVSTAT_CODE
 AND SPRADDR_CNTY_CODE = STVCNTY_CODE
 AND SPRADDR_NATN_CODE = STVNATN_CODE
 AND SPRIDEN_ID = matricula; --'G00125853';
 
 RETURN (c_out_datos_personales);
 
 END F_DATOS_PERSONALES;
 
FUNCTION F_EXISTE_BLOQUE(PERIODO varchar2, PROGRAMA varchar2, TURNO varchar2, GRADO varchar)  RETURN PKG_UTEG.cursor_existe_bloque

AS c_out_existe_bloque PKG_UTEG.cursor_existe_bloque;

BEGIN

if to_number(GRADO) < 10 then
    OPEN c_out_existe_bloque FOR
    select count(distinct ssbsect_crn) CRNS, nvl(sum(ssbsect_enrl),0) INSCRITOS
    from smracaa, smrpaap, ssbsect, ssrblck
    where smrpaap_program=PROGRAMA and smrpaap_area=smracaa_area
    and   smrpaap_area like '%'||lpad('1',2,'0')||'%'
    and   ssbsect_term_code=PERIODO and ssbsect_subj_code=smracaa_subj_code
    and   ssbsect_crse_numb=smracaa_crse_numb_low and ssbsect_keyword_index_id=smrpaap_program
    and   ssbsect_term_code=ssrblck_term_code and ssbsect_crn=ssrblck_crn
    and   substr(ssrblck_blck_code,7,1)=substr(TURNO,1,1)
    and   substr(ssrblck_blck_code,1,1)=GRADO;
else
    OPEN c_out_existe_bloque FOR
    select count(distinct ssbsect_crn) CRNS, nvl(sum(ssbsect_enrl),0) INSCRITOS
    from smracaa, smrpaap, ssbsect, ssrblck
    where smrpaap_program=PROGRAMA and smrpaap_area=smracaa_area
    and   smrpaap_area like '%'||GRADO||'%'
    and   ssbsect_term_code=PERIODO and ssbsect_subj_code=smracaa_subj_code
    and   ssbsect_crse_numb=smracaa_crse_numb_low and ssbsect_keyword_index_id=smrpaap_program
    and   ssbsect_term_code=ssrblck_term_code and ssbsect_crn=ssrblck_crn
    and   substr(ssrblck_blck_code,8,1)=substr(TURNO,1,1)
    and   substr(ssrblck_blck_code,1,2)=GRADO;
end if;

RETURN(c_out_existe_bloque);

END F_EXISTE_BLOQUE;

FUNCTION F_ALUMNOS_PARCIAL(PERIODO varchar2, CRN varchar2,  PARCIAL varchar2)  RETURN PKG_UTEG.cursor_alumnos_parcial

AS c_out_alumnos_parcial PKG_UTEG.cursor_alumnos_parcial;

BEGIN

OPEN c_out_alumnos_parcial FOR
select spriden_id Matricula, spriden_first_name Nombre, spriden_last_name Apellidos, 
(select count(*) from skrattr
where skrattr_term_code=shrgcom_term_code and skrattr_crn=shrgcom_crn
and   trunc(skrattr_date) between trunc(sfrrsts_start_date) and trunc(sfrrsts_end_date)+1
and   skrattr_attend_ind='N') No_Faltas ,
(select count(*) from tbraccd
 where tbraccd_pidm=shrmrks_pidm and tbraccd_term_code=shrmrks_term_code
 and   tbraccd_detail_code in (select tbbdetc_detail_code from tbbdetc where tbbdetc_dcat_code in ('FEE','TUI'))
 and   tbraccd_balance > 0 and trunc(tbraccd_effective_date) >= trunc(sysdate)) No_adeudos,
shrgcom_weight Ponderacion, shrmrks_grde_code Calificacion, shrgcom_name parcial, sfrrsts_start_date f_inicio, sfrrsts_end_date f_fin
from shrmrks, spriden, shrgcom, sfrrsts, ssbsect
where shrgcom_term_code=PERIODO and shrgcom_crn=CRN and substr(shrgcom_name,1,1)=PARCIAL
and   shrmrks_term_code=shrgcom_term_code and shrgcom_id=shrmrks_gcom_id
and   spriden_pidm=shrmrks_pidm and spriden_change_ind is null
and   ssbsect_term_code=shrgcom_term_code and ssbsect_crn=shrgcom_crn
and    sfrrsts_term_code=shrgcom_term_code and sfrrsts_ptrm_code=ssbsect_ptrm_code
and   substr(shrgcom_name,1,1)=substr(sfrrsts_rsts_code,1,1)
order by 2,3;

RETURN(c_out_alumnos_parcial);

END F_ALUMNOS_PARCIAL;

PROCEDURE FECHAS_INASISTENCIA (PERIODO varchar2, CRN varchar2) is

fecha varchar2(10);
dia   number;
f_semana varchar2(10);
clase varchar2(1);
contador number;

BEGIN

    delete from SZTFECH
    where sztfech_periodo=PERIODO and sztfech_crn=CRN;
    
    fecha:=to_char(sysdate,'dd/mm/yyyy');

    select DECODE(RTRIM(LTRIM(to_char(to_date(fecha,'dd/mm/yyyy'), 'DAY', 'NLS_DATE_LANGUAGE=SPANISH'))),
    'LUNES', 1, 'MARTES', 2, 'MIÉRCOLES', 3, 'JUEVES', 4,
    'VIERNES', 5, 'S�?BADO', 6, 7) into dia
    from dual;
    
    dbms_output.put_line('fecha:'||fecha||' dia:'||dia);

    for f in 1..7 loop
    
    if f < dia then
    
        f_semana:=to_char(to_date(fecha,'dd/mm/yyyy')-(dia-f));
        
    end if;
    
    if f = dia then
    
        f_semana:=to_char(to_date(fecha,'dd/mm/yyyy'));
    
    end if;
    
    if f > dia then
    
        f_semana:=to_char(to_date(fecha,'dd/mm/yyyy')+(f-dia));
   
    end if;
    
    if f=1 then
        select count(*) into contador from ssrmeet
        where ssrmeet_term_code=periodo and ssrmeet_crn=crn
        and   ssrmeet_mon_day='M';
    end if;
    
    if f=2 then
        select count(*) into contador from ssrmeet
        where ssrmeet_term_code=periodo and ssrmeet_crn=crn
        and   ssrmeet_tue_day='T';
    end if;
    
    if f=3 then
        select count(*) into contador from ssrmeet
        where ssrmeet_term_code=periodo and ssrmeet_crn=crn
        and   ssrmeet_wed_day='W';
    end if;
    
    if f=4 then
        select count(*) into contador from ssrmeet
        where ssrmeet_term_code=periodo and ssrmeet_crn=crn
        and   ssrmeet_thu_day='R';
    end if;
    
    if f=5 then
        select count(*) into contador from ssrmeet
        where ssrmeet_term_code=periodo and ssrmeet_crn=crn
        and   ssrmeet_fri_day='F';
    end if;
    
    if f=6 then
        select count(*) into contador from ssrmeet
        where ssrmeet_term_code=periodo and ssrmeet_crn=crn
        and   ssrmeet_mon_day='S';
    end if;
    
    if f=7 then
        select count(*) into contador from ssrmeet
        where ssrmeet_term_code=periodo and ssrmeet_crn=crn
        and   ssrmeet_sun_day='U';
    end if;
    

    if contador > 0 then
        clase:='S';
    else
        clase:='N';
    end if;
    
    dbms_output.put_line('dia semana:'||f||' fecha:'||f_semana||' contador:'||contador||' clase:'||clase);
    
    insert into SZTFECH values(f,f_semana,clase,PERIODO,CRN);
    
    end loop;

commit;

END FECHAS_INASISTENCIA;

FUNCTION F_FECHAS_INASISTENCIA(PERIODO varchar2, CRN varchar2)  RETURN PKG_UTEG.cursor_fechas_inasistencia

AS c_out_fechas_inasistencia PKG_UTEG.cursor_fechas_inasistencia;

BEGIN
   
OPEN c_out_fechas_inasistencia FOR
select SZTFECH_DIA Dia,
SZTFECH_FECHA Fecha,
SZTFECH_CLASE Clase
from SZTFECH
where sztfech_periodo=PERIODO and sztfech_crn=CRN
order by 1;

RETURN(c_out_fechas_inasistencia);

END F_FECHAS_INASISTENCIA;

FUNCTION F_LISTA_INASISTENCIA(PERIODO varchar2, CRN varchar2)  RETURN PKG_UTEG.cursor_lista_inasistencia

AS c_out_lista_inasistencia PKG_UTEG.cursor_lista_inasistencia;

BEGIN
   
OPEN c_out_lista_inasistencia FOR
select spriden_id Matricula, spriden_first_name||' '||spriden_last_name Nombre
from sfrstcr, spriden
where sfrstcr_term_code=PERIODO and sfrstcr_crn=CRN
and   sfrstcr_rsts_code='RE'
and   sfrstcr_pidm=spriden_pidm and spriden_change_ind is null
order by 2;

RETURN(c_out_lista_inasistencia);

END F_LISTA_INASISTENCIA;

FUNCTION F_CALIFICACIONES_PARCIALES(periodo varchar2, crn varchar2) RETURN PKG_UTEG.cursor_calif_par

AS c_out_calif_par PKG_UTEG.cursor_calif_par;

BEGIN

    OPEN c_out_calif_par FOR
    select smrprle_program_desc programa, 
    substr(sgrsatt_atts_code,2,1) grado,
    shrgcom_name parcial,
    sirasgn_crn clave_grupo,
    sgbstdn_rate_code turno,
    (select spriden_id from spriden a where sirasgn_pidm = a.spriden_pidm and spriden_change_ind is null) matricula_prof, 
    (select a.spriden_first_name||' '||a.spriden_last_name from spriden a where sirasgn_pidm = a.spriden_pidm and spriden_change_ind is null) nombre_prof, 
    ssbsect_subj_code||' '||ssbsect_crse_numb clave_materia, 
    ssbsect_crse_title nombre_materia,
    shrgcom_term_code ciclo,
    spriden_id matricula_alumno,
    spriden_first_name||' '||spriden_last_name nombre_alumno, 
    (select count(*) 
    from skrattr
    where skrattr_term_code=shrgcom_term_code and skrattr_crn=shrgcom_crn
    and   trunc(skrattr_date) between trunc(sfrrsts_start_date) and trunc(sfrrsts_end_date)
    and   skrattr_attend_ind='N') No_Faltas,
    shrmrks_grde_code calif_no,
    shrgrde_abbrev calif_letra
    from sfrstcr
    inner join spriden on spriden_pidm=sfrstcr_pidm and spriden_change_ind is null and sfrstcr_term_code = periodo and sfrstcr_rsts_code='RE' and sfrstcr_crn= crn --'1001'  '202420'
    inner join sgbstdn on spriden_pidm = sgbstdn_pidm
    inner join shrgcom on shrgcom_term_code=sfrstcr_term_code and shrgcom_crn=sfrstcr_crn --and shrgcom_name = parcial --'1P'
    inner join sirasgn on sirasgn_term_code = shrgcom_term_code and sirasgn_crn = shrgcom_crn
    inner join ssbsect on ssbsect_term_code=sfrstcr_term_code and ssbsect_crn=sfrstcr_crn 
    inner join sfrrsts on sfrrsts_term_code=shrgcom_term_code and sfrrsts_ptrm_code=ssbsect_ptrm_code and substr(shrgcom_name,1,1)=substr(sfrrsts_rsts_code,1,1)
    inner join shrmrks on shrmrks_term_code=shrgcom_term_code and shrmrks_crn=shrgcom_crn and shrgcom_id=shrmrks_gcom_id and shrmrks_pidm=sfrstcr_pidm
    left  join shrgrde on shrgrde_code = shrmrks_grde_code and shrgrde_levl_code = sgbstdn_levl_code
    inner join smrprle on ssbsect_keyword_index_id = smrprle_program
    inner join sgrsatt on sgrsatt_pidm = sfrstcr_pidm and sfrstcr_term_code = shrtckn_term_code
    inner join stvatts on stvatts_code = sgrsatt_atts_code
    order by 3,4,11 ASC;
    
    return(c_out_calif_par);

END F_CALIFICACIONES_PARCIALES;

PROCEDURE  ACTUALIZA_CALIF_PARCIAL (PERIODO varchar2, CRN varchar2, ID_ESTU varchar2, PARCIAL varchar2, ID_DOC varchar2, CALI varchar2, PROGRAMA varchar2) is

pidm_estu number;
pidm_doc  number;
calificacion decimal(4,1);
min_calif number;
calif_rep number;
porc_faltas number;
ptrm_code varchar2(4);
sesiones number;
No_Faltas number;
mensaje varchar2(20);

cursor a1 is
select shrgcom_name parcial, shrgcom_weight peso, nvl(to_number(shrmrks_grde_code),0) calif
from shrgcom, shrmrks
where shrgcom_term_code=PERIODO and shrgcom_crn=CRN
and   shrmrks_term_code=shrgcom_term_code and shrmrks_crn=shrgcom_crn
and   shrmrks_gcom_id=shrgcom_id and shrmrks_pidm=pidm_estu;

BEGIN

-- Obtiene pidm del alumno
select spriden_pidm into pidm_estu from spriden
where spriden_id=ID_ESTU and spriden_change_ind is null;
-- Obtiene pidm del docente
select spriden_pidm into pidm_doc from spriden
where spriden_id=ID_DOC and spriden_change_ind is null;

-- Obtienen calificación mínima por programa
select to_number(smbpgen_grde_code_min) into min_calif
from smbpgen
where smbpgen_program=PROGRAMA;

-- Obtiene Parte de periodo del CRN
select ssbsect_ptrm_code into ptrm_code from ssbsect
where ssbsect_term_code=PERIODO and ssbsect_crn=CRN;

dbms_output.put_line('pidm:'||pidm_estu);
update shrmrks set shrmrks_grde_code=CALI,  shrmrks_marker=pidm_doc, shrmrks_activity_date=sysdate
where shrmrks_term_code=PERIODO and shrmrks_crn=CRN
and   shrmrks_gcom_id in (select shrgcom_id from shrgcom where shrmrks_term_code=shrgcom_term_code and shrmrks_crn=shrgcom_crn
                            and shrgcom_name=PARCIAL)
and   shrmrks_pidm = pidm_estu;

calificacion:=0;
for c in a1 loop

    calificacion:=calificacion+(c.calif * (c.peso/100));
    dbms_output.put_line('peso:'||c.peso||' calif:'||c.calif||' suma:'||calificacion);

end loop;

select max(shrgrde_quality_points) into calif_rep from shrgrde, smrprle
    where smrprle_program=PROGRAMA
    and shrgrde_levl_code=smrprle_levl_code and shrgrde_passed_ind='N';
    
if calificacion < min_calif then -- Calificación menor a calificación mínima para aprobar
   
   calificacion:=calif_rep;
else
    -- Obtiene el porcentaje requerido de faltas
    select  CASE SYS.ANYDATA.getTypeName(gorsdav_value) 
                            WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(gorsdav_value) 
                            WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(gorsdav_value))
                            WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(gorsdav_value), 'DD-MON-YYYY') 
                        END   into porc_faltas
                from gorsdav, smrprle
                where smrprle_program=PROGRAMA
                and  gorsdav_table_name='STVLEVL' and gorsdav_attr_name='FA_SIN_DER' 
                and gorsdav_pk_parenttab='UTG'||chr(1)||smrprle_levl_code;
    -- Obtiene número total de faltas 
    select count(*) into No_Faltas
    from skrattr
    where skrattr_term_code=PERIODO and skrattr_crn=CRN
    and   skrattr_attend_ind='N';
    -- Obtiene numero de sesiones del CRN
--    select PKG_UTEG.NUMERO_SESIONES(PERIODO,CRN) into sesiones from dual;
    
    if porc_faltas < (No_faltas*100/sesiones) then
       calificacion:=calif_rep;
       mensaje:='REP_FALTAS';
    else
        calificacion:=round(calificacion,0);
        mensaje:=null;
    end if;
end if;

update sfrstcr set sfrstcr_grde_code=to_Char(calificacion), sfrstcr_data_origin=mensaje
where sfrstcr_term_code=PERIODO and sfrstcr_crn=CRN
and   sfrstcr_pidm=pidm_estu;

commit;

END ACTUALIZA_CALIF_PARCIAL;

function NUMERO_SESIONES(PERIODO varchar2, CRN varchar2) return number is 

f_inicio date;
f_fin    date;
dias number;
contador number; day_number number;
sesiones number;
ptrm_code varchar2(4);

begin

    -- Obtiene Parte de periodo del CRN
    select ssbsect_ptrm_code into ptrm_code from ssbsect
    where ssbsect_term_code=PERIODO and ssbsect_crn=CRN;

    -- Obtiene fecha de inicio y termino de parte de periodo
    select sobptrm_start_date, sobptrm_end_date into f_inicio, f_fin
    from sobptrm
    where sobptrm_term_code=periodo and sobptrm_ptrm_code=ptrm_code;
    
    dias:= f_fin - f_inicio;
    f_inicio:=f_inicio-1;
    
    dbms_output.put_line('número dias:'||dias);
    sesiones:=0;
    for f in 1..dias loop
      --  dbms_output.put_line('fecha:'||to_char(f_inicio+f,'dd/mm/yyyy'));
        select DECODE(RTRIM(LTRIM(to_char(to_date(f_inicio+f,'dd/mm/yyyy'), 'DAY', 'NLS_DATE_LANGUAGE=SPANISH'))),
        'LUNES', 1, 'MARTES', 2, 'MIÉRCOLES', 3, 'JUEVES', 4,
        'VIERNES', 5, 'S�?BADO', 6, 7) into day_number
        from dual;
              
        -- Obtiene horario del CRN y Fecha 
        
        if day_number= 1 then
            select count(*) into contador
            from ssrmeet
            where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
            and   ssrmeet_mon_day='M';
        end if;
        
        if day_number= 2 then
            select count(*) into contador
            from ssrmeet
            where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
            and   ssrmeet_tue_day='T';

        end if;
        
        if day_number= 3 then
            select count(*) into contador
            from ssrmeet
            where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
            and   ssrmeet_wed_day='W';
        end if;
        
        if day_number= 4 then
            select count(*) into contador
            from ssrmeet
            where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
            and   ssrmeet_thu_day='R';
        end if;
        
        if day_number= 5 then
            select count(*) into contador
            from ssrmeet
            where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
            and   ssrmeet_fri_day='F';
        end if;
        
        if day_number= 6 then
            select count(*) into contador
            from ssrmeet
            where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
            and   ssrmeet_sat_day='S';
        end if;
        
        if day_number= 7 then
            select count(*) into contador
            from ssrmeet
            where ssrmeet_term_code=PERIODO and ssrmeet_crn=CRN
            and   ssrmeet_sun_day='U';
        end if;
        
        sesiones:= sesiones+contador;
        
        dbms_output.put_line('FEcha:'||to_char(f_inicio+f,'dd/mm/yyyy')||' dia:'||day_number||' contador:'||contador||' sesiones:'||sesiones);

    
    end loop;

return sesiones;

end NUMERO_SESIONES;


FUNCTION F_INSERTA_CAL_EXT (matricula varchar2, term_code varchar2, crn varchar2, grade_code varchar2) return varchar2

     IS
     
     vl_pidm number := null;
     vl_msje varchar2(200);
     vl_return varchar2(200);
     vl_contexto varchar2(3):=Null;
     vl_matricula varchar2(9);
     
    
     
    BEGIN
    
        BEGIN
        select g$_vpdi_security.g$_vpdi_get_inst_code_fnc 
        into vl_contexto
        from dual;
        END;
    
    IF matricula IS NULL THEN
        vl_return:='Error : Matricula nula';
        return(vl_return);
        
    ELSE
    
         vl_pidm:= Null;
         vl_return:=Null;         
              
                BEGIN
                 
                  BEGIN
                    SELECT SPRIDEN_PIDM
                    INTO vl_pidm
                    FROM SPRIDEN
                    WHERE 1=1
                    AND SPRIDEN_ID = matricula
                    AND SPRIDEN_CHANGE_IND IS NULL;
                    EXCEPTION WHEN OTHERS THEN
                    vl_pidm:= 0;
                    vl_return:='Error : Alumno no encontrado o matricula incorrecta';
                    --dbms_output.put_line('PIDM: '||vl_pidm);
                  END;
                
                       IF vl_pidm = 0 THEN 
                        
                            return(vl_return);
                                    
                        ELSE                            
                             vl_return:=Null;
                              BEGIN
                                UPDATE SFRSTCR 
                                SET SFRSTCR_GRDE_CODE = grade_code,
                                SFRSTCR_ACTIVITY_DATE = trunc(sysdate), 
                                SFRSTCR_USER ='PORTAL' 
                                WHERE SFRSTCR_TERM_CODE = term_code
                                AND SFRSTCR_CRN = crn
                                AND SFRSTCR_PIDM = vl_pidm; 
                             vl_return:='Exito';
                             EXCEPTION WHEN OTHERS THEN
                                vl_msje:=sqlerrm;
                                vl_return:='Error : al asignar calificación'||vl_msje;
                              END;
                            COMMIT;                
                        END IF;
            END;
     return(vl_return);
     --dbms_output.put_line(vl_return);
 END IF; 
EXCEPTION WHEN OTHERS THEN
vl_msje:=sqlerrm;
vl_return:='Error general'||vl_msje;
return(vl_return);
END F_INSERTA_CAL_EXT;


FUNCTION F_REPORTE_CAL_FINALES (iden varchar2, periodo varchar2, parcial varchar2, crn varchar2) RETURN PKG_UTEG.cursor_calif_fin

AS c_out_calif_fin PKG_UTEG.cursor_calif_fin;

BEGIN

OPEN c_out_calif_fin FOR
    select 
    smrprle_program_desc programa, 
    substr(sgrsatt_atts_code,2,1) grado,
    shrtckn_crn clave_grupo,
    sgbstdn_rate_code turno,
    (select spriden_id from spriden a where sirasgn_pidm = a.spriden_pidm and spriden_change_ind is null) matricula_prof, 
    (select a.spriden_first_name||' '||a.spriden_last_name from spriden a where sirasgn_pidm = a.spriden_pidm and spriden_change_ind is null) nombre_prof, 
    shrtckn_subj_code||' '||shrtckn_crse_numb clave_materia, 
    shrtckn_crse_title nombre_materia,
    shrtckg_term_code ciclo,
    spriden_id matricula_alumno,
    spriden_first_name||' '||spriden_last_name nombre_alumno,
    (select count(*) from skrattr
    where 1=1
    and skrattr_pidm = shrtckn_pidm --569723
    and skrattr_term_code = shrtckn_term_code --'202420'
    and skrattr_attend_ind = 'N'
    and skrattr_crn = shrtckn_crn--'1001';
    )No_Faltas,
    shrtckg_grde_code_final calif_no,
    shrgrde_abbrev calif_letra
    from
    shrtckg
    inner join spriden on spriden_pidm = shrtckg_pidm and spriden_change_ind is null
    inner join sgbstdn on spriden_pidm = sgbstdn_pidm
    inner join shrtckn on shrtckn_pidm = shrtckg_pidm and shrtckn_term_code = shrtckg_term_code and shrtckn_seq_no = shrtckg_tckn_seq_no and shrtckg_gchg_code in ('AC','OE', 'RC') and shrtckn_term_code = periodo and shrtckn_crn = crn
    inner join sirasgn on sirasgn_term_code = shrtckn_term_code and sirasgn_crn = shrtckn_crn and sirasgn_pidm = (select spriden_pidm
                                                                                                                  from spriden where spriden_id = iden  --'G00122869'
                                                                                                                   and spriden_change_ind is null)
    inner join shrgrde on shrgrde_code = shrtckg_grde_code_final and shrgrde_levl_code = sgbstdn_levl_code and shrgrde_vpdi_code ='UTG'
    inner join smrprle on sgbstdn_program_1 = smrprle_program
    inner join sgrsatt on sgrsatt_pidm = shrtckg_pidm and sgrsatt_term_code_eff = shrtckn_term_code
    inner join stvatts on stvatts_code = sgrsatt_atts_code;
    
    RETURN(c_out_calif_fin);
    
 END F_REPORTE_CAL_FINALES;
 
 
FUNCTION F_ALUMNOS_GRUPO  (periodo varchar2, crn varchar2) RETURN PKG_UTEG.cursor_alumnos_crn

AS c_out_alumnos_crn PKG_UTEG.cursor_alumnos_crn;

BEGIN

OPEN c_out_alumnos_crn FOR
select spriden_id matricula,
spriden_first_name||' '||spriden_last_name nombre_alumno,
shrgcom_id parcial,
sfrstcr_crn grupo
From spriden, sfrstcr, shrmrks, shrgcom
Where 1=1
and spriden_pidm = sfrstcr_pidm
and spriden_change_ind is null
and sfrstcr_pidm = shrmrks_pidm
and sfrstcr_term_code = shrmrks_term_code
and sfrstcr_crn = shrmrks_crn
and shrmrks_term_code = shrgcom_term_code
and shrmrks_crn = shrgcom_crn
and shrmrks_gcom_id = shrgcom_id
and sfrstcr_term_code = periodo-- '202420'
and sfrstcr_crn  = crn --'1001'
order by 3,4 asc;


RETURN(c_out_alumnos_crn);

END F_ALUMNOS_GRUPO;
 
 PROCEDURE  GENERA_CRN_EXT  is

periodo_ext varchar2(6);
periodo_base varchar2(6);
tipo_per_ext varchar2(1);
tipo_per_base varchar2(1);
crn number;
title varchar2(30);
creditos decimal(6,2);
f_inicio date;
f_fin    date;
semanas  number;
teo     number;
prac    number;
otr     number;
cont    number;
nulo varchar2(1) default null;
SCHD_CODE varchar2(4);
INSM_CODE varchar2(4);
GSCH_NAME varchar2(10);
GMOD_CODE varchar2(1);

contador number;

cursor a2 is
select stvterm_code periodo_ext,stvterm_trmt_code tipo_per_ext  from stvterm
where stvterm_trmt_code in ('D','E','F')
and   trunc(stvterm_start_date)=trunc(sysdate);

cursor a1(per_base varchar2) is
select shrtckn_subj_code SUBJ_CODE,shrtckn_crse_numb CRSE_NUMB, shrtckn_crn, shrtckn_crse_title TITLE,
ssbsect_camp_code campus,ssbsect_keyword_index_id programa, count(*) Total_alumnos
from shrtckn, shrtckg  , ssbsect , smrprle, shrgrde
where shrtckn_term_code=per_base and shrtckg_term_code=shrtckn_term_code  and shrtckg_pidm=shrtckn_pidm
and shrtckg_tckn_seq_no=shrtckn_seq_no 
and ssbsect_term_code=shrtckn_term_code and ssbsect_crn=shrtckn_crn
and ssbsect_keyword_index_id=smrprle_program and smrprle_levl_code=shrgrde_levl_code
and shrtckg_grde_code_final=shrgrde_code and shrgrde_passed_ind='N'
--order by shrtckn_pidm, shrtckn_pidm;
group by shrtckn_subj_code, shrtckn_crse_numb, shrtckn_crn, shrtckn_crse_title, ssbsect_camp_code,ssbsect_keyword_index_id;


begin



for x in a2 loop

    if x.tipo_per_ext='D' then tipo_per_base:='C'; end if;
    if x.tipo_per_ext='E' then tipo_per_base:='S'; end if;
    if x.tipo_per_ext='F' then tipo_per_base:='T'; end if;
    
    select max(stvterm_code) into periodo_base from stvterm
    where stvterm_trmt_code=tipo_per_base and stvterm_code < x.periodo_ext;
    
    select count(*) into contador
    from ssbsect
    where ssbsect_term_code=x.periodo_ext;
    
    if contador = 0 then

    for c in a1(periodo_base) loop
    
        -- Crear CRN
        update sobterm set sobterm_crn_oneup=sobterm_crn_oneup+1
        where sobterm_term_code=x.periodo_ext;
        
        select sobterm_crn_oneup into crn from sobterm
        where sobterm_term_code=x.periodo_ext;
    
    
    
        select SCBCRSE_TITLE, SCBCRSE_LEC_HR_LOW, SCBCRSE_LAB_HR_LOW, SCBCRSE_OTH_HR_LOW, SCBCRSE_CONT_HR_LOW
        into title, teo, prac, otr, cont
        from scbcrse
        where scbcrse_subj_code=c.SUBJ_CODE and scbcrse_crse_numb=c.CRSE_NUMB;
    
        begin
         select SCBCRSE_CREDIT_HR_LOW into creditos 
            from scbcrse
            where scbcrse_subj_code=c.SUBJ_CODE and scbcrse_crse_numb=c.CRSE_NUMB;  
        exception when others then
        creditos:=0;
        end;
    
        select sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
        into f_inicio, f_fin, semanas
        from sobptrm
        where sobptrm_term_code=x.periodo_ext and sobptrm_ptrm_code='1';
    
        SELECT 
        SCRSCHD_SCHD_CODE,
        SCRSCHD_INSM_CODE
        INTO 
        SCHD_CODE,
        INSM_CODE 
        FROM SCRSCHD C1
        WHERE C1.SCRSCHD_SUBJ_CODE = c.SUBJ_CODE
        AND C1.SCRSCHD_CRSE_NUMB   = c.CRSE_NUMB
        AND C1.SCRSCHD_EFF_TERM   = ( select max(C2.SCRSCHD_EFF_TERM)
                                      FROM SCRSCHD C2
                                     WHERE C2.SCRSCHD_SUBJ_CODE = c.SUBJ_CODE
                                       AND C2.SCRSCHD_CRSE_NUMB   =c.CRSE_NUMB
                                       AND C2.SCRSCHD_EFF_TERM <= x.periodo_ext
                                  );
    
        -- Obtiene Escala de Calificación
        select  CASE SYS.ANYDATA.getTypeName(gorsdav_value) 
                                WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(gorsdav_value) 
                                WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(gorsdav_value))
                                WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(gorsdav_value), 'DD-MON-YYYY') 
                            END  into GSCH_NAME
                    from gorsdav, sobcurr
                    where sobcurr_camp_code=c.campus and sobcurr_program=c.programa
                    and  gorsdav_table_name='STVLEVL' and gorsdav_attr_name='ESCLA_CALI' 
                    and gorsdav_pk_parenttab='UTG'||chr(1)||sobcurr_levl_code;
                    
        -- Obtiene Modo de Calificación
        select  CASE SYS.ANYDATA.getTypeName(gorsdav_value) 
                                WHEN 'SYS.VARCHAR2' THEN SYS.ANYDATA.accessVarchar2(gorsdav_value) 
                                WHEN 'SYS.NUMBER'   THEN TO_CHAR(SYS.ANYDATA.accessNumber(gorsdav_value))
                                WHEN 'SYS.DATE'     THEN TO_CHAR(SYS.ANYDATA.accessDate(gorsdav_value), 'DD-MON-YYYY') 
                            END  into GMOD_CODE
                    from gorsdav, sobcurr
                    where sobcurr_camp_code=c.campus and sobcurr_program=c.programa
                    and  gorsdav_table_name='STVLEVL' and gorsdav_attr_name='MOD_CALI' 
                    and gorsdav_pk_parenttab='UTG'||chr(1)||sobcurr_levl_code;
    
        insert into ssbsect values(
        x.periodo_ext,  		-- Clave de periodo en dónde se crea el CRN
        CRN,				-- Se obtiene de SOBTERM_CRN_ONEUP +1 buscando por SOBTERM_TERM_CODE
        '1',		-- Regla de negocio para poner la parte de periodo
        c.SUBJ_CODE  ,		-- Subject de la matera (SUBJ_CODE)
        c.CRSE_NUMB  ,		-- Course de la materia (CRSE_NUMB)
        'A',		-- Definir valor para la sección (puede ser la letra del Bloque)
        'A',      		-- Valor por default 'A' Activo
        SCHD_CODE,      		-- Tipo de hora Teórico, Práctico Tabla (STVSCHD)
        c.campus,    		-- Clave de Campus
        TITLE       ,  	-- Nombre Materia (SCBCRSE_TITLE)
        creditos    , 	-- Créditos (SMRACAA_MAX_CRED_CRSE) 
        1       , 	-- Valor por default 1
        GMOD_CODE             , 	-- Tipo de Calificación (S=Standard, G=Base 100)
        nulo              , 	-- Valor por defaul null
        nulo               , 	-- Valor por defaul null
        nulo              , 	-- Valor por defaul null 
        'Y'               , 	-- Valor por default 'Y'
        'Y'           ,	-- Valor por default 'Y'
        nulo               ,	-- Valor por defaul null 
        0             ,	-- Valor por default 0 (cero)
        0             ,	-- Valor por default 0 (cero) 
        0              ,	-- Valor por default 0 (cero) 
        50               ,	-- Capacidad máxima del grupo
        0                   ,	-- Valor por default 0 (cero) 
        50            ,	-- Capacidad máxima del grupo
        0         ,	-- Valor por default 0 (cero)
        0            ,	-- Valor por default 0 (cero)
        f_inicio      ,   -- Fecha Inicio (SOBPTRM_START_DATE) dependiendo de la parte de periodo (PTRM_CODE)
        sysdate        , -- Fecha de registro
        f_inicio        ,   -- Fecha Inicio (SOBPTRM_START_DATE) dependiendo de la parte de periodo (PTRM_CODE)
        f_fin       ,   -- Fecha Fin    (SOBPTRM_END_DATE) dependiendo de la parte de periodo (PTRM_CODE)
        semanas,               -- SOBPTRM_PTRM_WEEKS dependiendo de la parte de periodo (PTRM_CODE)
        nulo           ,	-- Valor por default null
        0          ,	-- Valor por default 0 (cero)
        0             ,	-- Valor por default 0 (cero)
        0             ,	-- Valor por default 0 (cero)
        teo                 ,	-- Horas teóricas (SCBCRSE_LEC_HR_LOW)
        prac                 ,	-- Horas teóricas (SCBCRSE_LAB_HR_LOW)
        otr                 ,	-- Horas teóricas (SCBCRSE_OTH_HR_LOW)
        cont                ,	-- Horas teóricas (SCBCRSE_CONT_HR_LOW)
        nulo              ,	-- Valor por default null 
        nulo              ,	-- Valor por default null 
        nulo          ,	-- Valor por default null 
        nulo      ,	-- Valor por default null 
        nulo      ,	-- Valor por default null 
        nulo      ,	-- Valor por default null 
        0          ,	-- Valor por default 0 (cero)
        'Y'            ,	-- Valor por default 'Y'
        'N'   ,	-- Valor por default 'N'
        GSCH_NAME              ,	-- Regla para obtener la escala númerica de Calificación
        nulo           ,	-- Valor por default null 
        nulo         ,	-- Valor por default null 
        INSM_CODE, ----p_insm_code,   -- Regla para obtener la modalidad del grupo materia. Tabla (GTVINSM)
        nulo          ,	-- Valor por default null
        nulo            ,	-- Valor por default null
        nulo ,	-- Valor por default null
        nulo ,	-- Valor por default null
        nulo              ,	-- Valor por default null
        nulo        ,	-- Valor por default null
        0   ,	-- Valor por default 0 (cero)
        'INTERFAZ'            , -- Valor por default Usuario 'INTERFAZ'
        'AUTM'                ,	-- Valor por default Usuario 'AUTM'
        nulo               ,	-- Regla de negocio para colocar el socio de integración (MOODL) desde inicio del CRN o proceso posterior
        'B'  ,	-- Valor por default 'B'
        c.programa,
        nulo,
        nulo,
        nulo,
        nulo,
        nulo,
        nulo,
        nulo,
        'N',
        nulo,
        nulo);
        
    
    end loop;
    
    end if;

end loop;
 commit;


END GENERA_CRN_EXT;

--�ltimos Cambios 
    
END pkg_UTEG;
