import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const html = fs.readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];

function openPage(saved = new Map()) {
  const node = () => ({innerText: '', innerHTML: '', style: {}, classList: {toggle(){}, add(){}, remove(){}}, scrollIntoView(){}, querySelector: () => node()});
  const elements = new Map([...html.matchAll(/\bid="([^"]+)"/g)].map(match => [match[1], node()]));
  const context = vm.createContext({
    document: {getElementById: id => elements.get(id) || null, querySelectorAll: () => [], querySelector: () => null},
    // An isolated verified-member fixture; no live entitlement is changed.
    window: {MMMMembership: {active: () => true}},
    navigator: {}, location: {}, Date,
    localStorage: {getItem: key => saved.get(key), setItem: (key, value) => saved.set(key, value)},
  });
  vm.runInContext(script, context);
  return {context, elements, saved};
}

test('a saved move renders, survives reopening, and can be marked complete', () => {
  const page = openPage();
  vm.runInContext("chooseGoal('save'); choosePace('small'); finishCheckIn('once'); saveMove();", page.context);
  assert.equal(page.elements.get('weekCount').innerText, 1);
  assert.equal(page.elements.get('completedCount').innerText, 0);
  assert.match(page.elements.get('activeText').innerText, /dedicated savings account/);
  const reopened = openPage(page.saved);
  assert.equal(reopened.elements.get('weekCount').innerText, 1);
  vm.runInContext('markComplete()', reopened.context);
  assert.equal(reopened.elements.get('completedCount').innerText, 1);
  assert.equal(JSON.parse(page.saved.get('mmmData')).current.complete, true);
});
