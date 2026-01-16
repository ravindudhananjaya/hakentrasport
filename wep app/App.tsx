import React, { useState, useEffect } from 'react';
import { ViewMode, Employee, TransportStatus } from './types';
import { getEmployees, saveEmployees } from './services/storageService';
import StatsOverview from './components/StatsOverview';
import AdminPanel from './components/AdminPanel';
import UserCheckIn from './components/UserCheckIn';
import { Shield, Bus, RefreshCw } from 'lucide-react';

const App: React.FC = () => {
  const [data, setData] = useState<Employee[]>([]);
  const [mode, setMode] = useState<ViewMode>('USER');

  useEffect(() => {
    setData(getEmployees());
  }, []);

  const handleUpdate = (updatedData: Employee[]) => {
    setData(updatedData);
    saveEmployees(updatedData);
  };

  const handleStatusChange = (id: string, weekIndex: number, status: TransportStatus) => {
    const updated = data.map(e => {
        if(e.id === id) {
            const newWeeks = [...e.weeklyStatus];
            newWeeks[weekIndex] = status;
            return { ...e, weeklyStatus: newWeeks, lastUpdated: new Date().toISOString() };
        }
        return e;
    });
    handleUpdate(updated);
  };

  const handleReset = () => {
      if(confirm("Reset all data to default? This cannot be undone.")) {
         localStorage.clear();
         window.location.reload();
      }
  }

  return (
    <div className="min-h-screen pb-20">
      {/* Navigation */}
      <nav className="bg-white border-b border-slate-200 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center text-white font-bold">
                TS
              </div>
              <span className="font-bold text-slate-800 text-lg hidden sm:block">Transport Scheduler</span>
            </div>
            
            <div className="flex items-center gap-2">
              <button
                onClick={() => setMode('USER')}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-all flex items-center gap-2
                  ${mode === 'USER' ? 'bg-slate-800 text-white' : 'text-slate-600 hover:bg-slate-100'}`}
              >
                <Bus size={16} />
                Driver Mode
              </button>
              <button
                onClick={() => setMode('ADMIN')}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-all flex items-center gap-2
                  ${mode === 'ADMIN' ? 'bg-primary text-white' : 'text-slate-600 hover:bg-slate-100'}`}
              >
                <Shield size={16} />
                Admin
              </button>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8 flex justify-between items-end">
          <div>
            <h1 className="text-3xl font-bold text-slate-900">
              {mode === 'ADMIN' ? 'Transport Management' : 'Driver Attendance'}
            </h1>
            <p className="text-slate-500 mt-1">
              {mode === 'ADMIN' 
                ? 'Manage roster, view statistics, and optimize routes.' 
                : 'Mark passenger attendance and pickup status.'}
            </p>
          </div>
          {mode === 'ADMIN' && (
              <button onClick={handleReset} className="text-slate-400 hover:text-red-500 text-xs flex items-center gap-1">
                  <RefreshCw size={12} /> Reset Data
              </button>
          )}
        </div>

        <StatsOverview data={data} />

        <div className="animate-fadeIn">
          {mode === 'ADMIN' ? (
            <AdminPanel data={data} onUpdate={handleUpdate} />
          ) : (
            <UserCheckIn data={data} onStatusChange={handleStatusChange} />
          )}
        </div>
      </main>
    </div>
  );
};

export default App;