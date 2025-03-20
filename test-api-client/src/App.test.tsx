import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from './App';

describe('App', () => {
  test('renders Test API Client (React App) heading', () => {
    render(<App />);
    const headingElement = screen.getByText(/Test API Client \(React App\)/i);
    expect(headingElement).toBeInTheDocument();
  });
});
