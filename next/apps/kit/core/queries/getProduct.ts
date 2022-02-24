import { getClient } from '@black-pear-joggers/sanity';
import { groq } from 'next-sanity';
import { PortableText } from '@portabletext/react';
import { SanityImageSource } from '@sanity/image-url/lib/types/types';

export type GetProducts = {
  _id: string,
  title: string,
  defaultProductVariant: any,
  description: string,
  price: number,
  slug: string,
  vendor: any,
  body: any,
}

export function getProduct(slug: string) {
    return getClient(false).fetch<GetProducts[]>(groq`
      *[
        _type == "product" &&
        slug.current == "${slug}"
      ] |
      order(title) {
        _id,
        title,
        body,
        defaultProductVariant,
        variants,
        description,
        slug,
        vendor
      }
    `);
  }

export type Vendor = {
    title: string;
    slug: {
        current: string;
    };
    logo: SanityImageSource;
}

export type Variant = {
    title: string;
    price: number;
    stock: number;
    priceId: string;
    buyUrl: string;
    images: SanityImageSource[];
}

export type Product = {
    _id: string,
    title: string,
    defaultProductVariant: Variant,
    variants: Variant[],
    description: string,
    price: number,
    slug: string,
    vendor: Vendor,
    body: any,
    namePrinting: boolean;
}

export type GetProductsByCategory = {
    name: string,
    slug: string,
    products: Product[],
}

export function getProductsByCategory(categorySlug: string) {
    return getClient(false).fetch<GetProductsByCategory>(groq`
        *[
          _type=="category" &&
          slug.current == "${categorySlug}"
        ][0] {
        title,
        "slug": slug.current,
        "products": *[
            _type=='product' &&
            references(^._id)
        ] | order(order asc) {
            _id,
            title,
            body,
            defaultProductVariant,
            namePrinting,
            variants,
            description,
            slug,
            vendor->
            }
        }
    `)
}