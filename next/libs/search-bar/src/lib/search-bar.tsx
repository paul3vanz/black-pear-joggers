/* eslint-disable-next-line */
export interface SearchBarProps {
  search: string;
  setSearch: (search: string) => void;
  dark?: boolean;
}

export function SearchBar(props: SearchBarProps) {
  return (
    <div>
      <label htmlFor="search" className="sr-only">
        Search
      </label>
      <input
        type="text"
        id="search"
        className={
          'border rounded p-2 mb-4 text-lg w-full' +
          (props.dark ? ' text-black' : '')
        }
        placeholder="Search"
        onChange={(e) => props.setSearch(e.target.value)}
        value={props.search}
      />
    </div>
  );
}

export default SearchBar;
