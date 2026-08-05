@echo off
REM Graphify - incrementele, code-only update voor de Leerling-app (lib + supabase).
REM Gebruikt uitsluitend het officiele "graphify update" commando van de lokaal geinstalleerde
REM versie (AST re-extractie, GEEN LLM / semantische heranalyse). Bouwt geen nieuwe volledige graph.
REM Zie: graphify --help  ->  "update <path>  re-extract code files and update the graph (no LLM needed)"

setlocal

set "PYTHON_EXE=C:\Users\zaurs\AppData\Local\Programs\Python\Python312\python.exe"
set "PROJECT_ROOT=C:\Users\zaurs\Documents\ZaurProject\Leerling"
set "GRAPH_JSON=%PROJECT_ROOT%\graphify-out\graph.json"

if not exist "%PYTHON_EXE%" (
    echo [graphify update] FOUT: Python executable niet gevonden: %PYTHON_EXE% 1>&2
    exit /b 3
)

echo [graphify update] Leerling: incrementele code-only update wordt gestart...
"%PYTHON_EXE%" -m graphify update "%PROJECT_ROOT%"
if errorlevel 1 (
    echo [graphify update] FOUT: "graphify update" is mislukt of had niets te updaten. 1>&2
    exit /b 1
)

echo [graphify update] graph.json valideren...
"%PYTHON_EXE%" -c "import json,sys; d=json.load(open(r'%GRAPH_JSON%',encoding='utf-8')); n=len(d.get('nodes',[])); l=d.get('links',d.get('edges',[])); e=len(l); print(f'OK: {n} nodes, {e} edges'); sys.exit(0 if n>0 else 1)"
if errorlevel 1 (
    echo [graphify update] FOUT: graph.json is leeg of ongeldig na de update. 1>&2
    exit /b 2
)

echo [graphify update] Klaar. Herstart/herlaad de MCP-server (graphify-leerling) als de wijziging niet live zichtbaar is.
exit /b 0
