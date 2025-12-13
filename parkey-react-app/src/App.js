import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Web3Provider } from './context/Web3Context';
import Header from './components/Header';
import Footer from './components/Footer';
import Home from './pages/Home';
import Marketplace from './pages/Marketplace';
import Create from './pages/Create';
import MyTokens from './pages/MyTokens';

function App() {
  return (
    <Router>
      <Web3Provider>
        <div className="min-h-screen flex flex-col">
          <Header />
          <main className="flex-grow">
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/marketplace" element={<Marketplace />} />
              <Route path="/create" element={<Create />} />
              <Route path="/my-tokens" element={<MyTokens />} />
            </Routes>
          </main>
          <Footer />
        </div>
      </Web3Provider>
    </Router>
  );
}

export default App;