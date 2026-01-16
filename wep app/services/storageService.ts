import { Employee, TransportStatus } from '../types';
import { INITIAL_DATA } from '../constants';

const STORAGE_KEY = 'transport_schedule_db_v3'; // Bumped version for day migration

export const getEmployees = (): Employee[] => {
  const stored = localStorage.getItem(STORAGE_KEY);
  if (!stored) {
    // Check for old version
    const oldStored = localStorage.getItem('transport_schedule_db_v2');
    if (oldStored) {
        try {
            const parsedOld = JSON.parse(oldStored);
            // Migrate old data to include day='Monday'
            const migrated = parsedOld.map((emp: any) => ({
                ...emp,
                day: emp.day || 'Monday',
                weeklyStatus: emp.weeklyStatus || Array(5).fill(emp.status || TransportStatus.PENDING),
                status: undefined
            }));
            saveEmployees(migrated);
            return migrated;
        } catch(e) {
            console.error("Migration failed", e);
        }
    }

    // Seed initial data if empty
    localStorage.setItem(STORAGE_KEY, JSON.stringify(INITIAL_DATA));
    return INITIAL_DATA;
  }
  try {
    const parsedData = JSON.parse(stored);
    
    // Runtime migration check
    if (parsedData.length > 0) {
        let needsSave = false;
        const migrated = parsedData.map((emp: any) => {
            let newEmp = { ...emp };
            
            if (!newEmp.weeklyStatus) {
                newEmp.weeklyStatus = Array(5).fill(newEmp.status || TransportStatus.PENDING);
                delete newEmp.status;
                needsSave = true;
            }
            if (!newEmp.day) {
                newEmp.day = 'Monday';
                needsSave = true;
            }
            return newEmp;
        });

        if (needsSave) {
            saveEmployees(migrated);
            return migrated;
        }
    }

    return parsedData;
  } catch (e) {
    console.error("Failed to parse storage", e);
    return INITIAL_DATA;
  }
};

export const saveEmployees = (employees: Employee[]) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(employees));
};

export const updateEmployeeStatus = (id: string, weekIndex: number, status: TransportStatus): Employee[] => {
  const employees = getEmployees();
  const updated = employees.map(emp => {
    if (emp.id === id) {
        const newWeeks = [...emp.weeklyStatus];
        newWeeks[weekIndex] = status;
        return { ...emp, weeklyStatus: newWeeks, lastUpdated: new Date().toISOString() };
    }
    return emp;
  });
  saveEmployees(updated);
  return updated;
};

export const resetData = (): Employee[] => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(INITIAL_DATA));
  return INITIAL_DATA;
};
