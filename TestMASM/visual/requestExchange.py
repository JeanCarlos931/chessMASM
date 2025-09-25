# requestExchange.py
from pathlib import Path
import xml.etree.ElementTree as ET
from playwright.sync_api import sync_playwright

INDEX_URL = "https://www.sucursalelectronica.com/exchangerate/index.html"
XML_URL   = "https://www.sucursalelectronica.com/exchangerate/showXmlExchangeRate.do"

OUT_DIR = Path("data")
LOGS_DIR = Path("logs")
OUT_DIR.mkdir(exist_ok=True)
LOGS_DIR.mkdir(exist_ok=True)

OUT_FILE = OUT_DIR / "tipocambio.txt"
RAW_FILE = LOGS_DIR / "response_raw.txt"

UA = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/124.0.0.0 Safari/537.36"
)

def parse_and_format(xml_text: str) -> str:
    """
    Busca <country><name>Costa Rica</name> y devuelve:
    buyRateUSD saleRateUSD buyRateEUR saleRateEUR
    (formato separado por espacios, sin caracteres especiales)
    """
    root = ET.fromstring(xml_text.strip())
    for country in root.findall("country"):
        name = (country.findtext("name") or "").strip()
        if name.lower() == "costa rica":
            buy_usd  = (country.findtext("buyRateUSD")  or "").strip()
            sale_usd = (country.findtext("saleRateUSD") or "").strip()
            buy_eur  = (country.findtext("buyRateEUR")  or "").strip()
            sale_eur = (country.findtext("saleRateEUR") or "").strip()

            def norm(x: str) -> str:
                return x.replace(" ", "").replace(",", ".")
            return f"{norm(buy_usd)} {norm(sale_usd)} {norm(buy_eur)} {norm(sale_eur)}"
    raise ValueError("No se encontró el país 'Costa Rica' en el XML.")

def main():
    print("[INFO] Abriendo navegador (Playwright)...")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(
            user_agent=UA,
            locale="es-CR",
            # extra headers útiles para WAF/CDN
            extra_http_headers={
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Cache-Control": "no-cache",
                "Pragma": "no-cache",
            },
        )
        page = ctx.new_page()

        # 1) Visitar la página índice para obtener cookies y contexto
        print("[INFO] Cargando index.html para establecer cookies...")
        page.goto(INDEX_URL, wait_until="networkidle", timeout=30000)

        # Pausa corta por si hay scripts de inicialización
        page.wait_for_timeout(700)

        # 2) Hacer fetch del XML desde el contexto del navegador (mismo origen)
        print("[INFO] Solicitando XML con fetch (mismo origen)...")
        result = page.evaluate(
            """async (url) => {
                try {
                  const r = await fetch(url, {
                    method: 'GET',
                    headers: {
                      'accept': 'application/xml,text/xml;q=0.9,*/*;q=0.8',
                      'cache-control': 'no-cache',
                      'pragma': 'no-cache'
                    },
                    credentials: 'include' // incluye cookies del mismo origen
                  });
                  const status = r.status;
                  const ct = r.headers.get('content-type') || '';
                  const text = await r.text();
                  return { ok: r.ok, status, ct, text };
                } catch (e) {
                  return { ok: false, status: 0, ct: '', text: String(e) };
                }
            }""",
            XML_URL,
        )

        status = result.get("status")
        ct     = (result.get("ct") or "").lower()
        body   = result.get("text") or ""

        RAW_FILE.write_text(body, encoding="utf-8", errors="ignore")
        print(f"[INFO] HTTP {status} CT={ct}")
        print(f"[INFO] Respuesta guardada en {RAW_FILE}")

        # 3) Validaciones: debe venir XML o, al menos, un documento que empiece con '<'
        looks_like_xml = body.strip().startswith("<") and ("exchangeRates" in body)
        ct_is_xml = ("xml" in ct)

        if not (ct_is_xml or looks_like_xml):
            # Es HTML (403/anti-bot) u otra cosa; no intentes parsear como XML
            preview = body[:300].replace("\n", " ")
            raise RuntimeError(
                "El servidor no devolvió XML (posible 403 o challenge). "
                f"CT={ct} Status={status}. Preview: {preview}"
            )

        # 4) Parsear y escribir archivo para MASM
        print("[INFO] Parseando XML...")
        line = parse_and_format(body)
        OUT_FILE.write_text(line, encoding="ascii", errors="ignore")
        print(f"[OK] Archivo escrito: {OUT_FILE} -> {line}")

        browser.close()

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"[ERROR] {e}")
        raise
