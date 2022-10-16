import { mergeRight, andThen, invoker } from 'ramda';

interface Response {
  error: boolean | String,
}

const host = 'http://172.21.0.7:4000';

const baseOptions = {
  mode: 'cors',
  cache: 'no-cache',
  credentials: 'same-origin',
  headers: {
    'Content-Type': 'application/json'
  },
}

const fetchContent = (path: string, method: string = 'GET', data: object | undefined = undefined) =>
  fetch(`${host}${path}`, mergeRight(baseOptions, {
    method,
    body: data ? JSON.stringify(data) : undefined
  }))

const withSubmitData = async (p: Promise<Response>, entry: object) => {
  const res: Response = await p;
  return Promise.resolve(Object.assign(res, { entry }))
}

const getJson = andThen(invoker(0, 'json'));

const fetchEntries = () => getJson(fetchContent('/logging/entries'));

const createEntry = (params: object) => withSubmitData(getJson(fetchContent('/logging/entries', 'POST', params)), params)

const updateEntry = (id: string, params: object) => withSubmitData(getJson(fetchContent(`/logging/entries/${id}`, 'PUT', params)), params)

const destroyEntry = (id: string) => getJson(fetchContent(`/logging/entries/${id}`, 'DELETE'))

const fetchTargets = async () => {
  return await fetch(`${host}/logging/targets`);
};

const fetchCandidates = async (target: string) => {
  return await fetch(`${host}/logging/candidates?target=${target}`);
}

export { fetchEntries, createEntry, updateEntry, destroyEntry, fetchTargets, fetchCandidates };
