import 'sweetalert2/dist/sweetalert2.css';
import Swal from 'sweetalert2/dist/sweetalert2.js';
window.Swal = Swal;
import withReactContent from 'sweetalert2-react-content'
import { always, apply, applySpec, anyPass, call, compose, composeWith, curry, of, mergeRight, is, prop, ifElse, propEq, when, unless, isNil, tap, nthArg, juxt } from 'ramda';

const composeWithPromise = (...args: any[]) =>
  composeWith((f: (val: any) => void, val: any) => {
    if (val && val.then) {
      return val.then(f);
    }
    if (Array.isArray(val) && val.length && val[0] && val[0].then) {
      return Promise.all(val).then(f);
    }
    return f(val);
  })(args)

const LoadingSwal = withReactContent(Swal)

const toggleLoading = () => LoadingSwal.showLoading();

const fire = (opts: any) => LoadingSwal.fire(opts);

const fireOpts = compose( 
  mergeRight({
    showConfirmButton: false,
    showCancelButton: false,
    allowOutsideClick: false,
    allowEscapeKey: false,
    icon: 'success',
    title: '操作成功',
    text: '',
    timer: 2000,
  }),
  tap(console.info),
  ifElse(
    propEq('error', false),
    always({}),
    compose(
      apply(mergeRight),
      juxt([
        applySpec({
          willClose: nthArg(1),
        }),
        compose(
          applySpec({
            icon: always('error'),
            title: always('操作失败'),
            text: prop('error'),
          }),
          nthArg(0)
        )
      ]),
    )
  )
);

const promptConfirmation = (options: object, callback: Promise<any>, successCallback: () => void) =>
  LoadingSwal.fire(mergeRight(options, {
    icon: 'question',
    showConfirmButton: true,
    confirmButtonText: '确定',
    showCancelButton: true,
    cancelButtonText: '取消',
    allowOutsideClick: true,
    allowEscapeKey: true,
  })).then(
    when(
      propEq('isConfirmed', true),
      () => promptLoading(callback, successCallback)
    )
  );


  const promptLoading = (callback: Promise<any>, successCallback: (res: object) => void, finallyCallback: () => void = undefined) =>
  LoadingSwal.fire({
    title: '处理中',
    text: '正在发送数据, 请稍候...',
    allowOutsideClick: false,
    allowEscapeKey: false,
    didOpen: () => { 
      toggleLoading();
      callback().then((res: object) => {
        console.info(
          anyPass([
            isNil,
            compose(is(String), prop('error'))
          ])(res),
          res
        )
        compose(
          unless(
            anyPass([
              isNil,
              compose(is(String), prop('error'))
            ]),
            compose(
              curry(apply)(successCallback),
              of,
              prop('entry'),
            )
          ),
          tap(
            always(fire(fireOpts(res, finallyCallback)))
          ),
        )(res)
      });
    },
  });

export { promptConfirmation, promptLoading, composeWithPromise };
