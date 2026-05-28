const DEFAULT_AES_KEY_HEX = "bf76c74c23bd93c4016a2a0be4213f63";

const LICENCES = {
  "GMVMOBA-BINHBUN": {
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
      const licenceKey = "GMVMOBA-BINHBUN";
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
      {"x1":"Qa4FAHW6/O+d+pAD/5XLcRBUou7KrbQdSeM9xOhndmn+gWCPLxC0vOZqFyN+Dkc7lB6hes+hanrUuj1y2o6HmZ5c8nL+MQnPX7q5nnQ7mUvAm+RlsV1pkCekm1HLmYEoLeIgyVDRdoM/c2FKcwWHMZIV4/mM37LmhOv9RtEbjikEN07os1gxFAkSW0PAU/5WLotT+LxJ6C5cUDpM6jzRUblWPr1EIzEIHVhbeWFkB24toqtyXrpFMonK3CBkxm50PCiOU/SUtJcI424F8XIEjoN2pxcRivl20m83n6srO/Nd/BctDrYDCWvSAOFcWoi7/QraDTwQasnt0TsH1MBFVQ1dmH4U1lHFYg1Mu/NNlBU=",x2:"sttWM5uiZq0yljUZnJT/4WhiEnRnyLIqTgMI3eyCXR//I20RRCZRTGkq2S4EXRx75hkAx8hSSJMURaW9CAG526YmsSvXQi/fX/RBsD0Lb0HpPu3zHnIogwN5ouGCBmiFNBMr/MSgc86Qc2VRBaUxalcZFRZJgpcN2g68uraw+Bg=",x3:"ee075bb2c661163f9062997d2a73dff8",x4:"BgmcA0UhlNTugkoGp52d5dxZGZCBv6pCpmgFLjUHM3Xg8QHdDCltFdlggaeI8c1FmyCyz/rrYM5RrjA6NBuWSyecCgF67A72DukXFsM99iSWnR+JGnsrVYnOchLSzBrwyNgDBSNr0ghq8eyHazBt56epaCSgbQwo/Eg0Qh4G5x0=","timestamp":liveTimestamp}
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
      {"x1":"86+ldMKthlXgHUCCeCLNGonHBKwouOWLfywX+IZOyXVS9vr9DIny/sNaZVHG0XU0xeKYeHCWFT3M7xltbA+FjnbRC1p9rndXW2bX+O7ujJkInJmA8h3ovCYgOLU9xO3mVIKDMfYMj91mMtFHmZDtmYIjnjh7ZFeJAyJVyij30ZpT7igKOrtzeSj3ly/+Qso72DO3efCeJy3YVqZ2gp6TUzZ1cDOSTM6Xr3SB5XCsk9SHXXnEnhbjztFzApPj4IM14nKYiooB/xmokQPdev5eR6Yb6kILmzfwh6xpYsxqo2t2EmOnX5fyX+LoNNDL0puPatZrO7D+QDc1Ko9X4dZi8/kFoahhfFx9YF1ZsUzVFU2t52IkxcigEOfVnKgsYRbp8hP4dHMN6pLiJu92IHg6koV5CypYPdNblQBmxPhtBuxe0FbQ/zWDV0jzcoWqfLpiPmQOlWq76sSNcMkCcJzGPHmQYYpwdHn+tjwB3MctwB6cUm/gSBC0IZFi4xhxL2aMHUIkzgnxgoRSuoLQZ0aMrRE7EefmCW6eNhZHC3yrXRKmvB/N0wcKb9XUBTAx3kCLm/fGpnevzsgS3PefM5yBAA==",x2:"BUAhv0gFRRgfbNNH/lm9qXDwM5LPkRLCDE43LMU1Mkg0d9JZ51GuotpDwA2UQlsTrT4KNq9Vtf3cI+I3vJ9F2QWNYTCvykr1JB3aRzNoolsIu/wJ1BY08oWmM+KVsoFXByG8qqY+XqncIVsYhb+44oZWrFFwOJKxQvBGulp0sQ4=",x3:"0fdab70564f0382fce03a47c33d32d8a",x4:"yD+sSVQDYbhGrlIwFJSA1udo4BlO1kA1lBMvU6hHwj88fXGJGtFbsjCPDjdqhbl0b7ODjoIHv0iZHno4/iOFZfpaOf/RbLOaM8VDnik2CPZCyxFfqw/wUtn+HTNplQvGIZFrvWIncpx989YzvcMF7TVUk0hWF3Wt4mP/++QRges=","timestamp":liveTimestamp}

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
