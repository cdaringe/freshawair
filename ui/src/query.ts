export const getQuery: () => Record<string, string> = () => {
  const toParse = window.location.search.match(/\?(.*)/);
  if (!toParse) return {};
  const asObj = (kv: string) => {
    const [k, v] = kv.split("=");
    return { [k]: v };
  };
  const parts = toParse[1]!.split("&");
  return parts.reduce(
    (acc, kv) => ({ ...acc, ...asObj(kv) }),
    {} as Record<string, string>,
  );
};
