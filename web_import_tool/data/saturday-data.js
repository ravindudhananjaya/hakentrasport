// Saturday Transport Schedule Data
const saturdayData = [
    // 9:20 Shift
    { serialNumber: '54', name: 'Rekha', pickupLocation: 'Eki', company: 'akagi', time: '9:20' },
    { serialNumber: '55', name: 'Santa', pickupLocation: 'Eki', company: 'akagi', time: '9:20' },
    { serialNumber: '56', name: 'Ramesh pun', pickupLocation: 'eki', company: 'Dal-2', time: '9:20' },
    { serialNumber: '59', name: 'kushal', pickupLocation: 'EKI', company: 'Dai1', time: '9:20' },
    { serialNumber: '60', name: 'Lokman', pickupLocation: 'Eki', company: 'Akagi', time: '9:20' },
    { serialNumber: '', name: 'Amir Gill', pickupLocation: 'Eki', company: 'Akagi', time: '9:20' },
    { serialNumber: '61', name: 'nimesh', pickupLocation: 'Eki cycle park', company: 'dai 3', time: '9:20' },
    { serialNumber: '', name: 'Dinesh Lama', pickupLocation: 'Eki', company: 'Dal-1', time: '9:20' },
    { serialNumber: '', name: 'Nima', pickupLocation: 'Eki', company: 'Akagi', time: '9:20' },
    { serialNumber: '', name: 'Indira', pickupLocation: 'Eki', company: 'Akagi', time: '9:20' },

    // 11:00 Shift
    { serialNumber: '', name: 'Hanif', pickupLocation: 'Rokumachi', company: 'Dal-1', time: '11:00' },

    // 11:20 Shift
    { serialNumber: '63', name: 'Asmita', pickupLocation: 'Eki', company: 'Dal-1', time: '11:20' },
    { serialNumber: '64', name: 'punam', pickupLocation: 'Eki', company: 'dai 3', time: '11:20' },
    { serialNumber: '65', name: 'sanjaya', pickupLocation: 'Eki', company: 'haga', time: '11:20' },
    { serialNumber: '66', name: 'subash', pickupLocation: 'Eki', company: 'haga', time: '11:20' },

    // 11:25 Shift
    { serialNumber: '', name: 'Krishna khadka', pickupLocation: 'kodomo', company: 'Haga-B', time: '11:25' },

    // 11:30 Shift
    { serialNumber: '68', name: 'MD Akash', pickupLocation: 'kodomo', company: 'Akagi', time: '11:30' },
    { serialNumber: '70', name: 'HM Ali', pickupLocation: 'kodomo', company: 'Akagi', time: '11:30' },
    { serialNumber: '', name: 'Hein', pickupLocation: 'Mistumata', company: 'Haga-B', time: '11:30' },

    // 14:20 Shift
    { serialNumber: '71', name: 'Santosh Adhikari', pickupLocation: 'kodomo', company: 'haga', time: '14:20' },
    { serialNumber: '73', name: 'Nishant', pickupLocation: 'Eki', company: 'Akagi', time: '14:20' },
    { serialNumber: '74', name: 'Gayan', pickupLocation: 'Eki', company: 'HagaA', time: '14:20' },
    { serialNumber: '75', name: 'SANTOSH', pickupLocation: 'EKI', company: 'dai 1', time: '14:20' },
    { serialNumber: '', name: 'Bishal Thapa', pickupLocation: 'Eki', company: 'Dal-2', time: '14:20' },
    { serialNumber: '77', name: 'Thakuri Bikram', pickupLocation: 'Eki', company: 'Dal-1', time: '14:20' },
    { serialNumber: '78', name: 'ABBU', pickupLocation: 'EKI', company: 'dai 2', time: '14:20' },
    { serialNumber: '79', name: 'pradip', pickupLocation: 'EKI', company: 'DAI1', time: '14:20' },
    { serialNumber: '', name: 'Niraj Bhattarai', pickupLocation: 'Eki', company: 'Haga-A', time: '14:20' },

    // 14:25 Shift
    { serialNumber: '', name: 'Sujan', pickupLocation: 'kodomo', company: 'Dal-2', time: '14:25' }
];

// Data registry - add more days here as needed
const dataRegistry = {
    'Saturday': saturdayData,
    // Add more days here:
    // 'Monday': mondayData,
    // 'Tuesday': tuesdayData,
    // etc.
};
