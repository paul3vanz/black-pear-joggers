import type {
    SanityReference,
    SanityKeyedReference,
    SanityAsset,
    SanityImage,
    SanityFile,
    SanityGeoPoint,
    SanityBlock,
    SanityDocument,
    SanityImageCrop,
    SanityImageHotspot,
    SanityKeyed,
    SanityImageAsset,
    SanityImageMetadata,
    SanityImageDimensions,
    SanityImagePalette,
    SanityImagePaletteSwatch,
} from "sanity-codegen";

export type {
    SanityReference,
    SanityKeyedReference,
    SanityAsset,
    SanityImage,
    SanityFile,
    SanityGeoPoint,
    SanityBlock,
    SanityDocument,
    SanityImageCrop,
    SanityImageHotspot,
    SanityKeyed,
    SanityImageAsset,
    SanityImageMetadata,
    SanityImageDimensions,
    SanityImagePalette,
    SanityImagePaletteSwatch,
};

/**
 * Vendor
 *
 *
 */
export interface Vendor extends SanityDocument {
    _type: "vendor";

    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Slug — `slug`
     *
     *
     */
    slug?: { _type: "slug"; current: string };

    /**
     * logo — `image`
     *
     *
     */
    logo?: {
        _type: "image";
        asset: SanityReference<SanityImageAsset>;
        crop?: SanityImageCrop;
        hotspot?: SanityImageHotspot;
    };

    /**
     * Description — `blockContent`
     *
     *
     */
    description?: BlockContent;
}

/**
 * Category
 *
 *
 */
export interface Category extends SanityDocument {
    _type: "category";

    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Description — `text`
     *
     *
     */
    description?: string;
}

/**
 * Product
 *
 *
 */
export interface Product extends SanityDocument {
    _type: "product";

    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Slug — `slug`
     *
     *
     */
    slug?: { _type: "slug"; current: string };

    /**
     * Order — `number`
     *
     *
     */
    order?: number;

    /**
     * Default variant — `productVariant`
     *
     *
     */
    defaultProductVariant?: ProductVariant;

    /**
     * Variants — `array`
     *
     *
     */
    variants?: Array<SanityKeyed<ProductVariant>>;

    /**
     * Tags — `array`
     *
     *
     */
    tags?: Array<SanityKeyed<string>>;

    /**
     * Include name printing — `boolean`
     *
     *
     */
    namePrinting?: boolean;

    /**
     * Vendor — `reference`
     *
     *
     */
    vendor?: SanityReference<Vendor>;

    /**
     * Blurb — `localeString`
     *
     *
     */
    blurb?: LocaleString;

    /**
     * Categories — `array`
     *
     *
     */
    categories?: Array<SanityKeyedReference<Category>>;

    /**
     * Body — `localeBlockContent`
     *
     *
     */
    body?: LocaleBlockContent;
}

/**
 * Vacancy
 *
 *
 */
export interface Vacancy extends SanityDocument {
    _type: "vacancy";

    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Slug — `slug`
     *
     *
     */
    slug?: { _type: "slug"; current: string };

    /**
     * Image — `image`
     *
     *
     */
    image?: {
        _type: "image";
        asset: SanityReference<SanityImageAsset>;
        crop?: SanityImageCrop;
        hotspot?: SanityImageHotspot;
    };

    /**
     * Summary — `blockContent`
     *
     *
     */
    summary?: BlockContent;

    /**
     * Responsibilities — `blockContent`
     *
     *
     */
    responsibilities?: BlockContent;

    /**
     * How to apply — `blockContent`
     *
     *
     */
    howToApply?: BlockContent;

    /**
     * Status — `string`
     *
     *
     */
    status?: "recruiting" | "filled" | "hidden";

    /**
     * New recruit — `string`
     *
     *
     */
    newRecruit?: string;
}

/**
 * Landing page routes
 *
 *
 */
export interface Route extends SanityDocument {
    _type: "route";

    /**
     * page — `reference`
     *
     * The page you want to appear at this path. Remember it needs to be published.
     */
    page?: SanityReference<Page>;

    /**
     * Path — `slug`
     *
     * This is the website path the page will accessible on
     */
    slug?: { _type: "slug"; current: string };

    /**
     * Use site title? — `boolean`
     *
     * Use the site settings title as page title instead of the title on the referenced page
     */
    useSiteTitle?: boolean;

    /**
     * Open graph — `openGraph`
     *
     * These values populate meta tags
     */
    openGraph?: OpenGraph;

    /**
     * Include in sitemap — `boolean`
     *
     * For search engines. Will be generateed to /sitemap.xml
     */
    includeInSitemap?: boolean;

    /**
     * Disallow in robots.txt — `boolean`
     *
     * Hide this route for search engines like google
     */
    disallowRobots?: boolean;

    /**
     * Campaign — `string`
     *
     * UTM for campaings
     */
    campaign?: string;
}

/**
 * Site Settings
 *
 *
 */
export interface SiteSettings extends SanityDocument {
    _type: "siteSettings";

    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Open graph — `openGraph`
     *
     * These will be the default meta tags on all pages that have not set their own
     */
    openGraph?: OpenGraph;
}

/**
 * Blog Post
 *
 *
 */
export interface Post extends SanityDocument {
    _type: "post";

    /**
     * Title — `string`
     *
     * Titles should be catchy, descriptive, and not too long
     */
    title?: string;

    /**
     * Slug — `slug`
     *
     * Some frontends will require a slug to be set to be able to show the post
     */
    slug?: { _type: "slug"; current: string };

    /**
     * Published at — `datetime`
     *
     * This can be used to schedule post for publishing
     */
    publishedAt?: string;

    /**
     * Main image — `mainImage`
     *
     *
     */
    mainImage?: MainImage;

    /**
     * Excerpt — `excerptPortableText`
     *
     * This ends up on summary pages, on Google, when people share your post in social media.
     */
    excerpt?: ExcerptPortableText;

    /**
     * Authors — `array`
     *
     *
     */
    authors?: Array<SanityKeyed<AuthorReference>>;

    /**
     * Categories — `array`
     *
     *
     */
    categories?: Array<SanityKeyedReference<Category>>;

    /**
     * Body — `bodyPortableText`
     *
     *
     */
    body?: BodyPortableText;
}

/**
 * navigationMenu
 *
 *
 */
export interface NavigationMenu extends SanityDocument {
    _type: "navigationMenu";

    /**
     * title — `string`
     *
     *
     */
    title?: string;

    /**
     * items — `array`
     *
     *
     */
    items?: Array<SanityKeyed<Cta>>;
}

/**
 * Page
 *
 *
 */
export interface Page extends SanityDocument {
    _type: "page";

    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Navigation menu — `reference`
     *
     * Which nav menu should be shown, if any
     */
    navMenu?: SanityReference<NavigationMenu>;

    /**
     * Page sections — `array`
     *
     * Add, edit, and reorder sections
     */
    content?: Array<
        | SanityKeyed<Pricing>
        | SanityKeyed<UiComponentRef>
        | SanityKeyed<Hero>
        | SanityKeyed<InfoRows>
        | SanityKeyed<CtaColumns>
        | SanityKeyed<CtaPlug>
    >;
}

/**
 * Author
 *
 *
 */
export interface Author extends SanityDocument {
    _type: "author";

    /**
     * Name — `string`
     *
     *
     */
    name?: string;

    /**
     * Slug — `slug`
     *
     * Some frontends will require a slug to be set to be able to show the person
     */
    slug?: { _type: "slug"; current: string };

    /**
     * Image — `mainImage`
     *
     *
     */
    image?: MainImage;

    /**
     * Biography — `simpleBlockContent`
     *
     *
     */
    bio?: SimpleBlockContent;
}

export type ProductVariant = {
    _type: "productVariant";
    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Price — `number`
     *
     *
     */
    price?: number;

    /**
     * Stock — `number`
     *
     *
     */
    stock?: number;

    /**
     * Buy URL — `string`
     *
     *
     */
    buyUrl?: string;

    /**
     * Price ID — `string`
     *
     *
     */
    priceId?: string;

    /**
     * Images — `array`
     *
     *
     */
    images?: Array<
        SanityKeyed<{
            _type: "image";
            asset: SanityReference<SanityImageAsset>;
            crop?: SanityImageCrop;
            hotspot?: SanityImageHotspot;
        }>
    >;
};

export type BlockContent = Array<
    | SanityKeyed<SanityBlock>
    | SanityKeyed<{
        _type: "image";
        asset: SanityReference<SanityImageAsset>;
        crop?: SanityImageCrop;
        hotspot?: SanityImageHotspot;
    }>
>;

export type LocaleText = {
    _type: "localeText";
    /**
     * English — `text`
     *
     *
     */
    en?: string;

    /**
     * Spanish — `text`
     *
     *
     */
    es?: string;

    /**
     * Norwegian — `text`
     *
     *
     */
    nb?: string;
};

export type LocaleBlockContent = {
    _type: "localeBlockContent";
    /**
     * English — `blockContent`
     *
     *
     */
    en?: BlockContent;

    /**
     * Spanish — `blockContent`
     *
     *
     */
    es?: BlockContent;

    /**
     * Norwegian — `blockContent`
     *
     *
     */
    nb?: BlockContent;
};

export type LocaleString = {
    _type: "localeString";
    /**
     * English — `string`
     *
     *
     */
    en?: string;

    /**
     * Spanish — `string`
     *
     *
     */
    es?: string;

    /**
     * Norwegian — `string`
     *
     *
     */
    nb?: string;

    /**
     * Swedish — `string`
     *
     *
     */
    sv?: string;
};

export type Variation = {
    _type: "variation";
    /**
     * variationId — `string`
     *
     *
     */
    variationId?: string;

    /**
     * Traffic percentange — `number`
     *
     *
     */
    percentage?: number;

    /**
     * page — `reference`
     *
     *
     */
    page?: SanityReference<Page>;
};

export type OpenGraph = {
    _type: "openGraph";
    /**
     * Title — `string`
     *
     * Heads up! This will override the page title.
     */
    title?: string;

    /**
     * Description — `text`
     *
     *
     */
    description?: string;

    /**
     * Image — `mainImage`
     *
     * Facebook recommends 1200x630 (will be auto resized)
     */
    image?: MainImage;
};

export type Experiment = {
    _type: "experiment";
    /**
     * Experiment — `boolean`
     *
     * (De)activate this as a experiment
     */
    active?: boolean;

    /**
     * Google Experiment ID — `string`
     *
     * You will have to create an experiment with a correct number of variations on Google Optimize first
     */
    id?: string;

    /**
     * variations — `array`
     *
     * These are the different variations (pages) this route will point to in this experiment
     */
    variations?: Array<SanityKeyed<Variation>>;
};

export type Link = {
    _type: "link";
    /**
     * URL — `url`
     *
     *
     */
    href?: string;
};

export type SimpleBlockContent = Array<SanityKeyed<SanityBlock>>;

export type Cta = {
    _type: "cta";
    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Landing page — `reference`
     *
     *
     */
    landingPageRoute?: SanityReference<Route>;

    /**
     * Path — `string`
     *
     * Example: /blog
     */
    route?: string;

    /**
     * External link — `string`
     *
     * Example: https://www.sanity.io
     */
    link?: string;

    /**
     * Kind — `string`
     *
     *
     */
    kind?: "button" | "link";
};

export type MainImage = {
    _type: "mainImage";
    asset: SanityReference<SanityImageAsset>;
    crop?: SanityImageCrop;
    hotspot?: SanityImageHotspot;

    /**
     * Caption — `string`
     *
     *
     */
    caption?: string;

    /**
     * Alternative text — `string`
     *
     * Important for SEO and accessibility.
     */
    alt?: string;
};

export type AuthorReference = {
    _type: "authorReference";
    /**
     * author — `reference`
     *
     *
     */
    author?: SanityReference<Author>;
};

export type VideoEmbed = {
    _type: "videoEmbed";
    /**
     * url — `url`
     *
     *
     */
    url?: string;
};

export type BodyPortableText = Array<
    SanityKeyed<SanityBlock> | SanityKeyed<MainImage> | SanityKeyed<VideoEmbed>
>;

export type ExcerptPortableText = Array<SanityKeyed<SanityBlock>>;

export type CtaColumns = {
    _type: "ctaColumns";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * title — `string`
     *
     *
     */
    title?: string;

    /**
     * columns — `array`
     *
     *
     */
    columns?: Array<SanityKeyed<CtaPlug>>;
};

export type CtaPlug = {
    _type: "ctaPlug";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * label — `string`
     *
     *
     */
    label?: string;

    /**
     * Title — `string`
     *
     *
     */
    title?: string;

    /**
     * Body — `simpleBlockContent`
     *
     *
     */
    body?: SimpleBlockContent;

    /**
     * ctas — `array`
     *
     *
     */
    ctas?: Array<SanityKeyed<Cta>>;
};

export type Hero = {
    _type: "hero";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * label — `string`
     *
     *
     */
    label?: string;

    /**
     * Heading — `string`
     *
     *
     */
    heading?: string;

    /**
     * tagline — `simpleBlockContent`
     *
     *
     */
    tagline?: SimpleBlockContent;

    /**
     * illustration — `illustration`
     *
     *
     */
    illustration?: Illustration;

    /**
     * cta — `cta`
     *
     *
     */
    cta?: Cta;
};

export type Illustration = {
    _type: "illustration";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * Image — `mainImage`
     *
     *
     */
    image?: MainImage;
};

export type InfoRows = {
    _type: "infoRows";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * title — `string`
     *
     *
     */
    title?: string;

    /**
     * rows — `array`
     *
     *
     */
    rows?: Array<SanityKeyed<TextWithIllustration>>;
};

export type Pricing = {
    _type: "pricing";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * title — `string`
     *
     *
     */
    title?: string;

    /**
     * Enable gradient background — `boolean`
     *
     *
     */
    transparentCTAs?: boolean;
};

export type TextWithIllustration = {
    _type: "textWithIllustration";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * title — `string`
     *
     *
     */
    title?: string;

    /**
     * text — `simpleBlockContent`
     *
     *
     */
    text?: SimpleBlockContent;

    /**
     * illustration — `illustration`
     *
     *
     */
    illustration?: Illustration;
};

export type UiComponentRef = {
    _type: "uiComponentRef";
    /**
     * disabled — `boolean`
     *
     *
     */
    disabled?: boolean;

    /**
     * name — `string`
     *
     *
     */
    name?: string;
};

export type Documents =
    | Vendor
    | Category
    | Product
    | Vacancy
    | Route
    | SiteSettings
    | Post
    | NavigationMenu
    | Page
    | Author;
