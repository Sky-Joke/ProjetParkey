import React from 'react';
import { useWeb3 } from '../hooks/useWeb3';

function WalletConnect() {
  const { account, connectWallet, disconnectWallet } = useWeb3();

  const formatAddress = (address) => {
    if (!address) return '';
    return `${address.substring(0, 6)}...${address.substring(38)}`;
  };

  return (
    <button
      onClick={account ? disconnectWallet : connectWallet}
      className="bg-gradient-to-r from-primary to-secondary px-6 py-2 rounded-lg font-semibold hover:shadow-lg hover:shadow-primary/50 transition-all"
    >
      <i className="fas fa-wallet mr-2"></i>
      <span>{account ? formatAddress(account) : 'Connecter Wallet'}</span>
    </button>
  );
}

export default WalletConnect;