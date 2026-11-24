const fs = require('fs');
const path = require('path');

function walk(dir) {
    let files = [];
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, item.name);
        if (item.isDirectory()) {
            if (!['.git', '.godot'].includes(item.name)) files = files.concat(walk(full));
        } else if (item.name.endsWith('.gd')) files.push(full);
    }
    return files;
}

const gdFiles = walk('.');

// Parse each script to extract:
// - className
// - extendsName / extendsPath
// - members: constants, variables, signals, enums, functions
const scriptMap = {};

for (const file of gdFiles) {
    const text = fs.readFileSync(file, 'utf8');
    const rel = file.replace(/\\/g, '/');
    let className = null;
    let extendsTarget = null;
    const constants = new Set();
    const variables = new Set();
    const signals = new Set();
    const functions = new Set();

    const lines = text.split('\n');
    for (let rawLine of lines) {
        const l = rawLine.trim();
        if (l.startsWith('#')) continue;

        const cn = l.match(/^class_name\s+([A-Za-z0-9_]+)/);
        if (cn) className = cn[1];

        const ext = l.match(/^extends\s+(?:"res:\/\/([^"]+)"|([A-Za-z0-9_]+))/);
        if (ext) extendsTarget = ext[1] ? ext[1] : ext[2];

        // Only class-level members (no indentation at start of rawLine)
        if (!rawLine.startsWith('\t') && !rawLine.startsWith('    ')) {
            const c = l.match(/^const\s+([A-Za-z0-9_]+)/);
            if (c) constants.add(c[1]);

            const v = l.match(/^(?:@\w+(?:\([^)]*\))?\s+)*var\s+([A-Za-z0-9_]+)/);
            if (v) variables.add(v[1]);

            const s = l.match(/^signal\s+([A-Za-z0-9_]+)/);
            if (s) signals.add(s[1]);
        }

        const f = l.match(/^func\s+([A-Za-z0-9_]+)/);
        if (f) functions.add(f[1]);
    }

    scriptMap[rel] = {
        file: rel,
        className,
        extendsTarget,
        constants,
        variables,
        signals,
        functions
    };
    if (className) {
        scriptMap[className] = scriptMap[rel];
    }
}

console.log('Total parsed scripts:', gdFiles.length);

let totalCollisions = 0;

for (const rel in scriptMap) {
    if (!rel.includes('/')) continue; // Skip className alias keys
    const info = scriptMap[rel];
    if (!info.extendsTarget) continue;

    // Check inheritance chain
    let target = info.extendsTarget;
    let parentInfo = scriptMap[target] || scriptMap['scripts/' + target] || scriptMap[target.replace(/^\/?/, '')];

    while (parentInfo) {
        // In GDScript, child cannot declare member with same name as parent's const, var, or signal
        // Functions can be overridden (unless virtual/static issues)
        for (const c of info.constants) {
            if (parentInfo.constants.has(c)) {
                console.error(`[COLLISION] Const "${c}" in ${info.file} already exists in parent ${parentInfo.file}`);
                totalCollisions++;
            }
            if (parentInfo.variables.has(c)) {
                console.error(`[COLLISION] Const "${c}" in ${info.file} shadows var in parent ${parentInfo.file}`);
                totalCollisions++;
            }
        }
        for (const v of info.variables) {
            if (parentInfo.constants.has(v)) {
                console.error(`[COLLISION] Var "${v}" in ${info.file} shadows const in parent ${parentInfo.file}`);
                totalCollisions++;
            }
            if (parentInfo.variables.has(v)) {
                console.error(`[COLLISION] Var "${v}" in ${info.file} already exists in parent ${parentInfo.file}`);
                totalCollisions++;
            }
        }
        for (const s of info.signals) {
            if (parentInfo.signals.has(s)) {
                console.error(`[COLLISION] Signal "${s}" in ${info.file} already exists in parent ${parentInfo.file}`);
                totalCollisions++;
            }
        }

        target = parentInfo.extendsTarget;
        parentInfo = target ? (scriptMap[target] || scriptMap['scripts/' + target]) : null;
    }
}

console.log('Exhaustive inheritance collision check complete. Total collisions:', totalCollisions);
