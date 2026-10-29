'use strict';
// serialize-lab.js — single source of truth for the /api/labs payload shape.
// NOTE: certOf is imported from lib/grouping.js (single source of truth for cert logic).
const { certOf } = require('./grouping');

/**
 * serialize(l, labType) -> plain object suitable for JSON serialisation.
 * @param {object} l       - raw lab object loaded from disk
 * @param {function} labType - (l) => 'learn'|'exam'  — lives in bin/kindlab.js
 */
module.exports = function serialize(l, labType) {
  return {
    id: l.id,
    name: l.name,
    category: certOf(l),
    certs: l.certs || [],
    topics: l.topics || [],
    troubleshooting: !!l.troubleshooting,
    type: labType(l),
    requiresHost: !!l.requiresHost,
    tasks: (l.questions || []).length
  };
};
