import { Container } from '@black-pear-joggers/container';
import {
  Performance,
  usePerformances,
  useUser,
} from '@black-pear-joggers/core-services';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { useMemo } from 'react';
import { CertificatePreview } from './certificate-preview/certificate-preview';
import { AwardsSummary } from '../types/awards-summary';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faTriangleExclamation } from '@fortawesome/free-solid-svg-icons';

export function YourAwards() {
  const { data: userProfile, isLoading: isLoadingUser } = useUser();
  const { data: results, isLoading: isLoadingPerformances } = usePerformances(
    userProfile?.athleteId
  );

  const awardsSummaries = useMemo(() => {
    return results?.data ? getAwardsSummaries(results?.data) : null;
  }, [results]);

  const yearsWithAgeCategoryChanges = useMemo(() => {
    return results?.data ? getYearsWithAgeCategoryChanges(results?.data) : null;
  }, [results]);

  console.log(yearsWithAgeCategoryChanges);

  if (isLoadingUser || isLoadingPerformances) {
    return (
      <Stack backgroundColour={BackgroundColour.Light}>
        <Container>
          <h2>Your awards</h2>

          <p>Loading...</p>
        </Container>
      </Stack>
    );
  }

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <>
          <h2>Your awards</h2>

          <p className="mb-8">
            See the awards you have earned. The performances are taken from your{' '}
            <a
              href={`http://www.thepowerof10.info/athletes/profile.aspx?athleteid=${userProfile?.athleteId}`}
              target="_blank"
              rel="noreferrer"
            >
              Power of 10
            </a>{' '}
            profile, so please check that if anything is missing. You can also
            see your full set of results on your{' '}
            <a
              href={`https://apps.bpj.org.uk/race-results/#/athlete/${userProfile?.athleteId}`}
              target="_blank"
              rel="noreferrer"
            >
              BPJ race results page
            </a>
            .
          </p>

          {awardsSummaries &&
            awardsSummaries
              .filter((awardsSummary) => awardsSummary.award)
              .map((awardsSummary) => (
                <>
                  {yearsWithAgeCategoryChanges[awardsSummary.year]?.size >
                    1 && (
                    <div className="p-4 bg-orange-100 flex items-center mb-4">
                      <FontAwesomeIcon
                        className="pr-4 h-8 text-orange-400"
                        icon={faTriangleExclamation}
                      />
                      <span>
                        In {awardsSummary.year}, you moved from the{' '}
                        {[...yearsWithAgeCategoryChanges[awardsSummary.year]]
                          .reverse()
                          .join(' to the ')}{' '}
                        age category. For awards, all results must be in the
                        same category, which might explain any missing awards or
                        results. You can see your full set of results on your{' '}
                        <a
                          href={`https://apps.bpj.org.uk/race-results/#/athlete/${userProfile?.athleteId}`}
                          target="_blank"
                          rel="noreferrer"
                        >
                          BPJ race results page
                        </a>
                        .
                      </span>
                    </div>
                  )}

                  <CertificatePreview
                    key={`${awardsSummary.year}${awardsSummary.category}`}
                    athlete={userProfile.athlete}
                    year={awardsSummary.year}
                    category={awardsSummary.category}
                    performances={awardsSummary.performances}
                    award={awardsSummary.award}
                  />
                </>
              ))}
        </>
      </Container>
    </Stack>
  );
}

const eventDistances = {
  '1M': 'Mile',
  Mile: 'Mile',
  '5K': '5K',
  parkrun: '5K',
  '10K': '10K',
  '10KMT': '10K',
  HM: 'HM',
  HMMT: 'HM',
  Mar: 'Mar',
  MarMT: 'Mar',
};

function getAwardsSummaries(performances: Performance[]): AwardsSummary[] {
  const awardsSummaries: AwardsSummary[] = [];

  performances.forEach((performance) => {
    const year = new Date(performance.date).getFullYear();
    const category = performance.category;

    // Skip if no award for performance
    if (!performance.award) {
      return;
    }

    const yearAndCategoryIndex = awardsSummaries.findIndex(
      (_) => _.year === year && _.category === category
    );

    // Check if the current year/category has been stored
    if (yearAndCategoryIndex === -1) {
      awardsSummaries.push({
        year,
        category,
        award: null,
        categoryChangedInYear: false,
        performances: [performance],
      });

      // Skip further checks as this is the first performance for the
      // current year/category, so nothing to compare to
      return;
    }

    const eventIndex = awardsSummaries[
      yearAndCategoryIndex
    ].performances.findIndex(
      (_) => eventDistances[_.event] === eventDistances[performance.event]
    );

    // Add in result if it meets an award standard and is faster
    // than the previously known best for that year and category
    if (
      eventIndex === -1 ||
      Number(performance.timeParsed) <
        Number(
          awardsSummaries[yearAndCategoryIndex].performances[eventIndex]
            .timeParsed
        )
    ) {
      if (eventIndex === -1) {
        awardsSummaries[yearAndCategoryIndex].performances.push(performance);
      } else {
        awardsSummaries[yearAndCategoryIndex].performances[eventIndex] =
          performance;
      }
    }

    // Set the certificate award level if at least 3 performances
    if (awardsSummaries[yearAndCategoryIndex].performances.length >= 3) {
      awardsSummaries[yearAndCategoryIndex].award = 1;

      // Sort highest awards first
      awardsSummaries[yearAndCategoryIndex].performances.sort((a, b) => {
        return a.award < b.award ? 0 : -1;
      });

      // Set certificate to level of 3rd highest performance
      const minimumAward =
        awardsSummaries[yearAndCategoryIndex].performances[2].award;

      awardsSummaries[yearAndCategoryIndex].award = minimumAward;

      // Remove any performance under the certificate award level
      awardsSummaries[yearAndCategoryIndex].performances = awardsSummaries[
        yearAndCategoryIndex
      ].performances.filter((_) => _.award >= minimumAward);
    }
  });

  return awardsSummaries;
}

function getYearsWithAgeCategoryChanges(performances: Performance[]): {
  [year: number]: Set<number>;
} {
  const years = {};

  performances.forEach((performance) => {
    const year = new Date(performance.date).getFullYear();
    const category = performance.category;

    if (!years[year]) {
      years[year] = new Set();
    }

    years[year].add(category);
  });

  console.log(years);

  return years;
}
