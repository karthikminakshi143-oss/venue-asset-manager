import fs from 'fs';

const file = './server.js';
let s = fs.readFileSync(file, 'utf8');

function replaceOnce(oldText, newText, label) {
  if (!s.includes(oldText)) {
    throw new Error(`Could not find: ${label}`);
  }
  s = s.replace(oldText, newText);
  console.log(`Updated: ${label}`);
}

/* 1. Add status to normalizeAsset */
replaceOnce(
"quantity:a.quantity,details:a.details||''",
"quantity:a.quantity,status:a.status||'',details:a.details||''",
"normalizeAsset status"
);

/* 2. Add status to cleanAsset */
replaceOnce(
"quantity:Number(x.quantity||1),details:x.details||''",
"quantity:Number(x.quantity||1),status:x.status||'',details:x.details||''",
"cleanAsset status"
);

/* 3. Add status to the CREATE TABLE definition for fresh installations */
replaceOnce(
"serial_number VARCHAR(200) NULL,quantity INT NOT NULL DEFAULT 1,details VARCHAR(255)",
"serial_number VARCHAR(200) NULL,quantity INT NOT NULL DEFAULT 1,status VARCHAR(100) NULL,details VARCHAR(255)",
"asset_master schema status"
);

/* 4. upsertAsset SQL */
replaceOnce(
"asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
"asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,status,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
"upsertAsset columns"
);

replaceOnce(
"VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE venue_id=VALUES(venue_id)",
"VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE venue_id=VALUES(venue_id)",
"upsertAsset values"
);

replaceOnce(
"serialNumber,quantity,details,invoiceNo,invoiceDate||null,vendorName,removalDate||null,removed,updatedBy,createdBy",
"serialNumber,quantity,status,details,invoiceNo,invoiceDate||null,vendorName,removalDate||null,removed,updatedBy,createdBy",
"upsertAsset parameters"
);

/* 5. sync assets SQL */
replaceOnce(
"asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
"asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,status,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
"sync asset columns"
);

replaceOnce(
"VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE venue_id=VALUES(venue_id)",
"VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE venue_id=VALUES(venue_id)",
"sync asset values"
);

replaceOnce(
"z.serialNumber,z.quantity,z.details,z.invoiceNo,z.invoiceDate||null,z.vendorName,z.removalDate||null,z.removed,z.updatedBy,z.createdBy",
"z.serialNumber,z.quantity,z.status,z.details,z.invoiceNo,z.invoiceDate||null,z.vendorName,z.removalDate||null,z.removed,z.updatedBy,z.createdBy",
"sync asset parameters"
);

/* 6. /api/assets/save SQL */
replaceOnce(
"asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
"asset_master(id,venue_id,asset_type,category,model_name,serial_number,quantity,status,details,invoice_no,invoice_date,vendor_name,removal_date,removed,updated_by,created_by)",
"save asset columns"
);

replaceOnce(
"VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE venue_id=VALUES(venue_id)",
"VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE venue_id=VALUES(venue_id)",
"save asset values"
);

replaceOnce(
"x.serialNumber,x.quantity,x.details,x.invoiceNo,x.invoiceDate||null,x.vendorName,x.removalDate||null,x.removed,x.updatedBy,x.createdBy",
"x.serialNumber,x.quantity,x.status,x.details,x.invoiceNo,x.invoiceDate||null,x.vendorName,x.removalDate||null,x.removed,x.updatedBy,x.createdBy",
"save asset parameters"
);

/* 7. Replace permanent delete with soft removal */
const oldDelete =
"app.delete('/api/assets/:id',auth,async(req,res)=>{try{await pool.query('DELETE FROM asset_master WHERE id=?',[req.params.id]);res.json({ok:true})}catch(e){res.status(500).json({error:e.message})}});";

const newDelete =
"app.delete('/api/assets/:id',auth,async(req,res)=>{try{await pool.query('UPDATE asset_master SET removed=1,removal_date=CURDATE(),updated_by=? WHERE id=?',[req.user.email,req.params.id]);res.json({ok:true})}catch(e){res.status(500).json({error:e.message})}});";

replaceOnce(oldDelete,newDelete,"soft asset removal");

/* 8. Add explicit removal endpoint */
const marker = newDelete;

const removalRoute =
"app.post('/api/assets/:id/remove',auth,async(req,res)=>{try{const d=req.body?.removalDate||null;if(!d)return res.status(400).json({error:'Removal Date is required'});await pool.query('UPDATE asset_master SET removed=1,removal_date=?,updated_by=? WHERE id=?',[d,req.user.email,req.params.id]);res.json({ok:true})}catch(e){res.status(500).json({error:e.message})}});";

replaceOnce(
marker,
marker + removalRoute,
"asset removal date endpoint"
);

fs.writeFileSync(file, s, 'utf8');
console.log('');
console.log('SUCCESS: server.js updated.');
