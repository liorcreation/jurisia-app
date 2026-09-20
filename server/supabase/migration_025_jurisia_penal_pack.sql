-- migration_025 — Pack original JurisIA : droit pénal général, spécial et
-- procédure pénale.
--
-- Les ressources transmises servent de base thématique et bibliographique.
-- Cette migration publie des cours JurisIA rédigés avec une formulation
-- originale. Elle ne reproduit pas les ouvrages externes.

insert into public.legal_documents (
  id, title, type, domain, reference, date_publication, status, summary,
  full_content, outline, summary_only, official_source_name, source_url,
  tags, related_ids, imported_at
)
values
(
  'doc-jurisia-cours-complet-droit-penal-general',
  'Cours complet JurisIA — Droit pénal général', 'traite', 'penal',
  'Édition pédagogique originale JurisIA — pack Droit pénal', '2026-09-19', 'enVigueur',
  'Cours complet sur la loi pénale, l’infraction, la responsabilité, la participation, les causes d’irresponsabilité et les peines.',
  $general$
COURS COMPLET JURISIA — DROIT PÉNAL GÉNÉRAL

Le droit pénal général fournit les catégories qui permettent de déterminer
quand un comportement peut être poursuivi, qui peut en répondre et quelle
sanction peut être prononcée. Il doit être lu avec le Code pénal applicable,
la Constitution, les textes de procédure et les instruments internationaux en
vigueur. Ce cours est une création pédagogique JurisIA inspirée par les
thèmes des supports transmis, et non la reproduction d’un ouvrage.

PARTIE I — FONDEMENTS ET LÉGALITÉ

Le droit pénal protège des intérêts fondamentaux en définissant des interdictions
et des sanctions. Il poursuit une fonction de protection, de prévention, de
réinsertion et de réaffirmation de la norme. Ces finalités ne permettent pas
de condamner sur la seule dangerosité supposée d’une personne : la responsabilité
doit reposer sur un texte et des faits établis.

Le principe de légalité exige qu’une incrimination et une peine soient prévues
par un texte accessible avant les faits. Il commande une interprétation stricte
du texte pénal et interdit l’analogie défavorable. La loi pénale plus sévère ne
doit pas rétroagir, tandis qu’une loi plus douce peut recevoir l’application que
prévoit le droit applicable. Les règles de compétence territoriale et les cas
de compétence extraterritoriale doivent être vérifiés séparément.

PARTIE II — L’INFRACTION

Une infraction s’analyse par un élément légal, un élément matériel et un élément
moral. L’élément légal est le texte qui décrit le comportement et la sanction.
L’élément matériel comprend l’acte ou l’omission, le résultat lorsque le texte
l’exige, les circonstances et parfois un lien causal. L’élément moral correspond
à l’intention, à la conscience, à la volonté ou à la faute d’imprudence exigée.

La classification en contravention, délit et crime dépend du droit national et
produit des conséquences sur la juridiction, la tentative, la prescription,
les mesures d’enquête et la peine. Une infraction instantanée se consomme à un
moment déterminé; une infraction continue se prolonge par la volonté de son
auteur; une infraction d’habitude suppose la répétition prévue par le texte.

La tentative suppose un commencement d’exécution et une interruption
indépendante de la volonté de l’auteur, sous réserve du régime de l’infraction.
Les actes préparatoires ne suffisent pas toujours. Le désistement volontaire
peut modifier l’analyse, tandis que l’échec dû à un événement extérieur n’efface
pas nécessairement la tentative.

PARTIE III — AUTEURS ET RESPONSABILITÉ

L’auteur réalise les éléments de l’infraction. La coaction repose sur une action
concertée. La complicité exige, selon le texte applicable, une aide, une
assistance, une provocation ou des instructions données sciemment. Il faut
distinguer l’aide intentionnelle de la simple présence et démontrer le lien
entre l’acte du participant et l’infraction principale.

La responsabilité pénale est personnelle. Elle ne se déduit ni de la parenté,
ni de la fonction, ni de la propriété d’un bien. Une personne morale peut être
responsable lorsque le droit le prévoit et si l’infraction a été commise pour
son compte par un organe ou un représentant habilité. La responsabilité de la
personne morale n’efface pas nécessairement celle des personnes physiques.

L’âge, les troubles psychiques, la contrainte, l’erreur, l’état de nécessité,
la légitime défense et l’ordre de la loi peuvent modifier ou exclure la
responsabilité lorsque leurs conditions sont prouvées. La légitime défense
suppose une atteinte injustifiée et une riposte nécessaire et proportionnée.

PARTIE IV — PEINES ET MÉTHODE

La peine doit être légale, nécessaire et individualisée. Le juge tient compte
de la gravité des faits, du rôle de chacun, du préjudice, des antécédents et des
efforts de réparation dans les limites du texte. Il faut distinguer peine
principale, peine complémentaire, mesure de sûreté, réparation civile et
confiscation. La récidive, la tentative, la participation et les circonstances
aggravantes influent sur le régime applicable.

Pour traiter un cas : établir la chronologie; identifier chaque personne et
chaque acte; citer le texte; vérifier successivement les trois éléments; analyser
tentative et participation; examiner les causes d’irresponsabilité; déterminer
la peine et la compétence. Vérifier la version du Code pénal applicable à la
date des faits.
    $general$,
  array['Fondements et légalité', 'L’infraction', 'Auteurs et responsabilité', 'Imputabilité et irresponsabilité', 'Peines et individualisation', 'Méthode de cas pratique'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-penal', 'droit pénal général', 'infraction', 'responsabilité pénale', 'peines'], array[]::text[], now()
),
(
  'doc-jurisia-cours-complet-droit-penal-special',
  'Cours complet JurisIA — Droit pénal spécial', 'traite', 'penal',
  'Édition pédagogique originale JurisIA — pack Droit pénal', '2026-09-19', 'enVigueur',
  'Cours complet de qualification des atteintes aux personnes, aux biens, à la confiance, à l’autorité publique et à la sécurité.',
  $special$
COURS COMPLET JURISIA — DROIT PÉNAL SPÉCIAL

Le droit pénal spécial étudie chaque infraction à partir de son texte. Une
qualification sérieuse identifie le bien protégé, l’auteur, la victime, le
comportement, les circonstances, l’intention, le résultat, les aggravations et
la peine. Il faut éviter de partir d’une étiquette médiatique : les faits sont
confrontés aux éléments exacts de l’incrimination applicable.

ATTEINTES À LA VIE ET À L’INTÉGRITÉ

L’homicide volontaire se distingue de l’homicide involontaire par la volonté de
donner la mort et par la faute exigée. Les violences se qualifient selon
l’atteinte, les conséquences, l’arme, la préméditation, la vulnérabilité et le
contexte. Les blessures involontaires exigent une faute de maladresse,
imprudence, négligence ou violation d’une obligation de sécurité selon le texte.
Les violences dans le couple, sur un mineur ou sur une personne vulnérable
peuvent relever de dispositions spéciales.

ATTEINTES SEXUELLES ET PROTECTION DES PERSONNES

Les infractions sexuelles exigent une étude précise de l’âge, du consentement,
de la contrainte, de la menace, de la surprise, de l’autorité et des actes
reprochés. La protection des mineurs renforce les obligations et les
aggravations prévues par la loi. Le secret de l’enquête, la dignité de la
victime et la conservation des preuves médicales et numériques doivent être
préservés.

ATTEINTES AUX BIENS

Le vol suppose une soustraction frauduleuse de la chose d’autrui. L’extorsion
ajoute une contrainte, une menace ou une violence. Le recel porte sur la
détention, la transmission ou le profit tiré d’une chose provenant d’une
infraction, avec la connaissance requise.

L’abus de confiance repose sur le détournement d’un bien remis à charge de le
rendre, de le représenter ou d’en faire un usage déterminé. L’escroquerie
suppose des manœuvres ou une tromperie ayant déterminé une remise. La
distinction avec un simple litige contractuel dépend de la fraude initiale, du
moment de l’intention et des preuves disponibles.

FAUX, CORRUPTION ET INFRACTIONS ÉCONOMIQUES

Le faux altère la vérité dans un écrit ou un support ayant une portée juridique
et l’usage consiste à s’en prévaloir. La corruption et le trafic d’influence
nécessitent d’identifier l’avantage, l’intermédiaire, la fonction concernée,
l’accord ou la sollicitation et le moment de l’échange.

Les infractions d’affaires peuvent concerner la société, les créanciers, la
concurrence, le blanchiment, les marchés publics ou la gestion des fonds.
L’enquête financière suit les flux, les bénéficiaires effectifs, les actes de
gestion et les pièces comptables sans confondre mauvaise gestion et infraction
intentionnelle.

AUTORITÉ, PAIX PUBLIQUE ET NUMÉRIQUE

Les infractions contre l’autorité publique protègent le fonctionnement des
institutions, l’intégrité des agents et l’exécution des décisions. Les atteintes
à la paix publique, les associations criminelles, les armes et le terrorisme
relèvent de textes spéciaux à consulter dans leur version en vigueur.

L’accès frauduleux, l’atteinte à un système, la captation de données et la
fraude en ligne doivent être qualifiés selon le texte national. Les preuves
numériques exigent une chaîne de conservation : origine, date, support, copie,
intégrité, accès et rapprochement avec les autres faits.

MÉTHODE DE CAS

Construire un tableau par infraction : texte, bien protégé, auteur, victime,
acte, résultat, intention, circonstances, preuve, aggravations et sanction.
Comparer les qualifications concurrentes, examiner tentative et complicité,
puis retenir la qualification la plus précise. Les montants et durées de peine
doivent être vérifiés dans le Code pénal applicable, jamais déduits d’un ancien
support.
    $special$,
  array['Qualification pénale', 'Atteintes à la vie et à l’intégrité', 'Atteintes sexuelles', 'Atteintes aux biens', 'Faux, corruption et infractions économiques', 'Autorité, paix publique et numérique', 'Méthode de cas pratique'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-penal', 'droit pénal spécial', 'atteintes aux personnes', 'atteintes aux biens', 'infractions économiques'], array[]::text[], now()
),
(
  'doc-jurisia-cours-complet-procedure-penale',
  'Cours complet JurisIA — Procédure pénale', 'traite', 'procedurePenale',
  'Édition pédagogique originale JurisIA — pack Procédure pénale', '2026-09-19', 'enVigueur',
  'Cours complet sur l’action publique, l’enquête, l’instruction, le jugement, les voies de recours et l’exécution des décisions.',
  $procedure$
COURS COMPLET JURISIA — PROCÉDURE PÉNALE

La procédure pénale organise la recherche des infractions, la poursuite des
auteurs, le jugement et l’exécution. Elle concilie recherche de la vérité,
sécurité publique, présomption d’innocence, droits de la défense, dignité,
délai raisonnable, contrôle du juge et réparation de la victime. Les règles de
compétence, de délai et de nullité sont celles du Code applicable.

ACTEURS ET ACTIONS

Le ministère public apprécie les suites à donner selon ses pouvoirs. La police
judiciaire constate, recherche, conserve les indices et exécute les actes
autorisés sous la direction prévue par la loi. Le juge d’instruction, lorsqu’il
existe, recherche les charges à décharge et à charge. La juridiction de
jugement tranche culpabilité et peine. La victime peut être témoin, partie
civile ou demander réparation dans les formes prévues.

L’action publique tend à l’application de la loi pénale; l’action civile vise
la réparation du dommage. Elles peuvent être liées sans se confondre. Le
classement, la médiation et les alternatives aux poursuites supposent un
fondement légal, un consentement valide et une décision traçable.

ENQUÊTE

L’enquête de flagrance repose sur une situation permettant une intervention
immédiate; l’enquête préliminaire obéit à un cadre différent. Il faut vérifier
le déclenchement, la direction, l’autorisation, la durée, les horaires et la
proportionnalité de chaque acte. Auditions, perquisitions, saisies,
réquisitions, interceptions et constatations respectent leurs garanties propres.

La garde à vue ou mesure équivalente est encadrée : notification des droits,
information sur les faits, assistance d’un avocat lorsque la loi le prévoit,
examen médical, information d’un proche et contrôle de la durée. Les procès-
verbaux indiquent les heures, personnes présentes, actes accomplis et réserves.

POURSUITES, INSTRUCTION ET SÛRETÉ

Après l’enquête, le parquet peut classer, orienter, poursuivre ou saisir un
juge. L’acte de poursuite doit permettre au prévenu de connaître les faits et
la qualification. Lorsque l’instruction est ouverte, les parties peuvent
demander des actes, contester certaines décisions et accéder au dossier selon
les règles de confidentialité.

Le contrôle judiciaire, la détention provisoire, l’assignation et les obligations
de pointage ne sont pas des peines anticipées. Ils exigent nécessité,
proportionnalité, motivation et contrôle périodique. La liberté reste le
principe lorsque les conditions de la restriction ne sont pas démontrées.

PREUVE ET NULLITÉS

La preuve pénale doit être obtenue et discutée loyalement. La présomption
d’innocence impose à l’accusation de démontrer les éléments de l’infraction;
le silence ne vaut pas aveu. La preuve scientifique, numérique, documentaire
et testimoniale doit être authentifiée et replacée dans sa chaîne de
conservation.

Une nullité suppose l’identification d’une règle violée, d’un acte concerné et
du grief ou de la condition prévue par le droit. Il faut agir au bon moment,
devant la juridiction compétente et selon la forme requise. Une irrégularité ne
conduit pas automatiquement à l’annulation de tout le dossier.

JUGEMENT, RECOURS ET EXÉCUTION

L’audience respecte le contradictoire, la publicité ou le huis clos justifié,
la présence ou représentation, l’examen des preuves, les réquisitions, les
plaidoiries et le dernier mot de la personne poursuivie. La décision distingue
culpabilité, peine, intérêts civils et frais et répond aux moyens essentiels.

L’appel permet un nouvel examen dans la limite de sa saisine. Le pourvoi ou
recours en cassation contrôle l’application du droit selon les conditions du
système concerné. Les délais, effets suspensifs, personnes habilitées et
formalités doivent être vérifiés avant tout recours.

L’exécution concerne la peine, les mesures de sûreté, la confiscation et la
réparation. Le condamné conserve les droits compatibles avec la sanction et la
victime doit pouvoir faire valoir sa demande et être protégée contre les
représailles.

MÉTHODE DE CONSULTATION

Construire une chronologie; identifier l’autorité et l’acte; vérifier
compétence, base légale, délai, forme, notification, assistance et
proportionnalité; mesurer le grief; choisir la demande utile — nullité, remise
en liberté, acte d’enquête, appel ou réparation — et contrôler la date limite.
Toujours demander la version officielle du Code de procédure pénale avant de
conclure.

Ce cours est un support pédagogique original de JurisIA. Il ne remplace ni un
avocat, ni le texte officiel, ni une décision juridictionnelle dans un dossier
concret.
    $procedure$,
  array['Principes directeurs et acteurs', 'Action publique et victime', 'Enquête', 'Poursuites et instruction', 'Preuve et nullités', 'Audience et jugement', 'Voies de recours', 'Exécution et méthode'],
  false, 'JurisIA — contenu pédagogique original', null,
  array['pack-penal', 'procédure pénale', 'enquête', 'instruction', 'jugement', 'droits de la défense'], array[]::text[], now()
)
on conflict (id) do update set
  title = excluded.title, type = excluded.type, domain = excluded.domain,
  reference = excluded.reference, date_publication = excluded.date_publication,
  status = excluded.status, summary = excluded.summary,
  full_content = excluded.full_content, outline = excluded.outline,
  summary_only = excluded.summary_only,
  official_source_name = excluded.official_source_name,
  source_url = excluded.source_url, tags = excluded.tags,
  related_ids = excluded.related_ids, imported_at = excluded.imported_at;
