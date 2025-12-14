
async function main() {
  console.log("Déploiement du contrat Parkey sur Sepolia...");

  const hre = await import("hardhat");
  
  // Récupérer le contrat factory
  const Parkey = await hre.ethers.getContractFactory("Parkey");
  
  // Déployer
  const parkey = await Parkey.deploy();
  
  await parkey.waitForDeployment();
  
  const address = await parkey.getAddress();
  console.log("✅ Parkey déployé à l'adresse:", address);
  console.log("🔗 Voir sur Etherscan:", `https://sepolia.etherscan.io/address/${address}`);
  
  // Afficher le deployer
  const [deployer] = await hre.ethers.getSigners();
  console.log("👤 Déployé par:", deployer.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });