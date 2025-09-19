import { Button } from '@black-pear-joggers/button';
import { config } from '@black-pear-joggers/core-services';
import { Container } from '@black-pear-joggers/container';
import { Stack } from '@black-pear-joggers/stack';
import { useState } from 'react';

interface ApiResult {
  success: boolean;
  data?: any;
  error?: string;
  timestamp: Date;
}

interface LoadingState {
  [key: string]: boolean;
}

export default function Tools() {
  const [loading, setLoading] = useState<LoadingState>({});
  const [results, setResults] = useState<{ [key: string]: ApiResult }>({});

  const isAnyLoading = Object.values(loading).some(Boolean);

  const handleApiCall = async (endpoint: string, buttonKey: string) => {
    setLoading((prev) => ({ ...prev, [buttonKey]: true }));

    try {
      const response = await fetch(endpoint);
      const data = await response.text();

      let parsedData: any;
      try {
        parsedData = JSON.parse(data);
      } catch {
        parsedData = data;
      }

      setResults((prev) => ({
        ...prev,
        [buttonKey]: {
          success: response.ok,
          data: parsedData,
          error: response.ok
            ? undefined
            : `HTTP ${response.status}: ${response.statusText}`,
          timestamp: new Date(),
        },
      }));
    } catch (error) {
      setResults((prev) => ({
        ...prev,
        [buttonKey]: {
          success: false,
          error:
            error instanceof Error ? error.message : 'Unknown error occurred',
          timestamp: new Date(),
        },
      }));
    } finally {
      setLoading((prev) => ({ ...prev, [buttonKey]: false }));
    }
  };
  return (
    <Stack>
      <Container>
        <h1>Tools</h1>

        <h2>Fetch</h2>

        <p>
          <Button
            text={
              loading.fetchPerformances
                ? 'Fetching...'
                : 'Fetch all performances'
            }
            onClick={() =>
              handleApiCall(
                `${config.baseApiUrl}/fetch/performances`,
                'fetchPerformances'
              )
            }
          />
        </p>

        <p>
          <Button
            text={loading.fetchRankings ? 'Fetching...' : 'Fetch all rankings'}
            onClick={() =>
              handleApiCall(
                `${config.baseApiUrl}/fetch/rankings`,
                'fetchRankings'
              )
            }
          />
        </p>

        <p>
          <Button
            text={loading.syncMagicMile ? 'Syncing...' : 'Sync magic mile'}
            onClick={() =>
              handleApiCall(
                `${config.baseApiUrl}/magicmile/syncmagicmile`,
                'syncMagicMile'
              )
            }
          />
        </p>

        <p>
          <Button
            text={
              loading.updatePersonalBests
                ? 'Updating...'
                : 'Update personal bests'
            }
            onClick={() =>
              handleApiCall(
                `${config.baseApiUrl}/fetch/updatepersonalbests`,
                'updatePersonalBests'
              )
            }
          />
        </p>

        {Object.keys(results).length > 0 && (
          <>
            <div className="flex justify-between items-center">
              <h2>Results</h2>
              <Button
                text="Clear Results"
                onClick={() => setResults({})}
                size="sm"
              />
            </div>
            {Object.entries(results).map(([key, result]) => (
              <div key={key} className="mb-6 p-4 border rounded-lg">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="text-lg font-semibold capitalize">
                    {key.replace(/([A-Z])/g, ' $1').trim()}
                  </h3>
                  <span className="text-sm text-gray-500">
                    {result.timestamp.toLocaleString()}
                  </span>
                </div>

                <div
                  className={`p-3 rounded ${
                    result.success
                      ? 'bg-green-50 border-green-200'
                      : 'bg-red-50 border-red-200'
                  } border`}
                >
                  <div className="flex items-center mb-2">
                    <span
                      className={`inline-block w-3 h-3 rounded-full mr-2 ${
                        result.success ? 'bg-green-500' : 'bg-red-500'
                      }`}
                    ></span>
                    <span className="font-medium">
                      {result.success ? 'Success' : 'Error'}
                    </span>
                  </div>

                  {result.error && (
                    <div className="text-red-700 font-medium mb-2">
                      {result.error}
                    </div>
                  )}

                  {result.data && (
                    <div className="bg-gray-100 p-3 rounded border">
                      <pre className="text-sm whitespace-pre-wrap break-words max-h-96 overflow-auto">
                        {typeof result.data === 'string'
                          ? result.data
                          : JSON.stringify(result.data, null, 2)}
                      </pre>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </>
        )}
      </Container>
    </Stack>
  );
}
