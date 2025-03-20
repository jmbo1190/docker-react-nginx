import React, { useState, useEffect } from 'react';
import './App.css';

interface Item {
  id: number;
  name: string;
}

function App() {
  const [items, setItems] = useState<Item[]>([]);
  const [newItemName, setNewItemName] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    try {
      const response = await fetch('/api/items');
      if (!response.ok) throw new Error('Failed to fetch items');
      const data = await response.json();
      setItems(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch items');
    }
  };

  const addItem = async () => {
    try {
      const response = await fetch('/api/items', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: newItemName }),
      });
      if (!response.ok) throw new Error('Failed to add item');
      const newItem = await response.json();
      setItems([...items, newItem]);
      setNewItemName('');
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to add item');
    }
  };

  return (
    <div style={{ padding: '20px' }}>
      <h1>Test API Client (React App)</h1>
      
      <div style={{ marginBottom: '20px' }}>
        <h2>Items from API</h2>
        {error && <p style={{ color: 'red' }}>{error}</p>}
        <ul>
          {items.map(item => (
            <li key={item.id}>{item.name}</li>
          ))}
        </ul>
        <div style={{ marginTop: '10px' }}>
          <input
            type="text"
            value={newItemName}
            onChange={(e) => setNewItemName(e.target.value)}
            placeholder="New item name"
          />
          <button 
            onClick={addItem}
            disabled={!newItemName}
            style={{ marginLeft: '10px' }}
          >
            Add Item
          </button>
        </div>
      </div>
    </div>
  );
}

export default App;
