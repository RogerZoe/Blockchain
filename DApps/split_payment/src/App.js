import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import './App.css';
import { 
  WalletConnection, 
  CreateExpense, 
  PayShare, 
  StatusMessage,
  Header 
} from './components';
import CONTRACT_ABI from './abi/SplitPaymentABI.json';

const CONTRACT_ADDRESS = '0x5b19412bA386Fe5dbB425B98Fb1fbA28A261987d';

function App() {
  const [web3, setWeb3] = useState(null);
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState('');
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState({ message: '', type: '' });

  useEffect(() => {
    initializeWeb3();
  }, []);

  const initializeWeb3 = async () => {
    if (window.ethereum) {
      try {
        const web3Instance = new Web3(window.ethereum);
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        
        const accounts = await web3Instance.eth.getAccounts();
        const contractInstance = new web3Instance.eth.Contract(
          CONTRACT_ABI,
          CONTRACT_ADDRESS
        );

        setWeb3(web3Instance);
        setContract(contractInstance);
        setAccount(accounts[0]);

        // Listen for account changes
        window.ethereum.on('accountsChanged', (accounts) => {
          setAccount(accounts[0] || '');
        });

      } catch (error) {
        showStatus('Failed to connect wallet', 'error');
      }
    } else {
      showStatus('Please install MetaMask!', 'error');
    }
  };

  const showStatus = (message, type = 'info') => {
    setStatus({ message, type });
    setTimeout(() => setStatus({ message: '', type: '' }), 5000);
  };

  const createExpense = async (description, amount, splitters) => {
    setLoading(true);
    try {
      const amountWei = web3.utils.toWei(amount.toString(), 'ether');
      const splittersArray = splitters.split(',').map(s => s.trim()).filter(s => s !== '');
      
      if (splittersArray.length === 0) {
        throw new Error('Please add at least one splitter address');
      }

      console.log('Creating expense with:', { description, amountWei, splittersArray });

      // Get current expense counter BEFORE creating the expense
      const currentCounter = await contract.methods.expenseCounter().call();
      console.log('Current expense counter before creation:', currentCounter);

      // Send transaction
      const receipt = await contract.methods
        .createExpense(description, splittersArray)
        .send({ 
          from: account, 
          value: amountWei,
          gas: 500000 
        });
      
      console.log('Transaction receipt:', receipt);

      // METHOD 1: Try to get expense ID from events (most reliable)
      let expenseId;
      
      // Check different possible event formats
      if (receipt.events?.ExpenseCreated?.returnValues?.id) {
        expenseId = receipt.events.ExpenseCreated.returnValues.id;
        console.log('Found expense ID from events (direct):', expenseId);
      } 
      // Some contracts emit events with different structure
      else if (receipt.events && Object.keys(receipt.events).length > 0) {
        // Look for any event that might contain the expense ID
        for (const eventKey in receipt.events) {
          if (receipt.events[eventKey].returnValues?.id) {
            expenseId = receipt.events[eventKey].returnValues.id;
            console.log('Found expense ID from events (searched):', expenseId, 'in event:', eventKey);
            break;
          }
        }
      }

      // METHOD 2: If events didn't work, get the new counter value
      if (expenseId === undefined) {
        const newCounter = await contract.methods.expenseCounter().call();
        console.log('New expense counter after creation:', newCounter);
        
        // The new expense ID should be the previous counter value
        expenseId = currentCounter;
        console.log('Calculated expense ID from counter:', expenseId);
      }

      // METHOD 3: Verify the expense exists by trying to get its details
      if (expenseId !== undefined) {
        try {
          const expenseDetails = await contract.methods.getExpenseDetails(expenseId).call();
          console.log('Expense verification successful:', expenseDetails);
        } catch (verifyError) {
          console.error('Expense verification failed, trying alternative ID...');
          // If verification fails, try expenseId - 1 (sometimes it's off by one)
          try {
            const alternativeExpenseId = parseInt(expenseId) - 1;
            const expenseDetails = await contract.methods.getExpenseDetails(alternativeExpenseId).call();
            expenseId = alternativeExpenseId;
            console.log('Using alternative expense ID:', expenseId);
          } catch (altError) {
            console.error('Alternative ID also failed');
          }
        }
      }

      // Final fallback: if still no ID, use the original counter
      if (expenseId === undefined) {
        expenseId = currentCounter;
        console.log('Using fallback expense ID:', expenseId);
      }

      if (expenseId === undefined) {
        throw new Error('Could not retrieve expense ID after creation');
      }

      showStatus(`✅ Expense created successfully! ID: ${expenseId}`, 'success');
      return expenseId.toString();

    } catch (error) {
      console.error('Create expense error:', error);
      showStatus(`❌ Failed to create expense: ${error.message}`, 'error');
      return null;
    } finally {
      setLoading(false);
    }
  };

  const getExpenseDetails = async (expenseId) => {
    try {
      const details = await contract.methods
        .getExpenseDetails(expenseId)
        .call({ from: account });
      
      // Get splitters list
      const splitters = await contract.methods
        .getSplitters(expenseId)
        .call({ from: account });

      // Get payment status for each splitter
      const splitterDetails = await Promise.all(
        splitters.map(async (splitter) => {
          const hasPaid = await contract.methods
            .getPaymentStatus(expenseId, splitter)
            .call({ from: account });
          return {
            address: splitter,
            hasPaid: hasPaid
          };
        })
      );

      return {
        description: details.description,
        amount: web3.utils.fromWei(details.amount, 'ether'),
        payer: details.payer,
        shareAmount: details.hasPaid ? '0' : web3.utils.fromWei(details.shareAmount, 'ether'),
        hasPaid: details.hasPaid,
        splitters: splitterDetails,
        totalSplitters: splitters.length
      };
    } catch (error) {
      showStatus('Failed to fetch expense details. Please check the expense ID.', 'error');
      return null;
    }
  };

  const payShare = async (expenseId) => {
    setLoading(true);
    try {
      const details = await contract.methods
        .getExpenseDetails(expenseId)
        .call({ from: account });
      
      await contract.methods
        .payShare(expenseId)
        .send({ from: account, value: details.shareAmount });
      
      showStatus('✅ Payment successful! Your share has been paid.', 'success');
      return true;
    } catch (error) {
      showStatus(`❌ ${error.message}`, 'error');
      return false;
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app">
      <div className="background-gradient" />
      
      <Header />
      
      <WalletConnection account={account} onConnect={initializeWeb3} />
      
      {account && (
        <div className="main-container">
          <CreateExpense 
            onCreateExpense={createExpense} 
            loading={loading} 
          />
          
          <PayShare 
            onCheckExpense={getExpenseDetails}
            onPayShare={payShare}
            loading={loading}
          />
        </div>
      )}
      
      <StatusMessage status={status} />
    </div>
  );
}

export default App;