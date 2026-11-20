import type { FC } from 'react';

interface FilterBarProps {
  provinces: string[];
  categories: string[];
  selectedProvince: string;
  setSelectedProvince: (province: string) => void;
  selectedCategory: string;
  setSelectedCategory: (category: string) => void;
  startDate: string;
  setStartDate: (date: string) => void;
  endDate: string;
  setEndDate: (date: string) => void;
}

const fieldClass = 'block h-10 w-full min-w-0 rounded-xl border border-slate-200 bg-white px-2 text-sm text-slate-800';

const FilterBar: FC<FilterBarProps> = ({
  provinces,
  categories,
  selectedProvince,
  setSelectedProvince,
  selectedCategory,
  setSelectedCategory,
  startDate,
  setStartDate,
  endDate,
  setEndDate,
}) => (
  <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
    <label className="min-w-0 space-y-1 text-xs font-medium text-slate-600">
      <span>จังหวัด</span>
      <select className={fieldClass} value={selectedProvince} onChange={(event) => setSelectedProvince(event.target.value)}>
        {provinces.map((province) => <option key={province}>{province}</option>)}
      </select>
    </label>
    <label className="min-w-0 space-y-1 text-xs font-medium text-slate-600">
      <span>หมวดหมู่</span>
      <select className={fieldClass} value={selectedCategory} onChange={(event) => setSelectedCategory(event.target.value)}>
        {categories.map((category) => <option key={category}>{category}</option>)}
      </select>
    </label>
    <label className="min-w-0 space-y-1 text-xs font-medium text-slate-600">
      <span>ตั้งแต่วันที่</span>
      <input className={fieldClass} type="date" value={startDate} max={endDate || undefined} onChange={(event) => setStartDate(event.target.value)} />
    </label>
    <label className="min-w-0 space-y-1 text-xs font-medium text-slate-600">
      <span>ถึงวันที่</span>
      <input className={fieldClass} type="date" value={endDate} min={startDate || undefined} onChange={(event) => setEndDate(event.target.value)} />
    </label>
  </div>
);

export default FilterBar;
