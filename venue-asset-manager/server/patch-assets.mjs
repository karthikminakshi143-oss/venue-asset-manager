import fs from "fs";

const file = "./server.js";
let s = fs.readFileSync(file, "utf8");

function mustReplace(oldText, newText, name) {
  if (!s.includes(oldText)) {
    throw new Error("Could not find: " + name);
  }
  s = s.replaceAll(oldText, newText);
  console.log("Updated: " + name);
}

/* Add status to normalized asset returned to React */
mustReplace(
  "quantity:a.quantity,details:a.details||''",
  "quantity:a.quantity,status:a.status||'',details:a.details||''",
  "normalizeAsset"
);

/* Add status to cleaned asset */
mustReplace(
  "quantity:Number(x.quantity||1),details:x.details||''",
  "quantity:Number(x.quantity||1),status:x.status||'',details:x.details||''",
  "cleanAsset"
);

/* Add status to every asset INSERT */
mustReplace(
  "asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
  "asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,status,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
  "asset INSERT columns"
);

/* 15 placeholders -> 16 placeholders */
mustReplace(
  "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE",
  "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE",
  "asset INSERT placeholders"
);

/* Add status to duplicate update */
mustReplace(
  "serial_number=VALUES(serial_number),quantity=VALUES(quantity),details=VALUES(details)",
  "serial_number=VALUES(serial_number),quantity=VALUES(quantity),status=VALUES(status),details=VALUES(details)",
  "asset UPDATE status"
);

/* Add status to parameter arrays */
mustReplace(
  "z.serialNumber,z.quantity,z.details,z.invoiceNo",
  "z.serialNumber,z.quantity,z.status,z.details,z.invoiceNo",
  "sync asset parameters"
);

mustReplace(
  "x.serialNumber,x.quantity,x.details,x.invoiceNo",
  "x.serialNumber,x.quantity,x.status,x.details,x.invoiceNo",
  "save asset parameters"
);

/* Replace permanent DELETE with soft removal */
const oldDelete =
"app.delete('/api/assets/:id',auth,async(req,res)=>{try{await pool.query('DELETE FROM asset_master WHERE id=?',[req.params.id]);res.json({ok:true})}catch(e){res.status(500).json({error:e.message})}});";

const newDelete =
"app.delete('/api/assets/:id',auth,async(req,res)=>{try{await pool.query('UPDATE asset_master SET removed=1,removal_date=CURDATE(),updated_by=? WHERE id=?',[req.user.email,req.params.id]);res.json({ok:true})}catch(e){res.status(500).json({error:e.message})}});";

mustReplace(oldDelete,newDelete,"soft removal");

/* Add explicit removal-date endpoint */
const route =
"app.post('/api/assets/:id/remove',auth,async(req,res)=>{try{const d=req.body?.removalDate;if(!d)return res.status(400).json({error:'Removal Date is required'});await pool.query('UPDATE asset_master SET removed=1,removal_date=?,updated_by=? WHERE id=?',[d,req.user.email,req.params.id]);res.json({ok:true})}catch(e){res.status(500).json({error:e.message})}});";

if (!s.includes("/api/assets/:id/remove")) {
  s = s.replace(newDelete, newDelete + route);
  console.log("Added: removal-date API");
} else {
  console.log("Already present: removal-date API");
}

fs.writeFileSync(file, s, "utf8");
console.log("");
console.log("SUCCESS - server.js patched.");
