import FormData from "form-data"
import axios, {AxiosError} from 'axios';
import * as fs from "fs";
import path from "path";
import qs from "qs";
import dotenv from "dotenv";

dotenv.config();

/**
 * Use this file by calling the upload function with the path to the DMG to upload to kandji.
 * @example upload('~/Downloads/my-file.dmg')
 */



const kandji_domain = "https://thelangstonco.api.kandji.io"
const fetch_app_id = '4e24d169-a521-4b8c-ac10-08301787231a'
const fetch_beta_app_id = 'dc00c48f-194e-4108-9eb6-5ce2551105ef'
type SignedUrl = {
    name: string,
    expires: string,
    post_url: string,
    post_data: {
        "key": string,
        "x-amz-algorithm": string,
        "x-amz-credential": string,
        "x-amz-date": string,
        "x-amz-security-token": string,
        "policy": string,
        "x-amz-signature": string,
    },
    file_key: string;
}

type Page<T = any> = { results: T[], count: number, next: string | null, previous: string | null }
type CustomApp = {
    id: string,
    name: string,
    active: boolean,
    install_once: boolean;
    audit_script: string | null,
    install_type: string,
    unzip_location: string;
    preinstall_script: string;
    restart: boolean;
    file: string;
    file_url: string;
    sha256: string;
    file_size: number;
    file_updated: string;
    created_at: string;
    updated_at: string;
    file_key: string;
}

export async function listApps() {
    const response = await fetch(`${kandji_domain}/api/v1/library/custom-apps`, {headers: {Authorization: `Bearer ${process.env.KANDJI_API_TOKEN}`}})
    if (!response.ok) {
        console.log(`${response.status}: ${response.statusText}`);
        const body = await response.text();
        console.log(body)
        throw new Error('Invalid response')
    }
    const page = await response.json() as Page<CustomApp>;
    console.table(page.results, ["id", "name", "file_key"])
}

async function uploadToS3({filepath, signedUrl}: { filepath: string, signedUrl: SignedUrl }) {
    const fileFormData = new FormData();
    fileFormData.append('key', signedUrl.file_key)
    fileFormData.append("x-amz-algorithm", signedUrl.post_data["x-amz-algorithm"]);
    fileFormData.append("x-amz-credential", signedUrl.post_data["x-amz-credential"]);
    fileFormData.append("x-amz-date", signedUrl.post_data["x-amz-date"]);
    fileFormData.append("x-amz-security-token", signedUrl.post_data["x-amz-security-token"]);
    fileFormData.append("policy", signedUrl.post_data["policy"]);
    fileFormData.append("x-amz-signature", signedUrl.post_data["x-amz-signature"]);
    fileFormData.append("file", fs.createReadStream(filepath))

    console.log(`attempting to upload file to ${signedUrl.post_url}`)

    const response = await axios({
        url: signedUrl.post_url,
        method: 'post',
        headers: {...fileFormData.getHeaders()},
        data: fileFormData,
        maxBodyLength: Infinity,
    });

    console.log(`Upload result ${response.status}: ${response.statusText}`)


    console.log(JSON.stringify(response.data, null, 2))
}

export function isAxiosError(error: any): error is AxiosError {
    return !!(error as AxiosError)?.isAxiosError;

}

export async function Timeout(durationMs: number) {
    return new Promise<void>((resolve) => {
        setTimeout(() => {
            resolve();
        }, durationMs)
    })
}

export async function updateCustomApp(signedUrl: Pick<SignedUrl, 'file_key'>, APP_ID: string, attempt: number = 0) {
    const timeoutDuration = 5_000;
    const data = qs.stringify({file_key: signedUrl.file_key})

    console.log();
    console.log(`[Attempt ${attempt}] Update app via PATCH to ${kandji_domain}/api/v1/library/custom-apps/${APP_ID}`)
    console.log("PATCH params", data)

    if (attempt > 10) {
        throw new Error('Unable to verify updated app after 10 attempts. Exiting')
    }

    const url = `${kandji_domain}/api/v1/library/custom-apps/${APP_ID}`;
    try {
        const response = await axios({
            url,
            maxBodyLength: Infinity,
            method: 'patch',
            data,
            headers: {
                'Authorization': `Bearer ${process.env.KANDJI_API_TOKEN}`
                // Note: the API docs say to use Content-Type: multipart/form-data, but this fails with 400 bad request.
            },
        })

        const updatedApp = response.data;
        console.log(`PATCH to update custom app returned successfully with status ${response.status}: ${response.statusText}`)
        console.log(JSON.stringify(updatedApp, null, 2))
    } catch (error) {
        if (isAxiosError(error) && error.response) {
            const data = error.response.data as Partial<{ detail: string }> | undefined
            console.log(`Handling axios error. Status=${error.response.status}. Detail="${data?.detail ?? '(unknown)'}"`)
            if (data?.detail?.includes('still being processed') && error.response.status === 503) {
                console.log(`Upload is still processing...`)
                process.stdout.write(`Retrying in  ${(timeoutDuration / 1000).toFixed(1)} seconds.`)
                const interval = setInterval(() => {
                    process.stdout.write('.')
                }, 500 )
                await Timeout(timeoutDuration);
                clearInterval(interval)
                return updateCustomApp(signedUrl, APP_ID, attempt + 1)
            }
            else {
                console.error('Unhandled axios error');
                throw error;
            }
        } else {
            console.error('Failed to update app');
            throw error;
        }
    }

}

export function getAppId(beta?: boolean) {
    return beta ? fetch_beta_app_id : fetch_app_id;
}

type UploadOptions = { beta: boolean; }

export async function upload(dmgFilepath: string, options?: Partial<UploadOptions>) {
    const {beta = false} = options ?? {}

    if (!fs.existsSync(dmgFilepath)) {
        throw new Error(`File does not exists: ${dmgFilepath}`)
    }

    const APP_ID = getAppId(beta)
    console.log(`Uploading ${beta ? 'beta' : 'prod'} app to Kandji from ${dmgFilepath}`)
    console.log('Getting upload info from Kandji...')
    const filename = path.basename(dmgFilepath)
    const urlencoded = new URLSearchParams();
    urlencoded.append("name", filename);

    const headers = new Headers();
    headers.append('Authorization', `Bearer ${process.env.KANDJI_API_TOKEN}`)
    const requestOptions: RequestInit = {
        method: 'POST',
        body: urlencoded,
        redirect: 'follow',
        headers
    };


    const signedUrlResponse = await fetch(`${kandji_domain}/api/v1/library/custom-apps/upload`, requestOptions)


    if (!signedUrlResponse.ok) {
        const body = await signedUrlResponse.text()
        console.error(`${signedUrlResponse.status}: ${signedUrlResponse.statusText}`)
        console.error(body)
        throw new Error("Unable to get upload info from Kandji")
    }

    const signedUrl = (await signedUrlResponse.json()) as SignedUrl;
    console.log('Got signed URL info for uploading new file...', signedUrl.file_key)
    console.table([signedUrl], ['post_url', 'name', 'file_key'])

    await uploadToS3({filepath: dmgFilepath, signedUrl})

    await updateCustomApp(signedUrl, APP_ID)

    await listApps();
}



