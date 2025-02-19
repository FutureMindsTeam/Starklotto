# StarkLotto

StarkLotto is a decentralized lottery game built on **Starknet**, designed to offer secure and efficient transactions on the blockchain. It leverages **Cairo** technology and a modular architecture in **TypeScript** for a fluid and innovative experience.

## 🚀 Features

- Decentralized lottery with smart contracts on **Cairo**.
- User interface developed with **TypeScript** and modern web technologies.
- Integration with Starknet wallets.
- Transparency and verifiability in the generation of winning numbers.

## 📜 Prerequisites

Before you begin, make sure you have the following requirements installed:

| Herramienta          | Versión recomendada |
|----------------------|--------------------|
| **Node.js**         | >= v18.17          |
| **Yarn**            | v1 o v2+           |
| **Git**             | Última versión     |
| **Rust**            | Última versión     |
| **asdf**            | Última versión     |
| **Extensión Cairo** | 1.0 (VSCode)       |

## 🔧 Installation

Follow these steps to set up and run the project:

### 1️⃣ Clone the repository
```sh
git clone https://github.com/FutureMindsTeam/starklotto.git
cd starklotto
```
📌 **Note**: If you wish to contribute, please create a branch off of `Dev` before committing changes.
```bash
  git checkout -b feature/your-branch Dev
```

### 2️⃣ Install dependencies
Install the project dependencies with:

```bash
  yarn install
```

### 3️⃣ Start the local network
```bash
yarn chain
```

### 4️⃣ Deploy the contracts
```bash
yarn deploy
```

### 5️⃣ Start the web application
```bash
yarn start
```
Next, open your browser and visit: [http://localhost:3000](http://localhost:3000)

## ⚡ Usage

### 1️⃣ Compile and deploy the smart contract

Compile the contracts written in Cairo:

```sh
cd contracts
scarb build
```

## 📝 Contributions

If you want to contribute, follow these steps:

1. Fork the repository.
2. Create a branch off of `Dev`:
```bash
git checkout -b feature/new-feature Dev
```
3. Make your changes and commit:
```bash
git commit -m "Description of change"
```
4. Push your changes to your fork:
```bash
git push origin feature/new-feature
```
5. Open a Pull Request to the `Dev` branch.

## 🤝 Contact

If you have questions or want to contribute, you can contact us at:
- Discord: [FutureMinds Community](https://discord.gg/ZAhZZDYn)
- X: [@futureminds_7](https://x.com/futureminds_7)
- Telegram Group: [Starklotto Contributors](https://t.me/StarklottoContributors)
