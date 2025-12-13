import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import WalletConnect from './WalletConnect';

function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const location = useLocation();

  const isActive = (path) => {
    return location.pathname === path ? 'text-primary' : '';
  };

  return (
    <header className="bg-dark/50 backdrop-blur-md border-b border-purple-500/20 sticky top-0 z-50">
      <nav className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <Link to="/" className="flex items-center space-x-2">
            <i className="fas fa-parking text-3xl text-primary"></i>
            <span className="text-2xl font-bold bg-gradient-to-r from-primary to-secondary bg-clip-text text-transparent">
              Parkey
            </span>
          </Link>
          
          <div className="hidden md:flex items-center space-x-8">
            <Link to="/" className={`hover:text-primary transition-colors ${isActive('/')}`}>
              Accueil
            </Link>
            <Link to="/marketplace" className={`hover:text-primary transition-colors ${isActive('/marketplace')}`}>
              Marketplace
            </Link>
            <Link to="/my-tokens" className={`hover:text-primary transition-colors ${isActive('/my-tokens')}`}>
              Mes Tokens
            </Link>
            <Link to="/create" className={`hover:text-primary transition-colors ${isActive('/create')}`}>
              Créer
            </Link>
          </div>
          
          <div className="flex items-center space-x-4">
            <WalletConnect />
            
            <button 
              className="md:hidden text-2xl"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <i className={`fas ${mobileMenuOpen ? 'fa-times' : 'fa-bars'}`}></i>
            </button>
          </div>
        </div>

        {mobileMenuOpen && (
          <div className="md:hidden mt-4 pb-4 space-y-4">
            <Link 
              to="/" 
              className={`block hover:text-primary transition-colors ${isActive('/')}`}
              onClick={() => setMobileMenuOpen(false)}
            >
              Accueil
            </Link>
            <Link 
              to="/marketplace" 
              className={`block hover:text-primary transition-colors ${isActive('/marketplace')}`}
              onClick={() => setMobileMenuOpen(false)}
            >
              Marketplace
            </Link>
            <Link 
              to="/my-tokens" 
              className={`block hover:text-primary transition-colors ${isActive('/my-tokens')}`}
              onClick={() => setMobileMenuOpen(false)}
            >
              Mes Tokens
            </Link>
            <Link 
              to="/create" 
              className={`block hover:text-primary transition-colors ${isActive('/create')}`}
              onClick={() => setMobileMenuOpen(false)}
            >
              Créer
            </Link>
          </div>
        )}
      </nav>
    </header>
  );
}

export default Header;