import {getAppId, updateCustomApp} from "./upload";

async function start() {
    const file_key = 'companies/companies/55f5677f-a28e-4d8a-ab6a-bddda0ab4514/library/custom_apps/Fetch-Beta-v0-1-2_bee2d806.dmg'
    const beta = true;
    const app_id = getAppId(beta)
    await updateCustomApp({file_key}, app_id)
}

start().then(() => console.log("updated file key finished")).catch(console.error)