sed -i '' '/const \[trips, setTrips\] = useState<Trip\[\]>(\[\]);/a\
  const [page, setPage] = useState(1);\
  const [hasMore, setHasMore] = useState(true);\
  const [loadingMore, setLoadingMore] = useState(false);
' src/pages/Home.tsx

sed -i '' '/const fetchTrips = async () => {/,/};/c\
  const fetchTrips = async () => {\
    try {\
      setLoading(true);\
      setPage(1);\
      const response = await tripsAPI.getAll({ page: 1, limit: 20 });\
      setTrips(response.trips || []);\
      setHasMore(response.pagination?.page < response.pagination?.totalPages);\
      setError("");\
    } catch (err: any) {\
      console.error("Failed to fetch trips:", err);\
      setError("ไม่สามารถโหลดข้อมูลกิจกรรมได้");\
      setTrips([]);\
    } finally {\
      setLoading(false);\
    }\
  };\
\
  const loadMoreTrips = async () => {\
    if (loadingMore || !hasMore) return;\
    try {\
      setLoadingMore(true);\
      const nextPage = page + 1;\
      const response = await tripsAPI.getAll({ page: nextPage, limit: 20 });\
      setTrips(prev => {\
        const existingIds = new Set(prev.map(t => t.id));\
        const newTrips = (response.trips || []).filter((t: Trip) => !existingIds.has(t.id));\
        return [...prev, ...newTrips];\
      });\
      setPage(nextPage);\
      setHasMore(response.pagination?.page < response.pagination?.totalPages);\
    } catch (err: any) {\
      console.error("Failed to load more trips:", err);\
    } finally {\
      setLoadingMore(false);\
    }\
  };' src/pages/Home.tsx
