import { Illustration as IllustrationType } from '../types/content.types';
import { LazyLoadImage } from '@black-pear-joggers/lazy-load-image';
import { urlFor } from '@black-pear-joggers/sanity';

export interface IllustrationProps {
  illustration: IllustrationType;
}

export function Illustration(props: IllustrationProps) {
  const illustrations = props.illustration.image
    ? [props.illustration.image]
    : props.illustration.images;

  return (
    <div className="flex">
      {illustrations.map((illustration) => (
        <LazyLoadImage
          key={illustration.externalUrl || illustration.asset._id}
          className={
            illustrations.length > 1 ? `w-1/${illustrations.length}` : 'w-full'
          }
        >
          <img
            className="w-full object-cover sm:h-auto"
            src={illustration.externalUrl || urlFor(illustration).url()}
            alt={illustration.alt}
          />
        </LazyLoadImage>
      ))}
    </div>
  );
}
