    export interface Athlete {
        CompetitiveRegStatus: string;
        Dob: string;
        FirstClaimClubId: string;
        FirstClaimClubName: string;
        FirstClaimOtherId: string;
        FirstClaimOtherName?: any;
        Firstname: string;
        ForeignFlag: string;
        Gender: string;
        HigherClaimClubId: string;
        HigherClaimClubName?: any;
        Lastname: string;
        SecondClaimClubId: string;
        SecondClaimClubName: string;
        Urn: string;
    }

    export interface MembersResponse {
        Athletes: Athlete[];
        ResponseReference: string;
        ResponseStatus: string;
    }

    export interface MemberResponse extends Athlete {
        ResponseReference: string;
        ResponseStatus: string;
    }
