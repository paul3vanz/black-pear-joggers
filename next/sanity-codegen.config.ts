import { SanityCodegenConfig } from 'sanity-codegen';

const config: SanityCodegenConfig = {
    schemaPath: './apps/sanity-studio/schemas/schema',
    outputPath: './libs/sanity/src/lib/schema.ts',
};

export default config;