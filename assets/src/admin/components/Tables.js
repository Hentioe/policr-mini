import tw, { styled } from "twin.macro";

const Table = styled.table`
  ${tw`table-fixed border-collapse w-full shadow rounded`}
`;
const Thead = styled.thead`
  ${tw``}
`;
const Tr = styled.tr``;
const Th = styled.th`
  ${tw`text-gray-600 bg-gray-100 font-bold tracking-wider uppercase text-left py-3 px-2 border-b border-gray-200`}
`;
const Tbody = styled.tbody`
  ${tw``}
`;
const Td = styled.td`
  ${tw`py-3 px-2 text-gray-700 bg-white border-solid border-0 border-t border-gray-200`}
`;

export { Table, Thead, Tr, Th, Tbody, Td };
