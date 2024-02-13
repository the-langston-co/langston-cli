import {upload} from "./upload";
import * as path from "path";
import {existsSync} from "fs";
import dotenv from 'dotenv';

dotenv.config();

async function start() {
    const filepath = path.resolve('../dist/Fetch.dmg');

    const fileExists = existsSync(filepath);
    if (!fileExists) {
        throw new Error(`File not found for ${filepath}`)
    } else {
        console.log(`Uploading new version to Kandji from file ${filepath}`)
    }
    await upload(filepath)
    return;
}

start().then(() => {
    console.log('Fetch App loaded to Kandji')
}).catch(error => {
    console.error('Upload errored')
    console.error(error);
});