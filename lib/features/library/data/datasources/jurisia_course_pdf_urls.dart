/// Racine des PDF de la bibliothèque publique JurisIA.
const jurisiaLibraryPdfBaseUrl =
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';

String jurisiaLibraryPdfUrl(String filename) =>
    '$jurisiaLibraryPdfBaseUrl${Uri.encodeComponent(filename)}';

/// URL des éditions PDF générées à partir des cours originaux JurisIA.
String jurisiaCoursePdfUrl(String filename) => jurisiaLibraryPdfUrl(filename);
