import React from 'react';

export const WalletConnection = ({ account, onConnect }) => {
  const formatAddress = (addr) => {
    if (!addr) return '';
    return `${addr.substring(0, 6)}...${addr.substring(38)}`;
  };

  return (
    <div className="wallet-section">
      {account ? (
        <div className="wallet-connected">
          <span className="wallet-badge">
            <span className="status-dot" />
            Connected: {formatAddress(account)}
          </span>
        </div>
      ) : (
        <button className="connect-btn" onClick={onConnect}>
          <span className="btn-icon">🔗</span>
          Connect Wallet
        </button>
      )}
    </div>
  );
};