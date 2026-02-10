// Main Application Logic
let currentData = [];
let selectedDay = '';
let activeTab = 'preset';

// DOM Elements
const daySelector = document.getElementById('daySelector');
const dataPreview = document.getElementById('dataPreview');
const previewTableBody = document.getElementById('previewTableBody');
const totalCount = document.getElementById('totalCount');
const shiftCount = document.getElementById('shiftCount');
const importBtn = document.getElementById('importBtn');
const progressSection = document.getElementById('progressSection');
const progressFill = document.getElementById('progressFill');
const progressText = document.getElementById('progressText');
const notification = document.getElementById('notification');
const notificationText = document.getElementById('notificationText');
const clearAllBtn = document.getElementById('clearAllBtn');
const manualEntryForm = document.getElementById('manualEntryForm');
const csvFileInput = document.getElementById('csvFileInput');

// Tab Elements
const tabBtns = document.querySelectorAll('.tab-btn');
const tabContents = document.querySelectorAll('.tab-content');

// Event Listeners
daySelector.addEventListener('change', handleDaySelection);
importBtn.addEventListener('click', handleImport);
clearAllBtn.addEventListener('click', handleClearAll);
manualEntryForm.addEventListener('submit', handleManualEntry);
csvFileInput.addEventListener('change', handleCSVUpload);

// Tab switching
tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
        const tabName = btn.dataset.tab;
        switchTab(tabName);
    });
});

// Switch between tabs
function switchTab(tabName) {
    activeTab = tabName;

    // Update button states
    tabBtns.forEach(btn => {
        if (btn.dataset.tab === tabName) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });

    // Update content visibility
    tabContents.forEach(content => {
        content.classList.remove('active');
    });

    const activeContent = document.getElementById(`${tabName}Tab`);
    if (activeContent) {
        activeContent.classList.add('active');
    }

    // Clear day selector if switching away from preset
    if (tabName !== 'preset') {
        daySelector.value = '';
    }
}

// Handle day selection (preset data)
function handleDaySelection(event) {
    selectedDay = event.target.value;

    if (!selectedDay) {
        return;
    }

    // Get data for selected day
    const presetData = dataRegistry[selectedDay] || [];

    if (presetData.length === 0) {
        showNotification(`No preset data available for ${selectedDay}`, 'error');
        return;
    }

    // Replace current data with preset
    currentData = [...presetData];
    updateDataPreview();
    showNotification(`Loaded ${presetData.length} employees for ${selectedDay}`, 'success');
}

// Handle manual entry form submission
function handleManualEntry(event) {
    event.preventDefault();

    const employee = {
        serialNumber: document.getElementById('serialNo').value.trim(),
        name: document.getElementById('employeeName').value.trim(),
        pickupLocation: document.getElementById('pickupLocation').value.trim(),
        company: document.getElementById('company').value.trim(),
        time: document.getElementById('time').value.trim()
    };

    // Validate required fields
    if (!employee.name || !employee.pickupLocation || !employee.company || !employee.time) {
        showNotification('Please fill in all required fields', 'error');
        return;
    }

    // Add to current data
    currentData.push(employee);
    updateDataPreview();

    // Reset form
    manualEntryForm.reset();

    showNotification(`Added ${employee.name} to the list`, 'success');
}

// Handle CSV file upload
function handleCSVUpload(event) {
    const file = event.target.files[0];

    if (!file) {
        return;
    }

    if (!file.name.endsWith('.csv')) {
        showNotification('Please upload a CSV file', 'error');
        return;
    }

    const reader = new FileReader();

    reader.onload = function (e) {
        const csvContent = e.target.result;
        parseCSV(csvContent);
    };

    reader.onerror = function () {
        showNotification('Error reading CSV file', 'error');
    };

    reader.readAsText(file);
}

// Parse CSV content
function parseCSV(csvContent) {
    const lines = csvContent.split('\n').filter(line => line.trim());

    if (lines.length === 0) {
        showNotification('CSV file is empty', 'error');
        return;
    }

    const employees = [];
    let hasHeader = false;

    // Check if first line is a header
    const firstLine = lines[0].toLowerCase();
    if (firstLine.includes('serial') || firstLine.includes('name') || firstLine.includes('pickup')) {
        hasHeader = true;
    }

    const startIndex = hasHeader ? 1 : 0;

    for (let i = startIndex; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;

        const parts = line.split(',').map(p => p.trim());

        if (parts.length >= 5) {
            employees.push({
                serialNumber: parts[0],
                name: parts[1],
                pickupLocation: parts[2],
                company: parts[3],
                time: parts[4]
            });
        }
    }

    if (employees.length === 0) {
        showNotification('No valid employee data found in CSV', 'error');
        return;
    }

    // Add to current data
    currentData = [...currentData, ...employees];
    updateDataPreview();

    // Reset file input
    csvFileInput.value = '';

    showNotification(`Imported ${employees.length} employees from CSV`, 'success');
}

// Update data preview
function updateDataPreview() {
    if (currentData.length === 0) {
        dataPreview.classList.add('hidden');
        importBtn.disabled = true;
        return;
    }

    // Update stats
    totalCount.textContent = currentData.length;
    const uniqueShifts = [...new Set(currentData.map(emp => emp.time))];
    shiftCount.textContent = uniqueShifts.length;

    // Clear table
    previewTableBody.innerHTML = '';

    // Populate table
    currentData.forEach((employee, index) => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${index + 1}</td>
            <td><input type="text" class="inline-edit" data-index="${index}" data-field="serialNumber" value="${employee.serialNumber || ''}" placeholder="-"></td>
            <td><input type="text" class="inline-edit" data-index="${index}" data-field="name" value="${employee.name}" required></td>
            <td><input type="text" class="inline-edit" data-index="${index}" data-field="pickupLocation" value="${employee.pickupLocation}" required></td>
            <td><input type="text" class="inline-edit" data-index="${index}" data-field="company" value="${employee.company}" required></td>
            <td><input type="text" class="inline-edit" data-index="${index}" data-field="time" value="${employee.time}" required></td>
            <td>
                <div class="action-btns">
                    <button class="btn-delete" onclick="deleteEmployee(${index})">🗑️</button>
                </div>
            </td>
        `;
        previewTableBody.appendChild(row);
    });

    // Add event listeners for inline editing
    document.querySelectorAll('.inline-edit').forEach(input => {
        input.addEventListener('change', handleInlineEdit);
    });

    // Show preview
    dataPreview.classList.remove('hidden');
    importBtn.disabled = false;
}

// Handle inline editing
function handleInlineEdit(event) {
    const index = parseInt(event.target.dataset.index);
    const field = event.target.dataset.field;
    const value = event.target.value.trim();

    if (currentData[index]) {
        currentData[index][field] = value;
        showNotification('Data updated', 'success');
    }
}

// Delete employee
function deleteEmployee(index) {
    if (confirm(`Delete ${currentData[index].name}?`)) {
        currentData.splice(index, 1);
        updateDataPreview();
        showNotification('Employee deleted', 'success');
    }
}

// Clear all data
function handleClearAll() {
    if (currentData.length === 0) {
        return;
    }

    if (confirm(`Clear all ${currentData.length} employees?`)) {
        currentData = [];
        updateDataPreview();
        daySelector.value = '';
        showNotification('All data cleared', 'success');
    }
}

// Generate UUID
function generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
        const r = Math.random() * 16 | 0;
        const v = c === 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Create employee object for Firebase
function createEmployeeObject(employee, day) {
    return {
        id: generateUUID(),
        serialNumber: employee.serialNumber || '',
        name: employee.name,
        phoneNumber: '',
        pickupLocation: employee.pickupLocation,
        company: employee.company,
        time: employee.time,
        day: day || selectedDay || 'Saturday',
        weeklyStatus: ['PENDING', 'PENDING', 'PENDING', 'PENDING', 'PENDING'],
        weeklyHealthChecks: [null, null, null, null, null],
        lastUpdated: new Date().toISOString()
    };
}

// Handle import to Firebase
async function handleImport() {
    if (currentData.length === 0) {
        showNotification('No data to import', 'error');
        return;
    }

    // Ask for day if not set
    let importDay = selectedDay;
    if (!importDay) {
        importDay = prompt('Enter the day for this data (e.g., Monday, Saturday):');
        if (!importDay) {
            showNotification('Import cancelled - day not specified', 'error');
            return;
        }
    }

    // Disable button and show progress
    importBtn.disabled = true;
    progressSection.classList.remove('hidden');
    progressFill.style.width = '0%';
    progressText.textContent = 'Starting import...';

    let successCount = 0;
    let failCount = 0;

    try {
        const total = currentData.length;

        for (let i = 0; i < total; i++) {
            const employee = currentData[i];
            const employeeData = createEmployeeObject(employee, importDay);

            try {
                // Add to Firebase
                await db.collection('employees').doc(employeeData.id).set(employeeData);
                successCount++;

                // Update progress
                const progress = ((i + 1) / total) * 100;
                progressFill.style.width = `${progress}%`;
                progressText.textContent = `Importing ${i + 1} of ${total}...`;

                console.log(`✓ Added: ${employee.name} (${employee.time})`);
            } catch (error) {
                failCount++;
                console.error(`✗ Failed to add ${employee.name}:`, error);
            }
        }

        // Show completion message
        progressText.textContent = `Import complete! Success: ${successCount}, Failed: ${failCount}`;

        if (failCount === 0) {
            showNotification(`✓ Successfully imported ${successCount} employees to Firebase!`, 'success');
        } else {
            showNotification(`Import completed with ${failCount} errors. Check console for details.`, 'error');
        }

    } catch (error) {
        console.error('Import error:', error);
        showNotification(`Import failed: ${error.message}`, 'error');
    } finally {
        // Re-enable button after a delay
        setTimeout(() => {
            importBtn.disabled = false;
            progressSection.classList.add('hidden');
        }, 3000);
    }
}

// Show notification
function showNotification(message, type = 'success') {
    notificationText.textContent = message;
    notification.className = `notification ${type}`;
    notification.classList.remove('hidden');

    // Auto-hide after 5 seconds
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 5000);
}

// Initialize
console.log('Transport Data Import Tool initialized');
console.log('Available days:', Object.keys(dataRegistry));
console.log('Features: Preset Data, Manual Entry, CSV Upload, Inline Editing');
