select * from Rmc_Stg_Account_Contact
WHERE EXTERNALID__C IN (
'16203202070',
'17605577737',
'23396564782')
;

select * from RMC_STG_PREMISE_ACCOUNT
WHERE EXTERNALID__C IN (
'16203202070',
'17605577737',
'23396564782')
;


select * from RMC_STG_PREMISE_ACCOUNT

--CREATE TABLE Rmc_Stg_Account_Contact_bck_seg1 as select * from Rmc_Stg_Account_Contact
--create table RMC_STG_PREMISE_ACCOUNT_seg1 as select * from RMC_STG_PREMISE_ACCOUNT

create table Rmc_Stg_Account_Contact_inc as select * from Rmc_Stg_Account_Contact where rownum<=1000
create table RMC_STG_PREMISE_ACCOUNT_inc as select * from Rmc_Stg_Account_Contact where 1=2

insert into RMC_STG_PREMISE_ACCOUNT_inc
select * from RMC_STG_PREMISE_ACCOUNT a1 where a1.id_account in (
select * from (select distinct a1.id_account from RMC_STG_PREMISE_ACCOUNT  a1) where rownum<=1000)
--delete from RMC_STG_PREMISE_ACCOUNT_inc;;;
;


select * from Rmc_Stg_Account_Contact a 
left join Rmc_Stg_Account_Contact_inc b on a.EXTERNALID__C=b.EXTERNALID__C
where  b.EXTERNALID__C is null and a.id_mongo is not  null

--4374 -- sem id Mongo 
-- 346000 -- com id_mongo
-- 345991 -- carregado 

--- contagem de quanto existe na stage

select COUNT(1) from Rmc_Stg_Account_Contact a 
left join Rmc_Stg_Account_Contact_inc b on a.EXTERNALID__C=b.EXTERNALID__C
where  b.EXTERNALID__C is null and a.id_mongo is not  null

--Comparar a quantidade da consulta comparando documento acima com a quantidade desta consulta, as duas devem ser iguais
select doc_type, count(1) from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
where 
CREATED_USER_ID='2' and SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
group by doc_type

--CPF	345990
--RG	1

--Comparar a quantidade da consulta comparando party_id acima com a quantidade desta consulta, as duas devem ser iguais
select count(1) from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on a.PARTY_ID=c.id_mongo
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
where 
CREATED_USER_ID='2' and SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null

---- 345754

--Clientes que possuem o party_id, diferente do id_mongo

select a.party_id, c.DocumentType__c, c.EXTERNALID__C, c.id_mongo, b.doc_type, b.DOC_NUMBER  from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
where 
CREATED_USER_ID='2' and SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
and a.PARTY_ID!=c.id_mongo

---- validação quantitativo party, identification e individual

select 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN INDIVIDUAL E ON A.PARTY_ID=e.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
where 
CREATED_USER_ID='2' and SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
---
--and c.id_mongo=a.party_id ----345991=345745 -- NOK -- problema na tabela de de/para
--and upper(nvl(c.Type,'customer'))=upper(a.Party_kind) --345991=345987 -OK -- Porém valores do Sfa diferene do esperado
--and c.DOCUMENTTYPE__C=b.doc_type --345991=345991 -OK
--and nvl(c.CPFStatus__c,'a')=nvl(b.cpf_status,'a') --345991=345991 -OK
--and nvl(c.HomeCountry__c,'a')=nvl(E.nationality,'a') --345991=345987 -NOK -- não estava no script de carga
--and c.Name=E.full_name ---345991=345991 -OK
--and c.SpecialTreatment__c=E.special_treatment --345991=345991 -OK
--and c.HasDifferentName__c=E.is_exception_list --345991=345991 -OK
--and upper(nvl(c.NameDivergenceReason__c,'a'))=upper(nvl(E.exception_List_Reason,'a')) ---345991=345991 -OK
--and upper(nvl(c.FirstName,'a'))=upper(nvl(E.first_name,'a')) --345991=345991 -OK
--and upper(nvl(c.LastName,'a'))=upper(nvl(E.last_name,'a')) --345991=345991 -OK
--and nvl(c.Birthdate,'01/01/1900')=nvl(E.birth_date,'01/01/1900') --345991=345991 -OK
--and nvl(c.MotherName__c,'a')=nvl(E.mother_name,'a') --345991=345991 -OK
--and nvl(c.NickName__c,'a')=nvl(E.nick_name,'a')----345991=345991 -OK
--and nvl(c.vlocity_cmt__Gender__c,'a')=nvl(E.gender,'a') --345991=345991 -OK
and to_char(c.LAST_VERIFIED_AT, 'DD/MM/YYYY HH24:MI:SS')=to_char(A.last_verified_at, 'DD/MM/YYYY HH24:MI:SS')----345991=126 --NOK

-- Validação de valores fixos

select 
a.party_type,
a.status_party,
a.golden_record_flag,
a.updated_user_ID,
b.is_primary,
E.Is_Account_Data_Sanitized,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN INDIVIDUAL E ON A.PARTY_ID=e.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
where 
CREATED_USER_ID='2' and SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
group by a.party_type,
a.status_party,
a.golden_record_flag,
a.updated_user_ID,
b.is_primary,
E.Is_Account_Data_Sanitized
----------------- QUANTIDADE DE REGISTROS QUE POSSUEM E-MAIL PREENCHIDO NA STAGE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.EMAIL IS NOT NULL

--325040

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM E-MAIL PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join EMAILCONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
--Left join PHONECONTACT MOB on G.CONTACT_MEDIUM_ID=MOB.CONTACT_MEDIUM_ID
--Left join PHONECONTACT OTH on G.CONTACT_MEDIUM_ID=OTH.CONTACT_MEDIUM_ID
--Left join PHONECONTACT LAN on G.CONTACT_MEDIUM_ID=LAN.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND C.EMAIL=G.EMAIL_ADDRESS---325040=325040 OK
AND UPPER(CASE C.EMAILSTATUS__C WHEN 'Validado' THEN 'digitallyverified'
WHEN'Validado pelo Atendimento'THEN 'manuallyverified'
WHEN 'Expirado' THEN 'expired'
WHEN 'Não Validado' THEN 'notverified'
WHEN'Inválido' THEN 'invalid' ELSE 'a' END) =UPPER(NVL(EMAIL_STATUS,'A'))--325040=325040 OK

-- PREENCHIMENTO PADRÃO

SELECT 
F.medium_type,
F.is_primary,
F.valid_to,
F.source_system,
G.email_type,
COUNT(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join EMAILCONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
--Left join PHONECONTACT MOB on G.CONTACT_MEDIUM_ID=MOB.CONTACT_MEDIUM_ID
--Left join PHONECONTACT OTH on G.CONTACT_MEDIUM_ID=OTH.CONTACT_MEDIUM_ID
--Left join PHONECONTACT LAN on G.CONTACT_MEDIUM_ID=LAN.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND C.EMAIL=G.EMAIL_ADDRESS
GROUP BY
F.medium_type,
F.is_primary,
F.valid_to,
F.source_system,
G.email_type


--- PREENCHIMENTO VALID TO DEVE ESTAR PREENCHIDO APENAS PARA 'digitallyverified' E 'manuallyverified'

SELECT 
EMAIL_STATUS,
F.valid_to,
COUNT(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join EMAILCONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
--Left join PHONECONTACT MOB on G.CONTACT_MEDIUM_ID=MOB.CONTACT_MEDIUM_ID
--Left join PHONECONTACT OTH on G.CONTACT_MEDIUM_ID=OTH.CONTACT_MEDIUM_ID
--Left join PHONECONTACT LAN on G.CONTACT_MEDIUM_ID=LAN.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND C.EMAIL=G.EMAIL_ADDRESS
AND G.EMAIL_STATUS IS NOT NULL
GROUP BY
EMAIL_STATUS,F.valid_to



------------ QUANTIDADE DE REGISTROS QUE POSSUEM MOBILEPHONE PREENCHIDO NA STAGE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.MOBILEPHONE IS NOT NULL
and C.MOBILEPHONE  not like '%@%'

--339570

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM MOBILE PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join PHONECONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND C.MOBILEPHONE IS NOT NULL
AND PHONE_TYPE='mobile' -- 339572
AND REGEXP_REPLACE(C.MOBILEPHONE, '[^0-9]', '')=G.PHONE_NUMBER --- 339570 --339570 OK
AND UPPER(CASE C.CONTACTPHONESTATUS__C WHEN 'Validado' THEN 'digitallyverified'
WHEN'Validado pelo Atendimento'THEN 'manuallyverified'
WHEN 'Expirado' THEN 'expired'
WHEN 'Não Validado' THEN 'notverified'
WHEN'Inválido' THEN 'invalid' ELSE 'a' END) =UPPER(NVL(PHONE_STATUS,'A'))--339570=339570 OK

-- PREENCHIMENTO PADRÃO

SELECT 
F.medium_type,
F.is_primary,
F.source_system,
G.phone_type,
COUNT(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join PHONECONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND C.MOBILEPHONE IS NOT NULL
AND PHONE_TYPE='mobile'
GROUP BY
F.medium_type,
F.is_primary,
F.source_system,
G.phone_type


--- PREENCHIMENTO VALID TO DEVE ESTAR PREENCHIDO APENAS PARA 'digitallyverified' E 'manuallyverified'

SELECT 
PHONE_STATUS,
F.valid_to,
COUNT(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join PHONECONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND C.MOBILEPHONE IS NOT NULL
AND PHONE_TYPE='mobile'
GROUP BY
PHONE_STATUS,F.valid_to


----------------- QUANTIDADE DE REGISTROS QUE POSSUEM fixo PREENCHIDO NA STAGE 
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.OTHERPHONE IS NOT NULL
AND  C.OTHERPHONE NOT LIKE '%@%'
--47040


--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM móvel opcional PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE

SELECT 
count(1)
    
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join PHONECONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.OTHERPHONE IS NOT NULL
AND PHONE_TYPE='landline' ----47040--47040 -- OK
AND REGEXP_REPLACE( C.OTHERPHONE, '[^0-9]', '')=G.PHONE_NUMBER --- 47040 =47040 -- OK

-- PREENCHIMENTO PADRÃO

SELECT 
F.medium_type,
F.is_primary,
F.source_system,
G.phone_type,
COUNT(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join PHONECONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.OTHERPHONE IS NOT NULL
AND PHONE_TYPE='landline' ----47040--47040 -- OK
GROUP BY
F.medium_type,
F.is_primary,
F.source_system,
G.phone_type


----------------- QUANTIDADE DE REGISTROS QUE POSSUEM móvel opcional PREENCHIDO NA STAGE 
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.HOMEPHONE IS NOT NULL

--47435

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM móvel opcional PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join PHONECONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.HOMEPHONE IS NOT NULL
AND PHONE_TYPE='other' ----47435--47435 -- OK
AND REGEXP_REPLACE( C.HOMEPHONE, '[^0-9]', '')=G.PHONE_NUMBER --- 47435 =47435 -- OK


-- PREENCHIMENTO PADRÃO

SELECT 
F.medium_type,
F.is_primary,
F.source_system,
G.phone_type,
COUNT(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CONTACTMEDIUM f ON A.PARTY_ID=f.PARTY_ID
INNER join PHONECONTACT g on g.CONTACT_MEDIUM_ID=f.CONTACT_MEDIUM_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.HOMEPHONE IS NOT NULL
AND PHONE_TYPE='other' ----47435--47435 -- OK
GROUP BY
F.medium_type,
F.is_primary,
F.source_system,
G.phone_type

-------------------------crossreference
----------------- QUANTIDADE DE REGISTROS QUE POSSUEM accountid SFA preenchido 
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.ID_ACCOUNT IS NOT NULL

--345991

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM acoount Id PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.ID_ACCOUNT IS NOT NULL
AND source_column='sfaClientId' ----345991--345991 -- OK
AND C.ID_ACCOUNT=F.source_record_id ----345991--345991 -- OK

-- CAMPOS PADRAO

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM acoount Id PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.ID_ACCOUNT IS NOT NULL
AND source_column='sfaClientId' ----345991--345991 -- OK
AND C.ID_ACCOUNT=F.source_record_id ----345991--345991 -- OK
GROUP BY F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status

----------------- QUANTIDADE DE REGISTROS QUE POSSUEM CONTACT id SFA preenchido 
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.ID_CONTACT IS NOT NULL

--345991

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM CONTACT Id PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.ID_CONTACT IS NOT NULL
AND source_column='sfaContactId' ----345991--345991 -- OK
AND C.ID_CONTACT=F.source_record_id ----345991--345991 -- OK

-- CAMPOS PADRAO

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM acoount Id PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.ID_CONTACT IS NOT NULL
AND source_column='sfaContactId' ----345991--345991 -- OK
AND C.ID_CONTACT=F.source_record_id ----345991--345991 -- OK
GROUP BY F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status

----------------- QUANTIDADE DE REGISTROS QUE POSSUEM nextcontactId id SFA preenchido  stage
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.VIVONEXTCONTACTID__C IS NOT NULL

--280283

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM VIVONEXTCONTACTID__C PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.VIVONEXTCONTACTID__C IS NOT NULL
AND source_column='nextContactId' ----280283--280283 -- OK
AND C.VIVONEXTCONTACTID__C=F.source_record_id -----280283--280283 -- OK

-- CAMPOS PADRAO

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM acoount Id PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.VIVONEXTCONTACTID__C IS NOT NULL
AND source_column='nextContactId' ----280283--280283 -- OK
AND C.VIVONEXTCONTACTID__C=F.source_record_id -----280283--280283 -- OK
GROUP BY F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status


----------------- QUANTIDADE DE REGISTROS QUE POSSUEM VIVONEXTCUSTOMERID__C id SFA preenchido  stage
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.VIVONEXTCUSTOMERID__C IS NOT NULL

--280217

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM VIVONEXTCUSTOMERID__C PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.VIVONEXTCUSTOMERID__C IS NOT NULL
AND source_column='nextClientId' ----280217--280217 -- OK
AND C.VIVONEXTCUSTOMERID__C=F.source_record_id -----280217--280217 -- OK

-- CAMPOS PADRAO

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM nextcliente Id PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.VIVONEXTCUSTOMERID__C IS NOT NULL
AND source_column='nextClientId' ----280217--280217 -- OK
AND C.VIVONEXTCUSTOMERID__C=F.source_record_id -----280217--280217 -- OK
GROUP BY F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status


----------------- QUANTIDADE DE REGISTROS QUE POSSUEM VIVONETID__C id SFA preenchido  stage
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.VIVONETID__C IS NOT NULL

--3

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM VIVONETID__C PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.VIVONETID__C IS NOT NULL
AND source_column='VivoNetId' ----3--3 -- OK
AND C.VIVONETID__C=F.source_record_id ----3--3 -- OK

-- CAMPOS PADRAO

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM vivonet Id PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.VIVONETID__C IS NOT NULL
AND source_column='VivoNetId' ----3--3 -- OK
AND C.VIVONETID__C=F.source_record_id ----3--3 -- OK
GROUP BY F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status

----------------- QUANTIDADE DE REGISTROS QUE POSSUEM SAPECCID__C id SFA preenchido  stage
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.SAPECCID__C IS NOT NULL

--2

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM SAPECCID__C PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.SAPECCID__C IS NOT NULL
AND source_column='SAPECCId' ----2--2 -- OK
AND C.SAPECCID__C=F.source_record_id ----2--2 -- OK

-- CAMPOS PADRAO

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM SAPECCID__C PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.SAPECCID__C IS NOT NULL
AND source_column='SAPECCId' ----2--2 -- OK
AND C.SAPECCID__C=F.source_record_id ----2--2 -- OK
GROUP BY F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status


----------------- QUANTIDADE DE REGISTROS QUE POSSUEM NGINID__C id SFA preenchido  stage
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND  C.NGINID__C IS NOT NULL

--2

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM NGINID__C PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.NGINID__C IS NOT NULL
AND source_column='NGINId' ----2--2 -- OK
AND C.NGINID__C=F.source_record_id ----2--2 -- OK

-- CAMPOS PADRAO

--- ----------------- QUANTIDADE DE REGISTROS QUE POSSUEM NGINID__C PREENCHIDO NA STAGE COM MESMO VALOR NO ORACLE
SELECT 
F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status,
count(1)
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
INNER JOIN CROSSREFERENCE f ON A.PARTY_ID=f.PARTY_ID
left join Rmc_Stg_Account_Contact c on b.DOC_NUMBER=c.EXTERNALID__C
left join Rmc_Stg_Account_Contact_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND   C.NGINID__C IS NOT NULL
AND source_column='NGINId' ----2--2 -- OK
AND C.NGINID__C=F.source_record_id ----2--2 -- OK
GROUP BY F.source_system,
F.source_entity_type,
F.source_column,
F.sync_status

---ENDEREÇO RELACIONAMENTO


SELECT 
DISTINCT A.EXTERNALID__C  
FROM RMC_STG_PREMISE_ACCOUNT  A
LEFT JOIN RMC_STG_PREMISE_ACCOUNT_INC B ON A.EXTERNALID__C=B.EXTERNALID__C
WHERE B.EXTERNALID__C is null and A.id_mongo is  NOT null AND 
(A.ShippingPostalCode IS NOT NULL OR 
A.ShippingCity IS NOT NULL OR 
A.ShippingState IS NOT NULL OR 
A.ShippingCountry IS NOT NULL OR 
A.ShippingIBGECode__c IS NOT NULL OR 
A.ShippingStreet IS NOT NULL OR 
A.ShippingAddressType__c IS NOT NULL OR 
A.ShippingAddressTitle__c IS NOT NULL OR 
A.ShippingNumber__c IS NOT NULL OR 
A.ShippingNeighborhood__c  IS NOT NULL OR 
A.ShippingComplementType1__c IS NOT NULL OR 
A.ShippingComplement1__c IS NOT NULL OR 
A.ShippingComplementType2__c IS NOT NULL OR 
A.ShippingComplement2__c IS NOT NULL OR 
A.ShippingComplementType3__c IS NOT NULL OR 
A.ShippingComplement3__c IS NOT NULL OR 
A.ShippingReferencePoint__c IS NOT NULL OR 
A.ShippingAddressStatus__c IS NOT NULL OR 
A.ShippingCNL__c IS NOT NULL )
-- 2298



SELECT 
DISTINCT b.DOC_NUMBER
from party  a
inner join IDENTIFICATION b on a.PARTY_ID=b.PARTY_ID
left join RMC_STG_PREMISE_ACCOUNT c on b.DOC_NUMBER=c.EXTERNALID__C
left join RMC_STG_PREMISE_ACCOUNT_inc d on c.EXTERNALID__C=d.EXTERNALID__C
WHERE
A.CREATED_USER_ID='2' and A.SOURCE_SYSTEM='salesforce'
and d.EXTERNALID__C is null and c.id_mongo is not  null
AND 
(C.ShippingPostalCode IS NOT NULL OR 
C.ShippingCity IS NOT NULL OR 
C.ShippingState IS NOT NULL OR 
C.ShippingCountry IS NOT NULL OR 
C.ShippingIBGECode__c IS NOT NULL OR 
C.ShippingStreet IS NOT NULL OR 
C.ShippingAddressType__c IS NOT NULL OR 
C.ShippingAddressTitle__c IS NOT NULL OR 
C.ShippingNumber__c IS NOT NULL OR 
C.ShippingNeighborhood__c  IS NOT NULL OR 
C.ShippingComplementType1__c IS NOT NULL OR 
C.ShippingComplement1__c IS NOT NULL OR 
C.ShippingComplementType2__c IS NOT NULL OR 
C.ShippingComplement2__c IS NOT NULL OR 
C.ShippingComplementType3__c IS NOT NULL OR 
C.ShippingComplement3__c IS NOT NULL OR 
C.ShippingReferencePoint__c IS NOT NULL OR 
C.ShippingAddressStatus__c IS NOT NULL OR 
C.ShippingCNL__c IS NOT NULL )
--  2298 - 2281