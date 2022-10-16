import { Container } from '@black-pear-joggers/container';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { Stack } from '@black-pear-joggers/stack';
import {
  formatRelative,
  friendlyDate,
  longDate,
  shortDate,
  timestamp,
} from '@black-pear-joggers/helpers';

interface FrontmatterProps {
  title: string;
  publishDate: string;
  imageUrl: string;

  author: {
    name: string;
    avatarUrl: string;
  };
}

export function Frontmatter(props: FrontmatterProps) {
  return (
    <>
      <div className="text-center">
        <Stack>
          <Container>
            <h1 className="text-3xl">{props.title}</h1>

            {props.author && (
              <div className="flex flex-wrap flex-col sm:flex-row items-center justify-center">
                {props.author.avatarUrl && (
                  <div className="w-12 h-12 mr-2 mb-2 sm:mb-0 overflow-hidden rounded-full bg-gray-200 flex-shrink-0">
                    <img
                      src={props.author.avatarUrl}
                      alt={props.author.name}
                      width="30"
                      height="30"
                      className="object-cover w-full h-full"
                    />
                  </div>
                )}
                <div className="mr-2">
                  Posted by&nbsp;
                  <strong>{props.author.name}</strong>
                </div>
                <div
                  className="text-gray-500"
                  title={timestamp(props.publishDate)}
                >
                  {longDate(props.publishDate)}
                </div>
              </div>
            )}
          </Container>
        </Stack>

        {props.imageUrl ? (
          <LazyLoadImage className="h-36 lg:h-52 xl:h-72">
            <img
              className="w-full h-36 lg:h-52 xl:h-72 object-cover"
              src={props.imageUrl}
              alt=""
            />
          </LazyLoadImage>
        ) : null}
      </div>
    </>
  );
}
