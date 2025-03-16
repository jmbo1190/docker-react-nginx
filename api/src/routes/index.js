const express = require('express');
const router = express.Router();

// Sample data
let items = [
  { id: 1, name: 'Item 1' },
  { id: 2, name: 'Item 2' }
];

// GET /api/items
router.get('/items', (req, res) => {
  res.json(items);
});

// GET /api/items/:id
router.get('/items/:id', (req, res) => {
  const item = items.find(i => i.id === parseInt(req.params.id));
  if (!item) return res.status(404).json({ error: 'Item not found' });
  res.json(item);
});

// POST /api/items
router.post('/items', (req, res) => {
  const item = {
    id: items.length + 1,
    name: req.body.name
  };
  items.push(item);
  res.status(201).json(item);
});

// DELETE /api/items/:id
router.delete('/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const itemIndex = items.findIndex(i => i.id === id);
  
  if (itemIndex === -1) {
    return res.status(404).json({ error: 'Item not found' });
  }
  
  const deletedItem = items.splice(itemIndex, 1)[0];
  res.json({ message: 'Item deleted', item: deletedItem });
});

// Reset endpoint for testing
router.post('/reset', (req, res) => {
    items = [
        { id: 1, name: 'Item 1' },
        { id: 2, name: 'Item 2' }
    ];
    res.json({ message: 'Data reset to initial state' });
});

module.exports = router;