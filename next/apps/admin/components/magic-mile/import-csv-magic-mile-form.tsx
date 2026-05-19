import { ageCategories, magicMileLocations } from '../../helpers/enums';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { createMagicMileResult } from '@black-pear-joggers/core-services';
import { shortDate } from '@black-pear-joggers/helpers';
import { useState } from 'react';

interface ParsedRow {
  id: string;
  firstName: string;
  lastName: string;
  gender: 'M' | 'W';
  age: string;
  category: string;
  predictedTime: string;
  actualTime: string;
}

interface ImportCsvMagicMileFormProps {
  onImportComplete: () => void;
}

function capitaliseName(name: string): string {
  const trimmed = name.trim();
  if (!trimmed) return trimmed;
  return trimmed.charAt(0).toUpperCase() + trimmed.slice(1).toLowerCase();
}

function parseGender(raw: string): 'M' | 'W' {
  return raw.trim().toLowerCase().startsWith('f') ? 'W' : 'M';
}

// Parse Excel-style decimal time: "6.5" → "6:50", "5.55" → "5:55", "9" → "9:00"
// The decimal part represents seconds, single digit is treated as tens (e.g. .5 = :50)
function parseCsvTime(raw: string): string {
  const trimmed = raw.trim();
  if (!trimmed) return '';
  const parts = trimmed.split('.');
  const minutes = parseInt(parts[0], 10);
  if (isNaN(minutes)) return '';
  let seconds = 0;
  if (parts.length > 1) {
    const secStr = parts[1].padEnd(2, '0');
    seconds = parseInt(secStr, 10);
  }
  if (isNaN(seconds) || seconds >= 60) return '';
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

// Convert mm:ss display string to seconds
function timeDisplayToSeconds(display: string): number | null {
  if (!display || !display.trim()) return null;
  const parts = display.trim().split(':');
  if (parts.length !== 2) return null;
  const minutes = parseInt(parts[0], 10);
  const seconds = parseInt(parts[1], 10);
  if (isNaN(minutes) || isNaN(seconds)) return null;
  return minutes * 60 + seconds;
}

function categoryFromAge(age: number): string {
  if (age < 20) return 'U20';
  if (age < 23) return 'U23';
  if (age < 35) return 'SEN';
  if (age < 40) return 'V35';
  if (age < 45) return 'V40';
  if (age < 50) return 'V45';
  if (age < 55) return 'V50';
  if (age < 60) return 'V55';
  if (age < 65) return 'V60';
  if (age < 70) return 'V65';
  if (age < 75) return 'V70';
  if (age < 80) return 'V75';
  return 'V80';
}

function parseCSV(text: string): { rows: ParsedRow[]; errors: string[] } {
  const lines = text.trim().split('\n').filter((l) => l.trim());
  if (!lines.length) return { rows: [], errors: ['No data found'] };

  const errors: string[] = [];
  const rows: ParsedRow[] = [];

  const delimiter = lines[0].includes('\t') ? '\t' : ',';

  // Skip header row if it looks like one (first field is not a number/name)
  const firstField = lines[0].split(delimiter)[0].trim().toLowerCase();
  const startIndex =
    firstField === 'first name' || firstField === 'firstname' ? 1 : 0;

  for (let i = startIndex; i < lines.length; i++) {
    const cols = lines[i].split(delimiter).map((c) => c.trim());
    if (cols.length < 4) {
      errors.push(`Row ${i + 1}: not enough columns, skipping`);
      continue;
    }

    const [rawFirst, rawLast, rawGender, rawAge, rawPredicted = '', rawActual = ''] = cols;

    const firstName = capitaliseName(rawFirst);
    const lastName = capitaliseName(rawLast);

    if (!firstName || !lastName) {
      errors.push(`Row ${i + 1}: missing name, skipping`);
      continue;
    }

    const gender = parseGender(rawGender);
    const age = parseInt(rawAge, 10);
    const category = isNaN(age) ? 'SEN' : categoryFromAge(age);
    const predictedTime = parseCsvTime(rawPredicted);
    const actualTime = parseCsvTime(rawActual);

    rows.push({
      id: `${i}-${firstName}-${lastName}`,
      firstName,
      lastName,
      gender,
      age: isNaN(age) ? '' : age.toString(),
      category,
      predictedTime,
      actualTime,
    });
  }

  return { rows, errors };
}

export function ImportCsvMagicMileForm({ onImportComplete }: ImportCsvMagicMileFormProps) {
  const [step, setStep] = useState<'paste' | 'review'>('paste');
  const [csvText, setCsvText] = useState('');
  const [date, setDate] = useState(shortDate());
  const [location, setLocation] = useState(`Magic Mile (${magicMileLocations[2]})`);
  const [rows, setRows] = useState<ParsedRow[]>([]);
  const [parseErrors, setParseErrors] = useState<string[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitProgress, setSubmitProgress] = useState(0);
  const [submitErrors, setSubmitErrors] = useState<string[]>([]);

  function handleParse() {
    const { rows: parsed, errors } = parseCSV(csvText);
    setRows(parsed);
    setParseErrors(errors);
    if (parsed.length > 0) {
      setStep('review');
    }
  }

  function updateRow(id: string, field: keyof ParsedRow, value: string) {
    setRows((prev) =>
      prev.map((row) => (row.id === id ? { ...row, [field]: value } : row))
    );
  }

  function deleteRow(id: string) {
    setRows((prev) => prev.filter((row) => row.id !== id));
  }

  async function handleSubmit() {
    setIsSubmitting(true);
    setSubmitProgress(0);
    setSubmitErrors([]);

    const errors: string[] = [];

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const predictedTime = timeDisplayToSeconds(row.predictedTime);
      const actualTime = timeDisplayToSeconds(row.actualTime);

      if (actualTime === null) {
        errors.push(`${row.firstName} ${row.lastName}: invalid or missing actual time`);
        setSubmitProgress(i + 1);
        continue;
      }

      try {
        const response = await createMagicMileResult({
          athleteId: 0,
          firstName: row.firstName,
          lastName: row.lastName,
          gender: row.gender,
          category: row.category,
          date,
          location,
          predictedTime: predictedTime ?? actualTime,
          actualTime,
        });

        if (!response.ok) {
          errors.push(`${row.firstName} ${row.lastName}: ${response.statusText || 'failed to save'}`);
        }
      } catch (e) {
        errors.push(`${row.firstName} ${row.lastName}: network error`);
      }

      setSubmitProgress(i + 1);
    }

    setIsSubmitting(false);
    setSubmitErrors(errors);

    if (errors.length === 0) {
      onImportComplete();
    }
  }

  const inputClass = 'border rounded py-1 px-2 text-black w-full text-sm h-8';
  const selectClass = 'border rounded py-1 px-2 text-black w-full text-sm h-8';

  if (step === 'paste') {
    return (
      <div className="w-full max-w-2xl">
        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-3 md:mb-0">
            <label className="block font-bold mb-1" htmlFor="csv-date">Date</label>
            <input
              id="csv-date"
              type="text"
              className="block w-full border rounded py-3 px-4 h-12 text-black"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              placeholder="YYYY-MM-DD"
            />
          </div>
          <div className="w-full md:w-1/2 px-3">
            <label className="block font-bold mb-1" htmlFor="csv-location">Location</label>
            <select
              id="csv-location"
              className="block w-full border rounded py-3 px-4 h-12 text-black"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
            >
              {magicMileLocations.map((loc) => (
                <option key={loc} value={`Magic Mile (${loc})`}>{loc}</option>
              ))}
            </select>
          </div>
        </div>

        <div className="mb-3">
          <label className="block font-bold mb-1" htmlFor="csv-input">
            Paste CSV data
          </label>
          <p className="text-sm text-gray-600 mb-2">
            Expected columns: First name, Last name, Gender, Age, Predicted Time, Actual Time
          </p>
          <textarea
            id="csv-input"
            className="block w-full border rounded py-3 px-4 text-black font-mono text-sm"
            rows={10}
            value={csvText}
            onChange={(e) => setCsvText(e.target.value)}
            placeholder={'First name,Second name,Gender,Age,Predicted Time,Actual Time\nNick,Hitchings,M,57,5.55,5.41'}
          />
        </div>

        {parseErrors.length > 0 && (
          <div className="mb-3 p-3 bg-red-50 border border-red-200 rounded text-sm text-red-700">
            {parseErrors.map((e, i) => <div key={i}>{e}</div>)}
          </div>
        )}

        <div className="mb-6">
          <ButtonLightTextDarkBackground
            text="Parse CSV"
            onClick={handleParse}
          />
        </div>
      </div>
    );
  }

  // Review step
  const successCount = rows.length - submitErrors.length;
  const isDone = !isSubmitting && submitProgress === rows.length && submitProgress > 0;

  return (
    <div className="w-full">
      <div className="flex flex-wrap gap-4 mb-4 items-end">
        <div>
          <label className="block font-bold mb-1 text-sm" htmlFor="review-date">Date</label>
          <input
            id="review-date"
            type="text"
            className="border rounded py-1 px-2 text-black text-sm h-8"
            value={date}
            onChange={(e) => setDate(e.target.value)}
          />
        </div>
        <div>
          <label className="block font-bold mb-1 text-sm" htmlFor="review-location">Location</label>
          <select
            id="review-location"
            className="border rounded py-1 px-2 text-black text-sm h-8"
            value={location}
            onChange={(e) => setLocation(e.target.value)}
          >
            {magicMileLocations.map((loc) => (
              <option key={loc} value={`Magic Mile (${loc})`}>{loc}</option>
            ))}
          </select>
        </div>
      </div>

      {parseErrors.length > 0 && (
        <div className="mb-3 p-3 bg-yellow-50 border border-yellow-200 rounded text-sm text-yellow-800">
          <strong>Parse warnings:</strong>
          {parseErrors.map((e, i) => <div key={i}>{e}</div>)}
        </div>
      )}

      <div className="overflow-x-auto mb-4">
        <table className="w-full text-sm border-collapse min-w-[700px]">
          <thead>
            <tr className="border-b-2 border-gray-300">
              <th className="text-left py-2 px-2 font-bold">First name</th>
              <th className="text-left py-2 px-2 font-bold">Last name</th>
              <th className="text-left py-2 px-2 font-bold">Gender</th>
              <th className="text-left py-2 px-2 font-bold">Age</th>
              <th className="text-left py-2 px-2 font-bold">Category</th>
              <th className="text-left py-2 px-2 font-bold">Predicted (m:ss)</th>
              <th className="text-left py-2 px-2 font-bold">Actual (m:ss)</th>
              <th className="py-2 px-2"></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="py-1 px-2">
                  <input
                    type="text"
                    className={inputClass}
                    value={row.firstName}
                    onChange={(e) => updateRow(row.id, 'firstName', e.target.value)}
                  />
                </td>
                <td className="py-1 px-2">
                  <input
                    type="text"
                    className={inputClass}
                    value={row.lastName}
                    onChange={(e) => updateRow(row.id, 'lastName', e.target.value)}
                  />
                </td>
                <td className="py-1 px-2">
                  <select
                    className={selectClass}
                    value={row.gender}
                    onChange={(e) => updateRow(row.id, 'gender', e.target.value as 'M' | 'W')}
                  >
                    <option value="M">M</option>
                    <option value="W">W</option>
                  </select>
                </td>
                <td className="py-1 px-2 text-gray-500 text-center">{row.age}</td>
                <td className="py-1 px-2">
                  <select
                    className={selectClass}
                    value={row.category}
                    onChange={(e) => updateRow(row.id, 'category', e.target.value)}
                  >
                    {ageCategories.map((cat) => (
                      <option key={cat} value={cat}>{cat}</option>
                    ))}
                  </select>
                </td>
                <td className="py-1 px-2">
                  <input
                    type="text"
                    className={`${inputClass} ${!row.predictedTime ? 'text-gray-400' : ''}`}
                    value={row.predictedTime}
                    placeholder="m:ss"
                    onChange={(e) => updateRow(row.id, 'predictedTime', e.target.value)}
                  />
                </td>
                <td className="py-1 px-2">
                  <input
                    type="text"
                    className={`${inputClass} ${!row.actualTime ? 'bg-red-50 border-red-300' : ''}`}
                    value={row.actualTime}
                    placeholder="m:ss"
                    onChange={(e) => updateRow(row.id, 'actualTime', e.target.value)}
                  />
                </td>
                <td className="py-1 px-2">
                  <button
                    className="text-red-500 hover:text-red-700 font-bold px-1"
                    onClick={() => deleteRow(row.id)}
                    title="Remove row"
                    type="button"
                  >
                    ×
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {rows.length === 0 && (
        <p className="text-gray-500 text-sm mb-4">No rows remaining.</p>
      )}

      {isSubmitting && (
        <div className="mb-3">
          <div className="text-sm text-gray-600 mb-1">
            Importing... {submitProgress} / {rows.length}
          </div>
          <div className="w-full bg-gray-200 rounded h-2">
            <div
              className="bg-green-500 h-2 rounded transition-all"
              style={{ width: `${(submitProgress / rows.length) * 100}%` }}
            />
          </div>
        </div>
      )}

      {isDone && submitErrors.length === 0 && (
        <div className="mb-3 p-3 bg-green-50 border border-green-200 rounded text-sm text-green-800">
          Successfully imported {rows.length} result{rows.length !== 1 ? 's' : ''}.
        </div>
      )}

      {isDone && submitErrors.length > 0 && (
        <div className="mb-3 p-3 bg-red-50 border border-red-200 rounded text-sm text-red-700">
          <strong>
            {successCount} imported, {submitErrors.length} failed:
          </strong>
          {submitErrors.map((e, i) => <div key={i}>{e}</div>)}
        </div>
      )}

      <div className="flex gap-3 mb-6">
        <button
          type="button"
          className="font-bold underline cursor-pointer text-sm"
          onClick={() => {
            setStep('paste');
            setSubmitProgress(0);
            setSubmitErrors([]);
          }}
        >
          ← Back
        </button>
        {!isDone && (
          <ButtonLightTextDarkBackground
            text={isSubmitting ? `Importing ${submitProgress}/${rows.length}...` : `Import ${rows.length} result${rows.length !== 1 ? 's' : ''}`}
            onClick={handleSubmit}
          />
        )}
      </div>
    </div>
  );
}

export default ImportCsvMagicMileForm;
