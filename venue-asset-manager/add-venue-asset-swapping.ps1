$ErrorActionPreference = "Stop"

$root = "D:\venue-asset-manager"
$server = Join-Path $root "server\server.js"
$main = Join-Path $root "src\main.jsx"

Write-Host "Venue Asset Swapping - additive patch" -ForegroundColor Cyan

if (!(Test-Path $server)) { throw "server.js not found: $server" }
if (!(Test-Path $main)) { throw "main.jsx not found: $main" }

# Backups - existing files are never deleted.
Copy-Item $server "$server.before-venue-swapping.bak" -Force
Copy-Item $main "$main.before-venue-swapping.bak" -Force

# -------------------------
# 1. Backend endpoint
# -------------------------
$s = Get-Content $server -Raw

if ($s -notmatch "Venue Asset Swapping") {
$backend = @'

/* Venue Asset Swapping - transfers ONLY selected asset records. */
app.post('/api/assets/venue-swap',auth,async(req,res)=>{
  const currentVenueId=String(req.body?.currentVenueId||'').trim();
  const newVenueId=String(req.body?.newVenueId||'').trim();
  const assetIds=Array.isArray(req.body?.assetIds)?req.body.assetIds.map(x=>String(x)).filter(Boolean):[];

  if(!currentVenueId||!newVenueId)return res.status(400).json({error:'Current Venue ID and New Venue ID are required'});
  if(currentVenueId===newVenueId)return res.status(400).json({error:'Current and New Venue cannot be the same'});
  if(!assetIds.length)return res.status(400).json({error:'Select at least one asset'});

  let conn;
  try{
    conn=await pool.getConnection();
    await conn.beginTransaction();

    const [cv]=await conn.query(
      'SELECT id,venue_id,name FROM venue_master WHERE id=? OR venue_id=? LIMIT 1',
      [currentVenueId,currentVenueId]
    );
    const [nv]=await conn.query(
      'SELECT id,venue_id,name FROM venue_master WHERE id=? OR venue_id=? LIMIT 1',
      [newVenueId,newVenueId]
    );

    if(!cv[0])throw new Error('Current Venue not found');
    if(!nv[0])throw new Error('New Venue not found');
    if(String(cv[0].id)===String(nv[0].id))throw new Error('Current and New Venue cannot be the same');

    const placeholders=assetIds.map(()=>'?').join(',');
    const [assets]=await conn.query(
      `SELECT id,venue_id FROM asset_master WHERE id IN (${placeholders}) AND removed=0`,
      assetIds
    );

    if(assets.length!==assetIds.length){
      throw new Error('One or more selected assets were not found or are already removed');
    }

    const wrong=assets.find(x=>String(x.venue_id)!==String(cv[0].id));
    if(wrong)throw new Error('A selected asset does not belong to the Current Venue');

    await conn.query(
      `UPDATE asset_master SET venue_id=?,updated_by=?,updated_at=CURRENT_TIMESTAMP WHERE id IN (${placeholders})`,
      [nv[0].id,req.user?.name||req.user?.email||'Unknown',...assetIds]
    );

    await conn.commit();

    res.json({
      ok:true,
      transferred:assetIds.length,
      currentVenueId:cv[0].venue_id,
      newVenueId:nv[0].venue_id
    });
  }catch(e){
    if(conn)await conn.rollback().catch(()=>{});
    res.status(400).json({error:e.message});
  }finally{
    if(conn)conn.release();
  }
});

/* Venue Asset Swapping - returns current venue assets and letter count. */
app.get('/api/assets/venue-swap/:venueId',auth,async(req,res)=>{
  try{
    const id=String(req.params.venueId||'').trim();
    const [v]=await pool.query('SELECT id,venue_id,name FROM venue_master WHERE id=? OR venue_id=? LIMIT 1',[id,id]);
    if(!v[0])return res.status(404).json({error:'Venue not found'});
    const [a]=await pool.query('SELECT * FROM asset_master WHERE venue_id=? AND removed=0 ORDER BY updated_at DESC',[v[0].id]);
    const [l]=await pool.query('SELECT COUNT(*) count FROM asset_letters WHERE venue_id=?',[v[0].id]);
    res.json({venue:v[0],assets:a.map(normalizeAsset),assetLetters:Number(l[0]?.count||0)});
  }catch(e){
    res.status(500).json({error:e.message});
  }
});
'@
    $marker = "app.listen(PORT,'0.0.0.0'"
    $pos = $s.IndexOf($marker)
    if ($pos -lt 0) { throw "Could not find app.listen marker in server.js" }
    $s = $s.Insert($pos,$backend)
    Set-Content $server $s -Encoding UTF8
    Write-Host "Backend venue-swap endpoint added." -ForegroundColor Green
} else {
    Write-Host "Backend venue-swap endpoint already exists; skipped." -ForegroundColor Yellow
}

# -------------------------
# 2. Frontend component
# -------------------------
$m = Get-Content $main -Raw

if ($m -notmatch "function VenueAssetSwapping\(\)") {
$component = @'

function VenueAssetSwapping({close}){
  const venues=get('vam_venues',[]);
  const allAssets=get('vam_assets',[]);
  const token=localStorage.getItem('vam_token');
  const [currentVenueId,setCurrentVenueId]=useState('');
  const [newVenueId,setNewVenueId]=useState('');
  const [assets,setAssets]=useState([]);
  const [letters,setLetters]=useState(0);
  const [selected,setSelected]=useState([]);
  const [busy,setBusy]=useState(false);

  const load=async(id)=>{
    setCurrentVenueId(id);
    setSelected([]);
    if(!id){setAssets([]);setLetters(0);return}
    try{
      const r=await fetch(`${API_BASE}/api/assets/venue-swap/${encodeURIComponent(id)}`,{
        headers:{Authorization:`Bearer ${token}`}
      });
      const d=await r.json();
      if(!r.ok)throw new Error(d.error||'Unable to load venue assets');
      setAssets(d.assets||[]);
      setLetters(Number(d.assetLetters||0));
    }catch(e){
      const local=allAssets.filter(x=>String(x.venueId)===String(id)&&!x.removed);
      setAssets(local);
      setLetters(0);
    }
  };

  const toggle=id=>setSelected(s=>s.includes(id)?s.filter(x=>x!==id):[...s,id]);
  const allChecked=assets.length>0&&selected.length===assets.length;
  const toggleAll=()=>setSelected(allChecked?[]:assets.map(x=>String(x.id)));

  const transfer=async()=>{
    if(!currentVenueId)return alert('Select Current Venue ID');
    if(!newVenueId)return alert('Select New Venue ID');
    if(currentVenueId===newVenueId)return alert('Current and New Venue cannot be the same');
    if(!selected.length)return alert('Select at least one asset');
    if(!confirm(`Transfer ${selected.length} selected asset(s) to the new venue?`))return;

    setBusy(true);
    try{
      const r=await fetch(`${API_BASE}/api/assets/venue-swap`,{
        method:'POST',
        headers:{'Content-Type':'application/json',Authorization:`Bearer ${token}`},
        body:JSON.stringify({currentVenueId,newVenueId,assetIds:selected})
      });
      const d=await r.json();
      if(!r.ok)throw new Error(d.error||'Venue asset transfer failed');

      const newVenue=venues.find(v=>String(v.id)===String(newVenueId));
      const moved=new Set(selected.map(String));
      const localAssets=get('vam_assets',[]).map(x=>
        moved.has(String(x.id))
          ? {...x,venueId:newVenueId,venueName:newVenue?.name||x.venueName||''}
          : x
      );
      localStorage.setItem('vam_assets',JSON.stringify(localAssets));

      alert(`${d.transferred} asset(s) transferred successfully.`);
      setSelected([]);
      await load(currentVenueId);
    }catch(e){
      alert(e.message);
    }finally{
      setBusy(false);
    }
  };

  const current=venues.find(v=>String(v.id)===String(currentVenueId));
  const target=venues.find(v=>String(v.id)===String(newVenueId));

  return <Modal title="Venue Swapping" close={close}>
    <section className="panel">
      <div className="form">
        <label>Current Venue ID
          <select value={currentVenueId} onChange={e=>load(e.target.value)}>
            <option value="">Select Current Venue ID</option>
            {venues.map(v=><option key={v.id} value={v.id}>{v.venueId} — {v.name}</option>)}
          </select>
        </label>

        <label>New Venue ID
          <select value={newVenueId} onChange={e=>setNewVenueId(e.target.value)}>
            <option value="">Select New Venue ID</option>
            {venues.filter(v=>String(v.id)!==String(currentVenueId)).map(v=><option key={v.id} value={v.id}>{v.venueId} — {v.name}</option>)}
          </select>
        </label>
      </div>

      {currentVenueId&&<div className="asset-note">
        <b>{current?.venueId||''}</b> → <b>{target?.venueId||'Select New Venue ID'}</b>
        &nbsp; | &nbsp; Assets affected: <b>{assets.reduce((n,x)=>n+Number(x.quantity||0),0)}</b>
        &nbsp; | &nbsp; Asset Letters: <b>{letters}</b>
      </div>}

      {currentVenueId&&<section className="panel">
        <div className="toolbar">
          <label style={{display:'flex',alignItems:'center',gap:8}}>
            <input type="checkbox" checked={allChecked} onChange={toggleAll}/>
            Select All
          </label>
          <span className="asset-note">Selected: <b>{selected.length}</b> / {assets.length}</span>
        </div>

        <Table
          heads={['Select','Asset ID','Category','Model Name','Serial','Type','Qty','Status']}
          rows={assets.map(x=>[
            <input type="checkbox" checked={selected.includes(String(x.id))} onChange={()=>toggle(String(x.id))}/>,
            x.id||'-',
            x.category||'-',
            x.model||x.modelName||'-',
            x.serial||'-',
            x.assetType||'Own',
            x.quantity||0,
            x.status||x.details||'-'
          ])}
        />

        {!assets.length&&<div className="asset-note">No active assets found for this venue.</div>}

        <div style={{display:'flex',justifyContent:'flex-end',gap:10,marginTop:16}}>
          <button className="btn" onClick={close} disabled={busy}>Cancel</button>
          <button className="primary" onClick={transfer} disabled={busy||!selected.length}>
            {busy?'Transferring...':'Transfer Selected Assets'}
          </button>
        </div>
      </section>}
    </section>
  </Modal>
}
'@

    $marker = "function AssetLetters(){"
    $pos = $m.IndexOf($marker)
    if ($pos -lt 0) { throw "Could not find AssetLetters marker in main.jsx" }
    $m = $m.Insert($pos,$component)
    Write-Host "VenueAssetSwapping component added." -ForegroundColor Green
}

# Add a button to the existing Assets page without replacing it.
if ($m -notmatch "onClick=\{\(\)=>setVenueSwap\(true\)\}") {
    $old = '<button className="primary" onClick={()=>setShow(true)}><Plus size={17}/>Add Asset</button>'
    $new = '<div style={{display:"flex",gap:8}}><button className="btn" onClick={()=>setVenueSwap(true)}>Venue Swapping</button><button className="primary" onClick={()=>setShow(true)}><Plus size={17}/>Add Asset</button></div>'
    if ($m.Contains($old)) {
        # Add state near the existing Assets state declaration.
        $m = $m.Replace("const [selectedVenue,setSelectedVenue]=useState('');", "const [selectedVenue,setSelectedVenue]=useState('');`r`n  const [venueSwap,setVenueSwap]=useState(false);")
        $m = $m.Replace($old,$new)
        # Render the new component immediately after the existing AssetModal, keeping existing module behavior intact.
        $oldRender = '{show&&<AssetModal initial={edit} venues={v} save={save} close={()=>{setShow(false);setEdit(null)}}/>}'
        $newRender = '{show&&<AssetModal initial={edit} venues={v} save={save} close={()=>{setShow(false);setEdit(null)}}/>}{venueSwap&&<VenueAssetSwapping close={()=>setVenueSwap(false)}/> }'
        if ($m.Contains($oldRender)) {
            $m = $m.Replace($oldRender,$newRender)
        } else {
            throw "Could not find Assets modal render marker"
        }
        Write-Host "Venue Swapping button added to existing Assets page." -ForegroundColor Green
    } else {
        throw "Could not find existing Add Asset button marker. No frontend changes made."
    }
} else {
    Write-Host "Venue Swapping UI already exists; skipped." -ForegroundColor Yellow
}

Set-Content $main $m -Encoding UTF8
Write-Host ""
Write-Host "Patch complete. Existing files were backed up." -ForegroundColor Green
Write-Host "Next: node --check server\server.js"
Write-Host "Then: npm run build"
