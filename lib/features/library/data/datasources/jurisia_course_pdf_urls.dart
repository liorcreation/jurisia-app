/// URL publique des éditions PDF des cours originaux JurisIA.
/// Les mêmes fichiers sont suivis dans output/pdf et publiés dans le bucket
/// Supabase `legal-source-pdfs`.
const jurisiaCoursePdfBaseUrl =
    'https://gfpguuuzzyqoxjkhlhli.supabase.co/storage/v1/object/public/legal-source-pdfs/';

String jurisiaCoursePdfUrl(String filename) =>
    '$jurisiaCoursePdfBaseUrl$filename';
