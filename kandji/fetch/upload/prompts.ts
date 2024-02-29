import inquirer from "inquirer";
import dotenv from "dotenv";
import path from 'path'
import {readdir} from 'fs/promises'

dotenv.config();

export async function promptForBeta() {
    const answers = await inquirer.prompt<{ build_target: string }>([{
        type: 'list', name: 'build_target', message: 'Which Kandji app is this for?', choices: ['Fetch', 'Fetch (beta)']
    }])
    const isProd = answers.build_target === 'Fetch'
    return {beta: !isProd}
}

export async function promptForArtifactPath() {

    const distRoot = path.resolve(path.join(process.env.HOME ?? '~', '/langston-fetch/dist'))

    const folders = (await readdir(distRoot, {withFileTypes: true})).filter(dirent => dirent.isDirectory())
    const versionNames = folders.map(dirent => dirent.name)

    const {version} = await inquirer.prompt<{ version: string }>({
        type: 'list',
        name: 'version',
        choices: versionNames,
        message: 'Choose the version'
    })


    const versionDir = `${distRoot}/${version}`;

    const artifacts = (await readdir(versionDir, {withFileTypes: true})).filter(dirent => !dirent.isDirectory() && dirent.name.endsWith('.dmg'))


    if (artifacts.length === 1) {
        return {artifactPath: path.resolve(`${versionDir}/${artifacts[0].name}`), version}
    }

    const {artifactName} = await inquirer.prompt<{ artifactName: string }>({
        type: 'list',
        name: 'artifactName',
        choices: artifacts.map(a => a.name),
        message: 'Choose artifact'
    })

    return {artifactPath: path.resolve(`${versionDir}/${artifactName}`), version}
}

export async function promptConfirm(message: string) {
    const answers = await inquirer.prompt<{ confirm: boolean }>([{
        type: 'confirm', name: 'confirm', message: message
    }])
    return answers.confirm;
}

