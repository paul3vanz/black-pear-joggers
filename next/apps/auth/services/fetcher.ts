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

export function post(url: string, data?: {}, method = 'POST') {
    const accessToken = localStorage.getItem('bpj.token');

    return fetch(url, {
        method,
        headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
        body: data && JSON.stringify(data),
    });
}

export function remove(url: string) {
    return post(url, null, 'DELETE');
}