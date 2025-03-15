import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from './App';

describe('App', () => {
  test('renders React App 1 heading', () => {
    render(<App />);
    const headingElement = screen.getByText(/React App 1/i);
    expect(headingElement).toBeInTheDocument();
  });
});
