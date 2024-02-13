import {listApps} from "./upload";
import dotenv from 'dotenv';

dotenv.config();

listApps().then(() => {
    console.log('Done')
}).catch(console.error)