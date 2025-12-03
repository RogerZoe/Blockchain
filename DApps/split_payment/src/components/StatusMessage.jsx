import React from 'react';

export const StatusMessage = ({ status }) => {
  if (!status.message) return null;

  return (
    <div className={`status-message ${status.type}`}>
      <span className="status-icon">
        {status.type === 'success' && '✅'}
        {status.type === 'error' && '❌'}
        {status.type === 'info' && 'ℹ️'}
      </span>
      {status.message}
    </div>
  );
};