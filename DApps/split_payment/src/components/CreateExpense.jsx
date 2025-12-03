import React, { useState } from 'react';

export const CreateExpense = ({ onCreateExpense, loading }) => {
  const [formData, setFormData] = useState({
    description: '',
    amount: '',
    splitters: ''
  });
  const [createdId, setCreatedId] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.description || !formData.amount || !formData.splitters) {
      alert('Please fill all fields');
      return;
    }
    
    const expenseId = await onCreateExpense(formData.description, formData.amount, formData.splitters);
    if (expenseId) {
      setCreatedId(expenseId);
      // Clear form
      setFormData({
        description: '',
        amount: '',
        splitters: ''
      });
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <div className="card create-expense-card">
      <div className="card-header">
        <h2 className="card-title">
          <span className="card-icon">📝</span>
          Create New Expense
        </h2>
      </div>
      
      <form onSubmit={handleSubmit} className="expense-form">
        <div className="form-group">
          <label className="form-label">Description</label>
          <input
            type="text"
            name="description"
            className="form-input"
            placeholder="What's this expense for?"
            value={formData.description}
            onChange={handleChange}
            disabled={loading}
          />
        </div>

        <div className="form-group">
          <label className="form-label">Amount (ETH)</label>
          <input
            type="number"
            step="0.001"
            name="amount"
            className="form-input"
            placeholder="0.1"
            value={formData.amount}
            onChange={handleChange}
            disabled={loading}
          />
        </div>

        <div className="form-group">
          <label className="form-label">Split With (Addresses)</label>
          <textarea
            name="splitters"
            className="form-input textarea"
            placeholder="0x123..., 0x456..., 0x789..."
            value={formData.splitters}
            onChange={handleChange}
            disabled={loading}
            rows="3"
          />
          <small className="form-hint">Comma-separated wallet addresses</small>
        </div>

        <button type="submit" className="submit-btn" disabled={loading}>
          {loading ? (
            <span className="loading">Creating...</span>
          ) : (
            <>
              <span className="btn-icon">✨</span>
              Create & Pay My Share
            </>
          )}
        </button>
      </form>

      { createdId && (
        <div className="success-message ">
          <span className="success-icon">🎉</span>
          Expense created successfully! ID: <strong>{createdId}</strong>
        </div>
      )}
    </div>
  );
};