# 🏦 User Service — Banco Digital

Microservicio serverless de gestión de usuarios para una plataforma de banca digital. Permite a los usuarios registrarse, autenticarse, consultar y actualizar su perfil, desplegado sobre infraestructura AWS con arquitectura serverless.

---

## 📋 Descripción

Este servicio forma parte del backend de un banco digital. Está construido en **Python** y desplegado como funciones **AWS Lambda** expuestas a través de **API Gateway**. La autenticación se maneja con **JWT (PyJWT)** y la infraestructura completa está definida como código con **Terraform**.

---

## ✨ Funcionalidades

| Función | Descripción |
|---|---|
| `register` | Registro de nuevos usuarios |
| `login` | Autenticación y generación de token JWT |
| `getprofile` | Consulta del perfil del usuario autenticado |
| `updateprofile` | Actualización de los datos del perfil |
| `updateavatar` | Actualización de la foto de perfil |

---

## 🛠️ Stack Tecnológico

| Tecnología | Uso |
|---|---|
| **Python** | Lenguaje principal de las funciones Lambda |
| **PyJWT 2.11.0** | Generación y validación de tokens JWT |
| **AWS Lambda** | Ejecución serverless de cada función |
| **AWS API Gateway** | Exposición de los endpoints REST |
| **AWS DynamoDB** | Base de datos NoSQL para usuarios |
| **AWS S3** | Almacenamiento de avatares/imágenes |
| **AWS SQS** | Cola de mensajes para eventos asíncronos |
| **AWS Secrets Manager** | Gestión segura de credenciales y secretos |
| **AWS IAM** | Control de permisos y roles |
| **Terraform** | Infraestructura como código (IaC) |

---

## 📁 Estructura del Proyecto

```
user_service/
└── user-service/
    ├── python/                  # Dependencias empaquetadas para Lambda Layer
    │   └── jwt/                 # PyJWT 2.11.0
    │       ├── algorithms.py
    │       ├── api_jwt.py
    │       ├── api_jws.py
    │       ├── api_jwk.py
    │       ├── jwks_client.py
    │       ├── exceptions.py
    │       └── ...
    ├── src/                     # Código fuente de las funciones Lambda
    │   ├── register/            # Registro de usuario
    │   ├── login/               # Autenticación
    │   ├── getprofile/          # Consulta de perfil
    │   ├── updateprofile/       # Actualización de perfil
    │   └── updateavatar/        # Actualización de avatar
    └── terraform/               # Infraestructura como código
        ├── main.tf
        ├── api-gateway.tf
        ├── lambdas.tf
        ├── dynamodb.tf
        ├── s3.tf
        ├── sqs.tf
        ├── iam.tf
        ├── secrets.tf
        └── versions.tf
```

---

## 🚀 Despliegue

### Prerrequisitos

- Python 3.9+
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configurado con credenciales válidas

### 1. Configurar credenciales AWS

```bash
aws configure
# AWS Access Key ID:     <tu_access_key>
# AWS Secret Access Key: <tu_secret_key>
# Default region name:   us-east-1
```

### 2. Clonar el repositorio

```bash
git clone https://github.com/Mmejia810/user_service.git
cd user_service/user-service
```

### 3. Empaquetar las funciones Lambda

Cada función en `src/` debe ser comprimida para su despliegue:

```bash
cd src/register     && zip -r register.zip .     && mv register.zip ../../
cd ../login         && zip -r login.zip .         && mv login.zip ../../
cd ../getprofile    && zip -r getprofile.zip .    && mv getprofile.zip ../../
cd ../updateprofile && zip -r updateprofile.zip . && mv updateprofile.zip ../../
cd ../updateavatar  && zip -r updateavatar.zip .  && mv updateavatar.zip ../../
```

### 4. Desplegar con Terraform

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

---

## 📡 Endpoints de la API

| Método | Endpoint | Auth | Descripción |
|---|---|---|---|
| `POST` | `/register` | ❌ | Registrar un nuevo usuario |
| `POST` | `/login` | ❌ | Iniciar sesión y obtener token JWT |
| `GET` | `/profile` | ✅ | Obtener perfil del usuario autenticado |
| `PUT` | `/profile` | ✅ | Actualizar datos del perfil |
| `PUT` | `/profile/avatar` | ✅ | Actualizar foto de perfil |

> Los endpoints marcados con ✅ requieren el header:
> ```
> Authorization: Bearer <token>
> ```

---

## 🔐 Autenticación

El servicio usa **JWT** mediante la librería **PyJWT 2.11.0**, empaquetada como un **Lambda Layer** compartido entre todas las funciones. Los secretos de firma se gestionan de forma segura a través de **AWS Secrets Manager**.

Flujo de autenticación:
```
Cliente → POST /login → Lambda login → DynamoDB → JWT generado → Cliente
Cliente → GET /profile (+ token) → API Gateway → Lambda getprofile → Respuesta
```

---

## ☁️ Infraestructura AWS

| Archivo Terraform | Recurso |
|---|---|
| `api-gateway.tf` | API REST con rutas y métodos |
| `lambdas.tf` | Funciones Lambda + Lambda Layer (PyJWT) |
| `dynamodb.tf` | Tabla de usuarios |
| `s3.tf` | Bucket para almacenamiento de avatares |
| `sqs.tf` | Cola para eventos asíncronos |
| `iam.tf` | Roles y políticas de permisos |
| `secrets.tf` | Secretos en AWS Secrets Manager |
| `versions.tf` | Versión del provider AWS |

---

## 👥 Contribuidores

- [@Mmejia810](https://github.com/Mmejia810) — Mauricio José Mejía Morales
- [@Yovani1029](https://github.com/Yovani1029) — Yovani Navarro

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.
