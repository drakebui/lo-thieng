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
const classes = new Map();
const errors = [];

// 1. Gather all class_name declarations
for (const f of files) {
    const text = fs.readFileSync(f, 'utf-8');
    const match = text.match(/^\s*class_name\s+([a-zA-Z_]\w*)/m);
    if (match) {
        const cname = match[1];
        if (classes.has(cname)) {
            errors.push(`DUPLICATE class_name '${cname}': in ${f} and ${classes.get(cname)}`);
        } else {
            classes.set(cname, f);
        }
    }
}

console.log(`Registered ${classes.size} class_name declarations.`);

// 2. Check each file for extends and preloads
for (const f of files) {
    const text = fs.readFileSync(f, 'utf-8');
    const lines = text.split('\n');

    lines.forEach((line, i) => {
        const lineNum = i + 1;
        const trimmed = line.trim();
        if (trimmed.startsWith('#')) return;

        // Check extends
        const extMatch = trimmed.match(/^\s*extends\s+([a-zA-Z_]\w*)/);
        if (extMatch) {
            const base = extMatch[1];
            // Godot native classes
            const native = [
                'Node', 'Node2D', 'Node3D', 'Control', 'CanvasLayer', 'CharacterBody2D',
                'CharacterBody3D', 'StaticBody2D', 'RigidBody2D', 'Area2D', 'CollisionShape2D',
                'Sprite2D', 'AnimatedSprite2D', 'Polygon2D', 'Marker2D', 'RefCounted', 'Resource',
                'EditorScript', 'AcceptDialog', 'PanelContainer', 'BoxContainer', 'VBoxContainer',
                'HBoxContainer', 'MarginContainer', 'ScrollContainer', 'Button', 'Label', 'ColorRect',
                'TextureRect', 'Camera2D', 'AnimationPlayer', 'AnimationTree', 'AudioStreamPlayer'
            ];
            if (!native.includes(base) && !classes.has(base)) {
                errors.push(`${f}:${lineNum} -> Unknown extends base class '${base}'`);
            }
        }

        // Check preload
        const preloadMatches = trimmed.matchAll(/preload\s*\(\s*["']([^"']+)["']\s*\)/g);
        for (const pm of preloadMatches) {
            const resPath = pm[1];
            if (resPath.startsWith('res://')) {
                const fsPath = resPath.replace('res://', '');
                if (!fs.existsSync(fsPath)) {
                    errors.push(`${f}:${lineNum} -> Broken preload("${resPath}")`);
                }
            }
        }
    });
}

console.log(`Errors found: ${errors.length}`);
errors.forEach(e => console.log('ERROR:', e));
