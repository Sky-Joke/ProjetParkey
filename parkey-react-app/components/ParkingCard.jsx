import React from 'react';
import { useWeb3 } from '../hooks/useWeb3';
import { useContract } from '../hooks/useContract';

function ParkingCard({ parking }) {
  const { account } = useWeb3();
  const { buyParking } = useContract();

  const handleBuy = async () => {
    if (!account) {
      alert('Veuillez connecter votre wallet');
      return;
    }
    
    try {
      await buyParking(parking.id, parking.price);
      alert('Achat réussi!');
    } catch (error) {
      console.error('Error buying parking:', error);
      alert('Erreur lors de l\'achat');
    }
  };

  return (
    <div className="bg-white/5 backdrop-blur-md border border-white/10 rounded-xl overflow-hidden hover:border-primary/50 transition-all hover:shadow-lg hover:shadow-primary/20">
      <div className="relative h-48">
        <img
          src={parking.image}
          alt={parking.address}
          className="w-full h-full object-cover"
          loading="lazy"
        />
        <div className="absolute top-4 right-4">
          <span className={`px-3 py-1 rounded-full text-xs font-semibold ${parking.available ? 'bg-accent' : 'bg-red-500'}`}>
            {parking.available ? 'Disponible' : 'Loué'}
          </span>
        </div>
      </div>
      <div className="p-6">
        <h3 className="font-bold text-lg mb-2">{parking.address}</h3>
        <div className="flex items-center space-x-4 text-sm text-gray-400 mb-4">
          <span>
            <i className="fas fa-warehouse mr-1"></i>
            {parking.type}
          </span>
          <span>
            <i className="fas fa-ruler-combined mr-1"></i>
            {parking.size}
          </span>
        </div>
        <div className="flex items-center justify-between">
          <div>
            <div className="text-2xl font-bold text-primary">{parking.price} ETH</div>
            <div className="text-xs text-gray-400">Prix de vente</div>
          </div>
          <button
            onClick={handleBuy}
            disabled={!parking.available}
            className="bg-primary hover:bg-primary/80 px-6 py-2 rounded-lg font-semibold transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Acheter
          </button>
        </div>
      </div>
    </div>
  );
}

export default ParkingCard;