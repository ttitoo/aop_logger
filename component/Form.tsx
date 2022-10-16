import React, { FC, useState, useEffect, MouseEvent } from 'react'
import { fetchTargets, fetchCandidates } from './service';
import { apply, assoc, compose, curry, curryN, flip, map, nthArg, isNil, isEmpty, juxt, path, prop, propOr, anyPass, unless, __ } from 'ramda';
import Select from 'react-select';
import { Statement } from './List';
import styled from 'styled-components';

interface FormProps {
  statement: Statement | undefined;
  update: (e: MouseEvent<HTMLElement>, statement: Statement) => void;
  remove: (e: MouseEvent<HTMLElement>) => void;
};

const Actions = styled.div`
  text-align: right;
  > button {
    margin-left: 10px;
  }
`;

const toOption = (target: string) => ({
  value: target,
  label: target,
  key: target
});

const Form: FC<FormProps> = ({ statement, update, remove }) => {
  const [payload, setPayload] = useState<Statement | undefined>(statement);
  const [active, setActive] = useState<boolean>(false);
  const [targets, setTargets] = useState<string[]>([]);
  const [candidates, setCandidates] = useState<string[]>([]);

  useEffect(() => {
    fetchTargets().then((resp) => resp.json().then(compose(setTargets, propOr([], 'targets'))));
  }, []);

  useEffect(() => {
    setActive(!isNil(statement));
  }, [isNil(statement)])

  const listCandidates = (target: string) => {
    fetchCandidates(target).then((resp) => resp.json().then(compose(setCandidates, propOr([], 'candidates'))));
  };
  useEffect(() => {
    compose(
      unless(
        isEmpty,
        listCandidates
      ),
      prop('class')
    )(payload);
  }, [payload?.class])

  const updateAttr = compose(
    setPayload,
    apply(assoc),
    juxt([
      nthArg(0),
      nthArg(1),
      nthArg(2)
    ])
  );
  const updatePayload = curryN(3, updateAttr)(__, __, payload);

  const isAttrEmpty = (attr: string, payload: Statement): boolean =>
    compose(
      isEmpty,
      prop(attr)
    )(payload);
  const curryIsAttrEmpty = curry(isAttrEmpty);
  const hasEmptyAttr = compose(
    anyPass(
      [
        curryIsAttrEmpty('class'),
        curryIsAttrEmpty('method'),
        curryIsAttrEmpty('code'),
        curryIsAttrEmpty('variable')
      ]
    )
  );

  return (
    <div className="row">
      <div className="col-md-12 mb-2">
        <input 
          className="form-control"
          placeholder="变量名"
          defaultValue={prop('variable', payload)}
          onChange={compose(updatePayload('variable'), path(['target', 'value']))}
        />
      </div>
      <div className="col-md-12 mb-2">
        <Select
          placeholder='请选择需要调试的类'
          defaultValue={toOption(prop('class', payload))}
          options={map(toOption, targets)}
          onChange={compose(
            updatePayload('class'),
            prop('value')
          )}
        />
      </div>
      <div className="col-md-12 mb-2">
        <Select
          placeholder='请选择需要调试的方法'
          defaultValue={toOption(prop('method', payload))}
          options={map(toOption, candidates)}
          onChange={compose(
            updatePayload('method'),
            prop('value')
          )}
        />
      </div>
      <div className="col-md-12 mb-2">
        <textarea
          className="form-control"
          defaultValue={prop('code', payload)}
          onChange={compose(updatePayload('code'), path(['target', 'value']))}
        />
      </div>
      <Actions>
        <button className="btn btn-sm btn-danger" onClick={remove}>删除</button>
        <button
          className="btn btn-sm btn-primary"
          disabled={hasEmptyAttr(payload)}
          onClick={flip(update)(payload)}
        >
          确定
        </button>
      </Actions>
    </div>
  );
}

export default Form;
