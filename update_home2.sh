sed -i '' '/<\/div>$/,/<\/main>$/c\
          </div>\
          {hasMore \&\& filteredTrips.length > 0 \&\& (\
            <div className="mt-12 text-center">\
              <button\
                onClick={loadMoreTrips}\
                disabled={loadingMore}\
                className="px-8 py-3 bg-gray-100 text-black font-bold rounded-full text-sm hover:bg-gray-200 transition-colors disabled:opacity-50"\
              >\
                {loadingMore ? "กำลังโหลด..." : "โหลดเพิ่มเติม"}\
              </button>\
            </div>\
          )}\
        </main>\
' src/pages/Home.tsx
