const { invoke } = window.__TAURI__.tauri;

let greetInputEl;
let greetMsgEl;
let listContainer;
let pathEl;
let root = '/';
let selected;
let configDetail = false;

async function greet(path) {
  // Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
  // greetMsgEl.textContent = await invoke("greet", { name: greetInputEl.value });
  let result = await invoke('list', { path: path ? path : root });
  greetMsgEl.textContent = result;

  let data = JSON.parse(result);

  if (!data.error) {
    buildList(data);
    root = path ? path + '/' : root;
    pathEl.textContent = root;
  }
}

async function init() {
  root = await invoke('root');
  greet();
}

window.addEventListener('DOMContentLoaded', () => {
  greetInputEl = document.querySelector('#greet-input');
  greetMsgEl = document.querySelector('#greet-msg');

  document.getElementById('select-button').addEventListener('click', () => select());
  document.getElementById('cancel-button').addEventListener('click', () => cancel());
  document.getElementById('config-detail-switch').addEventListener('click', (ev) => {
    configDetail = ev.target.checked;
    refresh();
  });

  listContainer = document.getElementById('list-container');
  pathEl = document.getElementById('path');
  greetMsgEl.textContent = listContainer;

  init();
});

function select() {
  selected = root;
  refresh();
}

function cancel() {
  selected = null;
  configDetail = false;

  document.getElementById('config-detail-switch').checked = false;

  refresh();
}

function buildList(items) {
  listContainer.replaceChildren();
  listContainer.appendChild(buildRow({ folder: true, name: '..' }));
  for (let item of items) {
    listContainer.appendChild(buildRow(item));
  }
}

function buildRow(item) {
  let element = document.createElement('div');
  element.addEventListener('click', (ev) => {
    greet(root + ev.target.textContent);
  });
  // item.element =
  element.appendChild(buildIcon());
  element.appendChild(document.createTextNode(item.name));
  return element;
}

function buildIcon(type) {
  let element = document.createElement('img');
  element.src = 'assets/folder.svg';
  return element;
}

function refresh() {
  greetMsgEl.textContent = JSON.stringify(selected);

  if (configDetail) {
    document.getElementById('config-panel-detail').classList.remove('hidden');
  } else {
    document.getElementById('config-panel-detail').classList.add('hidden');
  }

  if (selected) {
    document.getElementById('select-panel').classList.add('hidden');
    document.getElementById('config-panel').classList.remove('hidden');
    document.getElementById('select-button').classList.add('hidden');
    document.getElementById('cancel-button').classList.remove('hidden');
    document.getElementById('process-button').classList.remove('hidden');
  } else {
    document.getElementById('select-panel').classList.remove('hidden');
    document.getElementById('config-panel').classList.add('hidden');
    document.getElementById('select-button').classList.remove('hidden');
    document.getElementById('cancel-button').classList.add('hidden');
    document.getElementById('process-button').classList.add('hidden');
  }
}
