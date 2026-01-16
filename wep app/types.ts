import React from 'react';

export type DayOfWeek = 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday';

export enum TransportStatus {
  PENDING = 'PENDING',
  ON_BOARD = 'ON_BOARD',
  DROPPED_OFF = 'DROPPED_OFF',
  SELF_TRAVEL = 'SELF_TRAVEL',
  ABSENT = 'ABSENT'
}

export interface Employee {
  id: string;
  serialNumber: string;
  name: string;
  pickupLocation: string;
  company: string;
  time: string;
  day: DayOfWeek;
  weeklyStatus: TransportStatus[]; // Array of 5 statuses for 5 weeks
  lastUpdated: string;
}

export interface StatCardProps {
  title: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
}

export type ViewMode = 'USER' | 'ADMIN';
