// Example booking wizard component using Zustand and TanStack Query
'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import useBookingStore, { 
  useBookingStep, 
  useBookingActions,
  useSelectedProfessional,
  useSelectedStudent 
} from '@/stores/bookingStore'
import { 
  useProfessionals, 
  useProfessionalAvailability,
  useStudents,
  useCreateAppointment 
} from '@/hooks/api/useBookingApi'
import { useTenant } from '@/lib/providers'
import { format, addDays } from 'date-fns'

// Step components
function ProfessionalSelection() {
  const { organization } = useTenant()
  const { data: professionals, isLoading } = useProfessionals(organization?.id || '')
  const { setProfessional, nextStep } = useBookingActions()

  if (isLoading) {
    return <div className="animate-pulse">Loading professionals...</div>
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Select a Professional</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {professionals?.map((professional) => (
          <div
            key={professional.id}
            onClick={() => {
              setProfessional(professional)
              nextStep()
            }}
            className="p-4 border rounded-lg cursor-pointer hover:bg-gray-50 
                     transition-colors duration-200"
          >
            <h3 className="font-semibold">{professional.name}</h3>
            <p className="text-sm text-gray-600">{professional.specialization}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

function StudentSelection() {
  const { data: students, isLoading } = useStudents()
  const { setStudent, nextStep, previousStep } = useBookingActions()

  if (isLoading) {
    return <div className="animate-pulse">Loading students...</div>
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Select a Student</h2>
      <div className="space-y-2">
        {students?.map((student) => (
          <div
            key={student.id}
            onClick={() => {
              setStudent(student)
              nextStep()
            }}
            className="p-4 border rounded-lg cursor-pointer hover:bg-gray-50 
                     transition-colors duration-200"
          >
            <h3 className="font-semibold">{student.name}</h3>
            <p className="text-sm text-gray-600">Grade: {student.grade}</p>
          </div>
        ))}
      </div>
      <button
        onClick={previousStep}
        className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
      >
        Back
      </button>
    </div>
  )
}

function DateTimeSelection() {
  const professional = useSelectedProfessional()
  const { setDate, setTime, nextStep, previousStep } = useBookingActions()
  const selectedDate = useBookingStore((state) => state.selectedDate)
  const selectedTime = useBookingStore((state) => state.selectedTime)
  
  // Get availability for the next 30 days
  const dateRange = {
    start: format(new Date(), 'yyyy-MM-dd'),
    end: format(addDays(new Date(), 30), 'yyyy-MM-dd')
  }
  
  const { data: availability, isLoading } = useProfessionalAvailability(
    professional?.id || '',
    dateRange
  )

  if (isLoading) {
    return <div className="animate-pulse">Loading availability...</div>
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Select Date & Time</h2>
      
      {/* Date selection */}
      <div className="space-y-2">
        <h3 className="font-semibold">Available Dates</h3>
        <div className="grid grid-cols-7 gap-2">
          {availability?.map((day) => (
            <button
              key={day.date}
              onClick={() => setDate(new Date(day.date))}
              className={`p-2 border rounded text-sm
                ${selectedDate?.toISOString().split('T')[0] === day.date 
                  ? 'bg-blue-500 text-white' 
                  : 'hover:bg-gray-100'
                }
                ${day.slots.some(s => s.available) 
                  ? '' 
                  : 'opacity-50 cursor-not-allowed'
                }`}
              disabled={!day.slots.some(s => s.available)}
            >
              {format(new Date(day.date), 'dd')}
            </button>
          ))}
        </div>
      </div>

      {/* Time selection */}
      {selectedDate && (
        <div className="space-y-2">
          <h3 className="font-semibold">Available Times</h3>
          <div className="grid grid-cols-4 gap-2">
            {availability
              ?.find(a => a.date === selectedDate.toISOString().split('T')[0])
              ?.slots.filter(s => s.available)
              .map((slot) => (
                <button
                  key={slot.time}
                  onClick={() => setTime(slot.time)}
                  className={`p-2 border rounded text-sm
                    ${selectedTime === slot.time 
                      ? 'bg-blue-500 text-white' 
                      : 'hover:bg-gray-100'
                    }`}
                >
                  {slot.time}
                </button>
              ))}
          </div>
        </div>
      )}

      <div className="flex gap-2">
        <button
          onClick={previousStep}
          className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
        >
          Back
        </button>
        <button
          onClick={nextStep}
          disabled={!selectedDate || !selectedTime}
          className="px-4 py-2 bg-blue-500 text-white rounded 
                   hover:bg-blue-600 disabled:opacity-50"
        >
          Continue
        </button>
      </div>
    </div>
  )
}

function BookingConfirmation() {
  const router = useRouter()
  const professional = useSelectedProfessional()
  const student = useSelectedStudent()
  const bookingStore = useBookingStore()
  const { previousStep, submitBooking } = useBookingActions()
  const createAppointment = useCreateAppointment()

  const handleConfirm = async () => {
    try {
      const appointment = await createAppointment.mutateAsync({
        professional_id: professional!.id,
        student_id: student!.id,
        date: bookingStore.selectedDate!.toISOString().split('T')[0],
        time: bookingStore.selectedTime!,
      })
      
      // Navigate to success page
      router.push(`/appointments/${appointment.id}/success`)
    } catch (error) {
      console.error('Failed to create appointment:', error)
    }
  }

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-bold">Confirm Your Booking</h2>
      
      <div className="bg-gray-50 p-4 rounded-lg space-y-2">
        <div>
          <span className="font-semibold">Professional:</span> {professional?.name}
        </div>
        <div>
          <span className="font-semibold">Student:</span> {student?.name}
        </div>
        <div>
          <span className="font-semibold">Date:</span>{' '}
          {bookingStore.selectedDate && format(bookingStore.selectedDate, 'MMMM d, yyyy')}
        </div>
        <div>
          <span className="font-semibold">Time:</span> {bookingStore.selectedTime}
        </div>
      </div>

      <div className="flex gap-2">
        <button
          onClick={previousStep}
          className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300"
        >
          Back
        </button>
        <button
          onClick={handleConfirm}
          disabled={createAppointment.isPending}
          className="px-4 py-2 bg-green-500 text-white rounded 
                   hover:bg-green-600 disabled:opacity-50"
        >
          {createAppointment.isPending ? 'Booking...' : 'Confirm Booking'}
        </button>
      </div>
    </div>
  )
}

// Main booking wizard component
export default function BookingWizard() {
  const currentStep = useBookingStep()
  const { resetBooking } = useBookingActions()

  // Reset booking state on unmount
  useEffect(() => {
    return () => {
      resetBooking()
    }
  }, [resetBooking])

  const steps = [
    <ProfessionalSelection key="professional" />,
    <StudentSelection key="student" />,
    <DateTimeSelection key="datetime" />,
    <BookingConfirmation key="confirmation" />,
  ]

  return (
    <div className="max-w-2xl mx-auto p-4">
      {/* Progress indicator */}
      <div className="mb-8">
        <div className="flex justify-between items-center">
          {['Professional', 'Student', 'Date & Time', 'Confirm'].map((label, index) => (
            <div
              key={label}
              className={`flex-1 text-center ${
                index <= currentStep ? 'text-blue-600' : 'text-gray-400'
              }`}
            >
              <div
                className={`w-8 h-8 mx-auto rounded-full flex items-center 
                         justify-center mb-2 ${
                  index <= currentStep 
                    ? 'bg-blue-600 text-white' 
                    : 'bg-gray-200'
                }`}
              >
                {index + 1}
              </div>
              <span className="text-sm">{label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Current step */}
      {steps[currentStep]}
    </div>
  )
}