export type Role = 'admin' | 'manager' | 'technician' | 'operator'

export interface Tenant {
  id: number
  name: string
  slug: string
  plan: string
  is_active: boolean
}

export interface User {
  id: number
  tenant_id: number
  name: string
  email: string
  role: Role
  phone: string | null
  is_active: boolean
}

export type EquipmentStatus = 'operational' | 'down' | 'maintenance'

export interface Equipment {
  id: number
  name: string
  reference: string | null
  qr_token: string
  category: string | null
  location: string | null
  status: EquipmentStatus
  manufacturer: string | null
  model: string | null
  serial_number: string | null
  purchase_date: string | null
  photo_path: string | null
  notes: string | null
  created_at: string
}

export type TicketPriority = 'low' | 'medium' | 'high' | 'urgent'
export type TicketStatus = 'open' | 'assigned' | 'in_progress' | 'closed'

export interface Ticket {
  id: number
  equipment_id: number
  equipment: Equipment
  reported_by: number
  reporter?: User
  assigned_to: number | null
  assignee?: User | null
  title: string
  description: string | null
  photo_path: string | null
  priority: TicketPriority
  status: TicketStatus
  closed_at: string | null
  created_at: string
}

export interface PreventivePlan {
  id: number
  equipment_id: number
  equipment: Equipment
  name: string
  frequency_type: 'days' | 'weeks' | 'months'
  frequency_value: number
  next_due_date: string
  active: boolean
}

export type WorkOrderStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled'

export interface WorkOrder {
  id: number
  equipment_id: number
  equipment: Equipment
  preventive_plan_id: number | null
  type: 'preventive' | 'corrective'
  title: string
  assigned_to: number | null
  assignee?: User | null
  status: WorkOrderStatus
  due_date: string
  completed_at: string | null
}

export interface Part {
  id: number
  name: string
  reference: string | null
  unit: string
  quantity_on_hand: number
  alert_threshold: number
  unit_cost: string | null
  supplier: string | null
}

export interface Intervention {
  id: number
  equipment_id: number
  equipment: Equipment
  ticket_id: number | null
  work_order_id: number | null
  technician_id: number
  technician?: User
  started_at: string | null
  ended_at: string | null
  duration_minutes: number | null
  comment: string | null
  photo_path: string | null
  signature_path: string | null
  signed_by: string | null
  parts: (Part & { pivot: { quantity: number } })[]
}

export interface DashboardKpis {
  equipment_counts: { total: number; operational: number; down: number; maintenance: number }
  ticket_counts: { open: number; assigned: number; in_progress: number; closed_period: number }
  mttr_hours: number | null
  mtbf_days: number | null
  parts_cost_period: number
  low_stock_parts: number
  daily_trend: { date: string; reported: number; closed: number }[]
}

export interface Paginated<T> {
  data: T[]
  total: number
  current_page: number
  last_page: number
  per_page: number
}
