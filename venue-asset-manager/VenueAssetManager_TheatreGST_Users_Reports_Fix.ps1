$ErrorActionPreference = "Stop"

cd D:\venue-asset-manager

$path = "D:\venue-asset-manager\src\main.jsx"
$backup = "$path.backup-theatre-gst-users-reports-20261005"

Copy-Item $path $backup -Force
Write-Host "Backup created: $backup" -ForegroundColor Green

$s = [System.IO.File]::ReadAllText($path)

function Replace-Block($text, $startMarker, $endMarker, $newBlock, $name) {
    $start = $text.IndexOf($startMarker)
    if ($start -lt 0) { throw "Could not find start marker for $name" }

    $end = $text.IndexOf($endMarker, $start + $startMarker.Length)
    if ($end -lt 0) { throw "Could not find end marker for $name" }

    return $text.Substring(0,$start) + $newBlock + $text.Substring($end)
}

# -------------------------------------------------------------------
# 1) THEATRE GST CALCULATOR
# Default = INCLUDING GST
#
# Option 1:
#   GST       = Amount * Rate / (100 + Rate)
#   CGST/SGST = GST / 2
#   Net       = Amount - Rate - GST
#
# Option 2:
#   Adjusted  = Amount - Rate
#   GST       = Adjusted * Rate / (100 + Rate)
#   CGST/SGST = GST / 2
#   Net       = Amount - Rate - GST
#
# This follows the user's examples exactly:
# 100 at 5%:
#   100*5/105 = 4.76
#   CGST = 2.38, SGST = 2.38
#   Net = 100 - 5 - 4.76 = 90.24
#
# Option 2:
#   100-5 = 95
#   95*5/105 = 4.52
#   CGST = 2.26, SGST = 2.26
#   Net = 100 - 5 - 4.52 = 90.48
# -------------------------------------------------------------------

$calculator = @'
function Calculator(){
  const [amount,setAmount]=useState('100');
  const [rate,setRate]=useState('5');
  const [option,setOption]=useState('option1');

  const rates=[5,12,18,36,40];
  const n=x=>{
    const v=Number(x);
    return Number.isFinite(v)?Math.max(0,v):0;
  };
  const f=x=>Number(x).toFixed(2);

  const gross=n(amount);
  const taxRate=n(rate);

  const adjustedAmount=option==='option2'
    ? Math.max(0,gross-taxRate)
    : gross;

  const gst=taxRate>0
    ? adjustedAmount*taxRate/(100+taxRate)
    : 0;

  const cgst=gst/2;
  const sgst=gst/2;

  const netAmount=Math.max(0,gross-taxRate-gst);

  const formula=option==='option2'
    ? `${f(gross)}-${f(taxRate)}=${f(adjustedAmount)} → ${f(adjustedAmount)}*${taxRate}/${100+taxRate}=${f(gst)}`
    : `${f(gross)}*${taxRate}/${100+taxRate}=${f(gst)}`;

  const allRateRows=rates.map(r=>{
    const adjusted=option==='option2'
      ? Math.max(0,gross-r)
      : gross;
    const g=r>0?adjusted*r/(100+r):0;
    const c=g/2;
    const sg=g/2;
    const net=Math.max(0,gross-r-g);
    return {r,adjusted,g,c,sg,net};
  });

  return <Page
    title="GST Calculator"
    sub="Theatre GST calculator — Including GST"
  >
    <section className="panel">
      <div className="gst-heading-row">
        <div>
          <h2>GST / Theatre Tax Calculator</h2>
          <p className="gst-sub">Default calculation is Including GST. Select the option and GST rate required.</p>
        </div>
        <span className="protected">CGST + SGST</span>
      </div>

      <div className="gst-form">
        <label>
          Amount
          <input
            type="number"
            min="0"
            step="0.01"
            value={amount}
            onChange={e=>setAmount(e.target.value)}
            placeholder="100"
          />
        </label>

        <label>
          GST Rate
          <select value={rate} onChange={e=>setRate(e.target.value)}>
            {rates.map(r=><option key={r} value={r}>{r}%</option>)}
          </select>
        </label>
      </div>

      <div className="gst-mode" style={{marginTop:'16px'}}>
        <button
          type="button"
          className={option==='option1'?'gst-mode-btn active':'gst-mode-btn'}
          onClick={()=>setOption('option1')}
        >
          Option 1 — Including GST
        </button>
        <button
          type="button"
          className={option==='option2'?'gst-mode-btn active':'gst-mode-btn'}
          onClick={()=>setOption('option2')}
        >
          Option 2 — Less GST Rate First
        </button>
      </div>

      <div className="cards" style={{marginTop:'20px'}}>
        <div className="stat">
          <small>Gross Amount</small>
          <strong>₹ {f(gross)}</strong>
        </div>
        <div className="stat">
          <small>Adjusted Amount</small>
          <strong>₹ {f(adjustedAmount)}</strong>
        </div>
        <div className="stat">
          <small>GST ({taxRate}%)</small>
          <strong>₹ {f(gst)}</strong>
        </div>
        <div className="stat">
          <small>CGST ({taxRate/2}%)</small>
          <strong>₹ {f(cgst)}</strong>
        </div>
        <div className="stat">
          <small>SGST ({taxRate/2}%)</small>
          <strong>₹ {f(sgst)}</strong>
        </div>
        <div className="stat">
          <small>Rate Amount</small>
          <strong>₹ {f(taxRate)}</strong>
        </div>
        <div className="stat">
          <small>Net Amount</small>
          <strong>₹ {f(netAmount)}</strong>
        </div>
      </div>

      <div className="formula-box theatre-formula" style={{marginTop:'20px'}}>
        <b>Theatre Formula</b>
        <code>{formula}</code>
        <code>CGST = {f(gst)} / 2 = {f(cgst)}</code>
        <code>SGST = {f(gst)} / 2 = {f(sgst)}</code>
        <code>Net Amount = {f(gross)} - {f(taxRate)} - {f(gst)} = {f(netAmount)}</code>
      </div>

      <h3 className="gst-table-title">All GST Rates — Including GST</h3>
      <div className="gst-rate-table">
        <table>
          <thead>
            <tr>
              <th>GST Rate</th>
              <th>Amount Used</th>
              <th>GST</th>
              <th>CGST</th>
              <th>SGST</th>
              <th>Rate Amount</th>
              <th>Net Amount</th>
              <th>Formula</th>
            </tr>
          </thead>
          <tbody>
            {allRateRows.map(x=>
              <tr key={x.r}>
                <td>{x.r}%</td>
                <td>₹ {f(x.adjusted)}</td>
                <td>₹ {f(x.g)}</td>
                <td>₹ {f(x.c)}</td>
                <td>₹ {f(x.sg)}</td>
                <td>₹ {f(x.r)}</td>
                <td>₹ {f(x.net)}</td>
                <td>
                  <code>
                    {option==='option2'
                      ? `(${f(gross)}-${x.r})*${x.r}/${100+x.r}`
                      : `${f(gross)}*${x.r}/${100+x.r}`}
                  </code>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="formula-reference">
        <b>Theatre Formula Reference</b>
        <div><span>5% Including:</span><code>Amount*5/105</code></div>
        <div><span>18% Including:</span><code>Amount*18/118</code></div>
        <div><span>12% Including:</span><code>Amount*12/112</code></div>
        <div><span>36% Including:</span><code>Amount*36/136</code></div>
        <div><span>40% Including:</span><code>Amount*40/140</code></div>
        <div><span>CGST / SGST:</span><code>GST/2</code></div>
        <div><span>Net Amount:</span><code>Amount-Rate-GST</code></div>
        <div><span>Option 2:</span><code>(Amount-Rate)*Rate/(100+Rate)</code></div>
      </div>
    </section>
  </Page>
}

'@

# -------------------------------------------------------------------
# 2) USERS PAGE
# Protect the main Administrator by ID OR known administrator email/name.
# No Edit and No Delete button for the protected administrator.
# -------------------------------------------------------------------

$usersPage = @'
function UsersPage(){
  const [u,setU]=useState(users());
  const [show,setShow]=useState(false);
  const [edit,setEdit]=useState(null);
  const session=normalizeUser(get('vam_session'));

  if(session?.role!=='Admin'){
    return <Navigate to="/dashboard" replace/>;
  }

  const isProtectedAdmin=x=>{
    const email=String(x?.email||x?.username||'').toLowerCase();
    const name=String(x?.name||'').toLowerCase();
    return x?.id==='1'
      || email==='admin@gmail.com'
      || email==='admin@venueassetmanager.local'
      || (name==='administrator' && x?.role==='Admin');
  };

  const openEdit=x=>{
    if(isProtectedAdmin(x)){
      alert('Administrator account is protected and cannot be edited.');
      return;
    }
    setEdit(x);
    setShow(true);
  };

  const remove=x=>{
    if(isProtectedAdmin(x)){
      alert('Administrator account is protected and cannot be deleted.');
      return;
    }

    if(confirm(`Remove user ${x.name}?`)){
      const list=u.filter(y=>y.id!==x.id);
      put('vam_users',list);
      setU(list);
    }
  };

  const save=x=>{
    const clean={
      ...x,
      name:String(x.name||'').trim(),
      email:String(x.email||x.username||'').trim().toLowerCase(),
      username:String(x.email||x.username||'').trim().toLowerCase(),
      role:x.role||'Support',
      permissions:x.role==='Admin'
        ? APP_ACCESS.map(a=>a[0])
        : (Array.isArray(x.permissions)?x.permissions:[])
    };

    if(!clean.name||!clean.email){
      return alert('Name and Email ID are required');
    }

    if(!/^\S+@\S+\.\S+$/.test(clean.email)){
      return alert('Enter a valid email ID');
    }

    if(u.some(y=>
      String(y.email||y.username).toLowerCase()===clean.email &&
      y.id!==clean.id
    )){
      return alert('Email ID already exists');
    }

    if(!edit && (String(x.password||'').length<6 || String(x.password||'').length>10)){
      return alert('Password must be 6 to 10 characters');
    }

    if(edit && isProtectedAdmin(edit)){
      return alert('Administrator account is protected and cannot be edited');
    }

    if(edit && x.password &&
      (String(x.password).length<6 || String(x.password).length>10)){
      return alert('Password must be 6 to 10 characters');
    }

    let list;

    if(edit){
      const existing=u.find(y=>y.id===clean.id);
      if(!existing)return alert('User not found');

      list=u.map(y=>
        y.id===clean.id
          ? normalizeUser({
              ...clean,
              password:x.password||existing.password
            })
          : y
      );
    }else{
      list=[
        ...u,
        normalizeUser({
          ...clean,
          password:x.password,
          id:crypto.randomUUID()
        })
      ];
    }

    put('vam_users',list);
    setU(list);
    setShow(false);
    setEdit(null);
  };

  const actionButtons=x=>
    <div className="table-actions">
      <button
        className="icon"
        title="Edit user"
        onClick={()=>openEdit(x)}
      >
        <Edit3 size={15}/>
      </button>
      <button
        className="icon danger"
        title="Delete user"
        onClick={()=>remove(x)}
      >
        <Trash2 size={15}/>
      </button>
    </div>;

  return <Page
    title="Users"
    sub="Administrator user and permission management"
    action={
      <button
        className="primary"
        onClick={()=>{setEdit(null);setShow(true)}}
      >
        <Plus size={16}/> Add User
      </button>
    }
  >
    <section className="panel">
      <div className="toolbar">
        <label>
          Search
          <input
            placeholder="Search name, email or role"
            onChange={e=>{
              const q=e.target.value.toLowerCase();
              const base=users();
              setU(base.filter(x=>
                `${x.name||''} ${x.email||x.username||''} ${x.role||''}`
                  .toLowerCase()
                  .includes(q)
              ));
            }}
          />
        </label>
      </div>

      <Table
        heads={['Name','Email ID','Role','Permissions','Actions']}
        rows={u.map(x=>[
          x.name,
          x.email||x.username,
          x.role,
          isProtectedAdmin(x)
            ? <span className="protected">All Applications</span>
            : (x.permissions||[]).length,
          isProtectedAdmin(x)
            ? <span className="protected">No Edit / No Delete</span>
            : actionButtons(x)
        ])}
      />
    </section>

    {show&&
      <Modal
        title={edit?'Edit User':'Add User'}
        close={()=>{setShow(false);setEdit(null)}}
      >
        <UserForm
          initial={edit}
          save={save}
          close={()=>{setShow(false);setEdit(null)}}
        />
      </Modal>
    }
  </Page>
}

'@

# -------------------------------------------------------------------
# 3) REPORTS PAGE
# Activity report filters:
#   Date From = datetime
#   Date To   = datetime
#   User      = select, populated from users
#   Module    = select
#   Preset    = Today / Yesterday / Last week / This week / This month / Last month
# Remove Role, Action and Search.
# -------------------------------------------------------------------

$reports = @'
function Reports(){
  const [view,setView]=useState('state');
  const [rows,setRows]=useState([]);
  const [loading,setLoading]=useState(false);

  const [from,setFrom]=useState('');
  const [to,setTo]=useState('');
  const [user,setUser]=useState('');
  const [module,setModule]=useState('');
  const [preset,setPreset]=useState('');

  const userOptions=users().filter(x=>x?.email||x?.username);
  const modules=[
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

  const configs={
    state:{
      title:'State-wise Report',
      heads:['State / UT','Venues','Asset Quantity'],
      url:'/api/reports/state'
    },
    district:{
      title:'District-wise Report',
      heads:['State / UT','District','Venues','Asset Quantity'],
      url:'/api/reports/district'
    },
    venue:{
      title:'Venue-wise Report',
      heads:['State / UT','District','Venue ID','Venue Name','Asset Records','Asset Quantity'],
      url:'/api/reports/venue'
    },
    user:{
      title:'User-wise Report',
      heads:['User','Email','Role','Activities','Last Activity'],
      url:'/api/reports/user'
    },
    asset:{
      title:'Asset-wise Report',
      heads:['Venue ID','Venue Name','Asset ID','Asset Type','Category','Model','Serial','Invoice No','Invoice Date','Vendor','Qty','Status','Removal Asset','Removal Date'],
      url:'/api/reports/asset'
    },
    letters:{
      title:'Asset Letters Report',
      heads:['Venue ID','Venue Name','Letter Date','File Name','MIME','Size','Uploaded By','Created At'],
      url:'/api/reports/letters'
    },
    swapping:{
      title:'Swapping Report',
      heads:['Date / Time','Asset ID','From Venue','To Venue','Asset Type','Category','Model','Serial','Qty','Swapped By'],
      url:'/api/reports/swapping'
    },
    activity:{
      title:'User Activity Log',
      heads:['Date / Time','User','Email','Role','Action','Module','Details','IP Address'],
      url:'/api/reports/user-log'
    }
  };

  const localDateTime=d=>{
    const pad=n=>String(n).padStart(2,'0');
    return `${d.getFullYear()}-${pad(d.getMonth()+1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
  };

  const startOfDay=d=>{
    const x=new Date(d);
    x.setHours(0,0,0,0);
    return x;
  };

  const endOfDay=d=>{
    const x=new Date(d);
    x.setHours(23,59,59,999);
    return x;
  };

  const applyPreset=value=>{
    setPreset(value);

    const now=new Date();
    let a=null,b=null;

    if(value==='today'){
      a=startOfDay(now);
      b=now;
    }else if(value==='yesterday'){
      const y=new Date(now);
      y.setDate(y.getDate()-1);
      a=startOfDay(y);
      b=endOfDay(y);
    }else if(value==='lastweek'){
      const d=startOfDay(now);
      const day=d.getDay();
      const mondayOffset=day===0?6:day-1;
      const thisMonday=new Date(d);
      thisMonday.setDate(thisMonday.getDate()-mondayOffset);
      a=new Date(thisMonday);
      a.setDate(a.getDate()-7);
      b=new Date(thisMonday);
      b.setMilliseconds(-1);
    }else if(value==='thisweek'){
      const d=startOfDay(now);
      const day=d.getDay();
      const mondayOffset=day===0?6:day-1;
      a=new Date(d);
      a.setDate(a.getDate()-mondayOffset);
      b=now;
    }else if(value==='thismonth'){
      a=new Date(now.getFullYear(),now.getMonth(),1,0,0,0,0);
      b=now;
    }else if(value==='lastmonth'){
      a=new Date(now.getFullYear(),now.getMonth()-1,1,0,0,0,0);
      b=new Date(now.getFullYear(),now.getMonth(),0,23,59,59,999);
    }else{
      return;
    }

    setFrom(localDateTime(a));
    setTo(localDateTime(b));
  };

  const load=async()=>{
    setLoading(true);
    try{
      const c=configs[view];
      const qs=new URLSearchParams();

      if(view==='activity'){
        if(from)qs.set('from',from);
        if(to)qs.set('to',to);
        if(user)qs.set('user',user);
        if(module)qs.set('module',module);
      }

      const token=localStorage.getItem('vam_token')||'';
      const r=await fetch(`${API_BASE}${c.url}${qs.toString()?`?${qs}`:''}`,{
        headers:{Authorization:`Bearer ${token}`}
      });

      const data=await r.json();
      if(!r.ok)throw new Error(data.error||`HTTP ${r.status}`);

      setRows(Array.isArray(data)?data:(Array.isArray(data.rows)?data.rows:[]));
    }catch(e){
      alert(e.message||'Unable to load report');
      setRows([]);
    }finally{
      setLoading(false);
    }
  };

  useEffect(()=>{
    load();
  },[view,from,to,user,module]);

  const dataRows=rows.map(x=>{
    if(view==='state'){
      return [x.state||'-',x.total_venues||0,x.total_assets||0];
    }

    if(view==='district'){
      return [x.state||'-',x.district||'-',x.total_venues||0,x.total_assets||0];
    }

    if(view==='venue'){
      return [
        x.state||'-',
        x.district||'-',
        x.venue_id||'-',
        x.venue_name||'-',
        x.asset_records||0,
        x.asset_quantity||0
      ];
    }

    if(view==='user'){
      return [
        x.user_name||'-',
        x.email||'-',
        x.role||'-',
        x.activities||0,
        x.last_activity||'-'
      ];
    }

    if(view==='asset'){
      return [
        x.venue_id||'-',
        x.venue_name||'-',
        x.asset_id||'-',
        x.asset_type||'-',
        x.category||'-',
        x.model_name||'-',
        x.serial_number||'-',
        x.invoice_no||'-',
        x.invoice_date||'-',
        x.vendor_name||'-',
        x.quantity||0,
        x.status||'-',
        x.removal_asset?'Yes':'No',
        x.removal_date||'-'
      ];
    }

    if(view==='letters'){
      return [
        x.venue_id||'-',
        x.venue_name||'-',
        x.letter_date||'-',
        x.file_name||'-',
        x.mime_type||'-',
        `${x.file_size||0} bytes`,
        x.uploaded_by||'-',
        x.created_at||'-'
      ];
    }

    if(view==='swapping'){
      return [
        x.swapped_at||'-',
        x.asset_id||'-',
        x.from_venue||x.from_venue_id||'-',
        x.to_venue||x.to_venue_id||'-',
        x.asset_type||'-',
        x.category||'-',
        x.model_name||'-',
        x.serial_number||'-',
        x.quantity||0,
        x.swapped_by||'-'
      ];
    }

    return [
      x.created_at||'-',
      x.user_name||'-',
      x.email||'-',
      x.role||'-',
      x.action||'-',
      x.module||'-',
      x.details||'-',
      x.ip_address||'-'
    ];
  });

  const reportTitle=configs[view].title;
  const headers=configs[view].heads;

  const csv=()=>{
    const csvContent=[headers,...dataRows]
      .map(row=>row.map(x=>`"${String(x??'').replaceAll('"','""')}"`).join(','))
      .join('\n');

    const blob=new Blob([csvContent],{type:'text/csv;charset=utf-8;'});
    const url=URL.createObjectURL(blob);
    const link=document.createElement('a');
    link.href=url;
    link.download=`venue-assets-${view}-report.csv`;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
  };

  const pdf=()=>{
    downloadSimplePDF(
      'Venue Asset Manager - '+reportTitle,
      headers,
      dataRows,
      `venue-assets-${view}-report.pdf`
    );
  };

  return <Page
    title="Reports"
    sub="MySQL reports — State, District, Venue, User, Asset, Letters, Swapping and Activity"
    action={
      <div className="report-actions">
        <button className="btn" onClick={csv}>
          <Download size={16}/>Export CSV
        </button>
        <button className="primary" onClick={pdf}>
          <Download size={16}/>Download PDF
        </button>
      </div>
    }
  >
    <section className="panel">
      <label>
        Report
        <select value={view} onChange={e=>setView(e.target.value)}>
          <option value="state">1. State-wise Report</option>
          <option value="district">2. District-wise Report</option>
          <option value="venue">3. Venue-wise Report</option>
          <option value="user">4. User-wise Report</option>
          <option value="asset">5. Asset-wise Report</option>
          <option value="letters">6. Asset Letters Report</option>
          <option value="swapping">7. Swapping Report</option>
          <option value="activity">8. User Activity Log</option>
        </select>
      </label>
    </section>

    {view==='activity'&&
      <section className="panel" style={{marginTop:'16px'}}>
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
              {userOptions.map(x=>
                <option key={x.id||x.email} value={x.email||x.username}>
                  {x.name} — {x.email||x.username}
                </option>
              )}
            </select>
          </label>

          <label>
            Module
            <select value={module} onChange={e=>setModule(e.target.value)}>
              <option value="">All Modules</option>
              {modules.map(x=><option key={x} value={x}>{x}</option>)}
            </select>
          </label>

          <label className="wide">
            Date Range
            <select value={preset} onChange={e=>applyPreset(e.target.value)}>
              <option value="">Custom</option>
              <option value="today">Today</option>
              <option value="yesterday">Yesterday</option>
              <option value="lastweek">Last week</option>
              <option value="thisweek">This week</option>
              <option value="thismonth">This Month</option>
              <option value="lastmonth">Last Month</option>
            </select>
          </label>
        </div>
      </section>
    }

    <section className="panel" style={{marginTop:'16px'}}>
      <h2>{reportTitle}</h2>
      {loading
        ? <p>Loading report...</p>
        : <Table heads={headers} rows={dataRows}/>
      }
    </section>
  </Page>
}

'@

# Apply replacements
$s = Replace-Block $s "function Reports(){" "function Calculator(){" $reports "Reports"
$s = Replace-Block $s "function Calculator(){" "function UsersPage(){" $calculator "Calculator"
$s = Replace-Block $s "function UsersPage(){" "function UserForm({" $usersPage "UsersPage"

[System.IO.File]::WriteAllText($path,$s,(New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Changes applied successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Protected Administrator:"
Write-Host "  - No Edit"
Write-Host "  - No Delete"
Write-Host "  - Protected by ID/email/name"
Write-Host ""
Write-Host "GST Calculator:"
Write-Host "  - Default: Including GST"
Write-Host "  - Option 1: Amount*Rate/(100+Rate)"
Write-Host "  - Option 2: (Amount-Rate)*Rate/(100+Rate)"
Write-Host "  - CGST/SGST = GST/2"
Write-Host "  - Net = Amount-Rate-GST"
Write-Host "  - Rates: 5%, 12%, 18%, 36%, 40%"
Write-Host ""
Write-Host "Reports Activity Log:"
Write-Host "  - Date From / Date To with time"
Write-Host "  - User selection"
Write-Host "  - Module selection"
Write-Host "  - Today / Yesterday / Last week / This week / This Month / Last Month"
Write-Host "  - Role, Action and Search removed"
Write-Host ""
Write-Host "Checking functions..."
Select-String -Path $path -Pattern 'function Calculator','function UsersPage','function Reports','function UserForm' |
  Select-Object LineNumber,Line
