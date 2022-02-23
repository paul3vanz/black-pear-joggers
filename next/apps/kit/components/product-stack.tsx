import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { PortableText } from '@portabletext/react';
import { Product, Variant } from '../core/queries/getProduct';
import { Select } from '@black-pear-joggers/form-controls';
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

  return (
    <Stack backgroundColour={backgroundColour}>
      <Container>
        <div className="md:grid grid-cols-2 gap-16">
          <div className="flex-1">
            <img
              src={urlFor(product.defaultProductVariant.images[0]).url()}
              alt={product.title}
              className="mb-6"
            />
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
              <>
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
              </>
            )}

            {selectedVariant.buyUrl ? (
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
};

function isOutOfStock(variant: Variant) {
  return variant.stock === -1;
}
