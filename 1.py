from reportlab.platypus import *
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4

pdf='/mnt/data/Marcio_Gouveia_CV_Data_Architect.pdf'
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='TitleC',alignment=TA_CENTER,fontSize=22,textColor=colors.HexColor('#0F4C81')))
styles.add(ParagraphStyle(name='H',fontSize=14,textColor=colors.HexColor('#0F4C81'),spaceBefore=10,spaceAfter=6))

story=[]
story.append(Paragraph('MARCIO OLIVEIRA GOUVEIA',styles['TitleC']))
story.append(Paragraph('Senior Data Architect | Lead Data Engineer | Databricks | Azure | AWS | Spark | AI & Analytics',styles['BodyText']))
story.append(Spacer(1,12))

sections=[
('Resumo Executivo','Profissional com mais de 20 anos de experiencia em Dados, Analytics, BI, Big Data e Arquitetura de Solucoes. Atuacao em Vivo, Claro e Atento liderando iniciativas de plataformas de dados, governanca, cloud, Data Warehouse, Lakehouse e analytics.'),
('Principais Conquistas','- Implantacao de CRM corporativo para canais de vendas na Claro, integrando dados comerciais e operacionais para aumentar a eficiencia das campanhas e acompanhamento de performance.\n- Desenvolvimento de arquitetura Lakehouse baseada no modelo Medallion (Bronze, Silver e Gold), com pipelines escalaveis para ingestao, tratamento e consumo analitico de dados.\n- Construcao e evolucao de ambientes Data Warehouse e Data Marts para suporte a decisoes estrategicas.\n- Implantacao do Master Data de Clientes (Cadastro Unico) na Vivo, consolidando multiplas fontes de dados e fortalecendo governanca, qualidade e visao unica do cliente.\n- Lideranca tecnica de squads de dados em iniciativas de transformacao digital e servicos digitais.'),
('Competencias','Data Architecture, Data Engineering, Databricks, Spark, Python, SQL Server, Oracle, Azure, AWS, Data Governance, Lakehouse, Data Warehouse, ETL/ELT, APIs, Power BI, CI/CD.'),
('Experiencia Recente - Vivo','Product Owner e Senior Data Engineer. Lideranca tecnica, arquitetura de dados, governanca, pipelines, APIs, ServiceNow, analytics e modernizacao de plataformas de dados.'),
('Experiencia - Claro','Engenharia de Dados, BI, CRM, ETL, DW, dashboards executivos e automacao de processos. Reducao de 45% no cancelamento de portabilidades atraves de solucoes orientadas por dados.'),
('Formacao','MBA Arquitetura de Solucoes (FIAP); Pos-Graduacao Ciencia de Dados (FMU); Sistemas de Informacao.')
]
for t,b in sections:
    story.append(Paragraph(t,styles['H']))
    story.append(Paragraph(b.replace('\n','<br/>'),styles['BodyText']))

SimpleDocTemplate(pdf,pagesize=A4,rightMargin=40,leftMargin=40,topMargin=40,bottomMargin=40).build(story)
print(pdf)
