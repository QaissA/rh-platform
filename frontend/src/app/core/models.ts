export type Role = 'employee' | 'lead' | 'manager' | 'rh' | 'admin';

export interface User {
  id: number;
  email: string;
  role: Role | string;
  team_id: number | null;
  business_unit_id: number | null;
  project_id: number | null;
  first_name?: string | null;
  last_name?: string | null;
  job_title?: string | null;
  pending_job_title?: string | null;
  must_change_password?: boolean;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface AppNotification {
  id: number;
  kind: string;
  title: string;
  body: string | null;
  link: string | null;
  read: boolean;
  created_at: string;
}

export interface LeaveBalance {
  user_id: number;
  days_remaining: number | string;
}

export type LeaveStatus = 'pending' | 'pending_hr' | 'approved' | 'rejected';

export function isAwaitingLeave(status: string): boolean {
  return status === 'pending' || status === 'pending_hr';
}

export interface LeaveRequest {
  id: number;
  user_id: number;
  team_id: number | null;
  start_date: string;
  end_date: string;
  status: LeaveStatus;
  reason: string | null;
  days?: number;
  decided_by?: number | null;
  decided_at?: string | null;
  decision_comment?: string | null;
}

export interface NewLeaveRequest {
  start_date: string;
  end_date: string;
  reason?: string;
}

/** Daily state of a team member in the team schedule ("emploi du temps"). */
export type PresenceStatus = 'on_site' | 'remote' | 'holiday';

/** Only on-site/remote are user-declarable; holiday comes from approved leaves. */
export type DeclarableStatus = 'on_site' | 'remote';

export interface ScheduleEntry {
  user_id: number;
  date: string; // YYYY-MM-DD
  status: PresenceStatus;
}

export interface ScheduleResponse {
  start: string;
  end: string;
  entries: ScheduleEntry[];
}

export interface NewPresence {
  start_date: string;
  end_date?: string;
  status: DeclarableStatus;
}

export interface TeamMember {
  id: number;
  email: string;
  first_name: string | null;
  last_name: string | null;
  role: string;
  job_title?: string | null;
}

export interface TeamResponse {
  team: { id: number; name: string } | null;
  members: TeamMember[];
}

/** A team as seen by an admin (auth-service /teams). A team is the roster of
 *  one project; its business unit is derived from that project. */
export interface TeamSummary {
  id: number;
  name: string;
  project_id: number | null;
  project: { id: number; name: string } | null;
  business_unit: { id: number; name: string } | null;
  member_count: number;
}

/** A single team with its members (auth-service /teams/:id). */
export interface TeamDetail extends TeamSummary {
  members: TeamMember[];
}

export interface NewTeam {
  name: string;
  project_id?: number | null;
}

export interface UpdateTeam {
  name?: string;
  project_id?: number | null;
}

export interface NewUser {
  email: string;
  first_name?: string;
  last_name?: string;
  role: string;
  team_id?: number | null;
  business_unit_id?: number | null;
  project_id?: number | null;
}

/** Response to user creation: the temp password is returned exactly once. */
export interface CreatedUser extends User {
  temporary_password: string;
}

export interface UpdateUser {
  role?: string;
  first_name?: string;
  last_name?: string;
  team_id?: number | null;
  business_unit_id?: number | null;
  project_id?: number | null;
  password?: string;
}

export type ContractType = 'cdi' | 'cdd' | 'stage' | 'alternance' | 'other';

export interface UserProfile extends User {
  pending_job_title: string | null;
  address_line: string | null;
  postal_code: string | null;
  city: string | null;
  country: string | null;
  signature_png?: string | null;
  signature_locked?: boolean;
}

export interface UserDossier extends UserProfile {
  salary_cents: number | null;
  contract_type: ContractType | null;
  hired_on: string | null;
  iban: string | null;
}

export interface UpdateProfile {
  address_line?: string | null;
  postal_code?: string | null;
  city?: string | null;
  country?: string | null;
  pending_job_title?: string | null;
  signature_png?: string | null;
}

export interface UpdateDossier {
  first_name?: string | null;
  last_name?: string | null;
  address_line?: string | null;
  postal_code?: string | null;
  city?: string | null;
  country?: string | null;
  job_title?: string | null;
  salary_cents?: number | null;
  contract_type?: ContractType | null;
  hired_on?: string | null;
  iban?: string | null;
}

/** A business unit as seen by an admin (auth-service /business-units). */
export interface BusinessUnit {
  id: number;
  name: string;
  manager_id: number | null;
  manager: TeamMember | null;
  project_count: number;
  member_count: number;
}

export interface NewBusinessUnit {
  name: string;
  manager_id?: number | null;
}

export interface UpdateBusinessUnit {
  name?: string;
  manager_id?: number | null;
}

/** A project as seen by an admin (auth-service /projects). */
export interface Project {
  id: number;
  name: string;
  business_unit_id: number;
  business_unit: { id: number; name: string } | null;
  lead_id: number | null;
  lead: TeamMember | null;
  member_count: number;
}

export interface NewProject {
  name: string;
  business_unit_id: number;
  lead_id?: number | null;
}

export interface UpdateProject {
  name?: string;
  business_unit_id?: number;
  lead_id?: number | null;
}

export type DocStatus = 'pending' | 'processing' | 'ready' | 'rejected';

export interface DocumentRequest {
  id: number;
  user_id: number;
  doc_type: string;
  status: DocStatus;
  note: string | null;
  fields?: Record<string, string>;
  issued_at?: string | null;
  decision_comment?: string | null;
}

export interface NewDocumentRequest {
  doc_type: string;
  note?: string;
}
