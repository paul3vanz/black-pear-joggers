export interface Club {
    ClubId: string;
    ClubName: string;
    HomeCountry: string;
    Locality: string;
    Region: string;
}

export interface ClubsResponse {
    Clubs: Club[];
    ResponseReference: string;
    ResponseStatus: string;
}
