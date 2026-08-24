import '../../../../models/legal_document/legal_domain.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/student_level.dart';

/// Frontière data vers le programme universitaire. Permet de substituer,
/// plus tard, un programme distant (API pédagogique) à la base locale sans
/// toucher au reste de l'architecture.
abstract class StudentCurriculumDataSource {
  List<CourseModule> getAll();
}

/// Parcours universitaire officiel et séquentiel de L1 à M2 : trois
/// modules par niveau, chacun débloqué par la validation du précédent.
/// Seul le premier module de L1 est débloqué par défaut.
class LocalStudentCurriculumDataSource implements StudentCurriculumDataSource {
  const LocalStudentCurriculumDataSource();

  @override
  List<CourseModule> getAll() => _curriculum;
}

CourseModule _module({
  required AcademicLevel level,
  required int order,
  required String title,
  required String description,
  required LegalDomain domain,
  required List<Lesson> lessons,
  required RevisionSheet revisionSheet,
  required List<Exercise> exercises,
}) {
  final id = '${level.name}-module-$order';
  return CourseModule(
    id: id,
    level: level,
    order: order,
    title: title,
    description: description,
    domain: domain,
    lessons: lessons,
    revisionSheets: [revisionSheet],
    exercises: exercises,
    isUnlocked: level == AcademicLevel.l1 && order == 1,
    isCompleted: false,
  );
}

final List<CourseModule> _curriculum = [
  // ---------------------------------------------------------------- L1 ----
  _module(
    level: AcademicLevel.l1,
    order: 1,
    title: 'Introduction générale au droit',
    description: 'Notion de droit, sources et organisation judiciaire.',
    domain: LegalDomain.civil,
    lessons: [
      Lesson(
        id: 'l1-m1-lecon-1',
        moduleId: 'l1-module-1',
        order: 1,
        title: 'Qu\'est-ce que le droit ?',
        content:
            'Le droit est l\'ensemble des règles qui organisent la vie en société et dont le '
            'respect est assuré, si nécessaire, par la contrainte publique. On distingue le '
            'droit objectif — l\'ensemble des règles — des droits subjectifs, prérogatives '
            'reconnues à une personne (droit de propriété, droit de créance...).\n\n'
            'La règle de droit se distingue des autres règles sociales (morale, religion, usages) '
            'par son caractère obligatoire et sa sanction étatique. Elle est générale et '
            'impersonnelle : elle s\'applique à toute personne se trouvant dans la situation '
            'qu\'elle vise, sans désigner nommément quiconque.',
      ),
      Lesson(
        id: 'l1-m1-lecon-2',
        moduleId: 'l1-module-1',
        order: 2,
        title: 'Les sources du droit',
        content:
            'Les sources du droit sont les modes de formation des règles juridiques. On distingue '
            'traditionnellement les sources écrites — la Constitution, les traités, les lois, les '
            'règlements (décrets, arrêtés) — et les sources non écrites, au premier rang '
            'desquelles la jurisprudence (l\'interprétation de la loi par les tribunaux) et la '
            'coutume.\n\n'
            'Ces sources sont hiérarchisées : une norme inférieure doit être conforme à la norme '
            'supérieure. La Constitution prime sur les traités, qui priment sur les lois, '
            'elles-mêmes supérieures aux règlements. Cette hiérarchie des normes est au cœur du '
            'contrôle de constitutionnalité et de légalité.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l1-m1-fiche',
      moduleId: 'l1-module-1',
      title: 'Notion de droit et hiérarchie des normes',
      keyPoints: const [
        'Droit objectif (les règles) / droits subjectifs (les prérogatives individuelles)',
        'La règle de droit est générale, impersonnelle et sanctionnée par l\'État',
        'Hiérarchie : Constitution > traités > lois > règlements (décrets, arrêtés)',
        'La jurisprudence et la coutume sont des sources non écrites du droit',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l1-m1-ex-1',
        moduleId: 'l1-module-1',
        statement:
            'Expliquez en quoi la règle de droit se distingue d\'une règle morale, en illustrant '
            'votre propos par un exemple.',
        correctionGuideline:
            'Attendu : caractère obligatoire et sanction étatique (contrainte, exécution forcée) '
            'de la règle de droit, absents de la règle morale qui relève de la conscience '
            'individuelle. Exemple attendu : l\'obligation de payer ses dettes (droit) versus le '
            'devoir moral de gratitude.',
      ),
      Exercise(
        id: 'l1-m1-ex-2',
        moduleId: 'l1-module-1',
        statement: 'Classez par ordre hiérarchique décroissant : décret, loi, Constitution, arrêté, traité.',
        correctionGuideline: 'Constitution, traité, loi, décret, arrêté.',
        difficulty: 1,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.l1,
    order: 2,
    title: 'Droit des personnes',
    description: 'Personnalité juridique, état civil, capacité.',
    domain: LegalDomain.civil,
    lessons: [
      Lesson(
        id: 'l1-m2-lecon-1',
        moduleId: 'l1-module-2',
        order: 1,
        title: 'La personnalité juridique',
        content:
            'La personnalité juridique est l\'aptitude à être titulaire de droits et débiteur '
            'd\'obligations. Elle est reconnue à toute personne physique dès la naissance (à '
            'condition de naître vivante et viable) et s\'éteint avec la mort.\n\n'
            'Les personnes morales (sociétés, associations, l\'État...) disposent également de la '
            'personnalité juridique, généralement à compter de leur immatriculation ou déclaration, '
            'ce qui leur permet d\'agir en justice, de posséder un patrimoine propre et de conclure '
            'des contrats en leur nom.',
      ),
      Lesson(
        id: 'l1-m2-lecon-2',
        moduleId: 'l1-module-2',
        order: 2,
        title: 'État civil et capacité',
        content:
            'L\'état civil identifie une personne : nom, prénoms, date et lieu de naissance, '
            'filiation, situation matrimoniale. Il est constaté par des actes dressés par '
            'l\'officier d\'état civil (naissance, mariage, décès).\n\n'
            'La capacité juridique se décompose en capacité de jouissance (aptitude à être '
            'titulaire de droits) et capacité d\'exercice (aptitude à les exercer soi-même). Les '
            'mineurs et les majeurs protégés bénéficient d\'un régime de protection qui restreint '
            'leur capacité d\'exercice, sans les priver de leurs droits.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l1-m2-fiche',
      moduleId: 'l1-module-2',
      title: 'Personnalité, état civil, capacité',
      keyPoints: const [
        'La personnalité juridique physique commence à la naissance (vivant et viable)',
        'Les personnes morales acquièrent la personnalité juridique par immatriculation/déclaration',
        'Capacité de jouissance ≠ capacité d\'exercice',
        'Les mineurs et majeurs protégés ont une capacité d\'exercice restreinte',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l1-m2-ex-1',
        moduleId: 'l1-module-2',
        statement: 'Un mineur peut-il être titulaire d\'un compte bancaire à son nom ? Justifiez.',
        correctionGuideline:
            'Oui pour la titularité (capacité de jouissance), mais l\'exercice des opérations est '
            'en principe encadré par les représentants légaux, faute de capacité d\'exercice '
            'pleine.',
      ),
      Exercise(
        id: 'l1-m2-ex-2',
        moduleId: 'l1-module-2',
        statement: 'Citez trois actes dressés par l\'officier d\'état civil.',
        correctionGuideline: 'Acte de naissance, acte de mariage, acte de décès.',
        difficulty: 1,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.l1,
    order: 3,
    title: 'Institutions judiciaires',
    description: 'Organisation des juridictions et acteurs du procès.',
    domain: LegalDomain.procedureCivile,
    lessons: [
      Lesson(
        id: 'l1-m3-lecon-1',
        moduleId: 'l1-module-3',
        order: 1,
        title: 'L\'organisation des juridictions',
        content:
            'L\'ordre judiciaire se structure en juridictions de première instance (tribunaux '
            'civils, tribunaux de commerce, tribunaux du travail selon la matière), en cours '
            'd\'appel qui réexaminent l\'affaire en fait et en droit, et en une juridiction '
            'suprême (Cour de cassation) qui ne contrôle que l\'application du droit.\n\n'
            'À côté de l\'ordre judiciaire, un ordre administratif connaît des litiges impliquant '
            'l\'administration, et une juridiction constitutionnelle contrôle la conformité des '
            'lois à la Constitution.',
      ),
      Lesson(
        id: 'l1-m3-lecon-2',
        moduleId: 'l1-module-3',
        order: 2,
        title: 'Les acteurs du procès',
        content:
            'Le juge tranche le litige en application du droit et dans le respect du '
            'contradictoire. Les parties (demandeur et défendeur) exposent leurs prétentions, '
            'assistées ou représentées par un avocat. Le ministère public défend l\'intérêt de la '
            'société dans les affaires qui l\'exigent.\n\n'
            'D\'autres officiers publics interviennent en périphérie du procès : l\'huissier de '
            'justice signifie les actes et exécute les décisions, le notaire authentifie certains '
            'actes, l\'expert judiciaire éclaire le juge sur des questions techniques.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l1-m3-fiche',
      moduleId: 'l1-module-3',
      title: 'Juridictions et acteurs du procès',
      keyPoints: const [
        'Première instance → Cour d\'appel (fait + droit) → Cour de cassation (droit uniquement)',
        'Ordre judiciaire / ordre administratif / juridiction constitutionnelle',
        'Le juge tranche ; les parties sont assistées ou représentées par un avocat',
        'Huissier (signification, exécution), notaire (authentification), expert (technique)',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l1-m3-ex-1',
        moduleId: 'l1-module-3',
        statement: 'Quelle est la différence entre l\'appel et le pourvoi en cassation ?',
        correctionGuideline:
            'L\'appel permet un réexamen complet de l\'affaire en fait et en droit ; le pourvoi en '
            'cassation ne porte que sur la correcte application du droit par les juges du fond.',
      ),
      Exercise(
        id: 'l1-m3-ex-2',
        moduleId: 'l1-module-3',
        statement: 'Quel officier public est chargé de faire exécuter une décision de justice ?',
        correctionGuideline: 'L\'huissier de justice.',
        difficulty: 1,
      ),
    ],
  ),

  // ---------------------------------------------------------------- L2 ----
  _module(
    level: AcademicLevel.l2,
    order: 1,
    title: 'Droit des obligations',
    description: 'Contrats, responsabilité civile et régime des obligations.',
    domain: LegalDomain.civil,
    lessons: [
      Lesson(
        id: 'l2-m1-lecon-1',
        moduleId: 'l2-module-1',
        order: 1,
        title: 'La formation du contrat',
        content:
            'Le contrat se forme par la rencontre d\'une offre et d\'une acceptation, portant sur '
            'des éléments essentiels, et suppose des parties capables et un contenu licite. '
            'Certains contrats requièrent en outre une forme particulière (écrit, acte '
            'authentique) à peine de nullité.\n\n'
            'Le principe de la liberté contractuelle permet aux parties de déterminer librement le '
            'contenu du contrat, dans les limites de l\'ordre public. Une fois formé, le contrat a '
            'force obligatoire : il s\'impose aux parties comme la loi elle-même.',
      ),
      Lesson(
        id: 'l2-m1-lecon-2',
        moduleId: 'l2-module-1',
        order: 2,
        title: 'La responsabilité civile',
        content:
            'La responsabilité civile délictuelle oblige l\'auteur d\'une faute ayant causé un '
            'dommage à autrui à le réparer. Trois conditions cumulatives sont requises : une '
            'faute, un dommage (certain, direct, personnel) et un lien de causalité entre les '
            'deux.\n\n'
            'La responsabilité contractuelle, elle, sanctionne l\'inexécution ou la mauvaise '
            'exécution d\'un contrat par l\'octroi de dommages et intérêts au créancier, sous '
            'réserve que le débiteur ait été mis en demeure et ne justifie pas d\'une cause '
            'étrangère exonératoire.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l2-m1-fiche',
      moduleId: 'l2-module-1',
      title: 'Formation du contrat et responsabilité',
      keyPoints: const [
        'Contrat = offre + acceptation + capacité + contenu licite',
        'Force obligatoire du contrat entre les parties',
        'Responsabilité délictuelle : faute + dommage + lien de causalité',
        'Responsabilité contractuelle : inexécution + mise en demeure (sauf cause étrangère)',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l2-m1-ex-1',
        moduleId: 'l2-module-1',
        statement: 'Un vendeur qui livre en retard peut-il s\'exonérer en invoquant un cas de force majeure ?',
        correctionGuideline:
            'Oui, si l\'événement est imprévisible, irrésistible et extérieur au débiteur ; la '
            'force majeure exonère de la responsabilité contractuelle.',
      ),
      Exercise(
        id: 'l2-m1-ex-2',
        moduleId: 'l2-module-1',
        statement: 'Citez les trois conditions cumulatives de la responsabilité délictuelle.',
        correctionGuideline: 'Une faute, un dommage, un lien de causalité entre les deux.',
        difficulty: 1,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.l2,
    order: 2,
    title: 'Droit administratif général',
    description: 'Acte administratif et action de l\'administration.',
    domain: LegalDomain.administratif,
    lessons: [
      Lesson(
        id: 'l2-m2-lecon-1',
        moduleId: 'l2-module-2',
        order: 1,
        title: 'L\'acte administratif unilatéral',
        content:
            'L\'administration agit principalement par voie d\'actes unilatéraux (décisions, '
            'arrêtés) qui s\'imposent sans le consentement de leurs destinataires, au nom de '
            'l\'intérêt général. Ces actes doivent être pris par une autorité compétente, dans le '
            'respect d\'une procédure et pour un motif légal.\n\n'
            'Un acte administratif illégal peut être contesté par un recours pour excès de '
            'pouvoir devant le juge administratif, qui peut en prononcer l\'annulation s\'il '
            'constate un vice de compétence, de forme, de procédure ou un motif illégal.',
      ),
      Lesson(
        id: 'l2-m2-lecon-2',
        moduleId: 'l2-module-2',
        order: 2,
        title: 'Le contrat administratif',
        content:
            'L\'administration peut aussi agir par voie contractuelle (marchés publics, '
            'concessions). Ces contrats se distinguent des contrats de droit privé par des '
            'clauses exorbitantes du droit commun et par les prérogatives reconnues à '
            'l\'administration : pouvoir de contrôle, de modification unilatérale et de sanction, '
            'en contrepartie du droit du cocontractant à l\'équilibre financier du contrat.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l2-m2-fiche',
      moduleId: 'l2-module-2',
      title: 'Action administrative',
      keyPoints: const [
        'Acte unilatéral : s\'impose sans le consentement du destinataire',
        'Conditions de légalité : compétence, procédure, motif',
        'Recours pour excès de pouvoir devant le juge administratif',
        'Contrat administratif : clauses exorbitantes + équilibre financier',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l2-m2-ex-1',
        moduleId: 'l2-module-2',
        statement: 'Quel recours permet de contester la légalité d\'un arrêté municipal ?',
        correctionGuideline: 'Le recours pour excès de pouvoir devant le juge administratif.',
      ),
      Exercise(
        id: 'l2-m2-ex-2',
        moduleId: 'l2-module-2',
        statement: 'Citez un exemple de clause exorbitante du droit commun dans un marché public.',
        correctionGuideline:
            'Le pouvoir de modification ou de résiliation unilatérale reconnu à l\'administration.',
        difficulty: 2,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.l2,
    order: 3,
    title: 'Droit des biens',
    description: 'Propriété, possession et démembrements.',
    domain: LegalDomain.civil,
    lessons: [
      Lesson(
        id: 'l2-m3-lecon-1',
        moduleId: 'l2-module-3',
        order: 1,
        title: 'Le droit de propriété',
        content:
            'La propriété est le droit de jouir et de disposer d\'une chose de la manière la plus '
            'absolue, dans les limites fixées par la loi et les règlements. Elle confère à son '
            'titulaire trois prérogatives : l\'usus (user de la chose), le fructus (en percevoir '
            'les fruits) et l\'abusus (en disposer, y compris la détruire ou l\'aliéner).\n\n'
            'La propriété peut être exercée seul ou en indivision entre plusieurs personnes, '
            'chacune disposant alors d\'une quote-part sur l\'ensemble du bien.',
      ),
      Lesson(
        id: 'l2-m3-lecon-2',
        moduleId: 'l2-module-3',
        order: 2,
        title: 'Les démembrements de propriété',
        content:
            'Le droit de propriété peut être démembré entre plusieurs personnes : l\'usufruitier '
            'dispose de l\'usus et du fructus, tandis que le nu-propriétaire conserve l\'abusus et '
            'récupère la pleine propriété à l\'extinction de l\'usufruit.\n\n'
            'Les servitudes constituent une autre forme de démembrement : elles grèvent un fonds '
            '(le fonds servant) au profit d\'un autre fonds (le fonds dominant), par exemple un '
            'droit de passage.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l2-m3-fiche',
      moduleId: 'l2-module-3',
      title: 'Propriété et démembrements',
      keyPoints: const [
        'Propriété = usus + fructus + abusus',
        'Usufruit : usus + fructus pour l\'usufruitier, abusus pour le nu-propriétaire',
        'Servitude : charge grevant un fonds servant au profit d\'un fonds dominant',
        'Indivision : quote-part de plusieurs propriétaires sur un même bien',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l2-m3-ex-1',
        moduleId: 'l2-module-3',
        statement: 'Un usufruitier peut-il vendre le bien dont il a l\'usufruit ? Justifiez.',
        correctionGuideline:
            'Non, il ne dispose pas de l\'abusus ; seul le nu-propriétaire (ou les deux ensemble) '
            'peut disposer du bien.',
      ),
      Exercise(
        id: 'l2-m3-ex-2',
        moduleId: 'l2-module-3',
        statement: 'Donnez un exemple de servitude.',
        correctionGuideline: 'Une servitude de passage au profit d\'un fonds enclavé.',
        difficulty: 1,
      ),
    ],
  ),

  // ---------------------------------------------------------------- L3 ----
  _module(
    level: AcademicLevel.l3,
    order: 1,
    title: 'Droit commercial général',
    description: 'Commerçant, fonds de commerce, actes de commerce.',
    domain: LegalDomain.commercial,
    lessons: [
      Lesson(
        id: 'l3-m1-lecon-1',
        moduleId: 'l3-module-1',
        order: 1,
        title: 'La qualité de commerçant',
        content:
            'Est commerçant celui qui accomplit des actes de commerce à titre de profession '
            'habituelle. Cette qualité emporte des obligations spécifiques : immatriculation au '
            'registre du commerce, tenue d\'une comptabilité, application des règles de preuve '
            'propres au droit commercial (liberté de la preuve entre commerçants).\n\n'
            'L\'espace OHADA connaît également le statut simplifié de l\'entreprenant, personne '
            'physique exerçant une activité professionnelle sans être soumise à l\'ensemble des '
            'obligations du commerçant de droit commun.',
      ),
      Lesson(
        id: 'l3-m1-lecon-2',
        moduleId: 'l3-module-1',
        order: 2,
        title: 'Le fonds de commerce',
        content:
            'Le fonds de commerce est un ensemble de biens mobiliers, corporels (matériel, '
            'stocks) et incorporels (clientèle, enseigne, droit au bail), affectés à l\'exercice '
            'd\'une activité commerciale. La clientèle en est l\'élément essentiel : sans elle, il '
            'n\'y a pas de fonds de commerce.\n\n'
            'Le fonds peut être cédé, donné en location-gérance ou nanti au profit d\'un '
            'créancier, selon des formalités propres destinées à protéger les tiers (créanciers, '
            'bailleur).',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l3-m1-fiche',
      moduleId: 'l3-module-1',
      title: 'Commerçant et fonds de commerce',
      keyPoints: const [
        'Commerçant = actes de commerce à titre de profession habituelle',
        'Obligations du commerçant : immatriculation, comptabilité, liberté de la preuve',
        'Fonds de commerce = éléments corporels + incorporels, la clientèle en est l\'essentiel',
        'Statut de l\'entreprenant (OHADA) : régime allégé pour l\'activité individuelle',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l3-m1-ex-1',
        moduleId: 'l3-module-1',
        statement: 'Quel est l\'élément essentiel du fonds de commerce, sans lequel il n\'existe pas ?',
        correctionGuideline: 'La clientèle.',
      ),
      Exercise(
        id: 'l3-m1-ex-2',
        moduleId: 'l3-module-1',
        statement: 'Quelle est la particularité de la preuve entre commerçants ?',
        correctionGuideline: 'Elle est libre : elle peut être rapportée par tout moyen.',
        difficulty: 2,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.l3,
    order: 2,
    title: 'Droit du travail',
    description: 'Contrat de travail, rupture, relations collectives.',
    domain: LegalDomain.travail,
    lessons: [
      Lesson(
        id: 'l3-m2-lecon-1',
        moduleId: 'l3-module-2',
        order: 1,
        title: 'Le contrat de travail',
        content:
            'Le contrat de travail se caractérise par une prestation de travail, une rémunération '
            'et un lien de subordination juridique envers l\'employeur, qui dispose d\'un pouvoir '
            'de direction, de contrôle et de sanction.\n\n'
            'Il peut être conclu à durée indéterminée (le régime de droit commun) ou à durée '
            'déterminée, dans les cas limitativement prévus par la loi (remplacement, '
            'accroissement temporaire d\'activité, emploi saisonnier), à défaut de quoi il est '
            'susceptible d\'être requalifié en CDI.',
      ),
      Lesson(
        id: 'l3-m2-lecon-2',
        moduleId: 'l3-module-2',
        order: 2,
        title: 'La rupture du contrat de travail',
        content:
            'Le licenciement pour motif personnel doit reposer sur une cause réelle et sérieuse ; '
            'à défaut, il est abusif et ouvre droit à des dommages et intérêts. Un préavis est dû, '
            'sauf faute grave du salarié.\n\n'
            'Les relations collectives organisent le dialogue social : délégués du personnel, '
            'syndicats et négociation collective permettent d\'adapter les conditions de travail '
            'par accord, dans le respect du socle légal minimal.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l3-m2-fiche',
      moduleId: 'l3-module-2',
      title: 'Contrat de travail et rupture',
      keyPoints: const [
        'Contrat de travail = prestation + rémunération + subordination',
        'CDD limité aux cas légaux, sinon requalification en CDI',
        'Licenciement : cause réelle et sérieuse + préavis (sauf faute grave)',
        'Relations collectives : délégués, syndicats, négociation collective',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l3-m2-ex-1',
        moduleId: 'l3-module-2',
        statement: 'Quel est le critère principal distinguant le contrat de travail du contrat d\'entreprise ?',
        correctionGuideline: 'Le lien de subordination juridique envers le donneur d\'ordre.',
      ),
      Exercise(
        id: 'l3-m2-ex-2',
        moduleId: 'l3-module-2',
        statement: 'Un licenciement sans préavis est-il toujours abusif ?',
        correctionGuideline: 'Non : la faute grave du salarié dispense l\'employeur du préavis.',
        difficulty: 2,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.l3,
    order: 3,
    title: 'Procédure civile',
    description: 'Instance, compétence, voies de recours.',
    domain: LegalDomain.procedureCivile,
    lessons: [
      Lesson(
        id: 'l3-m3-lecon-1',
        moduleId: 'l3-module-3',
        order: 1,
        title: 'L\'instance civile',
        content:
            'L\'instance débute par un acte introductif (assignation, requête) qui saisit le '
            'juge et informe le défendeur. Elle se déroule dans le respect du principe du '
            'contradictoire : chaque partie doit pouvoir discuter les prétentions, moyens et '
            'preuves de l\'autre.\n\n'
            'La compétence du juge saisi s\'apprécie au regard de la matière (compétence '
            'd\'attribution) et du territoire (compétence territoriale, en principe celle du '
            'domicile du défendeur).',
      ),
      Lesson(
        id: 'l3-m3-lecon-2',
        moduleId: 'l3-module-3',
        order: 2,
        title: 'Les voies de recours',
        content:
            'L\'appel est une voie de recours ordinaire, suspensive d\'exécution en principe, qui '
            'permet à la partie qui succombe de faire réexaminer l\'affaire par une juridiction '
            'supérieure. Le pourvoi en cassation est une voie de recours extraordinaire, réservée '
            'aux questions de droit.\n\n'
            'D\'autres voies existent, comme l\'opposition (ouverte au défendeur défaillant contre '
            'un jugement rendu par défaut) ou la tierce opposition (ouverte à un tiers lésé par un '
            'jugement auquel il n\'était pas partie).',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'l3-m3-fiche',
      moduleId: 'l3-module-3',
      title: 'Instance et voies de recours',
      keyPoints: const [
        'Instance = acte introductif + respect du contradictoire',
        'Compétence d\'attribution (matière) et compétence territoriale (lieu)',
        'Appel : voie ordinaire, réexamen fait + droit',
        'Cassation : voie extraordinaire, contrôle du droit uniquement',
      ],
    ),
    exercises: [
      Exercise(
        id: 'l3-m3-ex-1',
        moduleId: 'l3-module-3',
        statement: 'Quel principe impose que chaque partie puisse discuter les preuves adverses ?',
        correctionGuideline: 'Le principe du contradictoire.',
      ),
      Exercise(
        id: 'l3-m3-ex-2',
        moduleId: 'l3-module-3',
        statement: 'Quelle voie de recours est ouverte à un tiers lésé par un jugement ?',
        correctionGuideline: 'La tierce opposition.',
        difficulty: 3,
      ),
    ],
  ),

  // ---------------------------------------------------------------- M1 ----
  _module(
    level: AcademicLevel.m1,
    order: 1,
    title: 'Droit des sociétés',
    description: 'Constitution, fonctionnement et dissolution des sociétés.',
    domain: LegalDomain.commercial,
    lessons: [
      Lesson(
        id: 'm1-m1-lecon-1',
        moduleId: 'm1-module-1',
        order: 1,
        title: 'La constitution de la société',
        content:
            'La société naît d\'un contrat par lequel plusieurs personnes affectent des biens ou '
            'leur industrie à une entreprise commune, en vue de partager le bénéfice ou de '
            'profiter de l\'économie qui pourra en résulter. Elle acquiert la personnalité morale '
            'à compter de son immatriculation.\n\n'
            'Les associés apportent en numéraire, en nature ou en industrie, formant le capital '
            'social contre des parts ou actions représentatives de leurs droits dans la société.',
      ),
      Lesson(
        id: 'm1-m1-lecon-2',
        moduleId: 'm1-module-1',
        order: 2,
        title: 'Fonctionnement et dissolution',
        content:
            'Les organes sociaux (gérance, conseil d\'administration, assemblée des associés) '
            'assurent la gestion et le contrôle de la société, chacun dans les pouvoirs qui lui '
            'sont dévolus par la loi et les statuts.\n\n'
            'La société peut être dissoute pour diverses causes : arrivée du terme, réalisation ou '
            'extinction de l\'objet social, décision des associés, ou dissolution judiciaire pour '
            'juste motif (mésentente grave, inexécution des obligations d\'un associé).',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'm1-m1-fiche',
      moduleId: 'm1-module-1',
      title: 'Vie de la société',
      keyPoints: const [
        'La société acquiert la personnalité morale à l\'immatriculation',
        'Apports en numéraire, en nature, en industrie → capital social',
        'Organes sociaux : gérance/conseil d\'administration + assemblée des associés',
        'Causes de dissolution : terme, extinction de l\'objet, décision, dissolution judiciaire',
      ],
    ),
    exercises: [
      Exercise(
        id: 'm1-m1-ex-1',
        moduleId: 'm1-module-1',
        statement: 'À quel moment une société acquiert-elle la personnalité morale ?',
        correctionGuideline: 'À compter de son immatriculation au registre du commerce.',
      ),
      Exercise(
        id: 'm1-m1-ex-2',
        moduleId: 'm1-module-1',
        statement: 'Citez un motif de dissolution judiciaire d\'une société.',
        correctionGuideline: 'La mésentente grave entre associés paralysant le fonctionnement social.',
        difficulty: 2,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.m1,
    order: 2,
    title: 'Droit pénal des affaires',
    description: 'Infractions économiques et responsabilité pénale.',
    domain: LegalDomain.penal,
    lessons: [
      Lesson(
        id: 'm1-m2-lecon-1',
        moduleId: 'm1-module-2',
        order: 1,
        title: 'Les infractions économiques',
        content:
            'Le droit pénal des affaires réprime des infractions spécifiques au monde économique : '
            'abus de biens sociaux (usage des biens de la société contraire à son intérêt, à des '
            'fins personnelles), banqueroute, corruption, blanchiment de capitaux, escroquerie.\n\n'
            'Ces infractions supposent, comme toute infraction pénale, un élément légal (un texte '
            'qui incrimine le comportement), un élément matériel (le fait commis) et un élément '
            'moral (l\'intention, sauf exception).',
      ),
      Lesson(
        id: 'm1-m2-lecon-2',
        moduleId: 'm1-module-2',
        order: 2,
        title: 'La responsabilité pénale des dirigeants et de la personne morale',
        content:
            'Le dirigeant social engage sa responsabilité pénale personnelle pour les infractions '
            'commises dans la gestion de la société, sauf délégation de pouvoirs valable à un '
            'préposé pourvu de la compétence, de l\'autorité et des moyens nécessaires.\n\n'
            'La personne morale elle-même peut également voir sa responsabilité pénale engagée '
            'pour les infractions commises pour son compte par ses organes ou représentants, '
            'cumulativement avec celle de la personne physique auteur des faits.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'm1-m2-fiche',
      moduleId: 'm1-module-2',
      title: 'Infractions et responsabilité pénale',
      keyPoints: const [
        'Éléments de l\'infraction : légal, matériel, moral',
        'Abus de biens sociaux : usage contraire à l\'intérêt social, à fins personnelles',
        'Délégation de pouvoirs valable : compétence + autorité + moyens',
        'Responsabilité pénale de la personne morale cumulable avec celle du dirigeant',
      ],
    ),
    exercises: [
      Exercise(
        id: 'm1-m2-ex-1',
        moduleId: 'm1-module-2',
        statement: 'Quelles sont les trois conditions d\'une délégation de pouvoirs exonératoire ?',
        correctionGuideline: 'Compétence, autorité et moyens nécessaires du délégataire.',
      ),
      Exercise(
        id: 'm1-m2-ex-2',
        moduleId: 'm1-module-2',
        statement: 'La responsabilité pénale d\'une société exclut-elle celle de son dirigeant ?',
        correctionGuideline: 'Non, les deux responsabilités peuvent se cumuler.',
        difficulty: 3,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.m1,
    order: 3,
    title: 'Droit fiscal',
    description: 'Imposition des personnes et des entreprises.',
    domain: LegalDomain.fiscal,
    lessons: [
      Lesson(
        id: 'm1-m3-lecon-1',
        moduleId: 'm1-module-3',
        order: 1,
        title: 'Les grands principes de l\'imposition',
        content:
            'L\'impôt est un prélèvement obligatoire, sans contrepartie directe, destiné à '
            'financer les charges publiques. Il obéit au principe de légalité (seule la loi peut '
            'créer un impôt) et au principe d\'égalité devant l\'impôt, qui n\'exclut pas la '
            'progressivité selon les capacités contributives.\n\n'
            'On distingue les impôts directs (impôt sur le revenu, impôt sur les sociétés), '
            'supportés directement par le contribuable, des impôts indirects (TVA), répercutés '
            'sur le prix des biens et services.',
      ),
      Lesson(
        id: 'm1-m3-lecon-2',
        moduleId: 'm1-module-3',
        order: 2,
        title: 'L\'imposition des entreprises',
        content:
            'Les sociétés sont en principe soumises à l\'impôt sur les sociétés, assis sur le '
            'bénéfice net réalisé, après déduction des charges déductibles. Certaines structures '
            'peuvent opter pour la transparence fiscale, le résultat étant alors imposé '
            'directement entre les mains des associés.\n\n'
            'Le non-respect des obligations déclaratives ou de paiement expose le contribuable à '
            'des pénalités et majorations, et, dans les cas les plus graves, à des poursuites pour '
            'fraude fiscale.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'm1-m3-fiche',
      moduleId: 'm1-module-3',
      title: 'Principes fiscaux',
      keyPoints: const [
        'Principe de légalité de l\'impôt : seule la loi peut le créer',
        'Impôts directs (revenu, sociétés) / impôts indirects (TVA)',
        'Impôt sur les sociétés assis sur le bénéfice net',
        'Sanctions : pénalités, majorations, fraude fiscale',
      ],
    ),
    exercises: [
      Exercise(
        id: 'm1-m3-ex-1',
        moduleId: 'm1-module-3',
        statement: 'Sur quelle base l\'impôt sur les sociétés est-il calculé ?',
        correctionGuideline: 'Sur le bénéfice net réalisé, après déduction des charges déductibles.',
      ),
      Exercise(
        id: 'm1-m3-ex-2',
        moduleId: 'm1-module-3',
        statement: 'Citez un exemple d\'impôt indirect.',
        correctionGuideline: 'La taxe sur la valeur ajoutée (TVA).',
        difficulty: 1,
      ),
    ],
  ),

  // ---------------------------------------------------------------- M2 ----
  _module(
    level: AcademicLevel.m2,
    order: 1,
    title: 'Droit OHADA approfondi',
    description: 'Actes uniformes et contentieux communautaire.',
    domain: LegalDomain.ohada,
    lessons: [
      Lesson(
        id: 'm2-m1-lecon-1',
        moduleId: 'm2-module-1',
        order: 1,
        title: 'Les actes uniformes',
        content:
            'Les actes uniformes OHADA harmonisent le droit des affaires entre les États membres : '
            'droit commercial général, sociétés commerciales, sûretés, procédures collectives, '
            'arbitrage, entre autres. Directement applicables dans chaque État partie, ils '
            'priment sur les dispositions de droit interne contraires, antérieures ou '
            'postérieures.\n\n'
            'Cette intégration juridique vise à sécuriser l\'investissement et à faciliter les '
            'échanges au sein de l\'espace communautaire, en offrant un droit prévisible et '
            'commun.',
      ),
      Lesson(
        id: 'm2-m1-lecon-2',
        moduleId: 'm2-module-1',
        order: 2,
        title: 'Le contentieux devant la CCJA',
        content:
            'La Cour commune de justice et d\'arbitrage (CCJA) est la juridiction suprême en '
            'matière d\'interprétation et d\'application des actes uniformes. Elle se substitue aux '
            'cours de cassation nationales pour ce contentieux, garantissant une interprétation '
            'uniforme du droit OHADA.\n\n'
            'Elle exerce également une fonction d\'arbitrage institutionnel, offrant un cadre pour '
            'la résolution des litiges commerciaux internationaux au sein de l\'espace OHADA.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'm2-m1-fiche',
      moduleId: 'm2-module-1',
      title: 'OHADA : actes uniformes et CCJA',
      keyPoints: const [
        'Actes uniformes : applicables directement, priment sur le droit interne contraire',
        'Domaines harmonisés : commerce général, sociétés, sûretés, procédures collectives, arbitrage',
        'CCJA : juridiction suprême du contentieux OHADA (remplace les cassations nationales)',
        'La CCJA exerce aussi une fonction d\'arbitrage institutionnel',
      ],
    ),
    exercises: [
      Exercise(
        id: 'm2-m1-ex-1',
        moduleId: 'm2-module-1',
        statement: 'Un acte uniforme prime-t-il sur une loi nationale contraire postérieure ?',
        correctionGuideline: 'Oui, les actes uniformes priment sur le droit interne, y compris postérieur.',
      ),
      Exercise(
        id: 'm2-m1-ex-2',
        moduleId: 'm2-module-1',
        statement: 'Quelle juridiction remplace les cours de cassation nationales pour le contentieux OHADA ?',
        correctionGuideline: 'La Cour commune de justice et d\'arbitrage (CCJA).',
        difficulty: 2,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.m2,
    order: 2,
    title: 'Arbitrage et modes alternatifs',
    description: 'Médiation, conciliation, arbitrage commercial.',
    domain: LegalDomain.commercial,
    lessons: [
      Lesson(
        id: 'm2-m2-lecon-1',
        moduleId: 'm2-module-2',
        order: 1,
        title: 'La médiation et la conciliation',
        content:
            'La médiation et la conciliation sont des modes amiables de résolution des litiges, '
            'reposant sur l\'intervention d\'un tiers neutre qui aide les parties à trouver '
            'elles-mêmes une solution, sans la leur imposer. Elles préservent la relation entre '
            'les parties et permettent des solutions plus flexibles qu\'une décision de justice.\n\n'
            'L\'accord issu de la médiation peut être homologué par le juge, lui conférant force '
            'exécutoire, ce qui en garantit l\'efficacité en cas d\'inexécution ultérieure.',
      ),
      Lesson(
        id: 'm2-m2-lecon-2',
        moduleId: 'm2-module-2',
        order: 2,
        title: 'L\'arbitrage commercial',
        content:
            'L\'arbitrage est un mode juridictionnel de résolution des litiges dans lequel les '
            'parties confient à un ou plusieurs arbitres, choisis par elles, le pouvoir de trancher '
            'leur différend par une sentence ayant l\'autorité de la chose jugée.\n\n'
            'Il suppose une convention d\'arbitrage (clause compromissoire insérée dans le contrat, '
            'ou compromis conclu après la naissance du litige) et offre confidentialité, célérité '
            'et expertise technique des arbitres, particulièrement appréciées dans le commerce '
            'international.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'm2-m2-fiche',
      moduleId: 'm2-module-2',
      title: 'Modes alternatifs de résolution des litiges',
      keyPoints: const [
        'Médiation/conciliation : tiers neutre, solution non imposée, préserve la relation',
        'Accord de médiation homologué = force exécutoire',
        'Arbitrage : mode juridictionnel, sentence ayant autorité de chose jugée',
        'Convention d\'arbitrage : clause compromissoire ou compromis',
      ],
    ),
    exercises: [
      Exercise(
        id: 'm2-m2-ex-1',
        moduleId: 'm2-module-2',
        statement: 'Quelle est la différence essentielle entre médiation et arbitrage ?',
        correctionGuideline:
            'Le médiateur aide les parties à trouver leur propre solution sans la leur imposer ; '
            'l\'arbitre tranche le litige par une sentence qui s\'impose aux parties.',
      ),
      Exercise(
        id: 'm2-m2-ex-2',
        moduleId: 'm2-module-2',
        statement: 'Comment appelle-t-on la clause d\'un contrat prévoyant le recours à l\'arbitrage en cas de litige futur ?',
        correctionGuideline: 'La clause compromissoire.',
        difficulty: 2,
      ),
    ],
  ),
  _module(
    level: AcademicLevel.m2,
    order: 3,
    title: 'Rédaction d\'actes avancée',
    description: 'Techniques de rédaction contractuelle et contentieuse.',
    domain: LegalDomain.civil,
    lessons: [
      Lesson(
        id: 'm2-m3-lecon-1',
        moduleId: 'm2-module-3',
        order: 1,
        title: 'Les principes de la rédaction contractuelle',
        content:
            'Un acte bien rédigé anticipe les difficultés d\'exécution et d\'interprétation : '
            'précision des définitions, clarté des obligations de chaque partie, gestion des '
            'hypothèses de défaillance (clauses résolutoires, pénalités, garanties).\n\n'
            'La rédaction doit rechercher l\'équilibre entre exhaustivité et lisibilité : un acte '
            'trop elliptique expose à l\'insécurité juridique, un acte trop touffu nuit à sa '
            'compréhension et peut receler des contradictions internes.',
      ),
      Lesson(
        id: 'm2-m3-lecon-2',
        moduleId: 'm2-module-3',
        order: 2,
        title: 'La rédaction des actes de procédure',
        content:
            'Les actes de procédure (assignation, conclusions, requête) doivent présenter '
            'clairement les faits, les moyens de droit invoqués et les prétentions formulées, en '
            'respectant les exigences de forme prescrites à peine de nullité (mentions '
            'obligatoires, délais).\n\n'
            'Une argumentation juridique efficace articule chaque moyen autour d\'une règle de '
            'droit clairement identifiée, des faits qui lui sont rattachés, et de la conséquence '
            'juridique qui en est tirée.',
      ),
    ],
    revisionSheet: RevisionSheet(
      id: 'm2-m3-fiche',
      moduleId: 'm2-module-3',
      title: 'Techniques de rédaction',
      keyPoints: const [
        'Anticiper l\'exécution et l\'interprétation : définitions, obligations, clauses de garantie',
        'Équilibre entre exhaustivité et lisibilité',
        'Actes de procédure : faits + moyens de droit + prétentions',
        'Respect des mentions obligatoires et délais, à peine de nullité',
      ],
    ),
    exercises: [
      Exercise(
        id: 'm2-m3-ex-1',
        moduleId: 'm2-module-3',
        statement: 'Pourquoi insérer une clause de garantie dans un acte de cession ?',
        correctionGuideline:
            'Pour protéger le cessionnaire contre les passifs ou vices non révélés lors de la '
            'cession, en organisant une indemnisation contractuelle.',
      ),
      Exercise(
        id: 'm2-m3-ex-2',
        moduleId: 'm2-module-3',
        statement: 'Quels sont les trois éléments d\'un moyen de droit bien structuré ?',
        correctionGuideline: 'La règle de droit, les faits qui s\'y rattachent, la conséquence juridique tirée.',
        difficulty: 2,
      ),
    ],
  ),
];
