const { invoke } = window.__TAURI__.tauri;

// let greetMsgEl;
let config = emptyConfig();

import { createApp } from './vue.esm-browser.js';

const app = createApp({
  data() {
    return {
      root: '',
      path: '',
      selected: '',
      data: [],
      debug: 'Debug messages',
      conf: {},
    };
  },
  methods: {
    select,
    cancel,
    files,
  },
  computed: {
    filtered() {
      return this.data.filter((file) => !file.name.startsWith('_') && file.name.endsWith('.md'));
    },
    folders() {
      let count = 0;
      let res = { partial: false, folders: [] };
      const split = this.path.split('/').slice(0, -1);
      
      for (let i = split.length - 1; i >= 0; i--) {
        if (split[i].length + count < 40) {
          res.folders.unshift(split[i]);
          count += split[i].length;
        } else {
          res.partial = true;
          break;
        }
      }
      return res;
    },
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
    path = data.path;
    app.root = app.path = data.path;

    if (data.conf) {
      app.conf = data.conf;
    }

    // // check if book.yaml is present and read it if so
    // for (file of files) {
    //   if (file.name == 'book.yaml') {
    //     let res = await readConfig(app.root + 'book.yaml');
    //     config = JSON.parse(res);
    //     break;
    //   }
    // }
  }
}

async function init() {
  // app.root = await invoke('root');
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
