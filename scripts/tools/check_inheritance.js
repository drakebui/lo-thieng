const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, item.name);
        if (item.isDirectory()) {
            if (!['.git', '.godot', '__pycache__'].includes(item.name)) {
                results = results.concat(walk(full));
            }
        } else if (item.name.endsWith('.gd')) {
            results.push(full);
        }
    }
    return results;
}

const files = walk('.');

// Parse class names and paths
const classMap = new Map(); // className -> { file, parent, members: Set() }
const fileMap = new Map();  // filePath -> { className, parent, members: Set() }

for (const f of files) {
    const text = fs.readFileSync(f, 'utf-8');
    const classMatch = text.match(/^\s*class_name\s+([a-zA-Z_]\w*)/m);
    const className = classMatch ? classMatch[1] : null;

    let parent = null;
    const extMatch = text.match(/^\s*extends\s+([^\n#;]+)/m);
    if (extMatch) {
        parent = extMatch[1].trim().replace(/["']/g, '');
    }

    const members = new Map(); // memberName -> { type, line }

    const lines = text.split('\n');
    lines.forEach((line, idx) => {
        const lineNum = idx + 1;
        const trimmed = line.trim();
        if (trimmed.startsWith('#')) return;

        // constants
        const constMatch = trimmed.match(/^const\s+([a-zA-Z_]\w*)/);
        if (constMatch) members.set(constMatch[1], { type: 'const', lineNum });

        // variables
        const varMatch = trimmed.match(/^(?:@export\s+)?var\s+([a-zA-Z_]\w*)/);
        if (varMatch) members.set(varMatch[1], { type: 'var', lineNum });

        // signals
        const sigMatch = trimmed.match(/^signal\s+([a-zA-Z_]\w*)/);
        if (sigMatch) members.set(sigMatch[1], { type: 'signal', lineNum });
    });

    const info = { file: f, className, parent, members };
    if (className) classMap.set(className, info);
    fileMap.set(f, info);
    // also normalize path
    fileMap.set(f.replace(/\\/g, '/'), info);
    fileMap.set('res://' + f.replace(/\\/g, '/'), info);
}

console.log(`Parsed ${files.length} scripts.`);

// Now check inheritance trees for member collisions
const collisions = [];

for (const [f, info] of fileMap.entries()) {
    if (!f.endsWith('.gd')) continue; // only process file paths
    let curr = info;
    let parentRef = curr.parent;

    while (parentRef) {
        let parentInfo = classMap.get(parentRef) || fileMap.get(parentRef);
        if (!parentInfo && parentRef.startsWith('res://')) {
            const rel = parentRef.replace('res://', '');
            parentInfo = fileMap.get(rel);
        }

        if (parentInfo) {
            for (const [memberName, memData] of info.members.entries()) {
                if (parentInfo.members.has(memberName)) {
                    const parentMem = parentInfo.members.get(memberName);
                    collisions.push({
                        childFile: info.file,
                        childLine: memData.lineNum,
                        member: memberName,
                        childType: memData.type,
                        parentFile: parentInfo.file,
                        parentLine: parentMem.lineNum,
                        parentType: parentMem.type
                    });
                }
            }
            parentRef = parentInfo.parent;
        } else {
            break;
        }
    }
}

console.log(`Found ${collisions.length} member shadowing collisions:`);
for (const c of collisions) {
    console.log(`COLLISION: ${c.childFile}:${c.childLine} '${c.member}' (${c.childType}) shadows parent ${c.parentFile}:${c.parentLine} (${c.parentType})`);
}
