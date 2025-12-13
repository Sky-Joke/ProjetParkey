import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import ParkingCard from '../components/ParkingCard';
import StatsSection from '../components/StatsSection';

function Home() {
  const [featuredParkings, setFeaturedParkings] = useState([]);

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
        available: false,
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
      }
    ];
    setFeaturedParkings(mockParkings);
  }, []);

  return (
    <>
      <section className="container mx-auto px-4 py-20">
        <div className="text-center max-w-4xl mx-auto">
          <h1 className="text-5xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-primary via-secondary to-accent bg-clip-text text-transparent">
            Tokenisez vos Places de Parking
          </h1>
          <p className="text-xl text-gray-300 mb-8">
            Transformez vos places de parking en NFTs échangeables sur la blockchain. Achetez, vendez et louez en toute sécurité.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link 
              to="/create" 
              className="bg-primary hover:bg-primary/80 px-8 py-4 rounded-lg font-semibold text-lg transition-all hover:shadow-lg hover:shadow-primary/50 inline-block"
            >
              <i className="fas fa-plus-circle mr-2"></i>
              Créer un Token
            </Link>
            <Link 
              to="/marketplace" 
              className="bg-white/10 hover:bg-white/20 px-8 py-4 rounded-lg font-semibold text-lg transition-all border border-white/20 inline-block"
            >
              <i className="fas fa-store mr-2"></i>
              Explorer le Marketplace
            </Link>
          </div>
        </div>
      </section>

      <StatsSection />

      <section className="container mx-auto px-4 py-12">
        <div className="flex items-center justify-between mb-8">
          <h2 className="text-3xl font-bold">Places en Vedette</h2>
          <Link to="/marketplace" className="text-primary hover:text-secondary transition-colors">
            Voir tout <i className="fas fa-arrow-right ml-2"></i>
          </Link>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {featuredParkings.map(parking => (
            <ParkingCard key={parking.id} parking={parking} />
          ))}
        </div>
      </section>

      <section className="container mx-auto px-4 py-20">
        <h2 className="text-4xl font-bold text-center mb-12">Comment ça marche ?</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="text-center">
            <div className="bg-gradient-to-br from-primary to-secondary w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
              <i className="fas fa-file-contract text-3xl"></i>
            </div>
            <h3 className="text-xl font-bold mb-4">1. Tokenisez</h3>
            <p className="text-gray-400">
              Créez un NFT représentant votre place de parking avec tous les détails nécessaires
            </p>
          </div>
          <div className="text-center">
            <div className="bg-gradient-to-br from-secondary to-accent w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
              <i className="fas fa-exchange-alt text-3xl"></i>
            </div>
            <h3 className="text-xl font-bold mb-4">2. Échangez</h3>
            <p className="text-gray-400">
              Vendez ou louez votre place sur notre marketplace décentralisé
            </p>
          </div>
          <div className="text-center">
            <div className="bg-gradient-to-br from-accent to-primary w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-6">
              <i className="fas fa-shield-alt text-3xl"></i>
            </div>
            <h3 className="text-xl font-bold mb-4">3. Sécurisé</h3>
            <p className="text-gray-400">
              Toutes les transactions sont sécurisées par la blockchain Ethereum
            </p>
          </div>
        </div>
      </section>
    </>
  );
}

export default Home;