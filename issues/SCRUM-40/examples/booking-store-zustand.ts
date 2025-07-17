// Zustand booking store with TypeScript for appointment booking system
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'
import type {} from '@redux-devtools/extension' // required for devtools typing

// Define types for the booking system
interface Professional {
  id: string
  name: string
  organization_id: string
  availability: TimeSlot[]
}

interface Student {
  id: string
  name: string
  parent_id: string
  organization_id: string
}

interface TimeSlot {
  date: Date
  startTime: string
  endTime: string
  available: boolean
}

interface Appointment {
  id: string
  professional_id: string
  student_id: string
  date: Date
  time: string
  status: 'draft' | 'pre_confirmed' | 'confirmed' | 'executed' | 'cancelled'
}

// Define the store state interface
interface BookingState {
  // Current booking flow state
  currentStep: number
  selectedProfessional: Professional | null
  selectedStudent: Student | null
  selectedDate: Date | null
  selectedTime: string | null
  availableSlots: TimeSlot[]
  
  // Actions
  setStep: (step: number) => void
  setProfessional: (professional: Professional | null) => void
  setStudent: (student: Student | null) => void
  setDate: (date: Date) => void
  setTime: (time: string) => void
  setAvailableSlots: (slots: TimeSlot[]) => void
  nextStep: () => void
  previousStep: () => void
  resetBooking: () => void
  
  // Booking submission
  submitBooking: () => Promise<Appointment>
}

// Create the booking store with devtools and persist middleware
const useBookingStore = create<BookingState>()(
  devtools(
    persist(
      (set, get) => ({
        // Initial state
        currentStep: 0,
        selectedProfessional: null,
        selectedStudent: null,
        selectedDate: null,
        selectedTime: null,
        availableSlots: [],
        
        // Actions
        setStep: (step) => set({ currentStep: step }),
        
        setProfessional: (professional) => 
          set({ 
            selectedProfessional: professional,
            // Reset dependent fields
            availableSlots: [],
            selectedDate: null,
            selectedTime: null 
          }),
          
        setStudent: (student) => set({ selectedStudent: student }),
        
        setDate: (date) => 
          set({ 
            selectedDate: date,
            selectedTime: null // Reset time when date changes
          }),
          
        setTime: (time) => set({ selectedTime: time }),
        
        setAvailableSlots: (slots) => set({ availableSlots: slots }),
        
        nextStep: () => 
          set((state) => ({ 
            currentStep: Math.min(state.currentStep + 1, 4) 
          })),
          
        previousStep: () => 
          set((state) => ({ 
            currentStep: Math.max(state.currentStep - 1, 0) 
          })),
          
        resetBooking: () => 
          set({
            currentStep: 0,
            selectedProfessional: null,
            selectedStudent: null,
            selectedDate: null,
            selectedTime: null,
            availableSlots: []
          }),
          
        submitBooking: async () => {
          const state = get()
          
          if (!state.selectedProfessional || !state.selectedStudent || 
              !state.selectedDate || !state.selectedTime) {
            throw new Error('Missing required booking information')
          }
          
          // This would call the API to create the appointment
          const appointment: Appointment = {
            id: 'temp-id',
            professional_id: state.selectedProfessional.id,
            student_id: state.selectedStudent.id,
            date: state.selectedDate,
            time: state.selectedTime,
            status: 'pre_confirmed'
          }
          
          // Reset after successful booking
          state.resetBooking()
          
          return appointment
        }
      }),
      {
        name: 'booking-storage',
        // Only persist UI state, not sensitive data
        partialize: (state) => ({ 
          currentStep: state.currentStep 
        }),
      }
    )
  )
)

// Selector hooks for better performance
export const useBookingStep = () => useBookingStore((state) => state.currentStep)
export const useSelectedProfessional = () => useBookingStore((state) => state.selectedProfessional)
export const useSelectedStudent = () => useBookingStore((state) => state.selectedStudent)
export const useBookingActions = () => useBookingStore((state) => ({
  setStep: state.setStep,
  setProfessional: state.setProfessional,
  setStudent: state.setStudent,
  setDate: state.setDate,
  setTime: state.setTime,
  nextStep: state.nextStep,
  previousStep: state.previousStep,
  resetBooking: state.resetBooking,
  submitBooking: state.submitBooking
}))

export default useBookingStore