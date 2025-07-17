// TanStack Query (React Query) API hooks for booking system
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useSession } from 'next-auth/react'
import axios, { AxiosError } from 'axios'

// Configure API client
const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001/api/v1',
  headers: {
    'Content-Type': 'application/json',
  },
})

// Add auth token to requests
apiClient.interceptors.request.use(async (config) => {
  const session = await getSession()
  if (session?.accessToken) {
    config.headers.Authorization = `Bearer ${session.accessToken}`
  }
  return config
})

// Types
interface Professional {
  id: string
  name: string
  organization_id: string
  specialization: string
  availability: Availability[]
}

interface Availability {
  date: string
  slots: TimeSlot[]
}

interface TimeSlot {
  time: string
  available: boolean
}

interface Student {
  id: string
  name: string
  parent_id: string
  organization_id: string
  grade: string
}

interface Appointment {
  id: string
  professional_id: string
  student_id: string
  date: string
  time: string
  status: 'draft' | 'pre_confirmed' | 'confirmed' | 'executed' | 'cancelled'
  notes?: string
}

interface CreateAppointmentDto {
  professional_id: string
  student_id: string
  date: string
  time: string
  notes?: string
}

// API functions
const fetchProfessionals = async (organizationId: string): Promise<Professional[]> => {
  const { data } = await apiClient.get(`/professionals`, {
    params: { organization_id: organizationId }
  })
  return data
}

const fetchProfessionalAvailability = async (
  professionalId: string, 
  startDate: string, 
  endDate: string
): Promise<Availability[]> => {
  const { data } = await apiClient.get(`/professionals/${professionalId}/availability`, {
    params: { start_date: startDate, end_date: endDate }
  })
  return data
}

const fetchStudents = async (parentId: string): Promise<Student[]> => {
  const { data } = await apiClient.get(`/students`, {
    params: { parent_id: parentId }
  })
  return data
}

const createAppointment = async (appointment: CreateAppointmentDto): Promise<Appointment> => {
  const { data } = await apiClient.post('/appointments', appointment)
  return data
}

const cancelAppointment = async (appointmentId: string): Promise<Appointment> => {
  const { data } = await apiClient.patch(`/appointments/${appointmentId}/cancel`)
  return data
}

// Query hooks
export const useProfessionals = (organizationId: string) => {
  return useQuery({
    queryKey: ['professionals', organizationId],
    queryFn: () => fetchProfessionals(organizationId),
    staleTime: 5 * 60 * 1000, // 5 minutes
    enabled: !!organizationId,
  })
}

export const useProfessionalAvailability = (
  professionalId: string,
  dateRange: { start: string; end: string }
) => {
  return useQuery({
    queryKey: ['professional-availability', professionalId, dateRange],
    queryFn: () => fetchProfessionalAvailability(
      professionalId, 
      dateRange.start, 
      dateRange.end
    ),
    staleTime: 1 * 60 * 1000, // 1 minute (availability changes frequently)
    enabled: !!professionalId && !!dateRange.start && !!dateRange.end,
  })
}

export const useStudents = () => {
  const { data: session } = useSession()
  const parentId = session?.user?.id
  
  return useQuery({
    queryKey: ['students', parentId],
    queryFn: () => fetchStudents(parentId!),
    staleTime: 10 * 60 * 1000, // 10 minutes
    enabled: !!parentId,
  })
}

// Mutation hooks
export const useCreateAppointment = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: createAppointment,
    onSuccess: (data) => {
      // Invalidate and refetch availability
      queryClient.invalidateQueries({ 
        queryKey: ['professional-availability', data.professional_id] 
      })
      
      // Invalidate appointments list
      queryClient.invalidateQueries({ 
        queryKey: ['appointments'] 
      })
    },
    onError: (error: AxiosError) => {
      console.error('Failed to create appointment:', error.response?.data)
    },
  })
}

export const useCancelAppointment = () => {
  const queryClient = useQueryClient()
  
  return useMutation({
    mutationFn: cancelAppointment,
    onSuccess: (data) => {
      // Update the appointment in cache
      queryClient.setQueryData(
        ['appointments', data.id],
        data
      )
      
      // Invalidate availability to reflect the freed slot
      queryClient.invalidateQueries({ 
        queryKey: ['professional-availability', data.professional_id] 
      })
      
      // Invalidate appointments list
      queryClient.invalidateQueries({ 
        queryKey: ['appointments'] 
      })
    },
    onError: (error: AxiosError) => {
      console.error('Failed to cancel appointment:', error.response?.data)
    },
  })
}

// Prefetch utility for SSR
export const prefetchProfessionals = async (
  queryClient: QueryClient,
  organizationId: string
) => {
  return queryClient.prefetchQuery({
    queryKey: ['professionals', organizationId],
    queryFn: () => fetchProfessionals(organizationId),
    staleTime: 5 * 60 * 1000,
  })
}

// Example usage in a component
/*
function BookingWizard() {
  const { data: professionals, isLoading } = useProfessionals('org-123')
  const createAppointment = useCreateAppointment()
  
  const handleSubmit = async (appointmentData: CreateAppointmentDto) => {
    try {
      await createAppointment.mutateAsync(appointmentData)
      // Navigate to success page
    } catch (error) {
      // Error is already logged in the mutation
    }
  }
  
  if (isLoading) return <LoadingSpinner />
  
  return (
    // Booking UI
  )
}
*/