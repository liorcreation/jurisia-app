-- Adds in-person enrollment requests to the professional request workflow.
alter table public.professional_service_requests
  drop constraint if exists professional_service_requests_kind_check;
alter table public.professional_service_requests
  add constraint professional_service_requests_kind_check
  check (kind in ('legalAct', 'expertAppointment', 'trainingEnrollment'));

alter table public.professional_service_requests
  drop constraint if exists professional_service_request_context_check;
alter table public.professional_service_requests
  drop constraint if exists professional_service_requests_context_check;
alter table public.professional_service_requests
  add constraint professional_service_request_context_check check (
    (kind in ('legalAct', 'trainingEnrollment') and nullif(trim(act_type), '') is not null)
    or (kind = 'expertAppointment' and desired_date is not null)
  );
