import React, { useMemo } from 'react';
import { Employee, TransportStatus } from '../types';
import { Users, CheckCircle } from 'lucide-react';
import { BarChart, Bar, XAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';

interface Props {
  data: Employee[];
}

const StatsOverview: React.FC<Props> = ({ data }) => {
  const stats = useMemo(() => {
    let pending = 0;
    let dropped = 0;
    let self = 0;

    data.forEach(emp => {
        emp.weeklyStatus.forEach(status => {
            if (status === TransportStatus.PENDING) pending++;
            else if (status === TransportStatus.DROPPED_OFF) dropped++;
            else if (status === TransportStatus.SELF_TRAVEL) self++;
            // Note: ON_BOARD status is tracked in data but hidden from dashboard overview
        });
    });

    return {
      total: data.length * 5, // Total slots (Employees * 5 weeks)
      pending,
      dropped,
      self
    };
  }, [data]);

  const chartData = [
    { name: 'Pending', value: stats.pending, color: '#fbbf24' },
    { name: 'Dropped', value: stats.dropped, color: '#22c55e' },
    { name: 'Self', value: stats.self, color: '#94a3b8' },
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
      <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100 flex items-center space-x-4">
        <div className="p-3 bg-blue-50 text-blue-600 rounded-lg">
          <Users size={24} />
        </div>
        <div>
          <p className="text-sm text-slate-500 font-medium">Total Slots</p>
          <h3 className="text-2xl font-bold text-slate-800">{stats.total}</h3>
        </div>
      </div>

      <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100 flex items-center space-x-4">
        <div className="p-3 bg-green-50 text-green-600 rounded-lg">
          <CheckCircle size={24} />
        </div>
        <div>
          <p className="text-sm text-slate-500 font-medium">Completed</p>
          <h3 className="text-2xl font-bold text-slate-800">{stats.dropped}</h3>
        </div>
      </div>
      
      <div className="col-span-1 md:col-span-1 bg-white p-4 rounded-xl shadow-sm border border-slate-100 h-32">
         <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData}>
              <XAxis dataKey="name" hide />
              <Tooltip cursor={{fill: 'transparent'}} />
              <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                {chartData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Bar>
            </BarChart>
         </ResponsiveContainer>
      </div>
    </div>
  );
};

export default StatsOverview;