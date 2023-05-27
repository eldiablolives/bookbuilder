const { invoke } = window.__TAURI__.tauri;

// let greetMsgEl;
let config = emptyConfig();

import { createApp } from './vue.esm-browser.js';

const app = createApp({
  data() {
    return {
      root: '/',
      path: '',
      selected: '',
      data: [],
      debug: 'Debug messages',
    };
  },
  methods: {
    select,
    cancel,
    files,
  },
}).mount('#app');

async function files(path) {
  let pat = path ? app.root + path : app.root;

  app.debug = 'Getting files with param: ' + pat;

  let result = await invoke('list', { path: pat });

  app.debug = result;

  let data = JSON.parse(result);

  if (!data.error) {
    app.data = data.files;
    app.root = path ? app.root + path + '/' : app.root;
    app.path = app.root;

    // check if book.yaml is present and read it if so
    for (file of files) {
      if (file.name == 'book.yaml') {
        let res = await readConfig(app.root + 'book.yaml');
        config = JSON.parse(res);
        break;
      }
    }
  }
}

async function init() {
  app.root = await invoke('root');
  files();
}

window.addEventListener('DOMContentLoaded', () => {
  init();
});

function select() {
  this.selected = app.root;
}

function cancel() {
  app.selected = false;
  refresh();
}

///////////////////////

async function readConfig(path) {
  return invoke('get_book_conf', { path: path });
}

///////////////////////

function emptyConfig() {
  return {
    title: '',
    author: '',
  };
}
