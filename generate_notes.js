#!/usr/bin/env node
/**
 * generate_notes.js — NEO-GRID Release Notes Generator
 *
 * Uses OpenRouter (free tier, no credit card needed, stable free models).
 * Downloads nothing. Zero local storage impact.
 *
 * Setup (one time):
 *   1. Get a free API key at https://openrouter.ai  (sign in with GitHub/Google)
 *   2. export OPENROUTER_API_KEY="sk-or-..."   ← add this to your ~/.zshrc
 *
 * Run:
 *   node generate_notes.js [output_path]
 *
 * Default output: TicTacToe/TicTacToe/RELEASE_NOTES.md
 */

import { execSync } from 'child_process';
import fs   from 'fs';
import path from 'path';

// ─── Config ──────────────────────────────────────────────────────────────────
const API_URL     = 'https://openrouter.ai/api/v1/chat/completions';
// Free models on OpenRouter — tried in order, first success wins.
// All have ":free" suffix which means $0.00, no credits deducted.
const FREE_MODELS = [
    'meta-llama/llama-3.1-8b-instruct:free',
    'mistralai/mistral-7b-instruct:free',
    'google/gemma-3-4b-it:free',
];
const OUTPUT_PATH = process.argv[2] ?? 'TicTacToe/TicTacToe/RELEASE_NOTES.md';
// ─────────────────────────────────────────────────────────────────────────────

function getApiKey() {
    const key = process.env.OPENROUTER_API_KEY;
    if (!key) {
        console.error('❌  OPENROUTER_API_KEY is not set.\n');
        console.error('   1. Sign up free at https://openrouter.ai (use GitHub or Google)');
        console.error('   2. Go to Keys → Create Key');
        console.error('   3. Add this line to your ~/.zshrc:');
        console.error('        export OPENROUTER_API_KEY="sk-or-your_key_here"');
        console.error('   4. Run:  source ~/.zshrc\n');
        process.exit(1);
    }
    return key;
}

function getGitLog() {
    const cwd = path.dirname(new URL(import.meta.url).pathname);
    for (const cmd of [
        'git log origin/dev -n 30 --oneline',
        'git log -n 30 --oneline',
    ]) {
        try {
            const out = execSync(cmd, { cwd, stdio: ['pipe', 'pipe', 'pipe'] }).toString().trim();
            if (out) return out;
        } catch {}
    }
    return null;
}

async function callModel(apiKey, model, gitLog) {
    const res = await fetch(API_URL, {
        method: 'POST',
        headers: {
            'Content-Type':  'application/json',
            'Authorization': `Bearer ${apiKey}`,
            'HTTP-Referer':  'https://github.com/seaustech/neogrid',
            'X-Title':       'NEO-GRID Release Notes',
        },
        body: JSON.stringify({
            model,
            messages: [
                {
                    role: 'system',
                    content:
                        'You are an expert technical release writer for Seaus Tech. ' +
                        'The app is called NEO-GRID — a multiplatform Tic-Tac-Toe game for iOS, macOS, tvOS, and visionOS. ' +
                        'Write polished, professional release notes in markdown. Be concise. Use emojis. ' +
                        'Output ONLY the markdown — no preamble, no explanation.',
                },
                {
                    role: 'user',
                    content:
                        `Transform these git commits into release notes:\n\n${gitLog}\n\n` +
                        'Use exactly this format:\n' +
                        '# 🌌 NEO-GRID Release Notes vX.X.X\n\n' +
                        '## 🚀 What\'s New\n- ...\n\n' +
                        '## 📱 Platform Updates\n- **macOS & iOS**: ...\n- **visionOS**: ...\n- **tvOS**: ...\n\n' +
                        '## 🔧 Bug Fixes & Refinements\n- ...',
                },
            ],
            temperature: 0.4,
            max_tokens:  1024,
        }),
    });

    if (res.status === 429) throw new Error('rate_limit');
    if (res.status === 402) throw new Error('credits');  // shouldn't happen on :free models
    if (!res.ok) {
        const body = await res.text();
        throw new Error(`api_error:${res.status}:${body}`);
    }

    const data = await res.json();

    // OpenRouter surfaces model-level errors in choices[0].message.content sometimes
    const content = data.choices?.[0]?.message?.content?.trim();
    if (!content) throw new Error('empty_response');
    return content;
}

async function main() {
    console.log('─────────────────────────────────────────');
    console.log('  NEO-GRID Release Notes Generator');
    console.log('  Provider: OpenRouter (free models)');
    console.log(`  Output:   ${OUTPUT_PATH}`);
    console.log('─────────────────────────────────────────\n');

    const apiKey = getApiKey();

    console.log('🔍 Reading git log...');
    const gitLog = getGitLog();
    if (!gitLog) {
        console.log('✅ No commits found — nothing to generate.');
        process.exit(0);
    }
    console.log(`   Found ${gitLog.split('\n').length} commits.\n`);

    // Try each free model in order
    let notes = null;
    for (const model of FREE_MODELS) {
        process.stdout.write(`🤖 Trying ${model} ...`);
        try {
            notes = await callModel(apiKey, model, gitLog);
            console.log(' ✓\n');
            break;
        } catch (err) {
            if (err.message === 'rate_limit') {
                console.log(' rate limited, trying next model...');
            } else if (err.message === 'empty_response') {
                console.log(' empty response, trying next model...');
            } else if (err.message.startsWith('api_error')) {
                const [, status, body] = err.message.split(':');
                console.log(` error ${status}, trying next model...`);
                if (process.env.DEBUG) console.error('   ', body);
            } else {
                throw err;
            }
        }
    }

    if (!notes) {
        console.error('❌ All free models failed. Check your API key or try again in a minute.');
        process.exit(1);
    }

    // Write output
    const outDir = path.dirname(OUTPUT_PATH);
    if (outDir && outDir !== '.' && !fs.existsSync(outDir)) {
        fs.mkdirSync(outDir, { recursive: true });
    }
    fs.writeFileSync(OUTPUT_PATH, notes, 'utf8');

    console.log(`✅ Release notes written to: ${OUTPUT_PATH}\n`);
    console.log('── Preview ──────────────────────────────');
    const lines = notes.split('\n');
    console.log(lines.slice(0, 14).join('\n'));
    if (lines.length > 14) console.log('   ...');
    console.log('─────────────────────────────────────────');
}

main().catch(err => {
    console.error('\n❌', err.message);
    process.exit(1);
});
