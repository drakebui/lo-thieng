const fs = require('fs');
const path = require('path');

function walk(dir, ext) {
    let results = [];
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, item.name);
        if (item.isDirectory()) {
            if (item.name !== '.git' && item.name !== '.godot' && item.name !== '__pycache__') {
                results = results.concat(walk(full, ext));
            }
        } else if (item.name.endsWith(ext)) {
            results.push(full);
        }
    }
    return results;
}

const gdFiles = walk('.', '.gd');
console.log(`Auditing ${gdFiles.length} GDScript files...`);

const issues = [];

for (const file of gdFiles) {
    const content = fs.readFileSync(file, 'utf-8');
    const lines = content.split('\n');

    lines.forEach((line, idx) => {
        const lineNum = idx + 1;
        const trimmed = line.trim();
        if (trimmed.startsWith('#')) return;

        // Check for "for x in int_variable:" instead of range()
        const loopMatch = trimmed.match(/^for\s+([a-zA-Z_]\w*)\s+in\s+([a-zA-Z_]\w*):/);
        if (loopMatch) {
            const target = loopMatch[2];
            // check if target is an integer variable defined nearby or known to be int
            if (['segs', 'count', 'frame_count', 'cols', 'rows', 'steps'].includes(target)) {
                issues.push(`${file}:${lineNum} -> Iterate over int '${target}' without range(): "${trimmed}"`);
            }
        }

        // Check for setters calling themselves or infinite loops
        if (trimmed.includes('set(val):') && trimmed.includes('set_')) {
            issues.push(`${file}:${lineNum} -> Suspicious setter delegate: "${trimmed}"`);
        }
    });
}

console.log(`Found ${issues.length} potential issues:`);
issues.forEach(i => console.log(' - ' + i));
