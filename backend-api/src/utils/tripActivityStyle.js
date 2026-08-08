// Convert itinerary density into the same scale used by onboarding.
// 1-2 activities/day = 2, 3-4 = 5, 5+ = 8. No activities = no score.
export const calculateActivityStyleFromItinerary = (itinerary, startDate, endDate) => {
    if (!Array.isArray(itinerary)) return null;

    const activityCount = itinerary.reduce((total, day) => (
        total + (Array.isArray(day?.activities) ? day.activities.length : 0)
    ), 0);
    if (activityCount === 0) return null;

    let dayCount = 0;
    const start = startDate ? new Date(startDate) : null;
    const end = endDate ? new Date(endDate) : start;
    if (start && end && !Number.isNaN(start.getTime()) && !Number.isNaN(end.getTime()) && end >= start) {
        dayCount = Math.floor((Date.UTC(end.getUTCFullYear(), end.getUTCMonth(), end.getUTCDate()) - Date.UTC(start.getUTCFullYear(), start.getUTCMonth(), start.getUTCDate())) / 86400000) + 1;
    }
    if (dayCount < 1) dayCount = Math.max(itinerary.length, 1);

    const activitiesPerDay = activityCount / dayCount;
    if (activitiesPerDay <= 2) return 2;
    if (activitiesPerDay <= 4) return 5;
    return 8;
};
