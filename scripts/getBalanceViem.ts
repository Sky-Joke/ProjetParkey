import { createPublicClient, http , formatEther} from 'viem';
import { sepolia } from 'viem/chains';

const rpcURL = "https://sepolia.infura.io/v3/8cc912713d4944c68081267f227b4476"

const client = createPublicClient({
  chain: sepolia,
  transport: http(rpcURL),
});

const balance = await client.getBalance({ address: "0x13bc18faeC7f39Fb5eE428545dBba611267AEAa4" });
console.log(formatEther(balance));