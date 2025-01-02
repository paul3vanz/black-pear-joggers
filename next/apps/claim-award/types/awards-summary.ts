import { Performance } from "@black-pear-joggers/core-services";
import { Award } from "./award";

export type AwardsSummary = {
    year: number;
    category: string;
    award: Award;
    categoryChangedInYear: boolean;
    performances: Performance[];
};