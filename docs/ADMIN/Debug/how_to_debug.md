# 🔧 Proceso de Debugging entre StarkLotto y Debug_Starklotto

## 📌 Description 
Este documento explica el proceso para sincronizar y debuguear contratos entre el proyecto principal **StarkLotto** y el proyecto de debugging **Debug_Starklotto**. El proceso permite que ambos proyectos vean y interactúen con los mismos contratos desplegados en la misma red.

## 🎯 Motivation and Context 
Para facilitar el desarrollo y debugging de contratos inteligentes en Starknet, necesitamos un proceso estandarizado que permita:

- **Sincronización de contratos**: Ambos proyectos deben ver los mismos contratos desplegados
- **Debugging eficiente**: Poder debuguear contratos desde el proyecto de desarrollo sin afectar el principal
- **Consistencia de datos**: Mantener la misma información de contratos en ambos entornos
- **Flujo de trabajo optimizado**: Proceso claro y repetible para el equipo de desarrollo

## 🛠️ How to Test the Change (if applicable) 
Describe the steps to test your changes:

### 🔹 Paso 1: Hacer Deploy en StarkLotto
1. Navegar al proyecto principal **StarkLotto**
2. Ejecutar el comando de deploy:
   ```bash
   yarn deploy
   ```
3. Verificar que los contratos se hayan desplegado correctamente

### 🔹 Paso 2: Copiar archivo deployedContracts.ts
1. En el proyecto **StarkLotto**, localizar el archivo generado:
   ```
   packages/nextjs/contracts/deployedContracts.ts
   ```
2. Copiar todo el contenido del archivo
3. En el proyecto **Debug_Starklotto**, reemplazar el archivo:
   ```
   packages/nextjs/contracts/deployedContracts.ts
   ```
4. Verificar que el archivo se haya actualizado correctamente

### 🔹 Paso 3: Levantar el sitio y debuguear
1. En el proyecto **Debug_Starklotto**, instalar dependencias:
   ```bash
   yarn install
   ```
2. Levantar el servidor de desarrollo:
   ```bash
   yarn start
   # o
   yarn dev
   ```
3. Navegar a la página de debugging:
   ```
   http://localhost:3000/debug
   ```
4. Verificar que los contratos aparezcan correctamente
5. Probar las funciones de debugging disponibles

### 🔹 Paso 4: Verificar sincronización
1. Verificar que ambos proyectos apunten a la misma red (devnet/testnet)
2. Probar una transacción desde el proyecto de debugging
3. Confirmar que los cambios se reflejen en ambos proyectos

## 🖼️ Screenshots (if applicable) 
Si aplica, agregar capturas de pantalla o videos de los resultados de las pruebas.

## 🔍 Type of Change
- [x] 📖 **Documentation** - Updates or creates new documentation.
- [x] ✨ **New Feature** - Adds a new feature or functionality.
- [ ] 🐞 **Bugfix** - Fixes an existing issue or bug in the code.
- [ ] 🚀 **Hotfix** - A quick fix for a critical issue in production.
- [ ] 🔄 **Refactoring** - Improves the code structure without changing its behavior.
- [ ] ❓ **Other (please specify)** - Any other change that does not fit into the categories above.

## ✅ Checklist Before Merging
- [x] 🧪 I have tested the code and it works as expected.
- [x] 🎨 My changes follow the project's coding style.
- [x] 📖 I have updated the documentation if necessary.
- [x] ⚠️ No new warnings or errors were introduced.
- [x] 🔍 I have reviewed and approved my own code before submitting.

## 📌 Additional Notes 

### Estructura de Contratos Sincronizados
El archivo `deployedContracts.ts` contiene la información de los siguientes contratos:

- **StarkPlayERC20**: Token ERC20 personalizado con funcionalidades de mint, burn y premios
- **StarkPlayVault**: Vault para manejo de fondos y conversión de tokens
- **Lottery**: Contrato principal de la lotería con funcionalidades de tickets y sorteos

### Consideraciones Importantes

1. **Red de Despliegue**: Asegurarse de que ambos proyectos estén configurados para la misma red (devnet/testnet/mainnet)

2. **Versiones de Contratos**: Los contratos deben estar en la misma versión en ambos proyectos para evitar incompatibilidades

3. **Configuración de Red**: Verificar que la configuración de red en `scaffold.config.ts` sea consistente

### Flujo de Trabajo Recomendado

1. **Desarrollo**: Trabajar en el proyecto principal StarkLotto
2. **Deploy**: Desplegar contratos cuando estén listos para testing
3. **Sincronización**: Copiar el archivo de contratos al proyecto de debugging
4. **Testing**: Realizar pruebas exhaustivas en el entorno de debugging
5. **Iteración**: Repetir el proceso según sea necesario

### Herramientas de Debugging Disponibles

- **Interfaz de Contratos**: Acceso directo a todas las funciones de los contratos
- **Visualización de Eventos**: Monitoreo de eventos en tiempo real
- **Testing de Transacciones**: Prueba de funciones sin afectar el entorno principal
- **Análisis de Estado**: Verificación del estado actual de los contratos

Este proceso garantiza un flujo de trabajo eficiente y seguro para el desarrollo y debugging de contratos inteligentes en Starknet.
