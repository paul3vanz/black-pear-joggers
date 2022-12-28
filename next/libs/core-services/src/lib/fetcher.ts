interface HttpError extends Error {
    status?: number;
}

export const fetcherConfig = {
    revalidateIfStale: false,
    revalidateOnFocus: false,
    revalidateOnReconnect: false,
    onErrorRetry: (error: any) => {
        if (error.status === 404) {
            return;
        }
    }
};

export const fetcher = async (url: string) => {
    const accessToken = localStorage.getItem('bpj.token');

    return fetch(url, {
        headers: accessToken ? new Headers({
            'Authorization': `Bearer ${accessToken}`
        }) : undefined
    }).then(async (response) => {
        if (!response.ok) {
            throw new Error(response.status.toString());
        }

        return response.json();
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
    return post(url, undefined, 'DELETE');
}