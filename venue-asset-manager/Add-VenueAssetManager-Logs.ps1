$ErrorActionPreference = "Stop"
$Project = "D:\venue-asset-manager"
$Main = Join-Path $Project "src\main.jsx"
$Server = Join-Path $Project "server\server.js"
$Css = Join-Path $Project "src\styles.css"
$LogDir = Join-Path $Project "logs"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"

foreach ($f in @($Main,$Server,$Css)) { if (!(Test-Path $f)) { throw "Required file not found: $f" } }
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
Copy-Item $Main "$Main.before-logs-$Stamp"
Copy-Item $Server "$Server.before-logs-$Stamp"
Copy-Item $Css "$Css.before-logs-$Stamp"

# Backend patch
$js = Get-Content $Server -Raw
if ($js -notmatch "VENUE_ASSET_LOGGING_V1") {
  $anchor = '(?m)^function admin\(req,res,next\)\{[^\r\n]*\}\s*$'
  if ($js -notmatch $anchor) { throw "Could not safely find admin middleware. Backups were created; source files were not patched." }
  $helpers = @'

/* VENUE_ASSET_LOGGING_V1 */
const APP_LOG_DIR = path.resolve(__dirname, '..', 'logs');
fs.mkdirSync(APP_LOG_DIR, { recursive: true });
function writeAppLog(entry) {
  try {
    const day = new Date().toISOString().slice(0,10);
    const file = path.join(APP_LOG_DIR, `venue-asset-manager-${day}.jsonl`);
    const safe = {
      timestamp: new Date().toISOString(),
      source: String(entry?.source || 'backend').slice(0,40),
      level: String(entry?.level || 'error').slice(0,20),
      type: String(entry?.type || 'application').slice(0,80),
      message: String(entry?.message || 'No message').replace(/[\r\n\t]+/g, ' ').slice(0,2000),
      page: String(entry?.page || '').slice(0,300),
      status: Number.isFinite(Number(entry?.status)) ? Number(entry.status) : null,
      stack: String(entry?.stack || '').slice(0,6000)
    };
    fs.appendFileSync(file, JSON.stringify(safe) + '\n', 'utf8');
  } catch (e) { console.error('Unable to write application log:', e?.message || e); }
}
app.post('/api/logs/client', (req,res) => {
  const b = req.body || {};
  writeAppLog({source:'frontend',level:['error','warn','info'].includes(String(b.level))?String(b.level):'error',
    type:b.type,message:b.message,page:b.page,status:b.status,stack:b.stack});
  res.status(204).end();
});
app.get('/api/logs', auth, admin, (req,res) => {
  try {
    const files = fs.readdirSync(APP_LOG_DIR)
      .filter(n => /^venue-asset-manager-\d{4}-\d{2}-\d{2}\.jsonl$/.test(n)).sort().reverse().slice(0,14);
    const entries = [];
    for (const name of files) {
      const rows = fs.readFileSync(path.join(APP_LOG_DIR,name),'utf8').split(/\r?\n/).filter(Boolean);
      for (let i=rows.length-1;i>=0;i--) {
        try { entries.push(JSON.parse(rows[i])); } catch {}
        if (entries.length>=1000) break;
      }
      if (entries.length>=1000) break;
    }
    entries.sort((a,b)=>String(b.timestamp).localeCompare(String(a.timestamp)));
    res.json({entries:entries.slice(0,1000)});
  } catch(e) { console.error('Could not read application logs:',e); res.status(500).json({error:'Could not read application logs'}); }
});
'@
  $js = [regex]::Replace($js,$anchor,('$0'+"`r`n"+$helpers),1)
  Set-Content $Server $js -Encoding UTF8
  Write-Host "Backend logging endpoints added."
} else { Write-Host "Backend logging already present; skipped." }

# Frontend patch
$jsx = Get-Content $Main -Raw
if ($jsx -notmatch "VENUE_ASSET_LOGGING_V1") {
  $accessOld = "const APP_ACCESS=\[\['dashboard','Dashboard'\],\['venues','Venues'\],\['assets','Assets'\],\['letters','Asset Letters'\],\['reports','Reports'\],\['calculator','GST Calc'\],\['users','Users'\]\];"
  if ($jsx -notmatch $accessOld) { throw "Could not find APP_ACCESS. Backups are available." }
  $accessNew = "const APP_ACCESS=[['dashboard','Dashboard'],['venues','Venues'],['assets','Assets'],['letters','Asset Letters'],['reports','Reports'],['calculator','GST Calc'],['users','Users'],['logs','Logs']];"
  $jsx = [regex]::Replace($jsx,$accessOld,[System.Text.RegularExpressions.MatchEvaluator]{param($m) $accessNew},1)

  $logsComponent = @'
/* VENUE_ASSET_LOGGING_V1 */
function LogsPage(){
 const [entries,setEntries]=useState([]),[query,setQuery]=useState(''),[level,setLevel]=useState('all'),[loading,setLoading]=useState(false),[error,setError]=useState('');
 const token=localStorage.getItem('vam_token');
 const load=async()=>{setLoading(true);setError('');try{const r=await fetch(`${API_BASE}/api/logs`,{headers:{Authorization:`Bearer ${token}`}});if(!r.ok)throw new Error(r.status===403?'Admin access required':`Could not load logs (HTTP ${r.status})`);const d=await r.json();setEntries(Array.isArray(d.entries)?d.entries:[])}catch(e){setError(e.message||'Unable to load logs')}finally{setLoading(false)}};
 useEffect(()=>{load()},[]);
 const filtered=entries.filter(e=>(level==='all'||e.level===level)&&`${e.timestamp||''} ${e.source||''} ${e.type||''} ${e.message||''} ${e.page||''} ${e.stack||''}`.toLowerCase().includes(query.toLowerCase()));
 const exportLogs=()=>{const blob=new Blob([JSON.stringify(filtered,null,2)],{type:'application/json'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=`venue-asset-manager-logs-${new Date().toISOString().slice(0,10)}.json`;a.click();URL.revokeObjectURL(url)};
 return <section className="logs-page"><div className="page-head"><div><h1>Application Logs</h1><p>Automatic frontend and backend diagnostics.</p></div><div className="log-actions"><button onClick={load} disabled={loading}>{loading?'Refreshing…':'Refresh'}</button><button onClick={exportLogs} disabled={!filtered.length}>Export JSON</button></div></div>
 <div className="log-toolbar"><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search message, page, stack…"/><select value={level} onChange={e=>setLevel(e.target.value)}><option value="all">All levels</option><option value="error">Errors</option><option value="warn">Warnings</option><option value="info">Info</option></select><span>{filtered.length} of {entries.length} entries</span></div>
 {error&&<div className="log-error">{error}</div>}{!loading&&!error&&!filtered.length&&<div className="log-empty">No matching logs found.</div>}
 <div className="log-list">{filtered.map((e,i)=><article className="log-entry" key={`${e.timestamp||''}-${i}`}><div className="log-entry-head"><span className={`log-level log-${e.level||'error'}`}>{e.level||'error'}</span><time>{e.timestamp?new Date(e.timestamp).toLocaleString():'Unknown time'}</time><span>{e.source||'app'} · {e.type||'event'}</span>{e.status!=null&&<span>HTTP {e.status}</span>}</div><strong>{e.message||'No message'}</strong>{e.page&&<div className="log-page-path">Page: {e.page}</div>}{e.stack&&<details><summary>Details / stack trace</summary><pre>{e.stack}</pre></details>}</article>)}</div></section>;
}

'@
  $layoutStart = "function Layout(){"
  if ($jsx.IndexOf($layoutStart) -lt 0) { throw "Could not find Layout function. Backups are available." }
  $jsx = $jsx.Insert($jsx.IndexOf($layoutStart),$logsComponent)
  if ($jsx.IndexOf("letters:FileText}") -lt 0) { throw "Could not find Layout icon map. Backups are available." }
  $jsx = $jsx.Replace("letters:FileText}","letters:FileText,logs:FileText}")
  $routeOld = '<Route path="/users" element={<UsersPage/>}/>'
  if ($jsx.IndexOf($routeOld) -lt 0) { throw "Could not find Users route. Backups are available." }
  $jsx = $jsx.Replace($routeOld,'<Route path="/users" element={<UsersPage/>}/><Route path="/logs" element={s?.role==="Admin"?<LogsPage/>:<Navigate to="/dashboard" replace/>}/>')
  $appStart = 'function App(){const[ready,setReady]=useState(false);'
  if ($jsx.IndexOf($appStart) -lt 0) { throw "Could not find App() start. Backups are available." }
  $capture = @'
function App(){const[ready,setReady]=useState(false);useEffect(()=>{
 const send=(entry)=>{try{const payload={source:'frontend',level:entry.level||'error',type:String(entry.type||'javascript').slice(0,80),message:String(entry.message||'Unknown error').slice(0,2000),page:location.pathname.slice(0,300),stack:String(entry.stack||'').slice(0,6000),status:entry.status??null};fetch(`${API_BASE}/api/logs/client`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload),keepalive:true}).catch(()=>{})}catch{}};
 const onError=e=>send({type:'window.error',message:e.message||'JavaScript error',stack:e.error?.stack||''});
 const onReject=e=>send({type:'unhandledrejection',message:e.reason?.message||String(e.reason||'Unhandled promise rejection'),stack:e.reason?.stack||''});
 window.addEventListener('error',onError);window.addEventListener('unhandledrejection',onReject);
 const originalFetch=window.fetch.bind(window);
 window.fetch=async(...args)=>{const input=args[0],url=typeof input==='string'?input:(input?.url||'');try{const response=await originalFetch(...args);if(!String(url).includes('/api/logs/client')&&!response.ok&&String(url).includes('/api/'))send({type:'api.http_error',message:`API request failed: ${response.status} ${response.statusText}`,status:response.status});return response}catch(err){if(!String(url).includes('/api/logs/client')&&String(url).includes('/api/'))send({type:'api.network_error',message:err?.message||'API network request failed',stack:err?.stack||''});throw err}};
 return ()=>{window.removeEventListener('error',onError);window.removeEventListener('unhandledrejection',onReject);window.fetch=originalFetch};
},[]);
'@
  $jsx = $jsx.Replace($appStart,$capture)
  Set-Content $Main $jsx -Encoding UTF8

  $css = Get-Content $Css -Raw
  if ($css -notmatch "VENUE_ASSET_LOGGING_V1") {
    $css += @'

/* VENUE_ASSET_LOGGING_V1 */
.logs-page{display:grid;gap:16px}.page-head{display:flex;justify-content:space-between;align-items:flex-start;gap:16px;flex-wrap:wrap}.page-head h1{margin:0 0 6px}.page-head p{margin:0;color:#64748b}.log-actions{display:flex;gap:8px}.log-actions button{border:1px solid #cbd5e1;background:#fff;border-radius:8px;padding:9px 13px;color:#172033}.log-toolbar{display:flex;align-items:center;gap:10px;flex-wrap:wrap;background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:12px}.log-toolbar input{flex:1;min-width:220px}.log-toolbar input,.log-toolbar select{border:1px solid #cbd5e1;border-radius:8px;padding:10px;background:#fff}.log-toolbar span{font-size:13px;color:#64748b}.log-list{display:grid;gap:10px}.log-entry{background:#fff;border:1px solid #e2e8f0;border-radius:12px;padding:14px;overflow-wrap:anywhere}.log-entry-head{display:flex;align-items:center;gap:10px;flex-wrap:wrap;font-size:12px;color:#64748b;margin-bottom:9px}.log-level{font-weight:800;text-transform:uppercase;border-radius:5px;padding:4px 7px;background:#fee2e2;color:#991b1b}.log-warn{background:#fef3c7;color:#92400e}.log-info{background:#dbeafe;color:#1d4ed8}.log-entry>strong{display:block;font-size:14px}.log-page-path{font-size:12px;color:#64748b;margin-top:8px}.log-entry details{margin-top:10px}.log-entry summary{cursor:pointer;color:#2563eb;font-size:13px}.log-entry pre{white-space:pre-wrap;overflow:auto;background:#0f172a;color:#e2e8f0;padding:12px;border-radius:8px;font-size:12px;max-height:300px}.log-empty,.log-error{padding:18px;border-radius:10px;background:#fff;color:#64748b}.log-error{color:#991b1b;background:#fee2e2}
'@
    Set-Content $Css $css -Encoding UTF8
  }
  Write-Host "Frontend logging and Admin Logs page added."
} else { Write-Host "Frontend logging already present; skipped." }

Write-Host ""
Write-Host "Patch complete. Backups created with timestamp $Stamp"
Write-Host "Log folder: $LogDir"
Write-Host "Next command: Set-Location '$Project'; npm run build"
