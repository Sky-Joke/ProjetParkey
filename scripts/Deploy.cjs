const hre = require("hardhat");

async function main() {
  console.log("Déploiement du contrat Parkey sur Sepolia...");

  const Parkey = await hre.ethers.getContractFactory("Parkey");
  const parkey = await Parkey.deploy();
  
  await parkey.waitForDeployment();
  
  const address = await parkey.getAddress();
  console.log("✅ Parkey déployé à l'adresse:", address);
  console.log("🔗 Voir sur Etherscan:", `https://sepolia.etherscan.io/address/${address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});