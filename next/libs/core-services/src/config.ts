export const config = {
    baseApiUrl: process.env.NODE_ENV === 'development' ? 'http://localhost:8000' : 'https://bpj.org.uk/api/public/index.php'
}