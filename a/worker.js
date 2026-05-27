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