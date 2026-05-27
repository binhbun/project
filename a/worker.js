const AES_KEY_HEX = "683448516e3041376b464e367870796445434556703348356f4363316b463670";
const te = new TextEncoder();

function bytesToBase64(buf) {
  let bin = "";
  for (const b of buf) bin += String.fromCharCode(b);
  return btoa(bin);
}

async function importAesKey() {
  const raw = new Uint8Array(AES_KEY_HEX.match(/.{1,2}/g).map(b => parseInt(b, 16)));
  return crypto.subtle.importKey("raw", raw, { name: "AES-CBC" }, false, ["encrypt", "decrypt"]);
}

function pkcs7Pad(buf) {
  const padLen = 16 - (buf.length % 16);
  const out = new Uint8Array(buf.length + padLen);
  out.set(buf);
  out.fill(padLen, buf.length);
  return out;
}

async function aesEcbEncrypt(plaintext) {
  const key = await importAesKey();
  const padded = pkcs7Pad(plaintext);
  const out = new Uint8Array(padded.length);
  const zeroIV = new Uint8Array(16);
  
  for (let i = 0; i < padded.length; i += 16) {
    const block = padded.slice(i, i + 16);
    const enc = await crypto.subtle.encrypt({ name: "AES-CBC", iv: zeroIV }, key, block);
    out.set(new Uint8Array(enc).slice(0, 16), i);
  }
  return out;
}

export default {
  async fetch(request) {
    if (request.method === "OPTIONS") return new Response(null, { status: 204 });
    if (request.method !== "POST") return new Response("Method not allowed", { status: 405 });

    const url = new URL(request.url);
    const path = url.pathname;
    const liveTimestamp = Date.now();
    

    if (path === "/v4/client/package-v3") {

      const packagePayload = 
      {x1:"A6BDmVf6vFLNVziqZHKguD+a7Vl8w1JALwsNlPgfDvmOB9/9/LQW5B8dDmmbqmTaaA4hK+U5CM3OIK9PLtXWrKT5d0XkHVgicLcJmg01Ax0w4vZtm21UCO/1fLtOcw0LS8RrWlCHRZ+FV3aK4olucPiTHTRU/1ac1PNpKgubCUHQeP7pXPUdXrJMjGVj428JZ1+JydcDLLQ/ENz+CehMfsoK8evBHzco1hcpguD4bzFNsqQP8q67DiBmV+fp95EbAg5NYP5ssS0XN3qGbHkJjkzwVt3uReRkbe1B/uLSXkScExIq/RFJ/GvsvpPkxlccmi43/l0H4oKiV2V/ulNbaE73/kxHyjFRBWuRiH2jDWDO9Hepkkcnok0tfxF8mOJ6SXVW13lpLV7nJWlN8+4v40IjoNOEtc5lCZLHEf3YGKHgo8DC8KWQjUgMROyHLBAvCdhjmumCjDXvADRDcrkqAw==",x2:"TG879uhsSF38iIfYKULFAj7Kv7HEqjk2PJOqu3kFKpwY8qd1OzGLXoqlUS+px83lZQEwcMwue5zWCCl75Yf5aPw9O6AwwpGC2tN4sI+YBplMfhtqF7bS5rYJ9r3UaJJYWW3POqN9mRnLLXrZjsVw52RP2YzGkLiBSVWh/PsQil0=",x3:"cc84c7d6d138aa73d63d1429ee97535e",
        x4:"1NA5H1Sn5xBdv914nmyRQaq3Csb9tWl6fjkLxuyfX+8GESywbTqIbjDPfGdx2fa35h8Acf23NMOlyCC+aKpf2cdqm7RU+G7s/TQ14Oacxqy6oS8MoIR4S+vqvTPSsqIVi0JyeU68+K4MK597KV6z/Fa9mxcK9+m28GJp0n+zgUY=",timestamp:liveTimestamp}

      const outerBytes = te.encode(JSON.stringify(packagePayload));
      const outerEnc = await aesEcbEncrypt(outerBytes);
      const responseBody = bytesToBase64(outerEnc);

      return new Response(responseBody, {
        status: 200,
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          "access-control-expose-headers": "token",
          "s": "ipoxJbnvZi2SxAhcVUXfX63/Yb2kvjESP8SQ2vDaz8DGGP4OzkPYeQA2qq1JmJeZoVDW1m00MFuwnCc1krQxQTl94ecfU57kBsFssyZ+7DL9AosML+jeybA08rdnDFwsf0xtMT9DxXLtHesw1UNUbZPN/rhv6aeeHb87daJTbGw=",
          "etag": 'W/"42c-OkvPTBGYnDHtqbNcyqP57B62194"',
          "vary": "Accept-Encoding, Origin"
        }
      });
    }


    if (path === "/v4/client/credential-v3") {
      const credentialPayload = 
      {x1:"kV8JGmV4Ipn/fDGsmzyVzBEe022R8KxxwShEaPmyIBp6SjXcsl+6Hta18TgO+jcH5LaL2jxxT+dG88hyi9AsIy/Mcfjbc9dQxYMfDh01DgeM9fk7p3LKe+diW7svQtPIFshKwdS8X3QEVPO/dtj/rmiDqJhKdg99kjyg+1oDqwgZu4ulLZJqcbwfOrom8bNMJRv2rg8Ax1PVzYq7CRAgzYuGEKWE0+FvL/g2BYv2HT5GZnPcj9Zitp8f/YQ8p6F09uXMSpxoIOqZeizae6+4PfLD1LKPi6hiq2EQeG88hXdjg8FY43AARfR4OmL+XGx75e1LRLnRcCB7ru3jZP8CNGtP8zZkt4g5iB5+P6NQjvCxJbKbc42CFisSmCZS4ytB4eghJ6w2OoKUIhVzQqfMacj+lfF68WdDrko8GGAJN+U=",x2:"I1U370M1chj4zGd5y5jLeHXdm5FPf3sLx0JU3TcLbpqP4jdPU8/7CmoxfBSTr0tfTDHXdxWo3eaO8EXxZLQs3d+GrxhWzUONr6wxivhT3IcGK55KaHzMFBfXh5hLMPw1sYeyIb6mDBupQuJhF5QslQ3AcW4kyFDMToRzZfQ5T/w=",x3:"2bb5cd988b6a51060f720fa4c2d7c8a5",x4:"yCwS53ItQL0TBigFRi3e5ydEuCy2iqscJ7H1IjMoFLWEo7hyYwGuV993Fil+3OO5bIKStyfbl9bHnZbeFkb9aBIkxJZIewgoWjnmsMeePsrJDPq6qTblJT3KQxDnNsz7l0CsuYWUoh7U9nrVO+5SmfhRa3DURyylXpjbIVoev5k=",timestamp:liveTimestamp}

      const outerBytes = te.encode(JSON.stringify(credentialPayload));
      const outerEnc = await aesEcbEncrypt(outerBytes);
      const responseBody = bytesToBase64(outerEnc);

      return new Response(responseBody, {
        status: 200,
        headers: {
          "Content-Type": "text/html; charset=utf-8",
          "access-control-expose-headers": "token",
          "s": "ZXxQ5dQQn8Ie74SJlZMCrHU3ryH2m/tmEVp7Sl/6GLXOTz1QP4D6Xj5tJfTtY5IdEGbl98pDFoAYSjgfqkxt+rpZmZXh1CSdts5wVWrvFgFBFHQyD+wlDt0siKPqb3uFHIDmb/Ojth0C0q2o66uo5rBmO1/s1GuNTQfsm5vSXdY=",
          "etag": 'W/"42c-OkvPTBGYnDHtqbNcyqP57B62194"',
          "vary": "Accept-Encoding, Origin"
        }
      });
    }

    return new Response("Not found", { status: 404 });
  }
};




const DEFAULT_AES_KEY_HEX = "bf5135f9b4b0c0ad711907a0947b486e";

const LICENCES = {
  "NgocBongGaming-day-4zy8KzsZpmaqFlin": {
    isExpired : false,
    expiredAt : "9999-01-01T06:41:57.000Z",
    status    : 1,
  },
};

const SECURITY_HEADERS = {
  "content-security-policy":
    "default-src 'self';" +
    "base-uri 'self';" +
    "font-src 'self' https: data:;" +
    "form-action 'self';" +
    "frame-ancestors 'self';" +
    "img-src 'self' data:;" +
    "object-src 'none';" +
    "script-src 'self';" +
    "script-src-attr 'none';" +
    "style-src 'self' https: 'unsafe-inline';" +
    "upgrade-insecure-requests",
  "cross-origin-embedder-policy"     : "require-corp",
  "cross-origin-opener-policy"       : "same-origin",
  "cross-origin-resource-policy"     : "same-origin",
  "origin-agent-cluster"             : "?1",
  "referrer-policy"                  : "no-referrer",
  "x-content-type-options"           : "nosniff",
  "x-dns-prefetch-control"           : "off",
  "x-download-options"               : "noopen",
  "x-frame-options"                  : "SAMEORIGIN",
  "x-permitted-cross-domain-policies": "none",
  "x-xss-protection"                 : "0",
  "cf-cache-status"                  : "DYNAMIC",
  "access-control-expose-headers"    : "token",
  "vary"                             : "Origin",
};

function isValidEncryptedToken(token) {
  if (typeof token !== "string" || token.length === 0) return false;
  try {
    const bin = atob(token);
    return bin.length > 0 && bin.length % 16 === 0;
  } catch {
    return false;
  }
}

async function importAesKey(hexKey) {
  const raw = new TextEncoder().encode(hexKey);
  return crypto.subtle.importKey("raw", raw, { name: "AES-CBC" }, false, ["encrypt", "decrypt"]);
}

function pkcs7Pad(buf) {
  const padLen = 16 - (buf.length % 16);
  const out = new Uint8Array(buf.length + padLen);
  out.set(buf);
  out.fill(padLen, buf.length);
  return out;
}

function pkcs7Unpad(buf) {
  const padLen = buf[buf.length - 1];
  if (padLen < 1 || padLen > 16) throw new Error("Invalid PKCS7 padding");
  return buf.slice(0, buf.length - padLen);
}

async function aesEcbEncrypt(keyHex, plaintext) {
  const key    = await importAesKey(keyHex);
  const padded = pkcs7Pad(plaintext);
  const out    = new Uint8Array(padded.length);
  const zeroIV = new Uint8Array(16);

  for (let i = 0; i < padded.length; i += 16) {
    const enc = await crypto.subtle.encrypt(
      { name: "AES-CBC", iv: zeroIV },
      key,
      padded.slice(i, i + 16)
    );
    out.set(new Uint8Array(enc).slice(0, 16), i);
  }
  return out;
}

async function aesEcbDecrypt(keyHex, ciphertext) {
  const key    = await importAesKey(keyHex);
  const out    = new Uint8Array(ciphertext.length);
  const zeroIV = new Uint8Array(16);

  for (let i = 0; i < ciphertext.length; i += 16) {
    const block = ciphertext.slice(i, i + 16);

    const padXorBlock = new Uint8Array(16);
    for (let j = 0; j < 16; j++) padXorBlock[j] = 0x10 ^ block[j];

    const dummyBlock = new Uint8Array(
      await crypto.subtle.encrypt({ name: "AES-CBC", iv: zeroIV }, key, padXorBlock)
    ).slice(0, 16);

    const twoBlocks = new Uint8Array(32);
    twoBlocks.set(block, 0);
    twoBlocks.set(dummyBlock, 16);

    const dec = await crypto.subtle.decrypt(
      { name: "AES-CBC", iv: zeroIV },
      key,
      twoBlocks,
    );
    out.set(new Uint8Array(dec).slice(0, 16), i);
  }
  return pkcs7Unpad(out);
}

function bytesToBase64(buf) {
  let bin = "";
  for (const b of buf) bin += String.fromCharCode(b);
  return btoa(bin);
}

function base64ToBytes(b64) {
  const bin = atob(b64);
  const arr = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}

const te = new TextEncoder();
const td = new TextDecoder();

/**
 * Xáo trộn thứ tự field của object — giống App 1.
 * Mỗi lần JSON.stringify ra chuỗi khác → block đầu ECB khác → toàn bộ cipher khác.
 */
function shuffleObject(obj) {
  const keys = Object.keys(obj);
  // Fisher-Yates shuffle dùng crypto random
  const rnd = crypto.getRandomValues(new Uint8Array(keys.length));
  for (let i = keys.length - 1; i > 0; i--) {
    const j = rnd[i] % (i + 1);
    [keys[i], keys[j]] = [keys[j], keys[i]];
  }
  const shuffled = {};
  for (const k of keys) shuffled[k] = obj[k];
  return shuffled;
}

async function encryptResponse(keyHex, obj) {
  const shuffled = shuffleObject(obj);
  const cipher   = await aesEcbEncrypt(keyHex, te.encode(JSON.stringify(shuffled)));
  return bytesToBase64(cipher);
}

async function decryptPayload(keyHex, b64) {
  const plain = await aesEcbDecrypt(keyHex, base64ToBytes(b64));
  return JSON.parse(td.decode(plain));
}

async function computeEtag(body) {
  const digest = await crypto.subtle.digest("SHA-1", te.encode(body));
  const b64    = bytesToBase64(new Uint8Array(digest)).replace(/=+$/, "");
  return `W/"${body.length.toString(16)}-${b64}"`;
}

async function json(obj, status = 200) {
  const body = JSON.stringify(obj);
  const etag = await computeEtag(body);

  return new Response(body, {
    status,
    headers: {
      "Content-Type"             : "application/json; charset=utf-8",
      ...SECURITY_HEADERS,
      "strict-transport-security": "max-age=15552000; includeSubDomains",
      "etag"                     : etag,
    },
  });
}

export default {
  async fetch(request, env) {
    const KEY_HEX = env.AES_KEY_HEX || DEFAULT_AES_KEY_HEX;
    const method  = request.method;
    const path    = new URL(request.url).pathname;

    if (method === "OPTIONS") {
      return await json({ error: "Not found" }, 404);
    }

    if (method !== "POST") {
      return await json({ error: "Method not allowed" }, 405);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return await json({ error: "Invalid JSON body" }, 400);
    }

    // ── POST /public/v1/client/package ────────────────────────────────────────
    if (path === "/public/v1/client/package") {
      const { token } = body;

      if (!token) {
        return await json({ error: "Missing token" }, 400);
      }

      if (!isValidEncryptedToken(token)) {
        return await json({ error: "Invalid token format" }, 403);
      }
      
      const data = await encryptResponse(KEY_HEX, {
        requestTime       : Date.now(),
        name              : "Delta VNG & Skibx VNG",
        updateNote        : "",
        downloadUpdateLink: "",
        isNeedKey         : true,
        status            : 1,
        version           : "1.1.8",
        contactUrl        : "",
      });

      return await json({ data });
    }

    // ── POST /public/v1/client/check ──────────────────────────────────────────
    if (path === "/public/v1/client/check") {
      const { token, data } = body;

      if (!token || !data) {
        return await json({ error: "Missing token or data" }, 400);
      }

      if (!isValidEncryptedToken(token)) {
        return await json({ error: "Invalid token format" }, 403);
      }

      let deviceInfo;
      try {
        deviceInfo = await decryptPayload(KEY_HEX, data);
      } catch (e) {
        return await json({ error: "Invalid encrypted payload: " + e.message }, 400);
      }

      const { uid } = deviceInfo;
      if (!uid) {
        return await json({ error: "Missing uid in device info" }, 400);
      }
      const licenceKey = "NgocBongGaming-day-4zy8KzsZpmaqFlin";
      const licence    = LICENCES[licenceKey];

      const encrypted = await encryptResponse(KEY_HEX, {
        requestTime: Date.now(),
        isExpired  : licence.isExpired,
        expiredAt  : licence.expiredAt,
        status     : licence.status,
        key        : licenceKey,
      });

      return await json({ data: encrypted });
    }

    // ── POST /debug/encrypt ───────────────────────────────────────────────────
    if (path === "/debug/encrypt") {
      const { plain } = body;
      if (plain === undefined) return await json({ error: "Missing plain" }, 400);
      const obj  = typeof plain === "string" ? { value: plain } : plain;
      const data = await encryptResponse(KEY_HEX, obj);
      return await json({ data });
    }

    // ── POST /debug/decrypt ───────────────────────────────────────────────────
    if (path === "/debug/decrypt") {
      const { data } = body;
      if (!data) return await json({ error: "Missing data" }, 400);
      try {
        const plain = await decryptPayload(KEY_HEX, data);
        return await json({ plain });
      } catch (e) {
        return await json({ error: e.message }, 400);
      }
    }

    return await json({ error: "Not found" }, 404);
  },
};
