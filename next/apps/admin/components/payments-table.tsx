import Link from 'next/link';
import { Payment } from '@black-pear-joggers/core-services';
import { friendlyDate } from '@black-pear-joggers/helpers';
import { formatGender } from '../helpers/formatters';
import { Pill } from '@black-pear-joggers/ui/atoms/pill';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  faCheckCircle,
  faExclamationCircle,
  faPersonRunning,
  faTimesCircle,
  faTrophy,
} from '@fortawesome/free-solid-svg-icons';
import { useState } from 'react';

interface PaymentsTableProps {
  search: string;
  payments: Payment[];
}

function PaymentsTable(props: PaymentsTableProps) {
  const [statusFilter, setStatusFilter] = useState<string>(null);

  const filteredPayments = (
    props.search
      ? props.payments.filter((payment) => {
          const search = props.search.toLowerCase();
          const name =
            `${payment.firstname} ${payment.lastname}`.toLowerCase();

          return name.includes(search);
        })
      : props.payments
  )
    .filter((payment) =>
      statusFilter
        ? statusFilter === 'paid'
          ? payment.paymentStatus === 'Paid'
          : statusFilter === 'requested'
          ? payment.paymentStatus === 'Requested'
          : true
        : true
    )
    .sort((a, b) => {
      const result = a.firstname.localeCompare(b.firstname);

      return result !== 0 ? result : a.lastname.localeCompare(b.lastname);
    });

  return (
    <>
      <p>
        <strong>{filteredPayments.length}</strong> payments
      </p>

      <p>
        <strong>Status</strong>
        <Pill
          onClick={() => setStatusFilter(null)}
          active={!statusFilter}
          text="All"
        />

        <Pill
          onClick={() => setStatusFilter('paid')}
          active={statusFilter === 'paid'}
          text="Paid"
        />

        <Pill
          onClick={() => {
            setStatusFilter('requested');
          }}
          active={statusFilter === 'requested'}
          text="Requested"
        />
      </p>

      <table className="w-full">
        <thead className="divide-y divide-gray-200">
          <tr>
            <th className="px-4 py-2">URN</th>
            <th className="px-4 py-2">Name</th>
            <th className="px-4 py-2">Amount</th>
            <th className="px-4 py-2">Status</th>
            <th className="px-4 py-2">Email</th>
            <th className="px-4 py-2">Membership type</th>
            <th className="px-4 py-2">Date paid</th>
            <th className="px-4 py-2 hidden md:table-cell">Created</th>
            <th className="px-4 py-2 hidden md:table-cell">Updated</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {filteredPayments.map((payment, index) => (
            <tr
              key={payment.urn}
              className={index % 2 === 0 ? 'bg-gray-100' : ''}
            >
              <td className="px-4 py-2">{payment.urn}</td>
              <td className="px-4 py-2">
                  {payment.firstname + ' ' + payment.lastname}
              </td>
              <td className="px-4 py-2">{payment.amount}</td>
              <td className="px-4 py-2">{payment.paymentStatus}</td>
              <td className="px-4 py-2">{payment.email}</td>
              <td className="px-4 py-2">{payment.membershipType}</td>
              <td className="px-4 py-2">{friendlyDate(payment.datePaid)}</td>
              <td className="px-4 py-2 hidden md:table-cell">
                {friendlyDate(payment.createdAt)}
              </td>
              <td className="px-4 py-2 hidden md:table-cell">
                {payment.createdAt !== payment.updatedAt
                  ? friendlyDate(payment.updatedAt)
                  : ''}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );
}

export default PaymentsTable;
