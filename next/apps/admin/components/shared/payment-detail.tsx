import { Payment } from '@black-pear-joggers/core-services';
import { currency } from '../../helpers/formatters';
import { timestamp } from '@black-pear-joggers/helpers';

interface PaymentDetailProps {
  payment: Payment;
}

export function PaymentDetail(props: PaymentDetailProps) {
  return (
    <ul className="list-disc list-inside mb-4">
      <li>
        <strong>Amount:</strong> {currency(props.payment.amount)}
      </li>

      <li>
        <strong>Status:</strong> {props.payment.paymentStatus}
      </li>

      <li>
        <strong>Date paid:</strong> {props.payment.datePaid}
      </li>

      <li>
        <strong>URN:</strong> {props.payment.urn}
      </li>

      <li>
        <strong>Payment type:</strong> {props.payment.paymentType}
      </li>

      <li>
        <strong>First name:</strong> {props.payment.firstname}
      </li>

      <li>
        <strong>Last name:</strong> {props.payment.lastname}
      </li>

      <li>
        <strong>Date of birth:</strong> {props.payment.dob}
      </li>

      <li>
        <strong>Email address:</strong> {props.payment.email}
      </li>

      <li>
        <strong>Reference:</strong> {props.payment.reference}
      </li>

      <li>
        <strong>Payment method:</strong> {props.payment.paymentMethod}
      </li>

      <li>
        <strong>Membership type:</strong> {props.payment.membershipType}
      </li>

      <li>
        <strong>Created date:</strong> {timestamp(props.payment.createdAt)}
      </li>

      <li>
        <strong>Updated date:</strong> {timestamp(props.payment.updatedAt)}
      </li>
    </ul>
  );
}
