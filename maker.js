const fs = require('fs');
const { execSync } = require('child_process');

const progressFile = 'progress.md';
const draftFile = 'draft.txt';

let lastCommit = '';
const content = fs.readFileSync(progressFile, 'utf8');
const m = content.match(/last_commit:\s*(\S*)/);
if (m) lastCommit = m[1];

let log = [];
if (lastCommit) {
  try {
    log = execSync(`git log ${lastCommit}..HEAD --pretty=format:"%h|%s"`, { encoding: 'utf8' })
      .trim().split(/\r?\n/).filter(Boolean);
  } catch {
    log = [];
  }
}

if (log.length === 0) {
  fs.writeFileSync(draftFile, 'NO_NEW_COMMITS\n');
} else {
  const lines = log.map(l => {
    const [hash, ...rest] = l.split('|');
    return `- ${hash} ${rest.join(' ')}`;
  });
  fs.writeFileSync(draftFile, lines.join('\n') + '\n');
}
