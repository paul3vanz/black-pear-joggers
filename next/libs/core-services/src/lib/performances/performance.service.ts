export function getPersonalBests(): Promise<Response> {
    return fetch('https://bpj.org.uk/api/public/index.php/performancesindividual?isPersonalBest=1');
}