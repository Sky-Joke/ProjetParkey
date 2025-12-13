import React, { useEffect } from 'react';

function Notification({ message, type, onClose }) {
  const colors = {
    success: 'bg-accent',
    error: 'bg-red-500',
    info: 'bg-primary'
  };

  useEffect(() => {
    const timer = setTimeout(() => {
      onClose();
    }, 3000);

    return () => clearTimeout(timer);
  }, [onClose]);

  return (
    <div className={`fixed top-4 right-4 ${colors[type]} text-white px-6 py-4 rounded-lg shadow-lg z-50 animate-fade-in`}>
      {message}
    </div>
  );
}

export default Notification;