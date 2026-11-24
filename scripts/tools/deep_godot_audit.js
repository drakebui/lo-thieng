const fs = require('fs');
const path = require('path');

function walk(dir, ext) {
    let results = [];
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, item.name);
        if (item.isDirectory()) {
            if (!['.git', '.godot', '__pycache__'].includes(item.name)) {
                results = results.concat(walk(full, ext));
            }
        } else if (item.name.endsWith(ext)) {
            results.push(full);
        }
    }
    return results;
}

const gdFiles = walk('.', '.gd');
const tscnFiles = walk('.', '.tscn');
const tresFiles = walk('.', '.tres');

console.log(`Auditing project: ${gdFiles.length} .gd, ${tscnFiles.length} .tscn, ${tresFiles.length} .tres files...`);

const errors = [];
const warnings = [];

// 1. Check EventBus signals
const eventBusContent = fs.readFileSync('scripts/autoload/EventBus.gd', 'utf-8');
const eventBusSignals = new Set();
for (const match of eventBusContent.matchAll(/^\s*signal\s+([a-zA-Z_]\w*)/gm)) {
    eventBusSignals.add(match[1]);
}
console.log(`Registered ${eventBusSignals.size} EventBus signals.`);

// 2. Check AudioManager SFX paths and keys
const audioManagerContent = fs.readFileSync('scripts/autoload/AudioManager.gd', 'utf-8');
const sfxKeys = new Set();
const sfxKeyMatches = audioManagerContent.matchAll(/"([^"]+)":\s*"res:\/\/assets\/audio\/([^"]+)"/g);
for (const m of sfxKeyMatches) {
    sfxKeys.add(m[1]);
    const filePath = path.join('assets/audio', m[2]);
    if (!fs.existsSync(filePath)) {
        errors.push(`AudioManager SFX missing file: key '${m[1]}' -> ${filePath}`);
    }
}
console.log(`Registered ${sfxKeys.size} SFX keys in AudioManager.`);

// 3. Scan all files for res:// paths
const allSourceFiles = [...gdFiles, ...tscnFiles, ...tresFiles];
for (const file of allSourceFiles) {
    const text = fs.readFileSync(file, 'utf-8');
    const lines = text.split('\n');

    lines.forEach((line, idx) => {
        const lineNum = idx + 1;
        const trimmed = line.trim();
        if (trimmed.startsWith('#') || trimmed.startsWith(';')) return;

        // Check res:// references
        const resMatches = line.matchAll(/res:\/\/([a-zA-Z0-9_\-\.\/]+)/g);
        for (const rm of resMatches) {
            const rawPath = rm[0];
            const cleanPath = rm[1];
            if (rawPath.endsWith('.uid') || rawPath.endsWith('.import')) continue;
            if (!fs.existsSync(cleanPath)) {
                // Ignore commented or dynamically constructed template paths
                if (!line.includes('%') && !line.includes('{') && !line.includes('+')) {
                    errors.push(`${file}:${lineNum} -> Missing resource file: "${rawPath}"`);
                }
            }
        }

        // Check EventBus signal calls
        const ebEmitMatches = line.matchAll(/EventBus\.([a-zA-Z_]\w*)\.emit\(/g);
        for (const m of ebEmitMatches) {
            const sig = m[1];
            if (!eventBusSignals.has(sig)) {
                errors.push(`${file}:${lineNum} -> Unknown EventBus signal emit: "${sig}"`);
            }
        }
        const ebConnectMatches = line.matchAll(/EventBus\.([a-zA-Z_]\w*)\.connect\(/g);
        for (const m of ebConnectMatches) {
            const sig = m[1];
            if (!eventBusSignals.has(sig)) {
                errors.push(`${file}:${lineNum} -> Unknown EventBus signal connect: "${sig}"`);
            }
        }

        // Check AudioManager key playback
        const audioKeyMatches = line.matchAll(/AudioManager\.play_sfx_key\(\s*["']([^"']+)["']/g);
        for (const m of audioKeyMatches) {
            const k = m[1];
            if (!sfxKeys.has(k)) {
                warnings.push(`${file}:${lineNum} -> AudioManager play_sfx_key unknown key: "${k}"`);
            }
        }

        const audioLoopMatches = line.matchAll(/AudioManager\.play_sfx_loop\(\s*["']([^"']+)["']/g);
        for (const m of audioLoopMatches) {
            const k = m[1];
            if (!sfxKeys.has(k)) {
                warnings.push(`${file}:${lineNum} -> AudioManager play_sfx_loop unknown key: "${k}"`);
            }
        }
    });
}

console.log(`\nAudit completed: ${errors.length} errors, ${warnings.length} warnings.`);
if (errors.length > 0) {
    console.log('\n--- ERRORS ---');
    errors.forEach(e => console.log('ERROR:', e));
}
if (warnings.length > 0) {
    console.log('\n--- WARNINGS ---');
    warnings.forEach(w => console.log('WARN:', w));
}
