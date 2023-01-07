import { Performance } from '@black-pear-joggers/core-services';

type ResultsTableProps = {
  results: Performance[];
};

export const ResultsTable = ({ results }: ResultsTableProps) => {
  if (!results || !results.length) return null;

  return (
    <table className="w-full">
      <thead>
        <tr>
          <th>Date</th>
          <th>Athlete</th>
          <th>Distance</th>
          <th>Event name</th>
          <th>Gender</th>
          <th>Category</th>
          <th>Time</th>
        </tr>
      </thead>
      <tbody>
        {results.map((result) => (
          <tr key={result.id}>
            <td>{result.date}</td>
            <td>
              {result.firstName} {result.lastName}
            </td>
            <td>{result.event}</td>
            <td>{result.meetingName}</td>
            <td>{result.gender === 'M' ? 'Male' : 'Female'}</td>
            <td>{result.category}</td>
            <td>
              {result.time} {result.isPersonalBest ? ' (PB)' : ''}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};
