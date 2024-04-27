export interface Athlete {
    id: number;
    urn?: number;
    athlete_id: number;
    first_name: string;
    last_name: string;
    gender: string;
    dob?: string;
    created_at: string;
    updated_at: string;
    category: string;
    age?: number;
    affiliated: boolean;
    active: boolean;
    membership?: Membership;
    payments?: Payment[];
}

export interface Membership {
    firstName: string;
    lastName: string;
    gender: string;
    foreignFlag: string;
    competitiveRegStatus: string;
    firstClaimClubId: number;
    firstClaimClubName: string;
    firstClaimOtherId: number;
    firstClaimOtherName: string | null;
    higherClaimClubId: number;
    higherClaimClubName: string | null;
    secondClaimClubId: number;
    secondClaimClubName: string | null;
    created_at: string;
    updated_at: string;
    isActive: boolean;
}

export interface Payment {
    urn: number;
    firstname: string;
    lastname: string;
    dob: string;
    amount: number;
    paymentStatus: string;
    email: string;
    paymentType: string;
    reference: string;
    paymentMethod: string;
    datePaid: string;
    membershipType: string;
    createdAt: string;
    updatedAt: string | null;
}