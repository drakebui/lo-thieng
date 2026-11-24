const fs = require('fs');
const path = require('path');

console.log('=== 1. CHECKING AUTOLOADS ===');
const projectGodot = fs.readFileSync('project.godot', 'utf8');
const autoloadPart = projectGodot.split('[autoload]')[1] ? projectGodot.split('[autoload]')[1].split('[display]')[0] : '';
const autoloadLines = autoloadPart.split('\n').filter(l => l.includes('='));
for (const line of autoloadLines) {
    const parts = line.split('=');
    const name = parts[0].trim();
    const rawPath = parts[1].trim().replace(/^"?\*?res:\/\//, '').replace(/"/g, '');
    if (!fs.existsSync(rawPath)) {
        console.error('AUTOLOAD MISSING:', name, '->', rawPath);
    } else {
        console.log('Autoload OK:', name, '->', rawPath);
    }
}

console.log('\n=== 2. CHECKING SCENES (.tscn) ===');
function walk(dir, ext) {
    let res = [];
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, item.name);
        if (item.isDirectory()) {
            if (!['.git', '.godot'].includes(item.name)) res = res.concat(walk(full, ext));
        } else if (item.name.endsWith(ext)) res.push(full);
    }
    return res;
}

const tscnFiles = walk('.', '.tscn');
let brokenScenes = 0;
for (const f of tscnFiles) {
    const text = fs.readFileSync(f, 'utf8');
    const regex = /\[ext_resource\s+type="([^"]+)"\s+(?:uid="[^"]*"\s+)?path="res:\/\/([^"]+)"/g;
    let match;
    while ((match = regex.exec(text)) !== null) {
        const resPath = match[2];
        if (!fs.existsSync(resPath)) {
            console.error('SCENE BROKEN RESOURCE in ' + f + ' -> res://' + resPath);
            brokenScenes++;
        }
    }
}
console.log('Checked ' + tscnFiles.length + ' scenes. Broken resource references: ' + brokenScenes);

console.log('\n=== 3. CHECKING ALL SCRIPTS (.gd) FOR EXTENDS AND PRELOADS ===');
const gdFiles = walk('.', '.gd');
let brokenScripts = 0;
for (const f of gdFiles) {
    const text = fs.readFileSync(f, 'utf8');
    const lines = text.split('\n');
    lines.forEach((l, idx) => {
        // Check preload
        const preloadMatches = l.matchAll(/preload\s*\(\s*["']res:\/\/([^"']+)["']\s*\)/g);
        for (const m of preloadMatches) {
            if (!fs.existsSync(m[1])) {
                console.error('BROKEN PRELOAD in ' + f + ':' + (idx+1) + ' -> res://' + m[1]);
                brokenScripts++;
            }
        }
        // Check extends res://
        const extendsMatches = l.matchAll(/extends\s+["']res:\/\/([^"']+)["']/g);
        for (const m of extendsMatches) {
            if (!fs.existsSync(m[1])) {
                console.error('BROKEN EXTENDS in ' + f + ':' + (idx+1) + ' -> res://' + m[1]);
                brokenScripts++;
            }
        }
    });
}
console.log('Checked ' + gdFiles.length + ' scripts. Broken preload/extends: ' + brokenScripts);
