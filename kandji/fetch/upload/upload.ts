import FormData from "form-data"
import axios from 'axios';
import * as fs from "fs";
import path from "path";


const kandji_domain = "https://thelangstonco.api.kandji.io"
const fetch_app_id = '4e24d169-a521-4b8c-ac10-08301787231a'

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

export async function upload(filepath: string) {
    console.log('Getting upload info from Kandji...')
    const filename = path.basename(filepath)
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

    await uploadToS3({filepath, signedUrl})

    const updatePayload = new URLSearchParams();
    updatePayload.append("file_key", signedUrl.file_key);
    const updateResponse = await fetch(`${kandji_domain}/api/v1/library/custom-apps/${fetch_app_id}`, {
        method: 'PATCH',
        headers,
        body: updatePayload,
    })
    if (!updateResponse.ok) {
        console.error(`${updateResponse.status}: ${updateResponse.statusText}`);
        throw new Error('Failed to update Custom App info')
    }
    const updatedApp = await updateResponse.json()
    console.log(`PATCH to update custom app returned successfully with status ${updateResponse.status}: ${updateResponse.statusText}`)
    console.log(JSON.stringify(updatedApp, null, 2))

    console.log(`Update fetch app response`)
    console.log(`${updateResponse.status}: ${updateResponse.statusText}`)

    await listApps();

}