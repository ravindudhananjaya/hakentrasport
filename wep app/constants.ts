import { Employee, TransportStatus, DayOfWeek } from './types';

// Helper to generate IDs
const uuid = () => Math.random().toString(36).substr(2, 9);

// Helper for default weeks (5 weeks of PENDING)
const defaultWeeks = (initialStatus: TransportStatus = TransportStatus.PENDING) => {
    const weeks = Array(5).fill(TransportStatus.PENDING);
    // Set the first week to the initial status provided in the original data for continuity
    weeks[0] = initialStatus; 
    return weeks;
};

const createEmp = (serial: string, name: string, pickup: string, company: string, time: string, day: DayOfWeek = 'Monday', status: TransportStatus = TransportStatus.PENDING): Employee => ({
    id: uuid(),
    serialNumber: serial,
    name,
    pickupLocation: pickup,
    company,
    time,
    day,
    weeklyStatus: defaultWeeks(status),
    lastUpdated: new Date().toISOString()
});

// Parsed and cleaned data from the user's CSV
export const INITIAL_DATA: Employee[] = [
  // Monday Shifts
  createEmp("1", "Kanchan", "Apart", "Dai 1", "03:10", 'Monday'),
  createEmp("2", "Roshan Sharma", "Eki", "Dai 2", "04:20", 'Monday'),
  createEmp("3", "Binaya Adhikari", "Kodomo", "Dai-2", "04:20", 'Monday'),
  createEmp("4", "Laxmi", "Kodomo", "Dai 1", "04:20", 'Monday'),
  createEmp("5", "Sonika Pathak", "Kodomo", "Dai-1", "04:25", 'Monday'),
  createEmp("8", "Kamal Bhandari", "Rokumachi", "Akagi", "04:00", 'Monday'),
  createEmp("9", "Harka", "Rokumachi", "Akagi", "04:00", 'Monday'),
  createEmp("10", "Saleem", "Rokumachi", "Dai-3", "04:00", 'Monday'),
  createEmp("11", "Mohiddin", "Eki", "Dai-3", "04:20", 'Monday'),
  createEmp("12", "Dorje Tamang", "Shi-mae", "Dai-1", "05:00", 'Monday'),
  createEmp("14", "Mina", "Shi-mae", "Akagi", "05:00", 'Monday'),
  createEmp("20", "Kushal", "EKI", "Dai 2", "05:20", 'Monday'),
  createEmp("24", "Niru Dhakal Kharel", "Self", "Haga-A", "05:20", 'Monday', TransportStatus.SELF_TRAVEL),
  createEmp("26", "Amir Shrestha", "Self", "Dai-3", "05:20", 'Monday', TransportStatus.SELF_TRAVEL),
  createEmp("30", "Kabir", "Rokumachi", "Dai-1", "06:00", 'Monday'),
  createEmp("34", "Bikram Bogati", "EKI", "Dai 3", "06:20", 'Monday'),
  createEmp("38", "Rome", "Eki", "Haga-B", "06:20", 'Monday', TransportStatus.SELF_TRAVEL),
  createEmp("45", "Harris", "Rokumachi", "Dai-3", "07:00", 'Monday'),
  createEmp("50", "Hein", "Eki", "Dai 1", "07:20", 'Monday'),
  createEmp("60", "Kushal Thapa", "Eki", "Dai-1", "09:20", 'Monday'),
  createEmp("70", "Dumidu", "EKI", "DAI 3", "13:20", 'Monday'),
  createEmp("72", "Prashan", "Eki", "Haga-A", "13:20", 'Monday', TransportStatus.SELF_TRAVEL),
  createEmp("74", "Manoj Tiwari", "Eki Cycle Park", "Akagi", "14:20", 'Monday'),
  createEmp("100", "Deinaru", "Eki Cycle Park", "Dai 3", "15:20", 'Monday', TransportStatus.SELF_TRAVEL),

  // Sample Tuesday Shifts (Different people/schedule as requested)
  createEmp("T1", "John Doe", "Eki", "Dai 1", "08:00", 'Tuesday'),
  createEmp("T2", "Jane Smith", "Kodomo", "Dai 2", "08:30", 'Tuesday'),
];
