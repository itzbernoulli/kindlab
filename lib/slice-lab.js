// lib/slice-lab.js — pure helper that slices a source mega-lab into one small lab.
// Given a parsed source lab.json (with ._dir) and a cut spec, returns the new
// lab.json object + the list of validator/setup files to copy into the new folder.
// Pure: no fs, no cluster. The driver (scripts/slice-cka.js) performs the I/O.

const path = require('path');

// sliceLab(sourceLab, cut) -> { labJson, fileCopies }
//   cut = { id, name, topics, certs, troubleshooting?, needsSecondCluster?, exerciseIds[] }
function sliceLab(sourceLab, cut) {
  const byId = new Map(sourceLab.questions.map(q => [String(q.id), q]));
  const picked = cut.exerciseIds.map(id => {
    const q = byId.get(String(id));
    if (!q) throw new Error(`exercise ${id} not found in ${sourceLab.id}`);
    return JSON.parse(JSON.stringify(q)); // deep clone
  });

  const fileCopies = [];
  const seen = new Set();
  const add = (fromRel, to) => {
    if (seen.has(to)) return;
    seen.add(to);
    fileCopies.push({ from: path.join(sourceLab._dir, fromRel), to });
  };

  const questions = picked.map((q, i) => {
    q.id = String(i + 1); // renumber 1..n
    for (const v of (q.verification || [])) {
      const to = 'validate/' + path.basename(v.script);
      add(v.script, to);
      v.script = to;
    }
    if (q.setup) {
      const to = 'setup/' + path.basename(q.setup);
      add(q.setup, to);
      q.setup = to;
    }
    return q;
  });

  // Always carry the source q0 as the reseed starting point (driver hand-edits it).
  add('setup/q0_setup.sh', 'setup/q0_setup.sh');

  const labJson = {
    id: cut.id,
    name: cut.name,
    type: 'learn',
    objective: sourceLab.objective,
    certs: cut.certs,
    topics: cut.topics,
    questions,
  };
  if (cut.troubleshooting) labJson.troubleshooting = true;
  if (cut.needsSecondCluster) labJson.needsSecondCluster = true;

  return { labJson, fileCopies };
}

module.exports = { sliceLab };
