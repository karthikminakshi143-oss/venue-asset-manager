$ErrorActionPreference = "Stop"

$path = "D:\venue-asset-manager\src\main.jsx"
if (!(Test-Path $path)) { throw "main.jsx not found: $path" }

# Safety backup
$backup = "$path.backup-final-patch-20261005"
Copy-Item $path $backup -Force
Write-Host "Backup: $backup" -ForegroundColor Green

$s = Get-Content $path -Raw

function Replace-Function([string]$source,[string]$startMarker,[string]$nextMarker,[string]$replacement,[string]$name) {
  $start = $source.IndexOf($startMarker)
  if ($start -lt 0) { throw "$name start marker not found: $startMarker" }
  $end = $source.IndexOf($nextMarker,$start)
  if ($end -lt 0) { throw "$name next marker not found: $nextMarker" }
  return $source.Substring(0,$start) + $replacement + "`r`n`r`n" + $source.Substring($end)
}

# 1) Theatre GST Calculator
$calculator = @'
function Calculator(){
  const [amount,setAmount]=useState('');
  const [rate,setRate]=useState('5');
  const [option,setOption]=useState('option1');

  const gross=Number(amount)||0;
  const r=Number(rate)||0;

  let taxable=0;
  let gst=0;

  if(option==='option1'){
    taxable=gross;
    gst=r>0 ? gross*r/(100+r) : 0;
  }else{
    taxable=Math.max(0,gross-r);
    gst=r>0 ? taxable*r/(100+r) : 0;
  }

  const cgst=gst/2;
  const sgst=gst/2;
  const net=Math.max(0,gross-r-gst);

  const money=(v)=>v.toFixed(2);

  return (
    <Page
      title="GST Calculator"
      sub="Theatre GST calculator • GST Including"
    >
      <div className="panel">
        <div className="formgrid">
          <label>
            Gross Amount
            <input
              type="number"
              min="0"
              step="0.01"
              value={amount}
              onChange={e=>setAmount(e.target.value)}
              placeholder="Enter amount"
            />
          </label>

          <label>
            GST Rate
            <select value={rate} onChange={e=>setRate(e.target.value)}>
              <option value="5">5%</option>
              <option value="12">12%</option>
              <option value="18">18%</option>
              <option value="36">36%</option>
              <option value="40">40%</option>
            </select>
          </label>

          <label>
            Calculation Option
            <select value={option} onChange={e=>setOption(e.target.value)}>
              <option value="option1">Option 1 — Gross Amount</option>
              <option value="option2">Option 2 — Gross Amount − GST Rate Amount</option>
            </select>
          </label>
        </div>

        <div className="cards" style={{marginTop:16}}>
          <div className="card">
            <b>Gross Amount</b>
            <strong>₹{money(gross)}</strong>
          </div>
          <div className="card">
            <b>Taxable Amount</b>
            <strong>₹{money(taxable)}</strong>
          </div>
          <div className="card">
            <b>GST Amount</b>
            <strong>₹{money(gst)}</strong>
          </div>
          <div className="card">
            <b>CGST</b>
            <strong>₹{money(cgst)}</strong>
          </div>
          <div className="card">
            <b>SGST</b>
            <strong>₹{money(sgst)}</strong>
          </div>
          <div className="card">
            <b>Net Amount</b>
            <strong>₹{money(net)}</strong>
          </div>
        </div>

        <div className="panel" style={{marginTop:16}}>
          <b>Calculation</b>
          <div style={{marginTop:8,lineHeight:1.8}}>
            {option==='option1' ? (
              <>
                <div>GST = ₹{money(gross)} × {r}% ÷ (100 + {r}%) = <b>₹{money(gst)}</b></div>
                <div>CGST = ₹{money(gst)} ÷ 2 = <b>₹{money(cgst)}</b></div>
                <div>SGST = ₹{money(gst)} ÷ 2 = <b>₹{money(sgst)}</b></div>
                <div>Net Amount = ₹{money(gross)} − ₹{money(r)} − ₹{money(gst)} = <b>₹{money(net)}</b></div>
              </>
            ) : (
              <>
                <div>Step 1: ₹{money(gross)} − ₹{money(r)} = <b>₹{money(taxable)}</b></div>
                <div>Step 2: GST = ₹{money(taxable)} × {r}% ÷ (100 + {r}%) = <b>₹{money(gst)}</b></div>
                <div>CGST = ₹{money(gst)} ÷ 2 = <b>₹{money(cgst)}</b></div>
                <div>SGST = ₹{money(gst)} ÷ 2 = <b>₹{money(sgst)}</b></div>
                <div>Net Amount = ₹{money(gross)} − ₹{money(r)} − ₹{money(gst)} = <b>₹{money(net)}</b></div>
              </>
            )}
          </div>
        </div>
      </div>
    </Page>
  );
}
'@

$s = Replace-Function $s "function Calculator(){" "function UsersPage(){" $calculator "Calculator"

# 2) Protect the default Administrator from editing and deleting.
$guardOld = "const openEdit=(u)=>{"
$guardNew = @'
const openEdit=(u)=>{
    if(String(u.id)==='1'){
      return alert('Administrator account cannot be edited.');
    }
'@
if ($s.IndexOf($guardOld) -lt 0) { throw "UsersPage openEdit marker not found." }
$s = $s.Replace($guardOld,$guardNew,1)

$buttonOld = @'
<div style={{display:'flex',gap:'6px'}} key={u.id}>
              <button
                className="btn"
                onClick={()=>openEdit(u)}
              >
                <Edit3 size={15}/> Edit
              </button>

              {String(u.id)!=='1' &&
                <button
                  className="btn"
                  onClick={()=>removeUser(u)}
                >
                  <Trash2 size={15}/> Delete
                </button>
              }
            </div>
'@

$buttonNew = @'
<div style={{display:'flex',gap:'6px'}} key={u.id}>
              {String(u.id)!=='1' &&
                <>
                  <button
                    className="btn"
                    onClick={()=>openEdit(u)}
                  >
                    <Edit3 size={15}/> Edit
                  </button>

                  <button
                    className="btn"
                    onClick={()=>removeUser(u)}
                  >
                    <Trash2 size={15}/> Delete
                  </button>
                </>
              }
            </div>
'@

if ($s.IndexOf($buttonOld) -lt 0) { throw "UsersPage Edit/Delete button block not found." }
$s = $s.Replace($buttonOld,$buttonNew,1)

# 3) User Activity Log report filters: date+time, user dropdown, module dropdown, presets.
$reports = @'
function Reports(){
  const [view,setView]=useState('state');
  const [rows,setRows]=useState([]);
  const [busy,setBusy]=useState(false);
  const [err,setErr]=useState('');
  const [from,setFrom]=useState('');
  const [to,setTo]=useState('');
  const [user,setUser]=useState('');
  const [module,setModule]=useState('');
  const [preset,setPreset]=useState('');
  const token=localStorage.getItem('vam_token')||'';

  const configs={
    state:{title:'State-wise Report',heads:['State / UT','Venues','Asset Quantity'],url:'/api/reports/state'},
    district:{title:'District-wise Report',heads:['State / UT','District','Venues','Asset Quantity'],url:'/api/reports/district'},
    venue:{title:'Venue-wise Report',heads:['State / UT','District','Venue ID','Venue Name','Asset Records','Asset Quantity'],url:'/api/reports/venue'},
    user:{title:'User-wise Report',heads:['User','Email','Role','Activities','Last Activity'],url:'/api/reports/user'},
    asset:{title:'Asset-wise Report',heads:['Venue ID','Venue Name','Asset ID','Asset Type','Category','Model','Serial','Invoice No','Invoice Date','Vendor','Qty','Status','Removal Asset','Removal Date'],url:'/api/reports/asset'},
    letters:{title:'Asset Letters Report',heads:['Venue ID','Venue Name','Letter Date','File Name','MIME','Size','Uploaded By','Created At'],url:'/api/reports/letters'},
    swapping:{title:'Swapping Report',heads:['Date / Time','Asset ID','From Venue','To Venue','Asset Type','Category','Model','Serial','Qty','Swapped By'],url:'/api/reports/swapping'},
    activity:{title:'User Activity Log',heads:['Date / Time','User','Email','Role','Action','Module','Details','IP Address'],url:'/api/reports/user-log'}
  };

  const reportUsers=users();
  const moduleOptions=[
    'Authentication',
    'Dashboard',
    'Venues',
    'Assets',
    'Asset Letters',
    'Swapping',
    'Users',
    'Reports',
    'GST Calculator'
  ];

  const localDate=(d)=>{
    const p=(n)=>String(n).padStart(2,'0');
    return `${d.getFullYear()}-${p(d.getMonth()+1)}-${p(d.getDate())}`;
  };

  const localDateTime=(d)=>{
    const p=(n)=>String(n).padStart(2,'0');
    return `${localDate(d)}T${p(d.getHours())}:${p(d.getMinutes())}`;
  };

  const applyPreset=(name)=>{
    const now=new Date();
    let start=new Date(now);
    let end=new Date(now);

    if(name==='today'){
      start.setHours(0,0,0,0);
      end.setHours(23,59,59,999);
    }else if(name==='yesterday'){
      start.setDate(start.getDate()-1);
      start.setHours(0,0,0,0);
      end=new Date(start);
      end.setHours(23,59,59,999);
    }else if(name==='lastweek'){
      const day=now.getDay();
      const mondayOffset=day===0 ? -6 : 1-day;
      start.setDate(start.getDate()+mondayOffset-7);
      start.setHours(0,0,0,0);
      end=new Date(start);
      end.setDate(end.getDate()+6);
      end.setHours(23,59,59,999);
    }else if(name==='thisweek'){
      const day=now.getDay();
      const mondayOffset=day===0 ? -6 : 1-day;
      start.setDate(start.getDate()+mondayOffset);
      start.setHours(0,0,0,0);
      end=new Date(start);
      end.setDate(end.getDate()+6);
      end.setHours(23,59,59,999);
    }else if(name==='thismonth'){
      start=new Date(now.getFullYear(),now.getMonth(),1,0,0,0,0);
      end=new Date(now.getFullYear(),now.getMonth()+1,0,23,59,59,999);
    }else if(name==='lastmonth'){
      start=new Date(now.getFullYear(),now.getMonth()-1,1,0,0,0,0);
      end=new Date(now.getFullYear(),now.getMonth(),0,23,59,59,999);
    }

    setPreset(name);
    setFrom(localDateTime(start));
    setTo(localDateTime(end));
  };

  const load=async()=>{
    setBusy(true);
    setErr('');
    try{
      const c=configs[view];
      const qs=new URLSearchParams();

      if(view==='activity'){
        if(from)qs.set('from',from);
        if(to)qs.set('to',to);
        if(user)qs.set('user',user);
        if(module)qs.set('module',module);
      }

      const r=await fetch(
        `${API_BASE}${c.url}${qs.toString()?'?'+qs.toString():''}`,
        {headers:{Authorization:`Bearer ${token}`}}
      );

      const d=await r.json();
      if(!r.ok)throw new Error(d.error||'Unable to load report');
      setRows(Array.isArray(d)?d:[]);
    }catch(e){
      setRows([]);
      setErr(e.message||'Unable to load report');
    }finally{
      setBusy(false);
    }
  };

  useEffect(()=>{load()},[view,from,to,user,module]);

  const dataRows=rows.map(x=>{
    if(view==='state')return [x.state||'-',x.total_venues||0,x.total_assets||0];
    if(view==='district')return [x.state||'-',x.district||'-',x.total_venues||0,x.total_assets||0];
    if(view==='venue')return [x.state||'-',x.district||'-',x.venue_id||'-',x.venue_name||'-',x.asset_records||0,x.asset_quantity||0];
    if(view==='user')return [x.user_name||'-',x.email||'-',x.role||'-',x.activities||0,x.last_activity||'-'];
    if(view==='asset')return [x.venue_id||'-',x.venue_name||'-',x.asset_id||'-',x.asset_type||'-',x.category||'-',x.model_name||'-',x.serial_number||'-',x.invoice_no||'-',x.invoice_date||'-',x.vendor_name||'-',x.quantity||0,x.status||'-',x.removal_asset?'Yes':'No',x.removal_date||'-'];
    if(view==='letters')return [x.venue_id||'-',x.venue_name||'-',x.letter_date||'-',x.file_name||'-',x.mime_type||'-',`${x.file_size||0} bytes`,x.uploaded_by||'-',x.created_at||'-'];
    if(view==='swapping')return [x.swapped_at||'-',x.asset_id||'-',x.from_venue||x.from_venue_id||'-',x.to_venue||x.to_venue_id||'-',x.asset_type||'-',x.category||'-',x.model_name||'-',x.serial_number||'-',x.quantity||0,x.swapped_by||'-'];
    return [x.created_at||'-',x.user_name||'-',x.email||'-',x.role||'-',x.action||'-',x.module||'-',x.details||'-',x.ip_address||'-'];
  });

  const csv=()=>{
    const content=[configs[view].heads,...dataRows]
      .map(r=>r.map(v=>`"${String(v??'').replaceAll('"','""')}"`).join(','))
      .join('\n');
    const u=URL.createObjectURL(
      new Blob([content],{type:'text/csv;charset=utf-8;'})
    );
    const a=document.createElement('a');
    a.href=u;
    a.download=`venue-asset-${view}-report.csv`;
    a.click();
    URL.revokeObjectURL(u);
  };

  const pdf=()=>downloadSimplePDF(
    `Venue Asset Manager - ${configs[view].title}`,
    configs[view].heads,
    dataRows,
    `venue-asset-${view}-report.pdf`
  );

  return (
    <Page
      title="Reports"
      sub="State, district, venue, asset, user and activity reports"
    >
      <div className="toolbar">
        {Object.entries(configs).map(([key,c])=>(
          <button
            key={key}
            className={view===key?'primary':'btn'}
            onClick={()=>setView(key)}
          >
            {c.title}
          </button>
        ))}
      </div>

      {view==='activity'&&(
        <section className="panel">
          <div className="toolbar" style={{marginBottom:12}}>
            <b>Quick Date Range</b>
            <button className="btn" onClick={()=>applyPreset('today')}>Today</button>
            <button className="btn" onClick={()=>applyPreset('yesterday')}>Yesterday</button>
            <button className="btn" onClick={()=>applyPreset('lastweek')}>Last Week</button>
            <button className="btn" onClick={()=>applyPreset('thisweek')}>This Week</button>
            <button className="btn" onClick={()=>applyPreset('thismonth')}>This Month</button>
            <button className="btn" onClick={()=>applyPreset('lastmonth')}>Last Month</button>
            {preset&&<button className="btn" onClick={()=>{setPreset('');setFrom('');setTo('')}}>Clear</button>}
          </div>

          <div className="formgrid">
            <label>
              Date From
              <input
                type="datetime-local"
                value={from}
                onChange={e=>{setPreset('');setFrom(e.target.value)}}
              />
            </label>

            <label>
              Date To
              <input
                type="datetime-local"
                value={to}
                onChange={e=>{setPreset('');setTo(e.target.value)}}
              />
            </label>

            <label>
              User
              <select value={user} onChange={e=>setUser(e.target.value)}>
                <option value="">All Users</option>
                {reportUsers.map(u=>(
                  <option key={u.id||u.email} value={u.email||u.username||u.name}>
                    {u.name||u.email||u.username}
                    {u.email?` — ${u.email}`:''}
                  </option>
                ))}
              </select>
            </label>

            <label>
              Module
              <select value={module} onChange={e=>setModule(e.target.value)}>
                <option value="">All Modules</option>
                {moduleOptions.map(m=><option key={m} value={m}>{m}</option>)}
              </select>
            </label>
          </div>
        </section>
      )}

      {err&&<div className="error" style={{marginTop:12}}>{err}</div>}

      <div className="panel" style={{marginTop:12}}>
        {busy ? (
          <div>Loading report...</div>
        ) : (
          <>
            <div className="toolbar" style={{marginBottom:12}}>
              <button className="btn" onClick={csv}><Download size={15}/> CSV</button>
              <button className="btn" onClick={pdf}><FileText size={15}/> PDF</button>
            </div>
            <Table heads={configs[view].heads} rows={dataRows}/>
          </>
        )}
      </div>
    </Page>
  );
}
'@

$s = Replace-Function $s "function Reports(){" "function App(){" $reports "Reports"

Set-Content $path $s -Encoding UTF8

Write-Host ""
Write-Host "Patch applied successfully." -ForegroundColor Green
Write-Host "Running verification..." -ForegroundColor Cyan

Select-String -Path $path -Pattern 'function Calculator','function UsersPage','function Reports','function App' |
  Select-Object LineNumber,Line

Write-Host ""
Write-Host "Run: npm run build" -ForegroundColor Yellow
