const crypto = require('crypto');
const dotenv = require('dotenv');

dotenv.config();

const algorithm = 'aes-256-cbc';
const key = Buffer.from(process.env.AES_KEY || '0123456789abcdef0123456789abcdef', 'utf8');

function encrypt(text) {
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  const encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);
  return `${iv.toString('hex')}:${encrypted.toString('hex')}`;
}

function decrypt(text) {
  const [ivHex, encryptedHex] = text.split(':');
  const iv = Buffer.from(ivHex, 'hex');
  const encrypted = Buffer.from(encryptedHex, 'hex');
  const decipher = crypto.createDecipheriv(algorithm, key, iv);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  return decrypted.toString('utf8');
}

module.exports = { encrypt, decrypt };
