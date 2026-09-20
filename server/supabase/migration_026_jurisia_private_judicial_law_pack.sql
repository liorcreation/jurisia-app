-- migration_026 — Pack original JurisIA : droit judiciaire privé.
--
-- Les quatre ressources transmises servent de base thématique. Cette
-- migration publie des cours JurisIA rédigés avec une formulation originale
-- et ne reproduit pas les ouvrages externes.

insert into public.legal_documents (
  id, title, type, domain, reference, date_publication, status, summary,
  full_content, outline, summary_only, official_source_name, source_url,
  tags, related_ids, imported_at
)
values
(
  'doc-jurisia-fondements-droit-judiciaire-prive',
  'Cours complet JurisIA — Fondements du droit judiciaire privé', 'traite', 'procedureCivile',
  'Édition pédagogique originale JurisIA — pack DJP', '2026-09-20', 'enVigueur',
  'Cours complet sur la justice civile, l’action en justice, les acteurs, la compétence, la preuve et les principes directeurs du procès.',
  $foundations$
COURS COMPLET JURISIA — FONDEMENTS DU DROIT JUDICIAIRE PRIVÉ

Le droit judiciaire privé organise la manière dont une personne demande au juge civil de reconnaître, protéger ou réaliser un droit. Il ne se confond pas avec le droit substantiel : le droit des contrats, de la famille ou des biens détermine la règle de fond, tandis que le droit judiciaire privé règle la saisine, le débat, la décision et son exécution. Une consultation complète doit toujours articuler ces deux dimensions.

PARTIE I — OBJET, SOURCES ET FONCTIONS

La matière comprend les règles relatives aux juridictions civiles, à l’action en justice, à la compétence, à l’instance, à la preuve procédurale, aux voies de recours et à l’exécution des décisions. Ses sources sont la Constitution, les traités, les lois, les règlements de procédure, les textes organisant les juridictions et la jurisprudence dans les limites reconnues par le système juridique applicable.

Le procès remplit une fonction de protection et de pacification. Il permet de faire constater une situation, d’obtenir une condamnation, de faire cesser un trouble ou de prendre une mesure provisoire. Le juge doit préserver l’égalité des armes, la contradiction, l’accès au tribunal et le délai raisonnable.

PARTIE II — JURIDICTIONS ET ACTEURS

La compétence se vérifie selon la nature du litige, la qualité des parties, la valeur de la demande, le lieu pertinent et l’existence d’une attribution spéciale. Les juridictions de droit commun connaissent des litiges qui ne sont pas réservés à une juridiction spécialisée. Les juridictions commerciales, sociales, foncières ou familiales interviennent lorsque les textes leur attribuent le litige.

Le juge tranche les prétentions qui lui sont soumises et ne statue pas au-delà de ce qui est demandé. Le greffe assure l’authentification et la conservation de nombreux actes. L’avocat conseille, rédige et représente son client. L’huissier ou commissaire de justice signifie les actes et contribue à l’exécution lorsque son statut le prévoit.

PARTIE III — ACTION ET PRINCIPES DIRECTEURS

L’action est le droit de soumettre une prétention à un juge. Elle se distingue de la demande, acte par lequel ce droit est exercé, et de la défense, qui répond à la prétention adverse. La recevabilité s’apprécie notamment au regard de l’intérêt, de la qualité, de la capacité, du délai et des conditions de forme.

Les parties déterminent l’objet du litige par leurs prétentions. Elles exposent les faits utiles, les moyens de droit et les pièces qui les soutiennent. Le contradictoire impose que chaque pièce, demande et argument susceptible de fonder la décision soit communiqué et puisse être discuté.

PARTIE IV — PREUVE, ACTES ET DÉCISION

La preuve du fait générateur, du dommage et du lien causal relève en principe de celui qui prétend un droit. Il faut distinguer la recevabilité d’un moyen, sa force probante et l’appréciation du juge. Un acte de procédure doit identifier les parties, exposer l’objet, mentionner les délais et respecter les formes imposées. Une irrégularité ne justifie une nullité que si le régime prévu est rempli et, souvent, si un grief est démontré.

Le jugement doit répondre aux prétentions, être motivé et permettre de comprendre le raisonnement. L’autorité de la chose jugée porte sur ce qui a été tranché entre les mêmes parties, pour le même objet et sur la même cause. La force exécutoire et les voies de recours doivent être vérifiées séparément.

MÉTHODE DE CONSULTATION

Commencer par une chronologie. Identifier les parties, leur qualité, la prétention, le fondement substantiel, le juge compétent, le délai et l’acte à accomplir. Vérifier la recevabilité avant le fond, préparer la preuve et prévoir les conséquences d’une décision favorable ou défavorable. Ne jamais annoncer un délai ou une compétence sans vérifier la version du texte applicable au ressort concerné.
  $foundations$,
  array['Notion, fonctions et sources', 'Juridictions et acteurs', 'Action en justice', 'Principes directeurs', 'Preuve et actes', 'Décision et exécution', 'Méthode de consultation'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-judiciaire-prive', 'droit judiciaire privé', 'action en justice', 'compétence', 'procès civil'], array[]::text[], now()
),
(
  'doc-jurisia-procedure-civile-complete',
  'Cours complet JurisIA — Procédure civile', 'traite', 'procedureCivile',
  'Édition pédagogique originale JurisIA — pack DJP', '2026-09-20', 'enVigueur',
  'Cours complet sur l’introduction de l’instance, la mise en état, les mesures d’instruction, les incidents, le jugement et les recours.',
  $civil$
COURS COMPLET JURISIA — PROCÉDURE CIVILE

Une procédure civile suit une chaîne : différend, choix amiable ou contentieux, saisine, mise en état, débat, jugement, recours éventuel et exécution. Chaque étape possède ses propres délais et formes. L’analyse doit préciser la juridiction et le droit de procédure applicables.

PARTIE I — SAISINE ET INSTANCE

L’assignation informe le défendeur de la demande, des faits, des moyens, de la juridiction saisie, de la date d’audience et des conséquences d’une absence. La requête est adaptée lorsque le texte autorise une saisine non contradictoire ou une procédure simplifiée. Avant le dépôt, contrôler l’identité, l’adresse, la capacité, le pouvoir du représentant, la compétence, les pièces et les mentions obligatoires.

Les demandes initiales, additionnelles, reconventionnelles et incidentes ne produisent pas les mêmes effets. Les conclusions doivent exposer les demandes dans un dispositif clair, puis développer les faits, les moyens et les pièces. Le calendrier organise les échanges et garantit à chaque partie un temps utile pour répondre.

PARTIE II — INSTRUCTION ET INCIDENTS

Lorsque les pièces ne suffisent pas, le juge peut ordonner une expertise, un constat, une audition, une enquête ou la production d’un document. La mesure doit être utile et proportionnée. L’expert éclaire le juge sans trancher la question juridique et les parties doivent pouvoir discuter ses opérations et son rapport.

Les exceptions de procédure tendent à suspendre ou déclarer irrégulière la procédure. L’incompétence, la litispendance, la connexité et le défaut de pouvoir doivent être qualifiés et soulevés au moment prévu. La fin de non-recevoir conteste le droit d’agir, tandis que la nullité vise un acte irrégulier. Il faut vérifier le texte, le délai, le grief et la régularisation possible.

PARTIE III — AUDIENCE ET JUGEMENT

À l’audience, le juge vérifie l’état du dossier et entend les observations utiles. La clôture empêche en principe les écritures et pièces tardives. Le jugement expose les prétentions, les motifs et le dispositif. Une erreur matérielle, une omission de statuer et une difficulté d’interprétation ne se traitent pas par le même recours.

PARTIE IV — VOIES DE RECOURS

L’opposition permet, dans les cas prévus, de faire rejuger une décision rendue en l’absence d’une partie. L’appel remet devant la juridiction supérieure les points dévolus par l’acte d’appel et les prétentions recevables. Le recours en cassation contrôle la conformité de la décision au droit et aux règles de procédure sans constituer un troisième examen général des faits.

Le délai court à compter de l’événement prévu par le texte, souvent la notification. Vérifier le mode de notification, le point de départ, les causes d’interruption ou de suspension, la représentation obligatoire et les effets du recours sur l’exécution.

MÉTHODE DE RÉDACTION

Pour une assignation, présenter les parties, la juridiction, les faits, les fondements, les demandes et les pièces. Pour des conclusions, répondre point par point aux moyens adverses et terminer par un dispositif numéroté. Pour une consultation, distinguer les options, les risques, les délais, les preuves et la solution recommandée.
  $civil$,
  array['Saisine et introduction', 'Instance et prétentions', 'Mesures d’instruction', 'Incidents et nullités', 'Audience et jugement', 'Voies de recours', 'Méthode de rédaction'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-judiciaire-prive', 'procédure civile', 'instance', 'mise en état', 'voies de recours'], array[]::text[], now()
),
(
  'doc-jurisia-juridictions-execution-civile',
  'Cours complet JurisIA — Juridictions et exécution civile', 'traite', 'procedureCivile',
  'Édition pédagogique originale JurisIA — pack DJP', '2026-09-20', 'enVigueur',
  'Cours complet sur les juridictions civiles, les référés, les procédures spéciales, les mesures conservatoires et l’exécution forcée.',
  $execution$
COURS COMPLET JURISIA — JURIDICTIONS ET EXÉCUTION CIVILE

La carte juridictionnelle se lit selon la matière, le degré de juridiction et le lieu pertinent. La juridiction de première instance reçoit les demandes initiales, la juridiction d’appel réexamine les points dévolus et la juridiction suprême contrôle le droit dans les limites de son office. La dénomination et les seuils de compétence doivent être vérifiés dans l’organisation judiciaire nationale.

PARTIE I — RÉFÉRÉ ET PROCÉDURES RAPIDES

Le référé permet une mesure provisoire lorsque l’urgence, l’absence de contestation sérieuse, la prévention d’un dommage ou le trouble manifestement illicite répondent aux conditions du texte. Le juge des référés ne tranche pas définitivement le principal. La requête non contradictoire n’est admise que si la loi ou les circonstances justifient de ne pas avertir l’adversaire avant la mesure.

PARTIE II — MODES AMIABLES

La négociation, la conciliation et la médiation recherchent une solution sans imposer une décision. Il faut expliquer les concessions, la confidentialité, le rôle du tiers et la portée de l’accord. Un accord peut devenir exécutoire par homologation ou par la formalité prévue. Le recours à l’amiable n’autorise pas à laisser expirer un délai sans vérifier son effet juridique.

PARTIE III — MESURES CONSERVATOIRES

Une mesure conservatoire protège le recouvrement avant que le débiteur ne disparaisse ou n’organise son insolvabilité. Elle peut porter sur des biens ou des créances si la créance paraît fondée et si les circonstances menacent son recouvrement. L’autorisation, la dénonciation, la conversion et la mainlevée suivent des règles précises.

PARTIE IV — EXÉCUTION FORCÉE

L’exécution forcée suppose en principe un titre exécutoire, une obligation déterminée ou déterminable et une exigibilité actuelle. Le créancier choisit la mesure adaptée sans dépasser ce qui est nécessaire : paiement volontaire, saisie-attribution, saisie-vente, saisie immobilière, obligation de faire ou astreinte peuvent répondre à des situations différentes.

La saisie-attribution immobilise une créance entre les mains d’un tiers. La saisie mobilière vise des biens corporels identifiables et respecte les biens insaisissables. La saisie immobilière obéit à un formalisme renforcé : commandement, publicité, orientation, conditions de vente et répartition doivent être suivis dans l’ordre.

PARTIE V — CONTESTATIONS

Le débiteur peut contester le titre, le montant, la régularité de l’acte, la proportion de la mesure ou l’insaisissabilité d’un bien. Le tiers saisi doit déclarer ce qu’il détient. Chaque contestation relève de la juridiction désignée par le texte et doit être formée dans le délai applicable.

PARCOURS PRATIQUE

Établir l’objectif : obtenir une décision, préserver une preuve, empêcher un dommage, recouvrer une somme ou faire cesser un trouble. Rassembler le titre, le contrat, les échanges, les preuves de notification, les informations sur les biens et l’historique des paiements. Calculer les délais et les coûts, puis choisir la voie amiable, le fond, le référé ou la mesure conservatoire. Vérifier enfin la version actuelle des textes et les formalités du ressort concerné.
  $execution$,
  array['Carte des juridictions', 'Référé et procédures rapides', 'Modes amiables', 'Mesures conservatoires', 'Exécution forcée', 'Saisies et contestations', 'Parcours pratique'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-droit-judiciaire-prive', 'juridictions civiles', 'référé', 'exécution forcée', 'saisies'], array[]::text[], now()
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
