import Link from 'next/link';
import { Container } from '@black-pear-joggers/container';
import { GetCategories, getCategories } from '../../core/queries/getCategories';
import { GetStaticPaths, GetStaticProps } from 'next';
import { ProductStack } from '../../components/product-stack';
import { Stack } from '@black-pear-joggers/stack';
import {
  GetProductsByCategory,
  getProductsByCategory,
} from '../../core/queries/getProduct';

type KitCategoryProps = {
  categories: GetCategories[];
  categoryWithProducts: GetProductsByCategory;
};

const BackToKitPage = () => (
  <Stack padding="noBottom">
    <Container>
      <Link href="/">
        <a>&laquo; Back to kit</a>
      </Link>
    </Container>
  </Stack>
);

export const KitCategory = (props: KitCategoryProps) => {
  if (!props.categoryWithProducts.products)
    return (
      <div className="text-center mt-8 font-bold text-2xl">
        No products found
      </div>
    );

  return (
    <>
      <BackToKitPage />

      {props.categoryWithProducts.products.map((product, index) => (
        <ProductStack
          key={product._id}
          product={product}
          backgroundColour={index % 2 === 0 ? '' : 'light'}
        />
      ))}
    </>
  );
};

export const getStaticPaths: GetStaticPaths = async () => {
  const categories = await getCategories();

  return {
    paths: categories.map((category) => {
      return {
        params: { category: category.slug.current },
      };
    }),
    fallback: false,
  };
};

export const getStaticProps: GetStaticProps = async (context) => {
  const categories = await getCategories();
  const categoryWithProducts = await getProductsByCategory(
    context.params.category.toString()
  );

  console.log(categoryWithProducts);

  return {
    props: {
      categories,
      categoryWithProducts,
    },
  };
};

export default KitCategory;
