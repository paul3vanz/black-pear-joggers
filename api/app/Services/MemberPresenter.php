<?php

namespace App\Services;

use App\Models\Athlete;
use App\Models\Club;
use App\Models\ClubMember;

/**
 * Builds the camelCase JSON shapes for the /app endpoints, so `me`, `link` and
 * `profile` always agree. Never includes an athlete's urn or dob.
 */
class MemberPresenter
{
    const CLAIM_AWARD_URL = 'https://bpj.org.uk/claim-award';

    public static function club(Club $club): array
    {
        return [
            'id' => $club->id,
            'name' => $club->name,
            'slug' => $club->slug,
            'joinUrl' => $club->join_url,
        ];
    }

    public static function athleteSummary(Athlete $athlete): array
    {
        return [
            'id' => $athlete->id,
            'firstName' => $athlete->first_name,
            'lastName' => $athlete->last_name,
            'gender' => $athlete->gender,
            'category' => $athlete->category,
        ];
    }

    /**
     * One memberships[] item. Expects the club and athlete relations loaded.
     */
    public static function membership(ClubMember $member): array
    {
        return [
            'memberId' => $member->id,
            'club' => self::club($member->club),
            'status' => $member->status,
            'roles' => $member->roles ?? [],
            'athlete' => $member->athlete ? self::athleteSummary($member->athlete) : null,
        ];
    }

    /**
     * The profile body. Expects the athlete loaded with membership and payments.
     */
    public static function profile(ClubMember $member, Athlete $athlete): array
    {
        $registration = $athlete->membership;

        return [
            'memberId' => $member->id,
            'status' => $member->status,
            'roles' => $member->roles ?? [],
            'athlete' => self::athleteSummary($athlete) + [
                'athleteId' => $athlete->athlete_id,
                'po10Guid' => $athlete->po10_guid,
                'active' => $athlete->active,
                'affiliated' => $athlete->affiliated,
            ],
            'membership' => $registration ? [
                'competitiveRegStatus' => $registration->competitiveRegStatus,
                'firstClaimClubName' => $registration->firstClaimClubName,
            ] : null,
            'links' => [
                'results' => $athlete->athlete_id
                    ? 'https://apps.bpj.org.uk/race-results/#/athlete/' . $athlete->athlete_id
                    : null,
                'powerOf10' => $athlete->po10_guid
                    ? 'https://www.powerof10.uk/Home/Athlete/' . $athlete->po10_guid
                    : null,
                'claimAward' => self::CLAIM_AWARD_URL,
            ],
        ];
    }

    public static function statusFor(Athlete $athlete): string
    {
        return $athlete->active ? 'active' : 'lapsed';
    }
}
