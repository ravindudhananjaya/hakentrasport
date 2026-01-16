import React, { useState, useMemo } from 'react';
import { Employee, TransportStatus, DayOfWeek } from '../types';
import { Search, MapPin, Clock, Check, X, ChevronDown, Calendar, User, UserX } from 'lucide-react';

interface Props {
  data: Employee[];
  onStatusChange: (id: string, weekIndex: number, status: TransportStatus) => void;
}

const DAYS: DayOfWeek[] = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const SHIFT_COLORS = [
  { bg: 'bg-blue-50', border: 'border-blue-500', text: 'text-blue-800', badge: 'bg-blue-100 text-blue-700', divider: 'divide-blue-100' },
  { bg: 'bg-emerald-50', border: 'border-emerald-500', text: 'text-emerald-800', badge: 'bg-emerald-100 text-emerald-700', divider: 'divide-emerald-100' },
  { bg: 'bg-purple-50', border: 'border-purple-500', text: 'text-purple-800', badge: 'bg-purple-100 text-purple-700', divider: 'divide-purple-100' },
  { bg: 'bg-amber-50', border: 'border-amber-500', text: 'text-amber-800', badge: 'bg-amber-100 text-amber-700', divider: 'divide-amber-100' },
  { bg: 'bg-rose-50', border: 'border-rose-500', text: 'text-rose-800', badge: 'bg-rose-100 text-rose-700', divider: 'divide-rose-100' },
  { bg: 'bg-cyan-50', border: 'border-cyan-500', text: 'text-cyan-800', badge: 'bg-cyan-100 text-cyan-700', divider: 'divide-cyan-100' },
  { bg: 'bg-indigo-50', border: 'border-indigo-500', text: 'text-indigo-800', badge: 'bg-indigo-100 text-indigo-700', divider: 'divide-indigo-100' },
];

const getToday = (): DayOfWeek => {
  const days: DayOfWeek[] = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  return days[new Date().getDay()];
};

const UserCheckIn: React.FC<Props> = ({ data, onStatusChange }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedWeek, setSelectedWeek] = useState<number>(0);
  const [selectedDay, setSelectedDay] = useState<DayOfWeek>(getToday());

  const filteredData = useMemo(() => {
    // First filter by day
    let result = data.filter(d => d.day === selectedDay);
    
    // Sort by time (ascending)
    result.sort((a, b) => a.time.localeCompare(b.time));
    
    if (searchTerm) {
        const lowerTerm = searchTerm.toLowerCase();
        result = result.filter(e => 
          e.name.toLowerCase().includes(lowerTerm) || 
          e.serialNumber.includes(lowerTerm)
        );
    }
    return result;
  }, [data, searchTerm, selectedDay]);

  const groupedData = useMemo(() => {
    const groups: Record<string, Employee[]> = {};

    filteredData.forEach(emp => {
      const hourStr = emp.time.split(':')[0];
      const hour = parseInt(hourStr, 10);
      const displayHour = isNaN(hour) ? 'Unknown' : hour.toString().padStart(2, '0');
      const key = isNaN(hour) ? 'Unscheduled' : `${displayHour}:00 - ${displayHour}:59`;
      
      if (!groups[key]) groups[key] = [];
      groups[key].push(emp);
    });

    return Object.keys(groups).sort().map(key => ({
      title: key,
      employees: groups[key]
    }));
  }, [filteredData]);

  const counts = useMemo(() => {
      let dropped = 0;
      let absent = 0;
      filteredData.forEach(e => {
          if (e.weeklyStatus[selectedWeek] === TransportStatus.DROPPED_OFF) dropped++;
          if (e.weeklyStatus[selectedWeek] === TransportStatus.ABSENT) absent++;
      });
      return { dropped, absent, total: filteredData.length };
  }, [filteredData, selectedWeek]);

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      
      {/* Top Controls */}
      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-200 space-y-4 sticky top-16 z-40">
        {/* Day Selector */}
        <div className="flex overflow-x-auto no-scrollbar gap-2 pb-2">
            {DAYS.map(day => (
                <button
                    key={day}
                    onClick={() => setSelectedDay(day)}
                    className={`flex-1 min-w-[90px] px-3 py-2 rounded-lg text-sm font-medium transition-all whitespace-nowrap
                        ${selectedDay === day 
                            ? 'bg-slate-800 text-white shadow-md' 
                            : 'bg-slate-50 text-slate-600 hover:bg-slate-100'}`}
                >
                    {day}
                </button>
            ))}
        </div>

        <div className="flex flex-col md:flex-row gap-4 justify-between items-center">
             {/* Week Selector */}
            <div className="flex gap-1 overflow-x-auto w-full md:w-auto">
                {[0, 1, 2, 3, 4].map((week) => (
                    <button
                        key={week}
                        onClick={() => setSelectedWeek(week)}
                        className={`px-3 py-1.5 rounded-md text-xs font-bold uppercase tracking-wider transition-colors flex-1 md:flex-none
                            ${selectedWeek === week 
                                ? 'bg-primary text-white' 
                                : 'bg-slate-100 text-slate-500 hover:bg-slate-200'}`}
                    >
                        Week {week + 1}
                    </button>
                ))}
            </div>

            {/* Stats */}
            <div className="flex gap-4 text-sm font-medium">
                <div className="flex items-center gap-1.5 text-green-600 bg-green-50 px-3 py-1 rounded-full">
                    <Check size={14} />
                    <span>Done: {counts.dropped}</span>
                </div>
                 <div className="flex items-center gap-1.5 text-red-600 bg-red-50 px-3 py-1 rounded-full">
                    <UserX size={14} />
                    <span>Absent: {counts.absent}</span>
                </div>
                 <div className="flex items-center gap-1.5 text-slate-600 bg-slate-50 px-3 py-1 rounded-full">
                    <User size={14} />
                    <span>Total: {counts.total}</span>
                </div>
            </div>
        </div>

        {/* Search */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
          <input
            type="text"
            placeholder="Search passenger..."
            className="w-full pl-10 pr-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition-all bg-white text-black font-medium placeholder:text-slate-400"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {/* Grouped List View */}
      <div className="space-y-6">
        {filteredData.length === 0 ? (
            <div className="text-center p-12 text-slate-400 bg-white rounded-xl border border-dashed border-slate-200">
                <Calendar size={48} className="mx-auto mb-2 opacity-20" />
                No passengers found for {selectedDay}.
            </div>
        ) : (
            groupedData.map((group, index) => {
                const style = SHIFT_COLORS[index % SHIFT_COLORS.length];
                return (
                    <div key={group.title} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                        {/* Group Header */}
                        <div className={`${style.bg} border-b ${style.border} px-4 py-3 flex items-center justify-between`}>
                            <div className="flex items-center gap-2">
                                <Clock size={18} className={style.text} />
                                <span className={`font-bold text-lg ${style.text}`}>{group.title} Shift</span>
                            </div>
                            <span className={`text-xs px-2.5 py-0.5 rounded-full font-bold ${style.badge}`}>
                                {group.employees.length} Pax
                            </span>
                        </div>

                        {/* List Items */}
                        <div className={`divide-y ${style.divider}`}>
                            {group.employees.map((employee) => {
                                const currentStatus = employee.weeklyStatus[selectedWeek];
                                return (
                                    <div key={employee.id} className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4 hover:bg-slate-50 transition-colors">
                                        {/* Passenger Info */}
                                        <div className="flex items-start gap-4">
                                            <div className="bg-slate-100 text-slate-600 rounded-lg p-2 text-center min-w-[60px]">
                                                <span className="block text-lg font-bold leading-none">{employee.time}</span>
                                                <span className="text-[10px] uppercase font-bold text-slate-400">Time</span>
                                            </div>
                                            <div>
                                                <h3 className="font-bold text-slate-800 text-lg flex items-center gap-2">
                                                    {employee.name}
                                                    <span className="text-xs font-normal text-slate-400 bg-slate-100 px-1.5 py-0.5 rounded">#{employee.serialNumber}</span>
                                                </h3>
                                                <div className="flex items-center gap-3 text-sm text-slate-500 mt-1">
                                                    <span className="flex items-center gap-1 font-medium text-slate-700">
                                                        <MapPin size={14} className="text-primary" /> {employee.pickupLocation}
                                                    </span>
                                                    <span className="w-1 h-1 bg-slate-300 rounded-full"></span>
                                                    <span>{employee.company}</span>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Actions */}
                                        <div className="flex items-center gap-2 self-end sm:self-auto w-full sm:w-auto">
                                            <button
                                                onClick={() => onStatusChange(employee.id, selectedWeek, TransportStatus.DROPPED_OFF)}
                                                className={`flex-1 sm:flex-none px-6 py-2.5 rounded-lg text-sm font-bold flex items-center justify-center gap-2 transition-all border
                                                    ${currentStatus === TransportStatus.DROPPED_OFF 
                                                        ? 'bg-green-600 text-white border-green-600 shadow-md ring-2 ring-green-200' 
                                                        : 'bg-white text-slate-600 border-slate-200 hover:bg-green-50 hover:text-green-600'}`}
                                            >
                                                <Check size={18} />
                                                <span>Ok</span>
                                            </button>

                                            <button
                                                onClick={() => onStatusChange(employee.id, selectedWeek, TransportStatus.ABSENT)}
                                                className={`flex-1 sm:flex-none px-6 py-2.5 rounded-lg text-sm font-bold flex items-center justify-center gap-2 transition-all border
                                                    ${currentStatus === TransportStatus.ABSENT 
                                                        ? 'bg-red-600 text-white border-red-600 shadow-md ring-2 ring-red-200' 
                                                        : 'bg-white text-slate-600 border-slate-200 hover:bg-red-50 hover:text-red-600'}`}
                                            >
                                                <X size={18} />
                                                <span>Absent</span>
                                            </button>
                                            
                                            <div className="relative group ml-2">
                                                <div className={`w-3 h-3 rounded-full ${currentStatus === TransportStatus.SELF_TRAVEL ? 'bg-slate-400' : 'bg-transparent'}`}></div>
                                                <button
                                                    onClick={() => onStatusChange(employee.id, selectedWeek, TransportStatus.SELF_TRAVEL)}
                                                    className={`absolute right-0 top-1/2 -translate-y-1/2 opacity-0 group-hover:opacity-100 px-2 py-1 bg-slate-800 text-white text-xs rounded shadow-lg whitespace-nowrap z-10`}
                                                >
                                                    Mark Self
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                );
            })
        )}
      </div>
    </div>
  );
};

export default UserCheckIn;