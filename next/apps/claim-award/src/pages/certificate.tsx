import { Container } from '@black-pear-joggers/container';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { useAwardClaim } from '@black-pear-joggers/core-services';
import { useRouter } from 'next/router';
import { CertificatePreview } from '../components/certificate-preview/certificate-preview';
import { mapAwardClaimToCertificateProps } from '../helpers/map-award-claim-to-certificate';

// A static page reading ?id=&token= (rather than a [id]/[token] dynamic
// route) because this app is statically exported (output: 'export' in
// next.config.js), which needs getStaticPaths for dynamic segments and
// can't enumerate every claim id up front. Mirrors the query-string
// certificate link the old Angular club-standards app already used.
function CertificatePage() {
  const router = useRouter();
  const id = router.query.id ? Number(router.query.id) : undefined;
  const token = router.query.token as string | undefined;

  const { awardClaim, isLoading, isError } = useAwardClaim(id, token);

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <h1>Certificate</h1>

        {isLoading && <p>Loading...</p>}

        {isError && (
          <p>
            We couldn&apos;t find that certificate. Check the link is correct.
          </p>
        )}

        {awardClaim && (
          <>
            {!awardClaim.verified && (
              <p className="mb-4">
                This claim is still <strong>pending verification</strong> by
                the club. Printing will be available once it&apos;s verified.
              </p>
            )}

            <CertificatePreview
              {...mapAwardClaimToCertificateProps(awardClaim)}
              printable={!!awardClaim.verified}
            />
          </>
        )}
      </Container>
    </Stack>
  );
}

export default CertificatePage;
