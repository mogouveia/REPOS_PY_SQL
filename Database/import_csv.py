import csv
import os
from datetime import datetime 

# --- Configuracoes Iniciais ---
nome_arquivo_txt = 'id_next.txt' 
nome_arquivo_csv = 'itens_com_ids_combinados_mongo_1.csv'

# Define exatamente a ordem das colunas no CSV final
campos_csv = [
    'CreatedAt', 'lastModifiedAt', 'createBy', 'lastmodifiedBy', 
    'externalIds[0].fieldName', 'externalIds[1].fieldName', 
    'externalIds[0].originSystem', 'externalIds[1].originSystem',
    'externalIds[0].fieldValue', 'externalIds[1].fieldValue',
    'id.identificationNumber'
]

# Template de Dados  Formato ISO para melhor compatibilidade em CSV
hoje_iso = datetime.now().isoformat() 
template_dados_fixos = {
    "CreatedAt": hoje_iso,
    "lastModifiedAt": hoje_iso,
    "createBy": "JobMasterClienteCargaInicialExternalSystem", 
    "lastmodifiedBy": "JobMasterClienteCargaInicialExternalSystem",
    "externalIds[0].fieldName": "nextCustomer",
    "externalIds[1].fieldName": "nextContactId",
    "externalIds[0].originSystem": "VivoNext",
    "externalIds[1].originSystem": "VivoNext",
    # Os campos fieldValue e identificationNumber preenchidos dinamicamente
    "externalIds[0].fieldValue": "",
    "externalIds[1].fieldValue": "",
    "id.identificationNumber": ""
}

# Lista para armazenar todos os itens completos que serão escritos no CSV
dados_finais = []

# 2. Ler os dados do arquivo TXT e preencher
print(f"Tentando ler o arquivo TXT: '{nome_arquivo_txt}'")
if os.path.exists(nome_arquivo_txt):
    with open(nome_arquivo_txt, mode='r', encoding='utf-8') as arquivo_txt:
        # o formato de colunas do TXT
        leitor_txt = csv.reader(arquivo_txt, delimiter=',')
        
        #Pular o cabeçalho se seu .txt tiver uma primeira linha 
        next(leitor_txt, None) 
        
        for indice_linha, linha in enumerate(leitor_txt):
            # Garantir que a linha tem pelo menos 3 colunas (ajustar o indice 3 para 2, 3 campos no total)
            if len(linha) >= 3: 
                # Remover espacos em branco extras das bordas de cada valor
                customer_key = linha[0].strip()
                crm_source_id = linha[1].strip()
                #  indice 2 pois vc tinha usado 3 anteriormente o que pode ser um erro de indice no seu codigo original
                cpf_identifier = linha[2].strip() 
                
                # Criando uma nova copy do template de dados fixos para cada linha lida sobrescrever a mesma referência na memória
                novo_item = template_dados_fixos.copy()
                
                # Preencher os campos dinâmicos com os dados do TXT
                novo_item['externalIds[0].fieldValue'] = customer_key
                novo_item['externalIds[1].fieldValue'] = crm_source_id
                novo_item['id.identificationNumber'] = cpf_identifier
                
                # Adicionar o item completo à lista final
                dados_finais.append(novo_item)
            else:
                print(f"Aviso na linha {indice_linha + 1}: Linha incompleta no TXT ignorada: {linha}")
    
    print(f"Leitura do TXT concluída. {len(dados_finais)} registros processados.")

else:
    print(f"Erro: Arquivo '{nome_arquivo_txt}' não encontrado. O arquivo CSV será criado vazio.")

# Escrita do resultado final para o CSV
print(f"Iniciando a escrita do arquivo CSV: '{nome_arquivo_csv}'")
with open(nome_arquivo_csv, mode='w', newline='', encoding='utf-8') as arquivo_csv:
    escritor = csv.DictWriter(
        arquivo_csv, 
        fieldnames=campos_csv, 
        delimiter=',', 
        quoting=csv.QUOTE_MINIMAL 
    )
    
    escritor.writeheader()
    # Escreve todas as linhas
    escritor.writerows(dados_finais)

print(f"--- Finalizando ---")
print(f"Arquivo '{nome_arquivo_csv}' Criado com sucesso!!! Acabou e ficou bonito demais.")
