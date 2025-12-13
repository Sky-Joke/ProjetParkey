import React from 'react';

function StatsSection() {
  const stats = [
    { value: "1,247", label: "Places Tokenisées", icon: "fa-parking" },
    { value: "892", label: "Propriétaires", icon: "fa-users" },
    { value: "3.2 ETH", label: "Volume Total", icon: "fa-chart-line" },
    { value: "456", label: "Transactions", icon: "fa-exchange-alt" }
  ];

  return (
    <section className="container mx-auto px-4 py-12">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <div
            key={index}
            className="bg-white/5 backdrop-blur-md border border-white/10 rounded-xl p-6 text-center hover:bg-white/10 transition-all"
          >
            <div className="text-4xl font-bold text-primary mb-2">{stat.value}</div>
            <div className="text-gray-400">{stat.label}</div>
          </div>
        ))}
      </div>
    </section>
  );
}

export default StatsSection;