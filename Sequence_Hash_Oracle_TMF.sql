-- Garantir que a sequência tenha um cache alto para throughput
CREATE SEQUENCE seq_party_counter 
  START WITH 1 
  MAXVALUE 16777215 
  CYCLE 
  CACHE 5000;

/*
 O ObjectId é um valor de 12 bytes gerado automaticamente pelo MongoDB para o campo _id. Cada segmento carrega informação:

6823a4f1  |  3c2d1e  |  a4b2  |  001f3c
────────     ──────     ────     ──────
4 bytes      3 bytes   2 bytes   3 bytes
Timestamp    Machine     PID      Counter
  (Unix)       ID
  
Detalhamento:
Timestamp 4 bytes Segundos desde Unix epoch (1970-01-01). Precisão de 1 segundo.
Machine ID 3 bytes Hash do hostname da máquina que gerou o ID.
Process ID 2 bytes PID do processo MongoDB (ou do driver cliente).
Counter 3 bytes Incrementado a cada ObjectId gerado no mesmo segundo, no mesmo processo
*/

---------------------------------------------------------------------------------------------------------------
--- O objeito _ID '69137f21278d39ec0d1006e5' tem 24 caracteres hexadecimais, o que equivale exatamente a 12 bytes. 
CREATE OR REPLACE FUNCTION gerar_hash_sequencial RETURN RAW IS
    v_timestamp RAW(4);
    v_machine   RAW(3);
    v_pid       RAW(2);
    v_counter   RAW(3);


---------------------------------------------------------------------------------------------------------------
    -- Criado Timestamp (4 bytes) - 'FM' remove espaços em branco
    v_timestamp := HEXTORAW(to_char(floor((sysdate - to_date('01/01/1970','dd/mm/yyyy')) * 86400), 'FMXXXXXXXX'));

    -- Seguido Machine ID (3 bytes) 
    v_machine := HEXTORAW('3C2D1E'); 

    -- Completando PID (2 bytes) - 'FM0000' garante 4 caracteres hexa (2 bytes)
    v_pid := HEXTORAW(to_char(mod(sys_context('USERENV', 'SID'), 65535), 'FM0000'));

    -- Por ultimo Counter (3 bytes) - 'FM000000' garante 6 caracteres hexa (3 bytes)
    v_counter := HEXTORAW(to_char(mod(seq_party_counter.NEXTVAL, 16777215), 'FM000000'));

    -- Retorna o total de 12 bytes
    RETURN utl_raw.concat(v_timestamp, v_machine, v_pid, v_counter);
END;
   ------------------------------------------------------------------
--Exemplo de sequencial simples

DECLARE
    -- RAW(12) função personalizada retorna 12 bytes
    v_party_id    RAW(12);
    v_role_id     RAW(12);
    v_contact_id  RAW(12);
    v_address_id  RAW(12);
BEGIN
    FOR i IN 1..5 LOOP 
        
        -- USANDO SUA FUNÇÃO EM VEZ DE SYS_GUID()
        v_party_id := gerar_hash_sequencial();

        -- PARTY
        INSERT INTO PARTY (party_id, party_type, status_party, source_system, golden_record_flag)
        VALUES (v_party_id, 'Individual', 'Active', 'SALESFORCE_MIGRATION', 1);

        -- DADOS DO INDIVÍDUO
        INSERT INTO individual (party_id, cpf, full_name, first_name, last_name, birth_date, gender)
        VALUES (v_party_id, 
                LPAD(i, 11, '0'), 
                'Cliente Teste Oracle ' || i, 
                'Cliente', 
                'Teste ' || i, 
                TO_DATE('1990-01-01', 'YYYY-MM-DD'),
                CASE WHEN MOD(i, 2) = 0 THEN 'Masculino' ELSE 'Feminino' END);

        -- PAPEL DA PARTY (ROLE)
        v_role_id := gerar_hash_sequencial();
        INSERT INTO party_role (party_role_id, party_id, role_type, status_partyrole, name)
        VALUES (v_role_id, v_party_id, 'Customer', 'Active', 'Papel Cliente ' || i);

        -- DADOS DE NEGÓCIO (CUSTOMER)
        INSERT INTO customer (party_role_id, customer_code, customer_category, segment)
        VALUES (v_role_id, 'C-CODE-' || i, 'B2C', 'Vip');

        -- CONTATO TELEFONE
        v_contact_id := gerar_hash_sequencial();
        INSERT INTO contact_medium (contact_medium_id, party_id, medium_type, is_primary)
        VALUES (v_contact_id, v_party_id, 'Phone', 1);

        INSERT INTO phone_contact (contact_medium_id, area_code_ddd, phone_number, phone_type)
        VALUES (v_contact_id, '11', '9888877' || LPAD(i, 2, '0'), 'Mobile');

        -- CONTATO EMAIL
        v_contact_id := gerar_hash_sequencial();
        INSERT INTO contact_medium (contact_medium_id, party_id, medium_type, is_primary)
        VALUES (v_contact_id, v_party_id, 'Email', 0);

        INSERT INTO email_contact (contact_medium_id, email_address, email_type)
        VALUES (v_contact_id, 'contato' || i || '@provedor.com.br', 'Pessoal');

        -- ENDEREÇO
        v_address_id := gerar_hash_sequencial();
        INSERT INTO address (address_id, party_id, postal_code, street_address, street_number, neighborhood, municipality_name, state_code)
        VALUES (v_address_id, v_party_id, '0123456' || i, 'Avenida Principal', TO_CHAR(100 + i), 'Bairro Centro', 'São Paulo', 'SP');

    END LOOP;
    
    COMMIT;
END;
------------------------------------------------------------
--Tabelas de Nível 3 (Dependem de Roles ou Contatos)
BEGIN
    -- Deleta os detalhes finais (folhas)
    DELETE FROM customer;
    DELETE FROM phone_contact;
    DELETE FROM email_contact;
    -- Deleta as tabelas intermediárias
    DELETE FROM address;
    DELETE FROM contact_medium;
    DELETE FROM party_role;
    DELETE FROM individual;
    -- Deleta a tabela principal
    DELETE FROM party;
    COMMIT;
END;

--------------------------------------------------------------
--trigger
SELECT RAWTOHEX(gerar_hash_sequencial()) FROM dual;
--------------------------------------------------------------
SELECT 
    RAWTOHEX(party_id) as party_id_hash, 
    party_type, 
    status_party 
FROM PARTY;

DROP TABLE CLIENTES;

