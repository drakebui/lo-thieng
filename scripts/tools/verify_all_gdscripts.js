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

// Parse all methods and variables of each autoload
const autoloads = {
    GameManager: 'scripts/autoload/GameManager.gd',
    EventBus: 'scripts/autoload/EventBus.gd',
    SaveSystem: 'scripts/autoload/SaveSystem.gd',
    AudioManager: 'scripts/autoload/AudioManager.gd',
    SceneManager: 'scripts/autoload/SceneManager.gd',
    DayCycle: 'scripts/autoload/DayCycle.gd',
    DebtSystem: 'scripts/autoload/DebtSystem.gd',
    InventorySystem: 'scripts/autoload/InventorySystem.gd',
    CommissionSystem: 'scripts/autoload/CommissionSystem.gd',
};

const autoloadMembers = {};
for (const [name, filePath] of Object.entries(autoloads)) {
    const text = fs.readFileSync(filePath, 'utf-8');
    const members = new Set();
    // find func names
    for (const m of text.matchAll(/^\s*func\s+([a-zA-Z_]\w*)/gm)) {
        members.add(m[1]);
    }
    // find var / const names
    for (const m of text.matchAll(/^\s*(?:var|const|@export var)\s+([a-zA-Z_]\w*)/gm)) {
        members.add(m[1]);
    }
    // find signal names
    for (const m of text.matchAll(/^\s*signal\s+([a-zA-Z_]\w*)/gm)) {
        members.add(m[1]);
    }
    autoloadMembers[name] = members;
    console.log(`Autoload ${name} has ${members.size} declared members.`);
}

const errors = [];

for (const file of files) {
    const text = fs.readFileSync(file, 'utf-8');
    const lines = text.split('\n');

    lines.forEach((line, idx) => {
        const lineNum = idx + 1;
        const trimmed = line.trim();
        if (trimmed.startsWith('#')) return;

        for (const [autoName, members] of Object.entries(autoloadMembers)) {
            // Check autoload member access: AutoName.member
            const regex = new RegExp(`\\b${autoName}\\.([a-zA-Z_]\\w*)`, 'g');
            for (const m of trimmed.matchAll(regex)) {
                const member = m[1];
                if (!members.has(member)) {
                    // Check if member is a common built-in property (e.g. get_tree, name)
                    if (!['connect', 'disconnect', 'is_connected', 'emit_signal', 'has_signal', 'has_method', 'get', 'set'].includes(member)) {
                        errors.push(`${file}:${lineNum} -> ${autoName}.${member} does not exist in ${autoloads[autoName]}`);
                    }
                }
            }
        }
    });
}

console.log(`\nChecked member calls across all files. Total errors found: ${errors.length}`);
errors.forEach(e => console.log('ERROR:', e));
