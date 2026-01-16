import React, { useState, useMemo } from 'react';
import { Employee, TransportStatus, DayOfWeek } from '../types';
import { Edit2, Trash2, Save, X, Plus, Clock, Calendar } from 'lucide-react';

interface Props {
  data: Employee[];
  onUpdate: (updatedData: Employee[]) => void;
}

const DAYS: DayOfWeek[] = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const COMPANY_OPTIONS = [
  'Dai 1', 'Dai 2', 'Dai 3', 
  'Haga-A', 'Haga-B', 
  'Akagi', 'Ak.rejoko', 'Okara', 
  'Souji AK'
];

const PICKUP_OPTIONS = [
  'Apart', 'Eki', 'Kodomo', 'Rokmachi', 
  'Mistumata', 'SHIN MAE', 'Lowson', 
  'Self', 'Eki Cycle', 'Self(kodomo)', 
  'Dai-3', 'Ministop'
];

const getToday = (): DayOfWeek => {
  const days: DayOfWeek[] = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[new Date().getDay()];
};

const getCurrentTime = (): string => {
  const now = new Date();
  return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
};

const AdminPanel: React.FC<Props> = ({ data, onUpdate }) => {
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<Partial<Employee>>({});
  const [selectedDay, setSelectedDay] = useState<DayOfWeek>(getToday());

  // Group data by hour
  const groupedData = useMemo(() => {
    const dayFiltered = data.filter(d => d.day === selectedDay);
    const sorted = [...dayFiltered].sort((a, b) => a.time.localeCompare(b.time));
    
    const groups: Record<string, Employee[]> = {};

    sorted.forEach(emp => {
      const hourStr = emp.time.split(':')[0];
      const hour = parseInt(hourStr, 10);
      const displayHour = isNaN(hour) ? 'Unknown' : hour.toString().padStart(2, '0');
      // Label the group by the full hour range
      const key = isNaN(hour) ? 'Unscheduled' : `${displayHour}:00 - ${displayHour}:59`;
      
      if (!groups[key]) groups[key] = [];
      groups[key].push(emp);
    });

    return Object.keys(groups).sort().map(key => ({
      title: key,
      employees: groups[key]
    }));
  }, [data, selectedDay]);

  // Distinct colors for different shifts to make them easily distinguishable
  const SHIFT_COLORS = [
    { bg: 'bg-blue-50', border: 'border-blue-500', text: 'text-blue-800', badge: 'bg-blue-100 text-blue-700' },
    { bg: 'bg-emerald-50', border: 'border-emerald-500', text: 'text-emerald-800', badge: 'bg-emerald-100 text-emerald-700' },
    { bg: 'bg-purple-50', border: 'border-purple-500', text: 'text-purple-800', badge: 'bg-purple-100 text-purple-700' },
    { bg: 'bg-amber-50', border: 'border-amber-500', text: 'text-amber-800', badge: 'bg-amber-100 text-amber-700' },
    { bg: 'bg-rose-50', border: 'border-rose-500', text: 'text-rose-800', badge: 'bg-rose-100 text-rose-700' },
    { bg: 'bg-cyan-50', border: 'border-cyan-500', text: 'text-cyan-800', badge: 'bg-cyan-100 text-cyan-700' },
    { bg: 'bg-indigo-50', border: 'border-indigo-500', text: 'text-indigo-800', badge: 'bg-indigo-100 text-indigo-700' },
  ];

  const handleDelete = (id: string) => {
    if (confirm('Are you sure you want to delete this record?')) {
      onUpdate(data.filter(e => e.id !== id));
    }
  };

  const handleEditClick = (employee: Employee) => {
    setEditingId(employee.id);
    setEditForm(JSON.parse(JSON.stringify(employee)));
  };

  const handleSave = () => {
    if (editingId && editForm) {
      onUpdate(data.map(e => (e.id === editingId ? { ...e, ...editForm } as Employee : e)));
      setEditingId(null);
      setEditForm({});
    }
  };

  const handleCancel = () => {
    setEditingId(null);
    setEditForm({});
  };

  const handleChange = (field: keyof Employee, value: string) => {
    setEditForm(prev => ({ ...prev, [field]: value }));
  };

  const handleWeekChange = (index: number, value: TransportStatus) => {
    setEditForm(prev => {
        const newWeeks = [...(prev.weeklyStatus || [])];
        newWeeks[index] = value;
        return { ...prev, weeklyStatus: newWeeks };
    });
  };

  const handleAddNew = () => {
    const newEmployee: Employee = {
      id: Math.random().toString(36).substr(2, 9),
      serialNumber: String(data.length + 1),
      name: "New Employee",
      pickupLocation: '', // Initialize as empty to show placeholder
      company: '', // Initialize as empty to show placeholder
      time: getCurrentTime(), // Default to current time
      day: selectedDay, // Default to currently viewed day
      weeklyStatus: Array(5).fill(TransportStatus.PENDING),
      lastUpdated: new Date().toISOString()
    };
    onUpdate([newEmployee, ...data]);
    handleEditClick(newEmployee);
  };

  const getStatusColor = (status: TransportStatus) => {
      switch(status) {
          case TransportStatus.ON_BOARD: return 'bg-blue-100 text-blue-700 border-blue-200';
          case TransportStatus.DROPPED_OFF: return 'bg-green-100 text-green-700 border-green-200';
          case TransportStatus.SELF_TRAVEL: return 'bg-slate-100 text-slate-700 border-slate-200';
          case TransportStatus.ABSENT: return 'bg-red-100 text-red-700 border-red-200';
          default: return 'bg-yellow-50 text-yellow-700 border-yellow-200';
      }
  };

  const getStatusShort = (status: TransportStatus) => {
      switch(status) {
          case TransportStatus.ON_BOARD: return 'Bus';
          case TransportStatus.DROPPED_OFF: return 'Ok';
          case TransportStatus.SELF_TRAVEL: return 'Self';
          case TransportStatus.ABSENT: return 'X';
          default: return '-';
      }
  }

  return (
    <div className="space-y-6">
      {/* Day Selector */}
      <div className="bg-white p-2 rounded-xl shadow-sm border border-slate-200 flex overflow-x-auto no-scrollbar">
        {DAYS.map(day => (
            <button
                key={day}
                onClick={() => setSelectedDay(day)}
                className={`flex-1 min-w-[100px] px-4 py-2 rounded-lg text-sm font-medium transition-all
                    ${selectedDay === day 
                        ? 'bg-slate-800 text-white shadow-md' 
                        : 'text-slate-600 hover:bg-slate-50'}`}
            >
                {day}
            </button>
        ))}
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex flex-col md:flex-row justify-between items-center gap-4">
            <h2 className="text-lg font-semibold text-slate-800 flex items-center gap-2">
                <Calendar size={18} className="text-primary" />
                Schedule: {selectedDay}
            </h2>
            <div className="flex gap-2">
            <button 
                onClick={handleAddNew}
                className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
                <Plus size={18} />
                Add Row
            </button>
            </div>
        </div>

        <div className="overflow-x-auto">
            <table className="w-full text-left text-sm whitespace-nowrap">
            <thead className="bg-slate-50 text-slate-600 font-medium border-b border-slate-200">
                <tr>
                <th className="p-4 w-24">Time</th>
                <th className="p-4">Name</th>
                <th className="p-4">Pickup</th>
                <th className="p-4">Company</th>
                <th className="p-4 text-center w-12">W1</th>
                <th className="p-4 text-center w-12">W2</th>
                <th className="p-4 text-center w-12">W3</th>
                <th className="p-4 text-center w-12">W4</th>
                <th className="p-4 text-center w-12">W5</th>
                <th className="p-4 text-right">Actions</th>
                </tr>
            </thead>
            
            {groupedData.length === 0 ? (
                 <tbody>
                    <tr>
                        <td colSpan={10} className="p-8 text-center text-slate-400">
                            No shifts scheduled for {selectedDay}. Click "Add Row" to create one.
                        </td>
                    </tr>
                 </tbody>
            ) : (
                groupedData.map((group, index) => {
                const style = SHIFT_COLORS[index % SHIFT_COLORS.length];
                return (
                <tbody key={group.title} className="divide-y divide-slate-100">
                    {/* Group Header */}
                    <tr className={`${style.bg} border-l-4 ${style.border}`}>
                    <td colSpan={10} className="p-3">
                        <div className="flex items-center gap-2">
                            <Clock size={16} className={style.text} />
                            <span className={`font-bold ${style.text}`}>{group.title} Shift</span>
                            <span className={`text-xs px-2 py-0.5 rounded-full ${style.badge} ml-2 font-medium`}>
                            {group.employees.length} Staff
                            </span>
                        </div>
                    </td>
                    </tr>

                    {/* Group Rows */}
                    {group.employees.map((row) => (
                        <tr key={row.id} className={`hover:bg-slate-50 transition-colors border-l-4 ${style.border} border-l-transparent hover:border-l-gray-300`}>
                        {editingId === row.id ? (
                            <>
                            <td className="p-4"><input type="time" className="border p-1 rounded w-full" value={editForm.time} onChange={e => handleChange('time', e.target.value)} /></td>
                            <td className="p-4"><input className="border p-1 rounded w-32" value={editForm.name} onChange={e => handleChange('name', e.target.value)} /></td>
                            <td className="p-4">
                                <select 
                                    className={`border p-1 rounded w-32 bg-white text-sm ${editForm.pickupLocation ? 'text-black' : 'text-slate-400'}`}
                                    value={editForm.pickupLocation || ''} 
                                    onChange={e => handleChange('pickupLocation', e.target.value)}
                                >
                                    <option value="" disabled>Select Pickup</option>
                                    {PICKUP_OPTIONS.map(opt => (
                                        <option key={opt} value={opt} className="text-black">{opt}</option>
                                    ))}
                                    {/* Preserve existing value if not in list */}
                                    {editForm.pickupLocation && !PICKUP_OPTIONS.includes(editForm.pickupLocation) && (
                                        <option value={editForm.pickupLocation} className="text-black">{editForm.pickupLocation}</option>
                                    )}
                                </select>
                            </td>
                            <td className="p-4">
                                <select 
                                    className={`border p-1 rounded w-32 bg-white text-sm ${editForm.company ? 'text-black' : 'text-slate-400'}`}
                                    value={editForm.company || ''} 
                                    onChange={e => handleChange('company', e.target.value)}
                                >
                                    <option value="" disabled>Select Company</option>
                                    {COMPANY_OPTIONS.map(opt => (
                                        <option key={opt} value={opt} className="text-black">{opt}</option>
                                    ))}
                                    {/* Preserve existing value if not in list */}
                                    {editForm.company && !COMPANY_OPTIONS.includes(editForm.company) && (
                                        <option value={editForm.company} className="text-black">{editForm.company}</option>
                                    )}
                                </select>
                            </td>
                            {[0, 1, 2, 3, 4].map(idx => (
                                <td key={idx} className="p-2">
                                    <select 
                                        className="border p-1 rounded w-14 text-xs text-black" 
                                        value={editForm.weeklyStatus?.[idx]} 
                                        onChange={e => handleWeekChange(idx, e.target.value as any)}
                                    >
                                        <option value={TransportStatus.PENDING}>-</option>
                                        <option value={TransportStatus.ON_BOARD}>Bus</option>
                                        <option value={TransportStatus.DROPPED_OFF}>Ok</option>
                                        <option value={TransportStatus.SELF_TRAVEL}>Self</option>
                                        <option value={TransportStatus.ABSENT}>X</option>
                                    </select>
                                </td>
                            ))}
                            <td className="p-4 text-right flex justify-end gap-2">
                                <button onClick={handleSave} className="text-green-600 hover:bg-green-50 p-1 rounded"><Save size={18} /></button>
                                <button onClick={handleCancel} className="text-slate-500 hover:bg-slate-100 p-1 rounded"><X size={18} /></button>
                            </td>
                            </>
                        ) : (
                            <>
                            <td className="p-4 font-mono font-medium text-slate-700">{row.time}</td>
                            <td className="p-4 font-medium text-slate-800">{row.name}</td>
                            <td className="p-4 text-slate-600">{row.pickupLocation}</td>
                            <td className="p-4 text-slate-600">{row.company}</td>
                            {row.weeklyStatus.map((status, idx) => (
                                <td key={idx} className="p-2 text-center">
                                    <span className={`inline-flex items-center justify-center w-8 h-8 rounded-full text-xs font-bold border ${getStatusColor(status)}`}>
                                        {getStatusShort(status)}
                                    </span>
                                </td>
                            ))}
                            <td className="p-4 text-right flex justify-end gap-2">
                                <button onClick={() => handleEditClick(row)} className="text-blue-600 hover:bg-blue-50 p-1 rounded"><Edit2 size={16} /></button>
                                <button onClick={() => handleDelete(row.id)} className="text-red-500 hover:bg-red-50 p-1 rounded"><Trash2 size={16} /></button>
                            </td>
                            </>
                        )}
                        </tr>
                    ))}
                </tbody>
                );
            }))}
            </table>
        </div>
      </div>
    </div>
  );
};

export default AdminPanel;