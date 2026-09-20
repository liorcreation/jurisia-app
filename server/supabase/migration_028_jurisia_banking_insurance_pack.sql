-- migration_028 — Pack original JurisIA : droit bancaire et assurances.
--
-- Les supports transmis servent de base thématique. Cette migration publie
-- des cours JurisIA rédigés avec une formulation originale et ne reproduit
-- pas les ouvrages externes ni le Code CIMA article par article.

insert into public.legal_documents (
  id, title, type, domain, reference, date_publication, status, summary,
  full_content, outline, summary_only, official_source_name, source_url,
  tags, related_ids, imported_at
)
values
(
  'doc-jurisia-droit-bancaire-general',
  'Cours complet JurisIA — Droit bancaire', 'traite', 'commercial',
  'Édition pédagogique originale JurisIA — pack bancaire et assurances', '2026-09-20', 'enVigueur',
  'Cours complet sur les acteurs bancaires, les opérations de crédit et de paiement, la relation client, la conformité et la responsabilité.',
  $banking$
COURS COMPLET JURISIA — DROIT BANCAIRE

Le droit bancaire organise la collecte de l’épargne, la mise à disposition du crédit, les paiements et la circulation de la monnaie scripturale. Il protège la stabilité du système tout en encadrant la relation entre l’établissement, le client, les garants et les tiers. Toute consultation doit distinguer la règle générale, la réglementation professionnelle et les conditions prévues par le contrat.

PARTIE I — ACTEURS ET ACTIVITÉS

Les banques, établissements financiers, institutions de microfinance, prestataires de paiement et autres intervenants ne disposent pas des mêmes prérogatives. La collecte de dépôts remboursables, l’octroi habituel de crédits, la mise à disposition de moyens de paiement et les services de transmission de fonds peuvent être soumis à agrément ou à autorisation.

L’agrément est attaché à une personne et à un programme d’activités. Il ne dispense pas de respecter les règles de gouvernance, de contrôle interne, de gestion des risques, de protection de la clientèle et de lutte contre le blanchiment.

PARTIE II — COMPTE ET DÉPÔT

L’ouverture d’un compte implique l’identification du client, la vérification de ses pouvoirs et la définition des conditions de fonctionnement. Le contrat précise les frais, les moyens d’accès, les opérations autorisées, les modalités de clôture et la procédure de contestation. Un compte professionnel, un compte de paiement et un compte d’épargne n’emportent pas les mêmes droits.

Le dépôt crée une obligation de restitution selon la nature de l’opération. Les relevés et écritures bancaires constituent des éléments de preuve, mais leur portée doit être appréciée avec les contestations, les délais et les documents contractuels.

PARTIE III — CRÉDIT ET GARANTIES

Une opération de crédit se décrit par le montant, la durée, le taux, le coût global, l’échéancier, les conditions de déblocage et les événements de défaut. Le prêteur analyse la capacité de remboursement; l’emprunteur doit fournir des informations exactes et affecter les fonds conformément au contrat.

Le cautionnement, la garantie autonome, le gage, le nantissement, l’hypothèque et la garantie réelle n’ont pas le même régime. Identifier l’obligation garantie, le plafond, la durée, les formalités, le rang, les conditions d’appel et les recours du garant.

PARTIE IV — PAIEMENTS ET CONFORMITÉ

Le virement, le prélèvement, la carte, le chèque et la monnaie électronique obéissent à des règles distinctes. Contrôler l’autorisation, l’identité du donneur d’ordre, l’irrévocabilité éventuelle, les délais de contestation et la répartition des pertes en cas de fraude.

Le secret professionnel protège les informations obtenues dans l’activité financière. Il connaît des exceptions légales pour l’autorité judiciaire, la supervision et la lutte contre le blanchiment. La conformité comprend la connaissance du client, la surveillance des opérations et la conservation des pièces.

PARTIE V — RESPONSABILITÉ

La responsabilité de la banque peut être recherchée pour défaut d’exécution, faute dans un paiement, rupture fautive de crédit, manquement d’information, atteinte au secret ou concours irrégulier. Le client doit établir le devoir, le manquement, le dommage et le lien causal.

MÉTHODE D’ANALYSE

Qualifier l’acteur, le service, le contrat, les fonds, le risque et la date. Reconstituer les autorisations et les opérations, identifier les documents probatoires, vérifier les délais et distinguer responsabilité contractuelle, professionnelle et réglementaire.
  $banking$,
  array['Acteurs et activités', 'Compte et dépôt', 'Crédit et garanties', 'Paiements', 'Secret et conformité', 'Responsabilité', 'Méthode d’analyse'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-bancaire-assurances', 'droit bancaire', 'crédit', 'paiement', 'conformité bancaire'], array[]::text[], now()
),
(
  'doc-jurisia-droit-bancaire-umoa',
  'Cours complet JurisIA — Réglementation bancaire UMOA', 'traite', 'ohada',
  'Édition pédagogique originale JurisIA — pack bancaire et assurances', '2026-09-20', 'enVigueur',
  'Cours complet sur le cadre uniforme UMOA, les établissements de crédit, la supervision, la protection des déposants et les sanctions.',
  $umoa$
COURS COMPLET JURISIA — RÉGLEMENTATION BANCAIRE UMOA

La réglementation bancaire UMOA s’insère dans une architecture régionale qui organise la monnaie, la supervision et les conditions d’exercice des activités bancaires dans les États membres. Il faut distinguer le rôle de la banque centrale, de la commission de supervision, des autorités nationales et des organes de décision.

PARTIE I — ÉTABLISSEMENTS ET AGRÉMENT

Un établissement doit définir son activité, son capital, sa forme, ses dirigeants, ses actionnaires significatifs et son dispositif de contrôle. La demande d’agrément vérifie la solidité financière, l’honorabilité et la compétence des responsables. L’agrément ne couvre pas automatiquement toute activité financière : services de paiement, microfinance, monnaie électronique et change peuvent relever de règles complémentaires.

L’exercice sans agrément, l’utilisation indue d’une qualité bancaire et le non-respect des restrictions d’activité peuvent entraîner des mesures administratives, des sanctions disciplinaires et des poursuites. Il faut identifier l’auteur, l’activité réellement exercée et l’éventuelle exemption.

PARTIE II — GOUVERNANCE ET PRUDENCE

La gouvernance répartit les responsabilités entre organes sociaux, direction effective, contrôle permanent, audit et gestion des risques. Les exigences de solvabilité, de liquidité, de concentration des risques et de classement des créances protègent les déposants et la stabilité du système.

Les procédures internes doivent prévenir les conflits d’intérêts, les abus de biens, les opérations avec des personnes liées et la prise de risque excessive. Les documents comptables et prudentiels doivent être fiables, conservés et transmis aux autorités.

PARTIE III — CLIENTÈLE ET PAIEMENTS

L’établissement informe le client sur le service, le coût, les risques et les conditions de sortie. L’identification et la connaissance du client sont adaptées au risque. La protection impose une information loyale, l’exécution correcte et le traitement des réclamations.

Les moyens de paiement exigent des contrôles d’accès, une traçabilité et une répartition claire des responsabilités. En cas d’opération suspecte, il faut conserver les traces et respecter le secret ainsi que les obligations de déclaration.

PARTIE IV — SUPERVISION ET SANCTIONS

La supervision comprend les contrôles sur pièces, sur place, demandes d’information, injonctions et mesures de redressement. L’établissement doit coopérer, répondre exactement et corriger les insuffisances. Le superviseur peut limiter une activité, imposer un plan ou prendre une mesure conservatoire dans les conditions prévues.

La procédure de sanction doit identifier le manquement, respecter les droits de la défense, individualiser la mesure et permettre le recours prévu. Une sanction pécuniaire, une interdiction, un retrait d’agrément et une mesure de résolution n’ont pas la même finalité.

PARTIE V — CRISE ET PROTECTION

La défaillance d’un établissement affecte les déposants, les emprunteurs et les autres établissements. La prévention repose sur les fonds propres, la liquidité, les plans de continuité et la surveillance. En cas de crise, les autorités organisent la protection des fonctions essentielles et le traitement des actifs et passifs.

CAS PRATIQUE

Qualifier l’établissement, vérifier l’agrément et l’activité, relever les obligations de gouvernance et de conformité, identifier le manquement, contrôler l’autorité compétente, puis distinguer mesure corrective, sanction et recours. Vérifier la version la plus récente de la loi uniforme et des textes régionaux.
  $umoa$,
  array['Architecture de l’Union', 'Établissements et agrément', 'Gouvernance', 'Clientèle et paiements', 'Supervision', 'Sanctions', 'Crise et protection'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-bancaire-assurances', 'droit bancaire UMOA', 'BCEAO', 'établissement de crédit', 'supervision prudentielle'], array[]::text[], now()
),
(
  'doc-jurisia-droit-assurances-cima',
  'Cours complet JurisIA — Droit des assurances et Code CIMA', 'traite', 'commercial',
  'Édition pédagogique originale JurisIA — pack bancaire et assurances', '2026-09-20', 'enVigueur',
  'Cours complet sur le contrat d’assurance, les obligations des parties, les sinistres, l’indemnisation, l’assurance obligatoire et le cadre CIMA.',
  $cima$
COURS COMPLET JURISIA — DROIT DES ASSURANCES ET CODE CIMA

L’assurance organise la prise en charge d’un risque incertain en contrepartie d’une prime. Il faut distinguer le risque couvert, l’événement assuré, le dommage, la garantie, l’exclusion et le montant indemnisable dans le cadre CIMA et des textes nationaux complémentaires.

PARTIE I — ENTREPRISES ET INTERMÉDIAIRES

L’entreprise d’assurance doit être autorisée, disposer d’une organisation et de ressources compatibles avec ses engagements, constituer les provisions et respecter les règles de contrôle. L’intermédiaire agit dans les limites de son mandat, présente le produit avec loyauté et transmet les informations utiles.

La solvabilité protège les assurés. Les provisions techniques représentent les engagements futurs et les actifs doivent permettre leur couverture. Le contrôle, les obligations de reporting et les mesures de redressement répondent à une logique différente du règlement d’un sinistre individuel.

PARTIE II — FORMATION DU CONTRAT

La proposition, la police, les conditions générales et particulières décrivent le risque et la garantie. L’assureur apprécie le risque à partir des déclarations du souscripteur. Une information fausse ou incomplète peut affecter la garantie selon la gravité, l’intention, le lien avec le sinistre et le régime applicable.

La prime, la date d’effet, la durée, le renouvellement, la résiliation et les modalités de notification doivent être identifiés. Une exclusion doit être claire, précise et portée à la connaissance de l’assuré dans les conditions requises.

PARTIE III — RISQUE ET GARANTIES

L’aggravation du risque, sa disparition, le changement d’activité ou la modification du bien peuvent imposer une déclaration et permettre une adaptation du contrat. Les franchises, plafonds, sous-limites et règles de proportion encadrent l’indemnité de manière différente.

Les assurances de biens, de personnes, de responsabilité, de transport et de dommages liés à la circulation répondent à des logiques propres. L’assurance obligatoire poursuit aussi une fonction de protection des victimes, qui peut limiter les exceptions opposables.

PARTIE IV — SINISTRE ET INDEMNISATION

L’assuré doit déclarer le sinistre dans le délai prévu, prendre les mesures conservatoires, transmettre les pièces et éviter d’aggraver le dommage. L’assureur vérifie la garantie, la réalité de l’événement, la causalité, le montant et les exclusions. L’expertise éclaire le montant sans remplacer la qualification juridique.

L’indemnité répare le dommage garanti dans les limites du contrat et du droit. Il faut déduire la franchise, respecter le plafond et éviter l’enrichissement de l’assuré. Le paiement, le refus motivé et la contestation doivent être documentés.

PARTIE V — RESPONSABILITÉ ET RECOURS

La responsabilité civile suppose un fait générateur, un dommage et un lien causal. L’assureur peut prendre en charge la dette de responsabilité selon la police, tandis que la victime peut disposer d’une action directe ou d’un recours spécial lorsque le texte le prévoit. L’assureur qui indemnise peut exercer un recours subrogatoire.

La prescription, la déchéance, la notification, la compétence et la conciliation doivent être vérifiées séparément. Une clause de déchéance ne se présume pas et son application dépend de ses conditions.

MÉTHODE DE DOSSIER

Lire la police avant le récit du sinistre. Construire un tableau : souscripteur, assuré, victime, risque, date d’effet, événement, déclaration, pièces, exclusion, franchise, plafond, dommage et recours. Vérifier la version actuelle du Code CIMA et des textes nationaux.
  $cima$,
  array['Entreprise et intermédiaires', 'Formation du contrat', 'Risque et garanties', 'Sinistre', 'Indemnisation', 'Responsabilité et recours', 'Méthode de dossier'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-bancaire-assurances', 'droit des assurances', 'Code CIMA', 'sinistre', 'indemnisation'], array[]::text[], now()
)
on conflict (id) do update set
  title = excluded.title,
  type = excluded.type,
  domain = excluded.domain,
  reference = excluded.reference,
  date_publication = excluded.date_publication,
  status = excluded.status,
  summary = excluded.summary,
  full_content = excluded.full_content,
  outline = excluded.outline,
  summary_only = excluded.summary_only,
  official_source_name = excluded.official_source_name,
  source_url = excluded.source_url,
  tags = excluded.tags,
  related_ids = excluded.related_ids,
  imported_at = excluded.imported_at;
