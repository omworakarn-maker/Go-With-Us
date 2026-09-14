// Calculate the actual average number of itinerary activities per trip day.
// The stored integer is used directly by ratio-based similarity; no 2/5/8 code is used.
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

    return Math.max(1, Math.round(activityCount / dayCount));
};
