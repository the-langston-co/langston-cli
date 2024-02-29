import {upload} from "./upload";
import {existsSync} from "fs";
import dotenv from 'dotenv';
import {promptConfirm, promptForArtifactPath, promptForBeta} from "./prompts";

dotenv.config();

async function start() {
    const {version, artifactPath} = await promptForArtifactPath()
    const {beta} = await promptForBeta();

    const settings = [{version, artifactPath, beta}]
    console.log()
    console.log('Kandji release settings')

    console.table(settings, )
    console.log()
    const confirm = await promptConfirm('Proceed with the release using these settings?')

    if (!confirm) {
        console.log();

        console.log('Not proceeding with upload to Kandji.')
        return;
    }

    const fileExists = existsSync(artifactPath);
    if (!fileExists) {
        throw new Error(`File not found for ${artifactPath}`)
    } else {
        console.log(`Uploading new version to Kandji from file ${artifactPath}`)
    }
    await upload(artifactPath, {beta,})
    console.log('Fetch App loaded to Kandji')
    return;
}

start().then(() => {
    console.log('Done')
}).catch(error => {
    console.error('Upload errored')
    console.error(error);
});