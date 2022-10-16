import React, { useState, useEffect, MouseEvent } from 'react'
import { always, assoc, compose, flip, map, objOf, identity, prop, propEq, propOr, tap, invoker, ifElse, isNil, reject } from 'ramda';
import { fetchEntries, destroyEntry, } from './service';
import Modal from './Modal';
import styled from 'styled-components';
import './style.css';
import { promptConfirmation, composeWithPromise } from './utils';

export interface Statement {
  active: boolean;
  hint: string;
  class: string;
  method: string;
  code: string;
}

export interface Entry {
  id: string | number;
  name: string;
  statements: Statement[];
}

const Container = styled.div`
  margin: 15px;
`;

const ActionsContainer = styled.div`
  margin-bottom: 10px;
`;

const ListEntry = styled.div`
  display: flex;
  flex-direction: row;
`

const Label = styled.div`
  flex: 1;
`

const Actions = styled.div`
  width: 150px;
`

const Action = styled.a`
  font-size: 14px;
  margin-right: 5px;
  text-decoration: none;
`
const toListEntry = (entry: Entry, actions: { [key: string]: (entry: Entry) => void}) =>
  <ListEntry className='list-group-item' key={entry.id}>
    <Label>
      {entry.name}
    </Label>
    <Actions>
      <Action onClick={() => actions['edit'](entry)}>
        编辑
      </Action>
      <Action onClick={() => actions['delete'](entry.id)}>
        删除
      </Action>
    </Actions>
  </ListEntry>

export default () => {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [selected, setSelected] = useState<Entry | undefined>(undefined);
  const [page, setPage] = useState<number>(1);
  
  useEffect(() => {
    fetchEntries().then((resp) => compose(setEntries, tap(console.log), propOr([], 'entries'))(resp));
  }, []);

  const nextTimestamp = (): number => new Date().getTime();

  const addEntry = compose(
    setSelected,
    assoc('name', ''),
    objOf('id'),
    nextTimestamp,
    tap(invoker(0, 'preventDefault'))
  );

  const close = (e: MouseEvent<HTMLElement>) => {
    e.preventDefault();
    setSelected(undefined);
  }

  const deleteEntry = (payloads: Entry[], id: string) =>
    compose(
      setEntries,
      reject(propEq('id', id))
    )(payloads)

  const actions = {
    edit: setSelected,
    delete: (id: string) => {
      const destroy: Promise<any> = () =>
        composeWithPromise(
          prop('error'),
          destroyEntry
        )(id)
      promptConfirmation(
        {
          icon: 'question',
          title: '确认',
          text: '是否确定删除该项目?',
        },
        destroy,
        () => deleteEntry(entries, id)
      )
    },
  };

  const clearSelected = () => setSelected(undefined);

  const updateEntry = (entry: Entry) =>
    compose(
      tap(clearSelected),
      setEntries,
      map(
        ifElse(
          propEq('id', entry.id),
          always(entry),
          identity
        )
      ),
    )(entries)
  
  return (
    <Container>
      <ActionsContainer>
        <button className="btn btn-primary" onClick={addEntry}>
          添加
        </button>
      </ActionsContainer>
      <ul className="list-group">
        {map(flip(toListEntry)(actions), entries)}
      </ul>
      {isNil(selected) || <Modal entry={selected} update={updateEntry} close={close} />}
    </Container>
  );
}
