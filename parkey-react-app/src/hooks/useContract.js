import { ethers } from 'ethers';
import { useWeb3 } from './useWeb3';
import ParkeyNFTABI from '../contracts/abi/ParkeyNFT.json';

const CONTRACT_ADDRESS = process.env.REACT_APP_CONTRACT_ADDRESS || '0x0000000000000000000000000000000000000000';

export function useContract() {
  const { signer } = useWeb3();

  const getContract = () => {
    if (!signer) return null;
    return new ethers.Contract(CONTRACT_ADDRESS, ParkeyNFTABI, signer);
  };

  const createParking = async (parkingData) => {
    const contract = getContract();
    if (!contract) throw new Error('Contract not initialized');

    try {
      const tx = await contract.createParkingSpot(
        parkingData.address,
        parkingData.type,
        parkingData.size,
        ethers.parseEther(parkingData.price),
        parkingData.available247,
        '' // tokenURI - à implémenter avec IPFS
      );
      await tx.wait();
      return tx;
    } catch (error) {
      console.error('Error creating parking:', error);
      throw error;
    }
  };

  const buyParking = async (tokenId, price) => {
    const contract = getContract();
    if (!contract) throw new Error('Contract not initialized');

    try {
      const tx = await contract.buyParkingSpot(tokenId, {
        value: ethers.parseEther(price)
      });
      await tx.wait();
      return tx;
    } catch (error) {
      console.error('Error buying parking:', error);
      throw error;
    }
  };

  const listParking = async (tokenId, price) => {
    const contract = getContract();
    if (!contract) throw new Error('Contract not initialized');

    try {
      const tx = await contract.listParkingSpot(tokenId, ethers.parseEther(price));
      await tx.wait();
      return tx;
    } catch (error) {
      console.error('Error listing parking:', error);
      throw error;
    }
  };

  const getOwnerTokens = async (address) => {
    const contract = getContract();
    if (!contract) throw new Error('Contract not initialized');

    try {
      return await contract.getOwnerTokens(address);
    } catch (error) {
      console.error('Error getting owner tokens:', error);
      throw error;
    }
  };

  return {
    createParking,
    buyParking,
    listParking,
    getOwnerTokens
  };
}