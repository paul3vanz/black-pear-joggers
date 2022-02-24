import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { PortableText } from '@portabletext/react';
import { Product, Variant } from '../core/queries/getProduct';
import { SanityImageSource } from '@sanity/image-url/lib/types/types';
import { Select, TextInput } from '@black-pear-joggers/form-controls';
import { Stack } from '@black-pear-joggers/stack';
import { urlFor } from '@black-pear-joggers/sanity';
import { useRef, useState } from 'react';

type ProductStackProps = {
  product: Product;
  backgroundColour?: string;
};

export const ProductStack = ({
  product,
  backgroundColour,
}: ProductStackProps) => {
  const formReference = useRef<HTMLFormElement>();
  const [selectedVariant, setSelectedVariant] = useState<Variant>(
    (product.variants && product.variants[0]) ||
      product.defaultProductVariant ||
      null
  );
  const [namePrinting, setNamePrinting] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [selectedImage, setSelectedImage] = useState<SanityImageSource>(
    product.defaultProductVariant.images[0]
  );

  return (
    <Stack backgroundColour={backgroundColour}>
      <Container>
        <div className="md:grid grid-cols-2 gap-16">
          <div className="flex flex-col justify-center">
            <img
              src={urlFor(selectedImage).url()}
              alt={product.title}
              className="mb-6"
            />
            {product.defaultProductVariant.images.length > 1 && (
              <div className="flex justify-center">
                {product.defaultProductVariant.images.map((image, i) => (
                  <button key={i} onClick={() => setSelectedImage(image)}>
                    <img
                      src={urlFor(image).url()}
                      alt={product.title}
                      className="mb-6 h-36"
                    />
                  </button>
                ))}
              </div>
            )}
          </div>
          <div className="flex-1">
            <div className="flex w-full justify-between items-center">
              <h1 className="">{product.title}</h1>

              <p className="text-3xl font-bold">
                £{product.defaultProductVariant.price.toFixed(2)}
              </p>
            </div>

            {product.vendor?.logo && (
              <p>
                <img
                  src={urlFor(product.vendor.logo).url()}
                  alt={product.vendor.title}
                  className="h-10"
                />
              </p>
            )}

            <PortableText value={product.body.en} />

            {product.variants && (
              <div className="mb-4">
                <Select
                  label="Sizes"
                  id="variants"
                  options={product.variants.map((variant) => ({
                    value: variant.title,
                    label: isOutOfStock(variant)
                      ? `${variant.title} (out of stock)`
                      : variant.title,
                    disabled: isOutOfStock(variant) ? true : false,
                  }))}
                  onChange={(i) => {
                    setSelectedVariant(
                      product.variants.find(
                        (variant) => variant.title === i.target.value
                      )
                    );
                  }}
                />
              </div>
            )}

            {product.namePrinting && (
              <>
                <TextInput
                  label="Include name printing (£2 extra)"
                  id="namePrinting"
                  onChange={(e) => setNamePrinting(e.target.value)}
                />
              </>
            )}

            {selectedVariant.priceId ? (
              <div className="mt-6">
                <Button
                  text={isLoading ? 'Loading...' : 'Buy ' + product.title}
                  onClick={() => {
                    setIsLoading(true);
                    createCheckoutSession(selectedVariant, namePrinting);
                  }}
                />
              </div>
            ) : selectedVariant.buyUrl ? (
              <div className="mt-6">
                <Button
                  text={'Buy ' + product.title}
                  onClick={() => {
                    window.location.href = selectedVariant.buyUrl;
                  }}
                />
              </div>
            ) : (
              <form
                action="https://www.paypal.com/cgi-bin/webscr"
                encType="application/x-www-form-urlencoded"
                method="post"
                ref={formReference}
              >
                <input name="cmd" type="hidden" value="_cart" />
                <input name="add" type="hidden" value="1" />
                <input
                  name="business"
                  type="hidden"
                  value="kit@blackpearjoggers.org.uk"
                />
                <input
                  name="item_name"
                  type="hidden"
                  value={selectedVariant.title}
                />
                <input
                  name="amount"
                  type="hidden"
                  value={selectedVariant.price}
                />
                <input name="shipping" type="hidden" value="0" />
                <input name="shipping2" type="hidden" value="0" />
                <input name="currency_code" type="hidden" value="GBP" />
                <input
                  name="return"
                  type="hidden"
                  value="https://bpj.org.uk/kit/order-successful/"
                />
                <input name="undefined_quantity" type="hidden" value="1" />

                <div className="mt-6">
                  <Button
                    text={'Buy ' + product.title}
                    onClick={() => formReference.current.submit()}
                  />
                </div>
              </form>
            )}
          </div>
        </div>
      </Container>
    </Stack>
  );

  async function createCheckoutSession(
    variant: Variant,
    namePrinting?: string
  ) {
    const createCheckout = await fetch(
      'https://bpj.org.uk/api/public/index.php/checkout',
      {
        method: 'POST',
        headers: new Headers({
          Accept: 'application/json',
          'Content-Type': 'application/json',
        }),
        body: JSON.stringify({
          priceId: variant.priceId,
          quantity: 1,
          namePrinting: namePrinting || undefined,
        }),
      }
    );

    const response = await createCheckout.json();

    setIsLoading(false);

    if (response) {
      window.location.href = response.url;
    } else {
      alert('Sorry, there was an error');
    }
  }
};

function isOutOfStock(variant: Variant) {
  return variant.stock === -1;
}
