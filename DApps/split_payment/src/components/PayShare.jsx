import React, { useState } from 'react';

export const PayShare = ({ onCheckExpense, onPayShare, loading }) => {
  const [expenseId, setExpenseId] = useState('');
  const [expenseDetails, setExpenseDetails] = useState(null);
  const [checking, setChecking] = useState(false);

  const handleCheck = async () => {
    if (!expenseId) {
      alert('Please enter an expense ID');
      return;
    }
    
    setChecking(true);
    const details = await onCheckExpense(expenseId);
    setExpenseDetails(details);
    setChecking(false);
  };

  const handlePay = async () => {
    if (!expenseId) return;
    const success = await onPayShare(expenseId);
    if (success) {
      // Refresh details after payment
      setTimeout(handleCheck, 2000); // Wait 2 seconds for blockchain update
    }
  };

  const formatAddress = (addr) => {
    if (!addr) return '';
    return `${addr.substring(0, 6)}...${addr.substring(38)}`;
  };

  return (
    <div className="card pay-share-card">
      <div className="card-header">
        <h2 className="card-title">
          <span className="card-icon">💳</span>
          Pay Your Share
        </h2>
      </div>

      <div className="pay-form">
        <div className="form-group">
          <label className="form-label">Expense ID</label>
          <div className="input-group">
            <input
              type="number"
              className="form-input"
              placeholder="Enter expense ID"
              value={expenseId}
              onChange={(e) => setExpenseId(e.target.value)}
              disabled={loading || checking}
            />
            <button 
              className="check-btn"
              onClick={handleCheck}
              disabled={loading || checking || !expenseId}
            >
              {checking ? 'Checking...' : 'Check Details'}
            </button>
          </div>
        </div>

        {expenseDetails && (
          <div className="expense-details">
            <h3 className="details-title">Expense Details</h3>
            
            <div className="detail-item">
              <span className="detail-label">📋 Description:</span>
              <span className="detail-value">{expenseDetails.description}</span>
            </div>
            
            <div className="detail-item">
              <span className="detail-label">💰 Total Amount:</span>
              <span className="detail-value highlight">{expenseDetails.amount} ETH</span>
            </div>
            
            <div className="detail-item">
              <span className="detail-label">👤 Payer:</span>
              <span className="detail-value">{formatAddress(expenseDetails.payer)}</span>
            </div>
            
            <div className="detail-item">
              <span className="detail-label">🪙 Your Share:</span>
              <span className="detail-value highlight">
                {expenseDetails.shareAmount} ETH
                {expenseDetails.hasPaid && ' (Paid)'}
              </span>
            </div>
            
            <div className="detail-item">
              <span className="detail-label">📊 Your Status:</span>
              <span className={`status-badge ${expenseDetails.hasPaid ? 'paid' : 'pending'}`}>
                {expenseDetails.hasPaid ? '✅ Paid' : '⏳ Pending'}
              </span>
            </div>

            {/* Splitters List */}
            <div className="splitters-section">
              <h4 className="splitters-title">Split Among {expenseDetails.totalSplitters + 1} People:</h4>
              <div className="splitters-list">
                {/* Show payer first */}
                <div className="splitter-item payer">
                  <span className="splitter-address">
                    👑 {formatAddress(expenseDetails.payer)} (Payer)
                  </span>
                  <span className="splitter-status paid">✅ Paid</span>
                </div>
                
                {/* Show splitters */}
                {expenseDetails.splitters.map((splitter, index) => (
                  <div key={index} className="splitter-item">
                    <span className="splitter-address">
                      👤 {formatAddress(splitter.address)}
                    </span>
                    <span className={`splitter-status ${splitter.hasPaid ? 'paid' : 'pending'}`}>
                      {splitter.hasPaid ? '✅ Paid' : '⏳ Pending'}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            {!expenseDetails.hasPaid && (
              <button 
                className="pay-btn"
                onClick={handlePay}
                disabled={loading}
              >
                {loading ? 'Processing Payment...' : `Pay ${expenseDetails.shareAmount} ETH`}
              </button>
            )}

            { expenseDetails.hasPaid && (
              <div className="fully-paid-message">
                <span className="success-icon">🎉</span>
                You have successfully paid your share!
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};