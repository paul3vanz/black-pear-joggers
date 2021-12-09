export const fetcher = async (url: string) => {
    const accessToken = localStorage.getItem('bpj.token');

    return fetch(url, {
        headers: accessToken && new Headers({
            'Authorization': `Bearer ${accessToken}`
        })
    }).then((res) => {
        const data = res.json();

        return data;
    });
};

export function post(url: string, data?: {}) {
    const accessToken = localStorage.getItem('bpj.token');

    return fetch(url, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
        body: data && JSON.stringify(data),
    });
}