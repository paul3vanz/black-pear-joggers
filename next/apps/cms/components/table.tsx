import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { Table as TableType } from '../types/content.types';

interface TableProps {
  table: TableType;
}

export function Table({ table }: TableProps) {
  return (
    <Stack backgroundColour={table.backgroundColour || BackgroundColour.White}>
      <Container wide={true}>
        {table.caption ? <h3 className="mb-4">{table.caption}</h3> : null}

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-sm">
            {table.columns?.length ? (
              <thead>
                <tr>
                  {table.columns.map((column, index) => (
                    <th
                      key={index}
                      className="border-b-2 border-gray-300 p-2 font-bold"
                    >
                      {column}
                    </th>
                  ))}
                </tr>
              </thead>
            ) : null}

            <tbody>
              {table.rows?.map((row) => (
                <tr key={row._key}>
                  {row.cells?.map((cell, index) => (
                    <td key={index} className="border-b border-gray-200 p-2">
                      {cell}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Container>
    </Stack>
  );
}
