DECLARE
    v_json          CLOB;
    v_response_json CLOB;
BEGIN
    -- Exemplo inserindo um Maior  - 
    
    v_json := '
    { 
      "partyType": "INDIVIDUAL",
      "partyKind": "Customer",
      "sourceSystem" :"Nao Sei",
      "identifications": [
        {
          "id": null,
          "document": {
            "country": "BR",
            "type": "CPF",
            "value": "5656808869"
          },
          "status": "active"
        }
      ],
      "individual": {
        "name": {
          "firstName": "Robertos",
          "lastName": "Carlo",
          "fullName": "Robertos Carlo"
        },
        "birthDate": "1972-12-01",
        "isminor": false
      }
    }'; 
    
    -- Insere um Menor -- 546404647C7A9135E063C465C70A83F4
   /* v_json := '
    {
      "partyId": null,
      "partyType": "INDIVIDUAL",
      "partyKind": "Customer",
      "identifications": [
        {
          "id": null,
          "document": {
            "country": "BR",
            "type": "CPF",
            "value": "10987654321"
          },
          "status": "active"
        }
      ],
      "contact": [
        {
          "type": "email",
          "value": "meuemail@meuemail.com"
        }
      ],
      "relationships": [
        {
          "id": null,
          "relatedPartyId": "546404647C829135E063C465C70A83F4",
          "relationshipType": "father",
          "legalResponsibility": "T"
        }
      ],
      "individual": {
        "name": {
          "firstName": "Juliana",
          "lastName": "Oliveira",
          "fullName": "Juliana Aparecida Oliveira"
        },
        "birthDate": "2020-12-01",
        "isminor": "N"
      }
    }';*/


    PCK_FASTDATA.PRO_INSERE_DADOS
    (
        p_json           => v_json,
        p_response_json  => v_response_json
    );

    DBMS_OUTPUT.PUT_LINE(v_response_json);
END;


