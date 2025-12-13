import React, { useState, useEffect } from 'react';
import { useWeb3 } from '../hooks/useWeb3';
import { useContract } from '../hooks/useContract';
import ParkingCard from '../components/ParkingCard';

function MyTokens() {
  const { account } = useWeb3();
  const { getOwnerTokens } = useContract();
  const [myParkings, setMyParkings] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (account) {
      loadMyTokens();
    }
  }, [account]);

  const loadMyTokens = async () => {
    setLoading(true);
    try {
      const tokens = await getOwnerTokens(account);
      setMyParkings([]);
    } catch (error) {
      console.error('Error loading tokens:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!account) {
    return (
      <div className="container mx-auto px-4 py-20 text-center">
        <div className="max-w-md mx-auto">
          <i className="fas fa-wallet text-6xl text-primary mb-6"></i>
          <h1 className="text-4xl font-bold mb-4">Mes Tokens</h1>
          <p className="text-gray-400 mb-8">
            Veuillez connecter votre wallet pour voir vos tokens de parking
          </p>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-20 text-center">
        <i className="fas fa-spinner fa-spin text-6xl text-primary mb-4"></i>
        <p className="text-gray-400">Chargement de vos tokens...</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-12">
      <h1 className="text-4xl font-bold mb-8">Mes Tokens</h1>
      
      {myParkings.length === 0 ? (
        <div className="text-center py-20">
          <i className="fas fa-parking text-6xl text-gray-600 mb-4"></i>
          <p className="text-gray-400 text-xl mb-4">Vous n'avez pas encore de tokens</p>
          <p className="text-gray-500 mb-8">Créez votre premier token de parking ou achetez-en un sur le marketplace</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {myParkings.map(parking => (
            <ParkingCard key={parking.id} parking={parking} />
          ))}
        </div>
      )}
    </div>
  );
}

export default MyTokens;
