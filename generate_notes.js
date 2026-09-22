import { execSync } from 'child_process';
import fs from 'fs';
import { generateText } from 'ai';
import { google } from '@ai-sdk/google';

async function main() {
    try {
        console.log("🔍 Fetching target commit logs from branch dev...");
        // Pulls raw git commit messages between your last production tag and your development target branch
        const gitLog = execSync('git log origin/dev -n 20 --oneline').toString();
        
        if (!gitLog.trim()) {
            console.log("✅ No new changes detected.");
            process.exit(0);
        }

        const aiPrompt = `
You are an expert technical release writer for Seaus Tech. 
Review the following raw git commit log from our 'dev' branch and transform it into official, polished Release Notes.

The app is completely multiplatform (iOS, macOS, tvOS, and visionOS). Group features logically by platform if specific, or general game ecosystem enhancements. Use clean markdown formatting with emojis.

Raw Git Logs:
${gitLog}

Format the output strictly like this:
# 🌌 NEO-GRID Release Notes [Version]
## 🚀 What's New
- Short summary of major milestones.
## 📱 Platform Updates
- **macOS / iOS / visionOS / tvOS**: Group technical changes here.
## 🔧 Bug Fixes & Refinements
- List stability tweaks.
`;

        console.log("🤖 Generating production-ready release notes using Google Gemini Pro...");
        
        // Native SDK execution using your active shell API environment variable
        const { text } = await generateText({
            model: google('gemini-3.6-flash'),
            prompt: aiPrompt,
        });

        // Write out the pristine markdown output file
        fs.writeFileSync('RELEASE_NOTES.md', text);
        console.log("🎉 Done! Open RELEASE_NOTES.md to view your multiplatform notes.");

    } catch (error) {
        console.error("❌ Failed to compile automated release logs:", error.message);
    }
}

main();
