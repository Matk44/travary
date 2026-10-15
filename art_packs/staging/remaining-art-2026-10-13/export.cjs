// Mechanical export guard: generated artwork, original shell pixels and alpha.
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');
const crcTable = Array.from({length:256},(_,n)=>{for(let k=0;k<8;k++) n=(n&1)?0xedb88320^(n>>>1):n>>>1;return n>>>0;});
function crc(b){let c=0xffffffff;for(const v of b)c=crcTable[(c^v)&255]^(c>>>8);return (c^0xffffffff)>>>0;}
function read(file){
 const b=fs.readFileSync(file);let w,h,depth,type,parts=[];
 for(let o=8;o<b.length;){const n=b.readUInt32BE(o),t=b.toString('ascii',o+4,o+8),d=b.subarray(o+8,o+8+n);if(t==='IHDR'){w=d.readUInt32BE(0);h=d.readUInt32BE(4);depth=d[8];type=d[9];if(d[12])throw Error('Interlaced PNG');}if(t==='IDAT')parts.push(d);o+=n+12;}
 if(depth!==8||type!==6)throw Error(`Expected RGBA8: ${file} (${depth},${type})`);
 const raw=zlib.inflateSync(Buffer.concat(parts)),data=Buffer.alloc(w*h*4),stride=w*4;
 function paeth(a,b,c){const p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;}
 for(let y=0;y<h;y++){const f=raw[y*(stride+1)];for(let x=0;x<stride;x++){const i=y*stride+x,a=x>=4?data[i-4]:0,b=y?data[i-stride]:0,c=y&&x>=4?data[i-stride-4]:0;let v=raw[y*(stride+1)+1+x];v+=f===1?a:f===2?b:f===3?Math.floor((a+b)/2):f===4?paeth(a,b,c):0;data[i]=v&255;}}
 return {w,h,data};
}
function write(file,im){
 function chunk(t,d){const tb=Buffer.from(t),out=Buffer.alloc(d.length+12);out.writeUInt32BE(d.length);tb.copy(out,4);d.copy(out,8);out.writeUInt32BE(crc(Buffer.concat([tb,d])),d.length+8);return out;}
 const head=Buffer.alloc(13);head.writeUInt32BE(im.w);head.writeUInt32BE(im.h,4);head[8]=8;head[9]=6;
 const raw=Buffer.alloc((im.w*4+1)*im.h);for(let y=0;y<im.h;y++)im.data.copy(raw,y*(im.w*4+1)+1,y*im.w*4,(y+1)*im.w*4);
 fs.mkdirSync(path.dirname(file),{recursive:true});if(fs.existsSync(file)&&!process.argv.includes('--replace-generated'))throw Error(`Refusing to overwrite ${file}`);
 fs.writeFileSync(file,Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',head),chunk('IDAT',zlib.deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]));
}
function poly(x,y,p){let inside=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const [a,b]=p[i],[c,d]=p[j];if(((b>y)!==(d>y))&&(x<(c-a)*(y-b)/(d-b)+a))inside=!inside;}return inside;}
function exportCard(root,place,role,source,palette){
 const base=read(path.join(root,'art_packs/prompts/city_card_references',role+'.png')),gen=read(source);
 if(Math.abs(gen.w-base.w)>1||gen.h!==base.h)throw Error(`Unexpected canvas ${place}/${role}: ${gen.w}x${gen.h}`);
 const out={w:base.w,h:base.h,data:Buffer.from(base.data)};
 const tag=[[225,217],[391,196],[451,242],[506,612],[481,648],[258,678],[227,658],[174,325],[178,294]];
 function put(x,y,sx=x,sy=y,weight=1){const i=(y*base.w+x)*4,j=(Math.max(0,Math.min(gen.h-1,Math.round(sy)))*gen.w+Math.max(0,Math.min(gen.w-1,Math.round(sx))))*4;if(gen.data[j+3]<250)return;for(let k=0;k<3;k++)out.data[i+k]=Math.round(out.data[i+k]*(1-weight)+gen.data[j+k]*weight);}
 function stripe(x,y){const i=(y*base.w+x)*4,[r,g,b]=base.data.subarray(i,i+3);let old,target;if(b>r*1.1){old=[10,54,76];target=palette[0];}else if(r>g*1.3&&r>b*1.4){old=[205,72,46];target=palette[1];}else if(r>g*1.05&&g>b*1.4){old=[219,151,39];target=palette[2];}else return;const light=Math.max(.6,Math.min(1.2,(.2126*r+.7152*g+.0722*b)/(.2126*old[0]+.7152*old[1]+.0722*old[2])));for(let k=0;k<3;k++)out.data[i+k]=Math.max(0,Math.min(255,Math.round(target[k]*light)));}
 for(let y=0;y<base.h;y++)for(let x=0;x<base.w;x++){
  const i=(y*base.w+x)*4;if(base.data[i+3]<240)continue;
  if(role==='featured_ticket'){
   if(x>=48&&x<1361&&y>=108&&y<790){
    // Fit the generated scene to the strict 42% blank-text boundary.
    const sx=x<746?80+(x-48)*360/698:540+(x-746)*821/615;
    if(x>=746){
     put(x,y,440-(x-746)*360/615,y);
     const top=790-682*615/821;
     if(y>=top)put(x,y,sx,108+(y-top)*821/615,Math.min(1,(x-746)/64)*Math.min(1,(y-top)/64));
    }else put(x,y,sx,y);
   }
   if(x>=1394&&x<1486&&y>=108&&y<786)stripe(x,y);
  }else if(role==='room_card'){
   if(x>=58&&x<1484&&y>=96&&y<794){
    // Original left paper remains; extend it where the old landscape began.
    if(x>=700&&x<1100)put(x,y,430+(x-700)*270/400,y);
    else if(x>=1100){
     put(x,y,700-(x-1100)*270/384,y);
     const top=794-698*384/724;
     if(y>=top)put(x,y,760+(x-1100)*724/384,96+(y-top)*724/384,Math.min(1,(x-1100)/48)*Math.min(1,(y-top)/48));
    }
   }
   if(x>=1484&&x<1678&&y>=96&&y<790)stripe(x,y);
  }else{
   if(x>=1423&&x<1950&&y>=165&&y<713)put(x,y);
   if(x>=1406&&x<1413&&y>=192&&y<692)stripe(x,y);
   if(poly(x,y,tag)&&Math.hypot(x-307,y-269)>51&&!(x<326&&y<289))put(x,y);
  }
 }
 // Recolour original navy tag edging and the paper around the grommet;
 // preserve brass, cord, paper and exact tag geometry. Generated tag face
 // remains unchanged. This avoids a blue collar around a sage tag.
 if(role==='reservation_card')for(let y=190;y<686;y++)for(let x=170;x<515;x++){
  const i=(y*base.w+x)*4, [r,g,b]=out.data.subarray(i,i+3);
  if(b>r*1.12&&b>g*1.06&&r<100&&g<140&&out.data[i]===base.data[i]&&out.data[i+1]===base.data[i+1]&&out.data[i+2]===base.data[i+2]){
   const j=(450*gen.w+350)*4, light=Math.max(.45,Math.min(1.15,(r+g+b)/115));
   for(let k=0;k<3;k++)out.data[i+k]=Math.round(gen.data[j+k]*light);
  }
 }
 // Preserve the complete brass eyelet, including its cool reflections.
 if(role==='reservation_card')for(let y=226;y<=312;y++)for(let x=264;x<=350;x++){
  if(Math.hypot(x-307,y-269)<=43){const i=(y*base.w+x)*4;base.data.copy(out.data,i,i,i+4);}
 }
 // Protect the exact exterior outline and its antialiasing/shadow bytes.
 for(let y=1;y<base.h-1;y++)for(let x=1;x<base.w-1;x++){
  let edge=false;for(const [dx,dy] of [[-3,0],[3,0],[0,-3],[0,3]]){const a=base.data[((y+dy)*base.w+x+dx)*4+3];if(a<240)edge=true;}
  if(edge){const i=(y*base.w+x)*4;base.data.copy(out.data,i,i,i+4);}
 }
 const file=path.join(root,'art_packs/staging',place,role+'.png');write(file,out);
 let alphaChanges=0;for(let i=3;i<base.data.length;i+=4)if(base.data[i]!==out.data[i])alphaChanges++;
 console.log(JSON.stringify({place,role,path:file,size:[out.w,out.h],alphaChanges}));
}
const [root,jobFile]=process.argv.slice(2);for(const job of JSON.parse(fs.readFileSync(jobFile,'utf8')))exportCard(root,job.place,job.role,job.source,job.palette);
