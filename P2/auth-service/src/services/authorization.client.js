async function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function getRetryConfig() {
  const maxRetries = Number(process.env.MAX_RETRIES || 3);
  const backoff = Number(process.env.RETRY_BACKOFF || 300);

  return {
    maxRetries: Number.isFinite(maxRetries) && maxRetries > 0 ? maxRetries : 3,
    backoff: Number.isFinite(backoff) && backoff >= 0 ? backoff : 300,
  };
}

async function authorizeWithRetry({ role, requiredRole }) {
  const serviceUrl = process.env.AUTH_SERVICE_URL || 'http://localhost:3002';
  const { maxRetries, backoff } = getRetryConfig();
  let lastError = null;

  for (let attempt = 1; attempt <= maxRetries; attempt += 1) {
    try {
      const response = await fetch(`${serviceUrl}/authorize`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ role, requiredRole }),
      });

      if (!response.ok) {
        throw new Error(`Authorization service returned ${response.status}`);
      }

      const data = await response.json();
      return data.allowed === true;
    } catch (error) {
      lastError = error;

      if (attempt < maxRetries) {
        await wait(backoff * attempt);
      }
    }
  }

  
  throw lastError || new Error('Authorization service unavailable');
}

module.exports = { authorizeWithRetry };