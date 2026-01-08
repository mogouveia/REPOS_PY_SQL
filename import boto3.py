import boto3
import pandas as pd
from io import BytesIO

# Configurações do seu bucket e arquivo
bucket_name = 's3://raw-bronze-datalake/'
file_key = 'Churn.csv'

# Crie um cliente S3
s3 = boto3.client('s3')

# Obtenha o objeto do S3
obj = s3.get_object(Bucket=bucket_name, Key=file_key)

# Leia o conteúdo CSV usando pandas
df = pd.read_csv(BytesIO(obj['Body'].read()), encoding='utf8') 

# Imprima ou manipule os dados no terminal do VS Code
print(df.head())
