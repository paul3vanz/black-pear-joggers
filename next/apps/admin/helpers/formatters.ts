import { differenceInYears, parse } from 'date-fns';

export function toTitleCase(input: string): string {
    return input.replace(
        /\w\S*/g,
        function (txt) {
            return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
        }
    );
}

export function booleanLabels(input: string, labels?: ['Yes', 'No']): string {
    return input ? "Yes" : "No";
}

export function toAgeCategory(dateOfBirth: string): string {
    const age = differenceInYears(new Date(), parse(dateOfBirth, 'dd/MM/yyyy', new Date()));

    if (age < 20) {
        return 'U20';
    } else if (age < 23) {
        return 'U23';
    } else if (age < 35) {
        return 'SEN';
    } else {
        return 'V' + (Math.floor(age / 5) * 5);
    }
}