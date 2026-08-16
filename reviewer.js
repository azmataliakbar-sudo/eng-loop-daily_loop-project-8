const fs = require('fs');

const draft = fs.readFileSync('draft.txt', 'utf8').trim();

if (draft === 'NO_NEW_COMMITS') {
  console.log('PASS');
  console.log('Reason: no new commits since last run');
  process.exit(0);
}

const lines = draft.split(/\r?\n/).filter(Boolean);
const bad = lines.filter(l => !/^-\s+[0-9a-f]{7,}\s+.+/.test(l));

if (bad.length > 0) {
  console.log('FAIL');
  console.log('Reason: malformed changelog lines');
  console.log(bad.join('\n'));
  process.exit(1);
}

console.log('PASS');
console.log(`Reason: ${lines.length} valid changelog line(s)`);
