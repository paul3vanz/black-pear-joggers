import { useAuth0 } from "@auth0/auth0-react";

export const fetcher = async (url: string) => {
    const accessToken = localStorage.getItem('bpj.token');
   return fetch(url, {
    headers: accessToken && new Headers({
        'Authorization': `Bearer ${accessToken}`
    })
    }).then((res) => {
        const data = res.json();

        return data;
    })
};