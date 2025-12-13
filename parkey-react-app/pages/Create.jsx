import React from 'react';
import CreateParkingForm from '../components/CreateParkingForm';

function Create() {
  return (
    <div className="container mx-auto px-4 py-12">
      <div className="max-w-2xl mx-auto bg-white/5 backdrop-blur-md border border-white/10 rounded-2xl p-8">
        <h1 className="text-3xl font-bold mb-6 text-center">Créer un Token de Parking</h1>
        <p className="text-gray-400 text-center mb-8">
          Remplissez les informations ci-dessous pour tokeniser votre place de parking
        </p>
        <CreateParkingForm />
      </div>
    </div>
  );
}

export default Create;