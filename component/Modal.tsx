import React, { FC, useState, useEffect, MouseEvent } from "react";
import classNames from "classnames";
// import 'modali/dist/modali.css';
// import '../node_modules/modali/dist/modali.css';
import { fetchTargets, fetchCandidates, createEntry, updateEntry, } from "./service";
import {
  addIndex,
  any,
  anyPass,
  always,
  assoc,
  assocPath,
  append,
  apply,
  compose,
  equals,
  flip,
  map,
  not,
  ifElse,
  is,
  isNil,
  isEmpty,
  identity,
  curry,
  remove,
  gt,
  juxt,
  length,
  path,
  prop,
  propOr,
  when,
  tap,
  __,
} from "ramda";
import { Entry, Statement } from "./List";
import Form from "./Form";
import { promptConfirmation, promptLoading } from './utils';
import styled from "styled-components";

interface ModalProps {
  entry: Entry | undefined;
  update: (entry: Entry) => void;
  close: (e: MouseEvent<HTMLElement>) => void;
}

const AddStatementButton = styled.button`
  width: 100%;
  text-align: center;
  display: block;
  padding: 0.5rem 0.75rem;
  font-size: 32px;
  box-shadow: none !important;

  &::after {
    display: none;
  }
`;

const ModalBody = styled.div`
  position: relative;
  margin: 1rem;
`;

const SpinnerContainer = styled.div`
  width: 100%;
  height: 300px;
`;

const CopyButton = styled.div`
  position: absolute;
  z-index: 9;
  color: #fff!important;
  background-color: RGBA(13,110,253,var(--bs-bg-opacity,1))!important;
  top: 9px;
  right: 5px;
  cursor: pointer;
`

// const defaultStatement = () => ({
//   active: true,
//   hint: '',
//   class: undefined,
//   method: undefined,
//   code: '',
// });

// const defaultStatement = () => ({
//   active: true,
//   hint: '测试是否包含指定指',
//   class: 'CompanyNote',
//   method: 'keys',
//   code: 'output = args.first',
// });
const defaultStatement = () => ({
  active: true,
  variable: "",
  class: "",
  method: "",
  code: "",
});

const AddStatementElement: FC<{ addStatement: (e: MouseEvent<HTMLButtonElement>) => void }>  = ({ addStatement }) => (
  <div className="accordion-item">
    <h2 className="accordion-header">
      <AddStatementButton
        className="accordion-button collapsed"
        type="button"
        aria-expanded="true"
        onClick={addStatement}
      >
        +
      </AddStatementButton>
    </h2>
  </div>
);

const Modal: FC<ModalProps> = ({ entry, update, close }) => {
  const [submitting, setSubmitting] = useState<boolean>(false);
  const [entity, setEntity] = useState<Entry>(entry);
  const [active, setActive] = useState<boolean>(false);
  const [targets, setTargets] = useState<string[]>([]);
  const [candidates, setCandidates] = useState<string[]>([]);

  useEffect(() => {
    fetchTargets().then((resp) =>
      resp.json().then(compose(setTargets, propOr([], "targets")))
    );
  }, []);

  useEffect(() => {
    setEntity(entry);
  }, [entry?.id]);

  useEffect(() => {
    setActive(!isNil(entity));
  }, [isNil(entity)]);

  const closeModal = (e: MouseEvent<HTMLButtonElement>) => {
    setEntity(undefined);
    close(e);
  };

  const dispatch = (e: MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
    setSubmitting(true);
    promptLoading(
      always(
        ifElse(
          compose(is(Number), prop('id')),
          createEntry,
          compose(
            apply(updateEntry),
            juxt([
              prop('id'),
              identity 
            ])
          ),
        )(entity)
      ),
      (entry: object) => {
        setEntity(undefined);
        update(entry);
      },
      () => {
        setSubmitting(false);
      }
    )
  };

  const addStatement = (e: MouseEvent<HTMLButtonElement>) => {
    e.preventDefault();
    compose(
      setEntity,
      curry(assoc)("statements", __, entity),
      append(defaultStatement()),
      when(isNil, always([])),
      prop("statements")
    )(entity);
  };

  const canAppendMoreStatement = compose(
    curry(gt)(5),
    length,
    propOr([], "statements")
  );

  const updateStatement = (
    e: MouseEvent<HTMLButtonElement>,
    index: number,
    statement: Statement
  ) => {
    e.preventDefault();
    statement.active = false;
    compose(
      setEntity,
      assocPath(["statements", index], statement)
    )(entity);
  };

  const removeStatement = (e: MouseEvent<HTMLButtonElement>, index: number) => {
    e.preventDefault();
    compose(
      setEntity,
      assoc("statements", __, entity),
      remove(index, 1),
      prop("statements")
    )(entity)
  };

  const toggleStatement = (
    e: MouseEvent<HTMLButtonElement>,
    index: number,
    statement: Statement
  ) => {
    e.preventDefault();
    compose(
      setEntity,
      assocPath(["statements", index, "active"], __, entity),
      not,
      prop("active")
    )(statement);
  };

  const toStatementEntry = (statement: Statement, index: number) => (
    <div className="accordion-item" key={index}>
      <h2 className="accordion-header">
        <button
          className={classNames('accordion-button', { collapsed: !statement.active })}
          type="button"
          aria-expanded="true"
          onClick={curry(toggleStatement)(__, index, statement)}
        >
          {isEmpty(statement.variable) ? "未设置" : statement.variable}
        </button>
      </h2>
      <div
        id="collapseOne"
        className={classNames('accordion-collapse collapse', { show: statement.active })}
      >
        <div className="accordion-body">
          {statement.active && (
            <Form
              statement={statement}
              update={flip(updateStatement)(index)}
              remove={flip(removeStatement)(index)}
            />
          )}
        </div>
      </div>
    </div>
  );

  const listStatements = compose(
    addIndex(map)(toStatementEntry),
    propOr([], "statements")
  );

  const hasNoStatements = compose(
    equals(0),
    length,
    propOr([], 'statements')
  );

  const hasActiveStatement = compose(
    any(equals(true)),
    map(prop('active')),
    propOr([], 'statements')
  );

  const loading = () => (
    <SpinnerContainer className="d-flex justify-content-center align-items-center">
      <div
        className={classNames("spinner-border", { hidden: !submitting })}
        role="status"
      >
        <span className="sr-only"></span>
      </div>
    </SpinnerContainer>
  );

  const copyToClipboard = (e: MouseEvent<HTMLButtonElement>, entry: Entry) => {
    e.preventDefault();
    navigator.clipboard.writeText(entry.id.toString());
  }

  const content = () => (
    <>
      <div className="row">
        <div className="col-md-12 mb-2">
          <div>
            {compose(
              ifElse(
                is(String),
                (id: string) => (
                  <>
                    <CopyButton className="badge" onClick={flip(copyToClipboard)(entry)}>复制</CopyButton>
                    <input
                      className="form-control"
                      placeholder="该次检查的描述"
                      value={id}
                      disabled={true}
                    />
                  </>
                ),
                always('')
              ),
              prop('id')
            )(entry)}
          </div>
        </div>
        <div className="col-md-12 mb-2">
          <input
            className="form-control"
            placeholder="该次检查的描述"
            defaultValue={prop("name", entry)}
            onChange={compose(
              setEntity,
              curry(assoc)("name", __, entity),
              path(["target", "value"])
            )}
          />
        </div>
      </div>
      <div className="accordion">
        {listStatements(entity)}
        {canAppendMoreStatement(entity) && (
          <AddStatementElement addStatement={addStatement} />
        )}
      </div>
    </>
  );

  // console.info(entity)

  return (
    <div
      className={classNames('modal fade', { show: active })}
      tabIndex={-1}
      style={{ display: active && !submitting ? "block" : "none" }}
    >
      <div className="modal-dialog modal-dialog-centered d-flex justify-content-center">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">设置需要挂载的方法</h5>
            <button
              type="button"
              className={classNames("btn-close", { disabled: submitting })}
              onClick={close}
              aria-label="Close"
            ></button>
          </div>
          <div className="modal-body p-0">
            <ModalBody>{ifElse(always, content, loading)(submitting)}</ModalBody>
          </div>
          <div className="modal-footer">
            <button
              type="button"
              className={classNames("btn btn-secondary", {
                disabled: submitting,
              })}
              onClick={closeModal}
            >
              关闭
            </button>
            <button
              type="button"
              className={classNames("btn btn-primary", {
                disabled: submitting || hasNoStatements(entity) || hasActiveStatement(entity)
              })}
              onClick={dispatch}
            >
              {submitting}
              <span>保存</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Modal;
