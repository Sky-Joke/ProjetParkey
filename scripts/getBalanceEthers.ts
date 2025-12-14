import {ethers} from 'ethers';
const rpcURL = "https://sepolia.infura.io/v3/8cc912713d4944c68081267f227b4476";

const client = new ethers.JsonRpcProvider(rpcURL);
  
const balance = await client.getBalance("0x13bc18faeC7f39Fb5eE428545dBba611267AEAa4");
console.log(ethers.formatEther(balance));