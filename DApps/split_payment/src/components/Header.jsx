import React from 'react';

export const Header = () => {
  return (
    <header className="header">
      <div className="header-content">
        <div className="logo-section">
          <span className="logo">💰</span>
          <h1 className="title">Split Payment DApp</h1>
        </div>
        <p className="subtitle">Easily split expenses with friends on blockchain</p>
      </div>
    </header>
  );
};