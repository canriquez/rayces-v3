// Professional-specific Zustand store for managing professional's own data
import { create } from 'zustand'
import { devtools, subscribeWithSelector } from 'zustand/middleware'
import { shallow } from 'zustand/shallow'

interface TimeSlot {
  id: string
  date: string
  startTime: string
  endTime: string
  isAvailable: boolean
  isBreak?: boolean
}

interface ScheduleTemplate {
  id: string
  name: string
  dayOfWeek: number // 0-6 (Sunday-Saturday)
  slots: {
    startTime: string
    endTime: string
    isBreak?: boolean
  }[]
}

interface Appointment {
  id: string
  studentId: string
  studentName: string
  date: string
  time: string
  status: 'pre_confirmed' | 'confirmed' | 'executed' | 'cancelled'
  notes?: string
}

interface ProfessionalProfile {
  id: string
  name: string
  email: string
  specialization: string
  bio?: string
  organizationId: string
}

interface ProfessionalState {
  // Profile data
  profile: ProfessionalProfile | null
  
  // Schedule management
  scheduleTemplates: ScheduleTemplate[]
  customSlots: TimeSlot[]
  blockedDates: string[]
  
  // Appointments
  upcomingAppointments: Appointment[]
  todaysAppointments: Appointment[]
  
  // UI State
  selectedDate: Date | null
  viewMode: 'day' | 'week' | 'month'
  isEditingSchedule: boolean
  
  // Actions - Profile
  setProfile: (profile: ProfessionalProfile) => void
  updateProfile: (updates: Partial<ProfessionalProfile>) => void
  
  // Actions - Schedule
  addScheduleTemplate: (template: ScheduleTemplate) => void
  updateScheduleTemplate: (id: string, updates: Partial<ScheduleTemplate>) => void
  deleteScheduleTemplate: (id: string) => void
  
  // Actions - Custom Slots
  addCustomSlot: (slot: TimeSlot) => void
  removeCustomSlot: (slotId: string) => void
  blockDate: (date: string) => void
  unblockDate: (date: string) => void
  
  // Actions - Appointments
  setUpcomingAppointments: (appointments: Appointment[]) => void
  setTodaysAppointments: (appointments: Appointment[]) => void
  updateAppointmentStatus: (id: string, status: Appointment['status']) => void
  
  // Actions - UI
  setSelectedDate: (date: Date | null) => void
  setViewMode: (mode: 'day' | 'week' | 'month') => void
  toggleScheduleEdit: () => void
  
  // Computed values
  getAvailableSlotsForDate: (date: string) => TimeSlot[]
  hasAppointmentConflict: (date: string, time: string) => boolean
}

const useProfessionalStore = create<ProfessionalState>()(
  devtools(
    subscribeWithSelector((set, get) => ({
      // Initial state
      profile: null,
      scheduleTemplates: [],
      customSlots: [],
      blockedDates: [],
      upcomingAppointments: [],
      todaysAppointments: [],
      selectedDate: new Date(),
      viewMode: 'week',
      isEditingSchedule: false,
      
      // Profile actions
      setProfile: (profile) => set({ profile }),
      
      updateProfile: (updates) => 
        set((state) => ({
          profile: state.profile ? { ...state.profile, ...updates } : null
        })),
      
      // Schedule template actions
      addScheduleTemplate: (template) =>
        set((state) => ({
          scheduleTemplates: [...state.scheduleTemplates, template]
        })),
        
      updateScheduleTemplate: (id, updates) =>
        set((state) => ({
          scheduleTemplates: state.scheduleTemplates.map(t =>
            t.id === id ? { ...t, ...updates } : t
          )
        })),
        
      deleteScheduleTemplate: (id) =>
        set((state) => ({
          scheduleTemplates: state.scheduleTemplates.filter(t => t.id !== id)
        })),
      
      // Custom slot actions
      addCustomSlot: (slot) =>
        set((state) => ({
          customSlots: [...state.customSlots, slot]
        })),
        
      removeCustomSlot: (slotId) =>
        set((state) => ({
          customSlots: state.customSlots.filter(s => s.id !== slotId)
        })),
        
      blockDate: (date) =>
        set((state) => ({
          blockedDates: [...state.blockedDates, date]
        })),
        
      unblockDate: (date) =>
        set((state) => ({
          blockedDates: state.blockedDates.filter(d => d !== date)
        })),
      
      // Appointment actions
      setUpcomingAppointments: (appointments) => 
        set({ upcomingAppointments: appointments }),
        
      setTodaysAppointments: (appointments) => 
        set({ todaysAppointments: appointments }),
        
      updateAppointmentStatus: (id, status) =>
        set((state) => ({
          upcomingAppointments: state.upcomingAppointments.map(a =>
            a.id === id ? { ...a, status } : a
          ),
          todaysAppointments: state.todaysAppointments.map(a =>
            a.id === id ? { ...a, status } : a
          )
        })),
      
      // UI actions
      setSelectedDate: (date) => set({ selectedDate: date }),
      
      setViewMode: (mode) => set({ viewMode: mode }),
      
      toggleScheduleEdit: () => 
        set((state) => ({ isEditingSchedule: !state.isEditingSchedule })),
      
      // Computed values
      getAvailableSlotsForDate: (date) => {
        const state = get()
        
        // Check if date is blocked
        if (state.blockedDates.includes(date)) {
          return []
        }
        
        // Get day of week for the date
        const dayOfWeek = new Date(date).getDay()
        
        // Find matching template
        const template = state.scheduleTemplates.find(t => t.dayOfWeek === dayOfWeek)
        
        if (!template) {
          // Check for custom slots
          return state.customSlots.filter(s => s.date === date && s.isAvailable)
        }
        
        // Convert template to time slots
        const slots: TimeSlot[] = template.slots.map((s, index) => ({
          id: `${date}-${index}`,
          date,
          startTime: s.startTime,
          endTime: s.endTime,
          isAvailable: !s.isBreak,
          isBreak: s.isBreak
        }))
        
        // Filter out slots with appointments
        const appointments = [...state.upcomingAppointments, ...state.todaysAppointments]
        return slots.filter(slot => {
          const hasAppointment = appointments.some(
            a => a.date === date && a.time === slot.startTime && 
                a.status !== 'cancelled'
          )
          return !hasAppointment && slot.isAvailable
        })
      },
      
      hasAppointmentConflict: (date, time) => {
        const state = get()
        const appointments = [...state.upcomingAppointments, ...state.todaysAppointments]
        
        return appointments.some(
          a => a.date === date && a.time === time && 
              a.status !== 'cancelled'
        )
      }
    }))
  )
)

// Selector hooks
export const useProfessionalProfile = () => 
  useProfessionalStore((state) => state.profile)

export const useScheduleTemplates = () => 
  useProfessionalStore((state) => state.scheduleTemplates)

export const useTodaysAppointments = () => 
  useProfessionalStore((state) => state.todaysAppointments)

export const useScheduleView = () => 
  useProfessionalStore(
    (state) => ({
      selectedDate: state.selectedDate,
      viewMode: state.viewMode,
      setSelectedDate: state.setSelectedDate,
      setViewMode: state.setViewMode
    }),
    shallow
  )

// Subscribe to appointment changes for notifications
useProfessionalStore.subscribe(
  (state) => state.todaysAppointments,
  (appointments, previousAppointments) => {
    // Check for new appointments
    const newAppointments = appointments.filter(
      a => !previousAppointments.find(pa => pa.id === a.id)
    )
    
    if (newAppointments.length > 0) {
      // Trigger notification (could integrate with a notification system)
      console.log('New appointments:', newAppointments)
    }
  }
)

export default useProfessionalStore