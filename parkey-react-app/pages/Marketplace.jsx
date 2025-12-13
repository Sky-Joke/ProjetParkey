import React, { useState, useEffect } from 'react';
import ParkingCard from '../components/ParkingCard';

function Marketplace() {
  const [parkings, setParkings] = useState([]);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const mockParkings = [
      {
        id: 1,
        address: "15 Avenue des Champs-Élysées, Paris",
        type: "Souterrain",
        size: "Standard",
        price: "0.08",
        available: true,
        image: "https://picsum.photos/400/300?random=1"
      },
      {
        id: 2,
        address: "42 Rue de Rivoli, Paris",
        type: "Couvert",
        size: "Large",
        price: "0.12",
        available: true,
        image: "https://picsum.photos/400/300?random=2"
      },
      {
        id: 3,
        address: "88 Boulevard Saint-Germain, Paris",
        type: "Extérieur",
        size: "Standard",
        price: "0.05",
        available: true,
        image: "https://picsum.photos/400/300?random=3"
      },
      {
        id: 4,
        address: "23 Rue du Faubourg Saint-Honoré, Paris",
        type: "Souterrain",
        size: "Compact",
        price: "0.06",
        available: true,
        image: "https://picsum.photos/400/300?random=4"
      },
      {
        id: 5,
        address: "67 Avenue Montaigne, Paris",
        type: "Couvert",
        size: "Large",
        price: "0.15",
        available: true,
        image: "https://picsum.photos/400/300?random=5"
      },
      {
        id: 6,
        address: "31 Rue de la Paix, Paris",
        type: "Extérieur",
        size: "Standard",
        price: "0.07",
        available: true,
        image: "https://picsum.photos/400/300?random=6"
      },
      {
        id: 7,
        address: "55 Rue du Louvre, Paris",
        type: "Souterrain",
        size: "Large",
        price: "0.10",
        available: true,
        image: "https://picsum.photos/400/300?random=7"
      },
      {
        id: 8,
        address: "12 Place Vendôme, Paris",
        type: "Couvert",
        size: "Standard",
        price: "0.09",
        available: true,
        image: "https://picsum.photos/400/300?random=8"
      },
      {
        id: 9,
        address: "78 Boulevard Haussmann, Paris",
        type: "Extérieur",
        size: "Compact",
        price: "0.04",
        available: true,
        image: "https://picsum.photos/400/300?random=9"
      }
    ];
    setParkings(mockParkings);
  }, []);

  return (
    <div className="container mx-auto px-4 py-12">
      <h1 className="text-4xl font-bold mb-8">Marketplace</h1>
      
      <div className="flex flex-wrap gap-4 mb-8">
        <button
          onClick={() => setFilter('all')}
          className={`px-6 py-2 rounded-lg font-semibold transition-all ${
            filter === 'all' ? 'bg-primary' : 'bg-white/10 hover:bg-white/20'
          }`}
        >
          Tous
        </button>
        <button
          onClick={() => setFilter('available')}
          className={`px-6 py-2 rounded-lg font-semibold transition-all ${
            filter === 'available' ? 'bg-primary' : 'bg-white/10 hover:bg-white/20'
          }`}
        >
          Disponibles
        </button>
        <button
          onClick={() => setFilter('covered')}
          className={`px-6 py-2 rounded-lg font-semibold transition-all ${
            filter === 'covered' ? 'bg-primary' : 'bg-white/10 hover:bg-white/20'
          }`}
        >
          Couverts
        </button>
        <button
          onClick={() => setFilter('underground')}
          className={`px-6 py-2 rounded-lg font-semibold transition-all ${
            filter === 'underground' ? 'bg-primary' : 'bg-white/10 hover:bg-white/20'
          }`}
        >
          Souterrains
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {parkings.map(parking => (
          <ParkingCard key={parking.id} parking={parking} />
        ))}
      </div>
    </div>
  );
}

export default Marketplace;