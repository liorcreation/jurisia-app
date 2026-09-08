-- À exécuter une fois dans le SQL Editor de votre projet Supabase — élargit
-- la contrainte de format de `student_mock_exam_attempts.mode` pour accepter
-- 'voice' : l'examen blanc n'a désormais plus qu'un seul format (une
-- conversation vocale continue façon ChatGPT Voice Mode, combinant ce qui
-- était auparavant trois modes séparés — QCM chronométré, devoir écrit,
-- examen oral). Additive et sans risque à réexécuter (idempotent) — les
-- anciennes valeurs restent acceptées pour ne jamais invalider de lignes
-- déjà enregistrées.
--
-- Indispensable : sans cette migration, `jurisia_record_mock_exam_result`
-- échouerait silencieusement à l'insertion (contrainte violée, absorbée par
-- le `try/catch` de `MockExamRepositoryImpl.recordResult`) et le verrou de
-- 7 jours ne serait alors jamais réellement posé côté serveur après un
-- échec.

alter table public.student_mock_exam_attempts
  drop constraint if exists student_mock_exam_attempts_mode_check;

alter table public.student_mock_exam_attempts
  add constraint student_mock_exam_attempts_mode_check
  check (mode in ('qcm_timed', 'written', 'oral', 'voice'));
