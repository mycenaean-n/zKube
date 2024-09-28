'use client';
import { ApolloProvider } from '@apollo/client';
import { client } from '../clients/apollo';

export const ApolloClientProvider = ({
  children,
}: {
  children: React.ReactNode;
}) => {
  return <ApolloProvider client={client}>{children}</ApolloProvider>;
};
